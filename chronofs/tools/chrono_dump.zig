/// chrono_dump — chronofs diagnostic tool
///
/// Reads newline-delimited JSON from one or more subsystem log streams,
/// ingests them through the chronofs resolver, and prints a merged timeline.
///
/// Usage:
///   # Live: pipe all subsystem stdout into chrono_dump
///   { semaaud; semainputd; semadrawd; } | chrono_dump
///
///   # Drift analysis
///   { semaaud; semadrawd; } | chrono_dump --drift
///
///   # Replay a recorded log
///   chrono_dump --replay fabric.log
///
/// Each output line has the form:
///   t=<samples>  [<domain>]  <event>  <fields>
///
/// With --drift, frame_complete lines are followed by:
///   drift: expected=<t> actual=<t> delta=<n> samples (<ms>ms)

const std = @import("std");
const resolver_mod = @import("resolver");
const stream_mod   = @import("stream");
const clock_mod    = @import("clock");

const DomainStreams = stream_mod.DomainStreams;
const Resolver      = resolver_mod.Resolver;
const Clock         = clock_mod.Clock;

// ============================================================================
// stdout/stderr helpers following codebase conventions
// ============================================================================

fn writeStdout(line: []const u8) void {
    var file = std.fs.File.stdout();
    var buf: [4096]u8 = undefined;
    var w = file.writer(&buf);
    w.interface.writeAll(line) catch {};
    w.interface.flush() catch {};
}

fn writeStderr(line: []const u8) void {
    var file = std.fs.File.stderr();
    var buf: [4096]u8 = undefined;
    var w = file.writer(&buf);
    w.interface.writeAll(line) catch {};
    w.interface.flush() catch {};
}

fn printFmt(comptime fmt: []const u8, args: anytype) void {
    var buf: [512]u8 = undefined;
    const s = std.fmt.bufPrint(&buf, fmt, args) catch return;
    writeStdout(s);
}

// ============================================================================
// CLI argument parsing
// ============================================================================

const Mode = enum { live, drift, replay };

const Args = struct {
    mode:        Mode            = .live,
    replay_path: ?[]const u8    = null,
    /// Samples per frame for drift analysis (default 48000/60 = 800).
    spf:         u64            = 800,
    /// Sample rate for time display (default 48000).
    sample_rate: u32            = 48_000,
};

fn parseArgs(argv: []const []const u8) !Args {
    var a = Args{};
    var i: usize = 1;
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];
        if (std.mem.eql(u8, arg, "--drift")) {
            a.mode = .drift;
        } else if (std.mem.eql(u8, arg, "--replay")) {
            a.mode = .replay;
            i += 1;
            if (i >= argv.len) return error.MissingArg;
            a.replay_path = argv[i];
        } else if (std.mem.eql(u8, arg, "--spf")) {
            i += 1;
            if (i >= argv.len) return error.MissingArg;
            a.spf = try std.fmt.parseInt(u64, argv[i], 10);
        } else if (std.mem.eql(u8, arg, "--rate")) {
            i += 1;
            if (i >= argv.len) return error.MissingArg;
            a.sample_rate = try std.fmt.parseInt(u32, argv[i], 10);
        } else {
            var ebuf: [128]u8 = undefined;
            const msg = std.fmt.bufPrint(&ebuf, "chrono_dump: unknown argument: {s}\n", .{arg})
                catch "chrono_dump: unknown argument\n";
            writeStderr(msg);
            return error.UnknownArg;
        }
    }
    return a;
}

// ============================================================================
// JSON field extractors
// ============================================================================

fn extractSubsystem(line: []const u8) ?[]const u8 {
    const key = "\"subsystem\":\"";
    const idx = std.mem.indexOf(u8, line, key) orelse return null;
    const start = idx + key.len;
    const end = std.mem.indexOfScalarPos(u8, line, start, '"') orelse return null;
    return line[start..end];
}

fn extractStr(line: []const u8, key: []const u8) ?[]const u8 {
    var pat_buf: [64]u8 = undefined;
    const pat = std.fmt.bufPrint(&pat_buf, "\"{s}\":\"", .{key}) catch return null;
    const idx = std.mem.indexOf(u8, line, pat) orelse return null;
    const start = idx + pat.len;
    const end = std.mem.indexOfScalarPos(u8, line, start, '"') orelse return null;
    return line[start..end];
}

