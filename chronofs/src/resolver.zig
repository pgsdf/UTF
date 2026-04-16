const std = @import("std");
const stream_mod = @import("stream");
const clock_mod   = @import("clock");

const DomainStreams = stream_mod.DomainStreams;
const AudioEvent   = stream_mod.AudioEvent;
const VisualEvent  = stream_mod.VisualEvent;
const InputEvent   = stream_mod.InputEvent;
const Clock        = clock_mod.Clock;

// ============================================================================
// Resolver
// ============================================================================

/// The chronofs resolver: given a sample position `t`, answers "what was
/// the state of each domain at that point on the audio timeline?"
///
/// All resolve functions delegate to the corresponding `DomainStreams.at(t)`.
/// `currentTime()` delegates to `clock.now()` so callers can ask "what is
/// happening right now" without needing to hold the clock directly.
pub const Resolver = struct {
    streams: *DomainStreams,
    clock:   Clock,

    pub fn init(streams: *DomainStreams, clock: Clock) Resolver {
        return .{ .streams = streams, .clock = clock };
    }

    /// Current audio clock position in sample frames.
    /// Returns 0 if the clock is not valid (semaaud not running).
    pub fn currentTime(self: Resolver) u64 {
        return self.clock.now();
    }

    /// True if the audio clock is live (at least one stream has started).
    pub fn clockValid(self: Resolver) bool {
        return self.clock.isValid();
    }

    /// Most recent visual (frame_complete) event at or before `t`.
    pub fn resolveVisual(self: Resolver, t: u64) ?VisualEvent {
        const e = self.streams.visual.at(t) orelse return null;
        return e.payload;
    }

    /// Most recent input event at or before `t`.
    pub fn resolveInput(self: Resolver, t: u64) ?InputEvent {
        const e = self.streams.input.at(t) orelse return null;
        return e.payload;
    }

    /// Most recent audio lifecycle event at or before `t`.
    pub fn resolveAudio(self: Resolver, t: u64) ?AudioEvent {
        const e = self.streams.audio.at(t) orelse return null;
        return e.payload;
    }

    /// Resolve all three domains at `t` in one call.
    pub fn resolveAll(self: Resolver, t: u64) ResolvedState {
        return .{
            .t      = t,
            .audio  = self.resolveAudio(t),
            .visual = self.resolveVisual(t),
            .input  = self.resolveInput(t),
        };
    }
};

/// The resolved state of all domains at a single sample position.
pub const ResolvedState = struct {
    t:      u64,
    audio:  ?AudioEvent,
    visual: ?VisualEvent,
    input:  ?InputEvent,
};

// ============================================================================
// JSON ingestion helpers
// ============================================================================
//
// Each ingest function parses one JSON-lines event from a subsystem's stdout
// and appends it to the appropriate stream.
//
// The unified schema guarantees:
//   {"type":"...","subsystem":"...","session":"...","seq":N,
//    "ts_wall_ns":N,"ts_audio_samples":N|null,...}
//
// We extract `ts_audio_samples` as the timeline index `t`.
// Events with `ts_audio_samples: null` are silently skipped — they have no
// position on the audio timeline.
//
// Unknown `type` values produce error.UnknownEventType, which callers ignore.

pub const IngestError = error{
    MissingField,
    InvalidNumber,
    NullAudioSamples,
    UnknownEventType,
};

/// Extract the string value of a JSON field from a flat JSON line.
/// Looks for `"key":"<value>"` — the value is the content between the quotes
/// immediately after the colon.  Returns a slice into `line`.
fn extractString(line: []const u8, key: []const u8) ![]const u8 {
    var pat_buf: [64]u8 = undefined;
    const pat = std.fmt.bufPrint(&pat_buf, "\"{s}\":\"", .{key}) catch
        return error.MissingField;
    const idx = std.mem.indexOf(u8, line, pat) orelse return error.MissingField;
    const start = idx + pat.len;
    const end = std.mem.indexOfScalarPos(u8, line, start, '"') orelse
        return error.MissingField;
    return line[start..end];
}

