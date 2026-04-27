/// inputstate-check -- C.2 verification helper
///
/// Reads /var/run/sema/input/state via shared/src/input.zig's StateReader
/// and prints the contents in human-readable form. Used to verify that
/// C.2's kernel-side writes match what C.1's StateReader expects to read.
///
/// This is a throwaway: it exists to bridge C.2 (kernel state-region
/// writer landing) and C.4 (proper inputdump CLI). When C.4 lands,
/// this file should be removed.
///
/// Usage:
///   inputstate-check              # one-shot: read snapshot, print, exit
///   inputstate-check --watch      # loop, print diffs as they happen
///   inputstate-check --watch --interval-ms 100   # tune the poll rate

const std = @import("std");
const input = @import("input");

fn writeOut(comptime fmt: []const u8, args: anytype) void {
    var file = std.fs.File.stdout();
    var buf: [4096]u8 = undefined;
    var w = file.writer(&buf);
    w.interface.print(fmt, args) catch {};
    w.interface.flush() catch {};
}

fn writeErr(comptime fmt: []const u8, args: anytype) void {
    var file = std.fs.File.stderr();
    var buf: [4096]u8 = undefined;
    var w = file.writer(&buf);
    w.interface.print(fmt, args) catch {};
    w.interface.flush() catch {};
}

fn rolesToString(roles: u32, buf: []u8) []const u8 {
    if (roles == 0) return "<none>";
    var pos: usize = 0;
    var first = true;
    const names = [_][]const u8{ "pointer", "keyboard", "touch", "pen", "lighting" };
    inline for (0..5) |i| {
        if ((roles & (@as(u32, 1) << @intCast(i))) != 0) {
            if (!first) {
                if (pos < buf.len) {
                    buf[pos] = ',';
                    pos += 1;
                }
            }
            const n = names[i];
            const copy_len = @min(n.len, buf.len - pos);
            @memcpy(buf[pos..][0..copy_len], n[0..copy_len]);
            pos += copy_len;
            first = false;
        }
    }
    return buf[0..pos];
}

fn nameToString(name: *const [64]u8) []const u8 {
    // Find the null terminator, or use the full 64 bytes.
    var len: usize = 0;
    while (len < 64 and name[len] != 0) : (len += 1) {}
    return name[0..len];
}

fn deviceIdHex(id: [16]u8, buf: []u8) []const u8 {
    var pos: usize = 0;
    for (id) |b| {
        if (pos + 2 > buf.len) break;
        const hi = "0123456789abcdef"[b >> 4];
        const lo = "0123456789abcdef"[b & 0x0f];
        buf[pos + 0] = hi;
        buf[pos + 1] = lo;
        pos += 2;
    }
    return buf[0..pos];
}

fn dumpSnapshot(snap: input.StateSnapshot, header_label: []const u8) void {
    writeOut("=== {s} ===\n", .{header_label});
    writeOut("magic:      INST (0x{x:0>8})\n", .{input.STATE_MAGIC});
    writeOut("version:    {d}\n", .{input.STATE_VERSION});
    writeOut("seqlock:    (consistent snapshot)\n", .{});
    writeOut("last_seq:   {d}\n", .{snap.last_sequence});
    writeOut("boot_off:   {d} ns\n", .{snap.boot_wall_offset_ns});
    writeOut("pointer:    x={d} y={d} buttons=0x{x}\n", .{
        snap.pointer_x, snap.pointer_y, snap.pointer_buttons,
    });
    writeOut("dev_count:  {d}\n", .{snap.device_count});
    writeOut("touch_act:  {d}\n", .{snap.active_touch_count});

    // Walk the device array and print populated slots.
    var slot: usize = 0;
    var printed: u16 = 0;
    while (slot < input.STATE_SLOT_COUNT and printed < snap.device_count) : (slot += 1) {
        const dev = snap.devices[slot];
        // Empty slot detector: device_id all zero means unused.
        var is_empty = true;
        for (dev.device_id) |b| {
            if (b != 0) {
                is_empty = false;
                break;
            }
        }
        if (is_empty) continue;

        var role_buf: [64]u8 = undefined;
        const role_str = rolesToString(dev.roles, &role_buf);
        var id_buf: [33]u8 = undefined;
        const id_str = deviceIdHex(dev.device_id, &id_buf);
        const name_str = nameToString(&dev.name);

        writeOut("  slot[{d}]: id={s}\n", .{ slot, id_str });
        writeOut("           vendor=0x{x:0>4} product=0x{x:0>4}\n", .{
            dev.usb_vendor, dev.usb_product,
        });
        writeOut("           roles={s}\n", .{role_str});
        writeOut("           name='{s}'\n", .{name_str});
        printed += 1;
    }
    writeOut("\n", .{});
}

fn snapshotEquals(a: input.StateSnapshot, b: input.StateSnapshot) bool {
    if (a.pointer_x != b.pointer_x) return false;
    if (a.pointer_y != b.pointer_y) return false;
    if (a.pointer_buttons != b.pointer_buttons) return false;
    if (a.last_sequence != b.last_sequence) return false;
    if (a.device_count != b.device_count) return false;
    if (a.active_touch_count != b.active_touch_count) return false;
    return true;
}

fn parseArgs(args: [][:0]u8) struct {
    watch: bool,
    interval_ms: u64,
} {
    var watch = false;
    var interval_ms: u64 = 250;
    var i: usize = 1; // skip argv[0]
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--watch")) {
            watch = true;
        } else if (std.mem.eql(u8, a, "--interval-ms")) {
            i += 1;
            if (i >= args.len) {
                writeErr("error: --interval-ms requires a value\n", .{});
                std.process.exit(2);
            }
            interval_ms = std.fmt.parseInt(u64, args[i], 10) catch {
                writeErr("error: --interval-ms value must be an integer\n", .{});
                std.process.exit(2);
            };
            if (interval_ms == 0) {
                writeErr("error: --interval-ms must be > 0\n", .{});
                std.process.exit(2);
            }
        } else if (std.mem.eql(u8, a, "--help") or std.mem.eql(u8, a, "-h")) {
            writeOut(
                \\inputstate-check -- read /var/run/sema/input/state and print contents
                \\
                \\Usage:
                \\  inputstate-check              one-shot read
                \\  inputstate-check --watch      loop until interrupted
                \\  inputstate-check --watch --interval-ms <ms>   tune poll rate (default 250)
                \\
            , .{});
            std.process.exit(0);
        } else {
            writeErr("error: unknown argument '{s}' (try --help)\n", .{a});
            std.process.exit(2);
        }
    }
    return .{ .watch = watch, .interval_ms = interval_ms };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const opts = parseArgs(args);

    const reader = input.StateReader.init(input.STATE_PATH);
    defer reader.deinit();

    if (!reader.isValid()) {
        writeErr("inputstate-check: state region not valid at {s}\n", .{input.STATE_PATH});
        writeErr("  (file absent, wrong magic/version, or state_valid=0)\n", .{});
        writeErr("  load inputfs and attach at least one device, then retry.\n", .{});
        std.process.exit(1);
    }

    const initial = try reader.snapshot();
    dumpSnapshot(initial, "initial snapshot");

    if (!opts.watch) return;

    writeOut("watching (interval={d} ms; Ctrl-C to stop)\n\n", .{opts.interval_ms});

    var prev = initial;
    while (true) {
        std.Thread.sleep(opts.interval_ms * std.time.ns_per_ms);
        const snap = try reader.snapshot();
        if (!snapshotEquals(prev, snap)) {
            dumpSnapshot(snap, "changed");
            prev = snap;
        }
    }
}