fn extractU64(line: []const u8, key: []const u8) ?u64 {
    var pat_buf: [64]u8 = undefined;
    const pat = std.fmt.bufPrint(&pat_buf, "\"{s}\":", .{key}) catch return null;
    const idx = std.mem.indexOf(u8, line, pat) orelse return null;
    var i = idx + pat.len;
    while (i < line.len and line[i] == ' ') : (i += 1) {}
    var end = i;
    while (end < line.len and std.ascii.isDigit(line[end])) : (end += 1) {}
    if (end == i) return null;
    return std.fmt.parseInt(u64, line[i..end], 10) catch null;
}

fn extractAudioSamples(line: []const u8) ?u64 {
    const key = "\"ts_audio_samples\":";
    const idx = std.mem.indexOf(u8, line, key) orelse return null;
    var i = idx + key.len;
    while (i < line.len and line[i] == ' ') : (i += 1) {}
    if (std.mem.startsWith(u8, line[i..], "null")) return null;
    var end = i;
    while (end < line.len and std.ascii.isDigit(line[end])) : (end += 1) {}
    if (end == i) return null;
    return std.fmt.parseInt(u64, line[i..end], 10) catch null;
}

// ============================================================================
// Timeline printers
// ============================================================================

fn printAudioLine(t: u64, event_type: []const u8, line: []const u8) void {
    const stream_id = extractU64(line, "stream_id") orelse 0;
    const active = std.mem.eql(u8, event_type, "stream_begin");
    printFmt("t={d:<12} [audio]  {s:<20} stream_id={d} active={}\n",
        .{ t, event_type, stream_id, active });
}

fn printInputLine(t: u64, event_type: []const u8, line: []const u8) void {
    const device = extractStr(line, "device") orelse "";
    const dx = extractU64(line, "dx") orelse 0;
    const dy = extractU64(line, "dy") orelse 0;
    if (dx != 0 or dy != 0) {
        printFmt("t={d:<12} [input]  {s:<20} device={s} dx={d} dy={d}\n",
            .{ t, event_type, device, dx, dy });
    } else {
        printFmt("t={d:<12} [input]  {s:<20} device={s}\n",
            .{ t, event_type, device });
    }
}

fn printVisualLine(t: u64, event_type: []const u8, line: []const u8) void {
    const surface_id   = extractU64(line, "surface_id")  orelse 0;
    const frame_number = extractU64(line, "frame_number") orelse 0;
    printFmt("t={d:<12} [visual] {s:<20} surface_id={d} frame={d}\n",
        .{ t, event_type, surface_id, frame_number });
}

// ============================================================================
// Drift tracker
// ============================================================================

const DriftTracker = struct {
    spf:             u64,
    sample_rate:     u32,
    next_expected_t: ?u64 = null,
    total_drift:     u64  = 0,
    frame_count:     u64  = 0,

    pub fn onFrame(self: *DriftTracker, t: u64) void {
        if (self.next_expected_t) |expected| {
            const drift: i64 = @as(i64, @intCast(t)) - @as(i64, @intCast(expected));
            const abs_drift: u64 = @intCast(@abs(drift));
            self.total_drift += abs_drift;
            self.frame_count += 1;
            const rate: f64 = if (self.sample_rate > 0)
                @as(f64, @floatFromInt(self.sample_rate)) else 48_000.0;
            const drift_ms = @as(f64, @floatFromInt(drift)) / rate * 1000.0;
            printFmt("  drift: expected={d} actual={d} delta={d} samples ({d:.2}ms)\n",
                .{ expected, t, drift, drift_ms });
            if (self.frame_count > 0) {
                const avg = self.total_drift / self.frame_count;
                const avg_ms = @as(f64, @floatFromInt(avg)) / rate * 1000.0;
                printFmt("  avg drift over {d} frames: {d} samples ({d:.2}ms)\n",
                    .{ self.frame_count, avg, avg_ms });
            }
        }
        self.next_expected_t = t + self.spf;
    }
};

// ============================================================================
// Ingestion dispatcher
// ============================================================================

fn ingestLine(streams: *DomainStreams, line: []const u8) void {
    const subsystem = extractSubsystem(line) orelse return;
    if (std.mem.eql(u8, subsystem, "semaaud")) {
        resolver_mod.ingestSemaaudLine(streams, line) catch {};
    } else if (std.mem.eql(u8, subsystem, "semainput")) {
        resolver_mod.ingestSemainputLine(streams, line) catch {};
    } else if (std.mem.eql(u8, subsystem, "semadraw")) {
        resolver_mod.ingestSemadrawLine(streams, line) catch {};
    }
}