/// Extract a u64 value: handles `"key":123` and `"key": 123`.
fn extractU64(line: []const u8, key: []const u8) !u64 {
    var pat_buf: [64]u8 = undefined;
    const pat = std.fmt.bufPrint(&pat_buf, "\"{s}\":", .{key}) catch
        return error.MissingField;
    const idx = std.mem.indexOf(u8, line, pat) orelse return error.MissingField;
    var i = idx + pat.len;
    while (i < line.len and line[i] == ' ') : (i += 1) {}
    var end = i;
    while (end < line.len and std.ascii.isDigit(line[end])) : (end += 1) {}
    if (end == i) return error.InvalidNumber;
    return std.fmt.parseInt(u64, line[i..end], 10) catch error.InvalidNumber;
}

/// Extract a u32 value.
fn extractU32(line: []const u8, key: []const u8) !u32 {
    const v = try extractU64(line, key);
    return @intCast(v);
}

/// Extract `ts_audio_samples`: returns error.NullAudioSamples if the value
/// is the literal `null`, or error.MissingField if the key is absent.
fn extractAudioSamples(line: []const u8) !u64 {
    var pat_buf: [64]u8 = undefined;
    const pat = std.fmt.bufPrint(&pat_buf, "\"ts_audio_samples\":", .{}) catch
        return error.MissingField;
    const idx = std.mem.indexOf(u8, line, pat) orelse return error.MissingField;
    var i = idx + pat.len;
    while (i < line.len and line[i] == ' ') : (i += 1) {}
    // Check for null
    if (std.mem.startsWith(u8, line[i..], "null")) return error.NullAudioSamples;
    // Parse integer
    var end = i;
    while (end < line.len and std.ascii.isDigit(line[end])) : (end += 1) {}
    if (end == i) return error.InvalidNumber;
    return std.fmt.parseInt(u64, line[i..end], 10) catch error.InvalidNumber;
}

/// Ingest one JSON-lines event from semaaud into the audio stream.
/// Recognised types: stream_begin, stream_end, stream_stop, stream_flush,
/// stream_preempt, stream_reject.
pub fn ingestSemaaudLine(streams: *DomainStreams, line: []const u8) !void {
    const t = extractAudioSamples(line) catch |e| switch (e) {
        error.NullAudioSamples => return, // no audio position yet — skip
        else => return e,
    };

    const event_type = try extractString(line, "type");

    // All semaaud stream events map to an AudioEvent.
    // stream_begin → active=true, stream_end/stop/flush → active=false.
    const active = std.mem.eql(u8, event_type, "stream_begin");
    const inactive = std.mem.eql(u8, event_type, "stream_end") or
                     std.mem.eql(u8, event_type, "stream_stop") or
                     std.mem.eql(u8, event_type, "stream_flush") or
                     std.mem.eql(u8, event_type, "stream_preempt");

    if (!active and !inactive) return error.UnknownEventType;

    const stream_id = extractU64(line, "stream_id") catch 0;
    const samples   = extractU64(line, "samples_written") catch t;

    streams.appendAudio(t, .{
        .stream_id       = stream_id,
        .samples_written = samples,
        .active          = active,
    });
}

/// Ingest one JSON-lines event from semainput into the input stream.
/// Recognised types: all semantic and gesture event types.
/// Lifecycle types (daemon_start, daemon_state, classification_snapshot,
/// identity_snapshot) are silently skipped.
pub fn ingestSemainputLine(streams: *DomainStreams, line: []const u8) !void {
    const t = extractAudioSamples(line) catch |e| switch (e) {
        error.NullAudioSamples => return,
        else => return e,
    };

    const event_type = try extractString(line, "type");

    // Skip lifecycle events.
    const lifecycle = std.mem.eql(u8, event_type, "daemon_start") or
                      std.mem.eql(u8, event_type, "daemon_state") or
                      std.mem.eql(u8, event_type, "classification_snapshot") or
                      std.mem.eql(u8, event_type, "identity_snapshot");
    if (lifecycle) return;

    const device = extractString(line, "device") catch "";
    var ev = InputEvent.fromType(event_type, device);

    // Optionally extract x/y for pointer and touch events.
    ev.x = @intCast(extractU32(line, "x") catch 0);
    ev.y = @intCast(extractU32(line, "y") catch 0);

    streams.appendInput(t, ev);
}

/// Ingest one JSON-lines event from semadraw into the visual stream.
/// Recognised types: frame_complete.
/// client_connected, client_disconnected, surface_created, surface_destroyed
/// are skipped (not relevant to the visual timeline).
pub fn ingestSemadrawLine(streams: *DomainStreams, line: []const u8) !void {
    const t = extractAudioSamples(line) catch |e| switch (e) {
        error.NullAudioSamples => return,
        else => return e,
    };

    const event_type = try extractString(line, "type");
    if (!std.mem.eql(u8, event_type, "frame_complete"))
        return error.UnknownEventType;

    const surface_id    = try extractU32(line, "surface_id");
    const frame_number  = extractU64(line, "frame_number") catch 0;

    streams.appendVisual(t, .{
        .surface_id   = surface_id,
        .frame_number = frame_number,
    });
}

// ============================================================================
// Ingestion driver
// ============================================================================

/// Which subsystem a driver thread is reading from.
pub const Subsystem = enum { semaaud, semainput, semadraw };

/// Arguments passed to an ingestion thread.
pub const IngestionArgs = struct {
    streams:   *DomainStreams,
    fd:        std.posix.fd_t,
    subsystem: Subsystem,
};

/// Run an ingestion thread. Reads newline-delimited JSON from `args.fd` and
/// ingests each line into the appropriate domain stream.  Runs until EOF or
/// read error.  Intended to be spawned with `std.Thread.spawn`.
pub fn ingestionThread(args: IngestionArgs) void {
    var buf: [8192]u8 = undefined;
    var pending: usize = 0;

    while (true) {
        const n = std.posix.read(args.fd, buf[pending..]) catch break;
        if (n == 0) break; // EOF

        pending += n;
        var start: usize = 0;

        // Process complete lines.
        while (std.mem.indexOfScalarPos(u8, buf[0..pending], start, '\n')) |nl| {
            const line = buf[start..nl];
            if (line.len > 0) {
                const err = switch (args.subsystem) {
                    .semaaud   => ingestSemaaudLine(args.streams, line),
                    .semainput => ingestSemainputLine(args.streams, line),
                    .semadraw  => ingestSemadrawLine(args.streams, line),
                };
                // Silently ignore unknown event types and null audio samples.
                err catch |e| switch (e) {
                    error.UnknownEventType, error.NullAudioSamples => {},
                    else => {}, // log in a future debug build
                };
            }
            start = nl + 1;
        }

        // Shift remaining partial line to start of buffer.
        if (start < pending) {
            std.mem.copyForwards(u8, &buf, buf[start..pending]);
            pending -= start;
        } else {
            pending = 0;
        }
    }
}

/// Spawn one ingestion thread per subsystem fd.
/// Returns the thread handles — callers should join them at shutdown.
pub fn spawnIngestionThreads(
    streams:    *DomainStreams,
    semaaud_fd: std.posix.fd_t,
    semainput_fd: std.posix.fd_t,
    semadraw_fd:  std.posix.fd_t,
) ![3]std.Thread {
    var threads: [3]std.Thread = undefined;
    threads[0] = try std.Thread.spawn(.{}, ingestionThread, .{IngestionArgs{
        .streams   = streams,
        .fd        = semaaud_fd,
        .subsystem = .semaaud,
    }});
    threads[1] = try std.Thread.spawn(.{}, ingestionThread, .{IngestionArgs{
        .streams   = streams,
        .fd        = semainput_fd,
        .subsystem = .semainput,
    }});
    threads[2] = try std.Thread.spawn(.{}, ingestionThread, .{IngestionArgs{
        .streams   = streams,
        .fd        = semadraw_fd,
        .subsystem = .semadraw,
    }});
    return threads;
}