// ============================================================================
// Live / drift mode
// ============================================================================

fn runLive(args: Args) !void {
    var streams = DomainStreams.init();
    var drift = DriftTracker{ .spf = args.spf, .sample_rate = args.sample_rate };

    var stdin_file = std.fs.File.stdin();
    var buf: [8192]u8 = undefined;
    var pending: usize = 0;

    while (true) {
        const n = stdin_file.read(buf[pending..]) catch break;
        if (n == 0) break;
        pending += n;

        var start: usize = 0;
        while (std.mem.indexOfScalarPos(u8, buf[0..pending], start, '\n')) |nl| {
            const line = buf[start..nl];
            start = nl + 1;
            if (line.len == 0) continue;

            ingestLine(&streams, line);

            const t            = extractAudioSamples(line) orelse continue;
            const event_type   = extractStr(line, "type") orelse continue;
            const subsystem    = extractSubsystem(line) orelse continue;

            if (std.mem.eql(u8, subsystem, "semaaud")) {
                printAudioLine(t, event_type, line);
            } else if (std.mem.eql(u8, subsystem, "semainput")) {
                printInputLine(t, event_type, line);
            } else if (std.mem.eql(u8, subsystem, "semadraw")) {
                printVisualLine(t, event_type, line);
                if (args.mode == .drift and std.mem.eql(u8, event_type, "frame_complete")) {
                    drift.onFrame(t);
                }
            }
        }

        if (start < pending) {
            std.mem.copyForwards(u8, &buf, buf[start..pending]);
            pending -= start;
        } else {
            pending = 0;
        }
    }
}

// ============================================================================
// Replay mode
// ============================================================================

fn runReplay(args: Args, allocator: std.mem.Allocator) !void {
    const path = args.replay_path orelse return error.MissingReplayPath;

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, 64 * 1024 * 1024);
    defer allocator.free(content);

    var streams = DomainStreams.init();
    var max_t: u64 = 0;

    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        ingestLine(&streams, line);
        if (extractAudioSamples(line)) |t| {
            if (t > max_t) max_t = t;
        }
    }

    if (max_t == 0) {
        writeStdout("chrono_dump: no audio-timestamped events in replay file\n");
        return;
    }

    const clk = Clock.init("/var/run/sema/clock_c5_replay_absent");
    defer clk.deinit();
    const r = Resolver.init(&streams, clk);

    const interval: u64 = 1000;
    const rate: f64 = if (args.sample_rate > 0)
        @as(f64, @floatFromInt(args.sample_rate)) else 48_000.0;

    var t: u64 = 0;
    while (t <= max_t + interval) : (t += interval) {
        const secs = @as(f64, @floatFromInt(t)) / rate;
        printFmt("t={d:<12} ({d:.3}s)\n", .{ t, secs });

        const state = r.resolveAll(t);

        if (state.audio) |a| {
            printFmt("  audio:  stream_id={d} samples_written={d} active={}\n",
                .{ a.stream_id, a.samples_written, a.active });
        } else {
            writeStdout("  audio:  (none)\n");
        }

        if (state.visual) |v| {
            printFmt("  visual: surface_id={d} frame={d}\n",
                .{ v.surface_id, v.frame_number });
        } else {
            writeStdout("  visual: (none)\n");
        }

        if (state.input) |inp| {
            printFmt("  input:  {s} device={s}\n",
                .{ inp.typeName(), inp.deviceName() });
        } else {
            writeStdout("  input:  (none)\n");
        }
    }
}

// ============================================================================
// Entry point
// ============================================================================

const USAGE =
    \\Usage: chrono_dump [--drift] [--replay <file>] [--spf <n>] [--rate <hz>]
    \\
    \\  (no flags)      Read unified JSON-lines from stdin, print timeline
    \\  --drift         Also report per-frame drift vs audio clock
    \\  --replay <file> Read a recorded log file, print resolved state
    \\                  at every 1000-sample interval
    \\  --spf <n>       Samples per frame for drift analysis (default: 800)
    \\  --rate <hz>     Sample rate for time display (default: 48000)
    \\
    \\Examples:
    \\  { semaaud; semainputd; semadrawd; } 2>/dev/null | chrono_dump --drift
    \\  chrono_dump --replay fabric.log --rate 48000
    \\
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    const args = parseArgs(argv) catch {
        writeStderr(USAGE);
        return;
    };

    switch (args.mode) {
        .live, .drift => try runLive(args),
        .replay       => try runReplay(args, allocator),
    }
}