// ============================================================================
// Tests
// ============================================================================

test "Resolver resolveVisual returns most recent frame at or before t" {
    var ds = DomainStreams.init();
    ds.appendVisual(1000, .{ .surface_id = 1, .frame_number = 1 });
    ds.appendVisual(2000, .{ .surface_id = 1, .frame_number = 2 });
    ds.appendVisual(3000, .{ .surface_id = 1, .frame_number = 3 });

    const mock = clock_mod.MockClock.init(48_000);
    _ = mock;
    // Use a real Clock in invalid state (no semaaud) for the resolver.
    const clk = Clock.init("/var/run/sema/clock_c3_test_absent");
    defer clk.deinit();

    const r = Resolver.init(&ds, clk);

    // Exactly on timestamp.
    const v1 = r.resolveVisual(1000).?;
    try std.testing.expectEqual(@as(u64, 1), v1.frame_number);

    // Between frames — returns most recent.
    const v2 = r.resolveVisual(1500).?;
    try std.testing.expectEqual(@as(u64, 1), v2.frame_number);

    const v3 = r.resolveVisual(2001).?;
    try std.testing.expectEqual(@as(u64, 2), v3.frame_number);

    // Before any frame.
    const v0 = r.resolveVisual(500);
    try std.testing.expect(v0 == null);
}

test "Resolver resolveInput" {
    var ds = DomainStreams.init();
    ds.appendInput(500,  InputEvent.fromType("mouse_move", "pointer:rel-0"));
    ds.appendInput(1000, InputEvent.fromType("key_down", "keyboard:0"));
    ds.appendInput(1500, InputEvent.fromType("touch_down", "touch:0"));

    const clk = Clock.init("/var/run/sema/clock_c3_test_absent");
    defer clk.deinit();
    const r = Resolver.init(&ds, clk);

    const inp1 = r.resolveInput(750).?;
    try std.testing.expectEqualStrings("mouse_move", inp1.typeName());

    const inp2 = r.resolveInput(1000).?;
    try std.testing.expectEqualStrings("key_down", inp2.typeName());

    const inp3 = r.resolveInput(2000).?;
    try std.testing.expectEqualStrings("touch_down", inp3.typeName());
}

test "Resolver resolveAudio" {
    var ds = DomainStreams.init();
    ds.appendAudio(0,     .{ .stream_id = 1, .samples_written = 0,     .active = true  });
    ds.appendAudio(48000, .{ .stream_id = 1, .samples_written = 48000, .active = false });

    const clk = Clock.init("/var/run/sema/clock_c3_test_absent");
    defer clk.deinit();
    const r = Resolver.init(&ds, clk);

    const a1 = r.resolveAudio(1000).?;
    try std.testing.expect(a1.active);

    const a2 = r.resolveAudio(48000).?;
    try std.testing.expect(!a2.active);
}

test "ingestSemaaudLine stream_begin" {
    var ds = DomainStreams.init();
    const line =
        \\{"type":"stream_begin","subsystem":"semaaud","session":"deadbeef","seq":1,"ts_wall_ns":1000,"ts_audio_samples":48000,"stream_id":1,"samples_written":48000}
    ;
    try ingestSemaaudLine(&ds, line);

    const e = ds.audio.at(48000).?;
    try std.testing.expectEqual(@as(u64, 1), e.payload.stream_id);
    try std.testing.expect(e.payload.active);
}

test "ingestSemaaudLine stream_end produces active=false" {
    var ds = DomainStreams.init();
    const line =
        \\{"type":"stream_end","subsystem":"semaaud","session":"deadbeef","seq":2,"ts_wall_ns":2000,"ts_audio_samples":96000,"stream_id":1}
    ;
    try ingestSemaaudLine(&ds, line);

    const e = ds.audio.at(96000).?;
    try std.testing.expect(!e.payload.active);
}

test "ingestSemaaudLine null ts_audio_samples is skipped" {
    var ds = DomainStreams.init();
    const line =
        \\{"type":"stream_begin","subsystem":"semaaud","session":"deadbeef","seq":1,"ts_wall_ns":1000,"ts_audio_samples":null,"stream_id":1}
    ;
    // Should return without error, and nothing appended.
    try ingestSemaaudLine(&ds, line);
    try std.testing.expect(ds.audio.isEmpty());
}

test "ingestSemadrawLine frame_complete" {
    var ds = DomainStreams.init();
    const line =
        \\{"type":"frame_complete","subsystem":"semadraw","session":"deadbeef","seq":7,"ts_wall_ns":3000,"ts_audio_samples":72000,"surface_id":2,"frame_number":5,"backend":"software"}
    ;
    try ingestSemadrawLine(&ds, line);

    const e = ds.visual.at(72000).?;
    try std.testing.expectEqual(@as(u32, 2), e.payload.surface_id);
    try std.testing.expectEqual(@as(u64, 5), e.payload.frame_number);
}

test "ingestSemainputLine mouse_move" {
    var ds = DomainStreams.init();
    const line =
        \\{"type":"mouse_move","subsystem":"semainput","session":"deadbeef","seq":5,"ts_wall_ns":2000,"ts_audio_samples":24000,"device":"pointer:rel-0","source":"/dev/input/event0","dx":3,"dy":-1}
    ;
    try ingestSemainputLine(&ds, line);

    const e = ds.input.at(24000).?;
    try std.testing.expectEqualStrings("mouse_move", e.payload.typeName());
    try std.testing.expectEqualStrings("pointer:rel-0", e.payload.deviceName());
}

test "ingestSemainputLine daemon_start is skipped" {
    var ds = DomainStreams.init();
    const line =
        \\{"type":"daemon_start","subsystem":"semainput","session":"deadbeef","seq":1,"ts_wall_ns":1000,"ts_audio_samples":null,"name":"semainputd","version":"v41"}
    ;
    try ingestSemainputLine(&ds, line);
    try std.testing.expect(ds.input.isEmpty());
}

test "ingestSemadrawLine unknown type returns error" {
    var ds = DomainStreams.init();
    const line =
        \\{"type":"client_connected","subsystem":"semadraw","session":"deadbeef","seq":1,"ts_wall_ns":1000,"ts_audio_samples":1000,"client_id":1}
    ;
    const result = ingestSemadrawLine(&ds, line);
    try std.testing.expectError(error.UnknownEventType, result);
    try std.testing.expect(ds.visual.isEmpty());
}

test "resolveAll returns state for all domains" {
    var ds = DomainStreams.init();
    ds.appendAudio(1000,  .{ .stream_id = 1, .samples_written = 1000,  .active = true });
    ds.appendVisual(1200, .{ .surface_id = 3, .frame_number = 10 });
    ds.appendInput(1100,  InputEvent.fromType("key_down", "keyboard:0"));

    const clk = Clock.init("/var/run/sema/clock_c3_test_absent");
    defer clk.deinit();
    const r = Resolver.init(&ds, clk);

    const state = r.resolveAll(1500);
    try std.testing.expectEqual(@as(u64, 1500), state.t);
    try std.testing.expect(state.audio.?.active);
    try std.testing.expectEqual(@as(u64, 10), state.visual.?.frame_number);
    try std.testing.expectEqualStrings("key_down", state.input.?.typeName());
}
