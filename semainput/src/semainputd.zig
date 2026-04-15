const std = @import("std");
const evdev = @import("adapters/evdev.zig");
const queue_mod = @import("event_queue.zig");
const semantic = @import("semantic.zig");
const classify = @import("device_classify.zig");
const aggregate = @import("device_aggregate.zig");
const activity_mod = @import("device_activity.zig");
const gesture_mod = @import("gesture.zig");
const smoother_mod = @import("smoother.zig");
const output_mod = @import("output.zig");

fn writeStdout(bytes: []const u8) !void {
    var stdout_file = std.fs.File.stdout();
    var stdout_buf: [4096]u8 = undefined;
    var out = stdout_file.writer(&stdout_buf);
    try out.interface.writeAll(bytes);
    try out.interface.flush();
}

fn rebuildMappings(
    allocator: std.mem.Allocator,
    classifier: *classify.Classifier,
    aggregator: *aggregate.Aggregator,
    activity: *activity_mod.ActivityTracker,
    snapshot: *std.ArrayList(classify.DeviceObservation),
    mapping_snapshot: *std.ArrayList(aggregate.DeviceMapping),
) !void {
    try classifier.snapshot(snapshot, allocator);
    defer classifier.freeSnapshot(snapshot, allocator);
    if (snapshot.items.len == 0) return;
    try aggregator.rebuild(snapshot.items, activity);

    var outbuf = std.ArrayList(u8){};
    defer outbuf.deinit(allocator);

    try outbuf.appendSlice(allocator, "{\"type\":\"classification_snapshot\",\"devices\":[");
    for (snapshot.items, 0..) |d, idx| {
        if (idx != 0) try outbuf.appendSlice(allocator, ",");
        const part = try std.fmt.allocPrint(allocator,
            "{{\"source\":\"{s}\",\"role\":\"{s}\",\"rel_x\":{s},\"rel_y\":{s},\"abs_x\":{s},\"abs_y\":{s},\"btn_left\":{s},\"btn_right\":{s},\"btn_middle\":{s},\"touch_btn\":{s},\"touch_tool\":{s},\"mt_tracking\":{s},\"key_other\":{s}}}",
            .{ d.path, d.role.asString(), if (d.caps.rel_x) "true" else "false", if (d.caps.rel_y) "true" else "false", if (d.caps.abs_x) "true" else "false", if (d.caps.abs_y) "true" else "false", if (d.caps.btn_left) "true" else "false", if (d.caps.btn_right) "true" else "false", if (d.caps.btn_middle) "true" else "false", if (d.caps.btn_touch) "true" else "false", if (d.caps.btn_tool_finger) "true" else "false", if (d.caps.mt_tracking_id) "true" else "false", if (d.caps.key_other) "true" else "false" });
        defer allocator.free(part);
        try outbuf.appendSlice(allocator, part);
    }
    try outbuf.appendSlice(allocator, "]}\n");
    try writeStdout(outbuf.items);

    outbuf.clearRetainingCapacity();
    try aggregator.snapshot(mapping_snapshot, allocator);
    defer aggregator.freeSnapshot(mapping_snapshot, allocator);
    try outbuf.appendSlice(allocator, "{\"type\":\"identity_snapshot\",\"mappings\":[");
    for (mapping_snapshot.items, 0..) |m, idx| {
        if (idx != 0) try outbuf.appendSlice(allocator, ",");
        const part = try std.fmt.allocPrint(allocator,
            "{{\"source\":\"{s}\",\"logical_kind\":\"{s}\",\"logical_id\":{d},\"stable\":\"{s}\",\"fingerprint\":\"0x{x}\"}}",
            .{ m.path, m.kind.asString(), m.logical_id, m.stable_name, m.fingerprint });
        defer allocator.free(part);
        try outbuf.appendSlice(allocator, part);
    }
    try outbuf.appendSlice(allocator, "]}\n");
    try writeStdout(outbuf.items);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try writeStdout("{\"type\":\"daemon_start\",\"name\":\"semainputd\",\"version\":\"v28\"}\n");
    try evdev.discover();
    var devices = try evdev.openAllEventDevices(allocator);
    defer devices.deinit();
    var queue = queue_mod.EventQueue.init(allocator);
    defer queue.deinit();
    var classifier = classify.Classifier.init(allocator);
    defer classifier.deinit();
    var aggregator = aggregate.Aggregator.init(allocator);
    defer aggregator.deinit();
    var activity = activity_mod.ActivityTracker.init(allocator);
    defer activity.deinit();
    var gestures = gesture_mod.GestureRecognizer.init(allocator);
    defer gestures.deinit();
    var smoother = smoother_mod.PointerSmoothing.init(allocator);
    defer smoother.deinit();

    const daemon_state = try std.fmt.allocPrint(allocator, "{{\"type\":\"daemon_state\",\"message\":\"spawning readers\",\"device_count\":{d}}}\n", .{devices.items.items.len});
    defer allocator.free(daemon_state);
    try writeStdout(daemon_state);

    var threads = std.ArrayList(std.Thread){};
    defer threads.deinit(allocator);
    var contexts = std.ArrayList(evdev.ReaderContext){};
    defer contexts.deinit(allocator);
    for (devices.items.items) |*dev| {
        try contexts.append(allocator, .{ .path = dev.path, .file = &dev.file, .queue = &queue, .classifier = &classifier });
    }
    for (contexts.items) |ctx| {
        const t = try std.Thread.spawn(.{}, evdev.readerMain, .{ctx});
        try threads.append(allocator, t);
    }

    var drained = std.ArrayList(semantic.SemanticEvent){};
    defer drained.deinit(allocator);
    var staging = std.ArrayList(semantic.SemanticEvent){};
    defer staging.deinit(allocator);
    var snapshot = std.ArrayList(classify.DeviceObservation){};
    defer snapshot.deinit(allocator);
    var mapping_snapshot = std.ArrayList(aggregate.DeviceMapping){};
    defer mapping_snapshot.deinit(allocator);

    const stabilization_ns: u64 = 2 * std.time.ns_per_s;
    const start_ns: u64 = @as(u64, @intCast(std.time.nanoTimestamp()));
    var stabilized = false;
    var last_summary_ns: u64 = 0;

    while (true) {
        try queue.drainTo(&drained, allocator);
        const now_ns = @as(u64, @intCast(std.time.nanoTimestamp()));
        for (drained.items) |event| try activity.noteEvent(event.sourcePath(), now_ns);
        if (!stabilized) {
            for (drained.items) |event| try staging.append(allocator, event);
            drained.clearRetainingCapacity();
            if (now_ns - start_ns >= stabilization_ns) {
                try rebuildMappings(allocator, &classifier, &aggregator, &activity, &snapshot, &mapping_snapshot);
                stabilized = true;
                for (staging.items) |event| {
                    if (aggregator.hasMappingForPath(event.sourcePath())) {
                        const smoothed = try smoother.smoothEvent(&aggregator, event);
                        try output_mod.emitSemanticEvent(&aggregator, smoothed);
                        try gestures.handleEvent(&aggregator, smoothed, now_ns);
                    }
                }
                staging.clearRetainingCapacity();
            } else {
                std.Thread.sleep(5 * std.time.ns_per_ms);
            }
            continue;
        }
        for (drained.items) |event| {
            if (aggregator.hasMappingForPath(event.sourcePath())) {
                const smoothed = try smoother.smoothEvent(&aggregator, event);
                try output_mod.emitSemanticEvent(&aggregator, smoothed);
                try gestures.handleEvent(&aggregator, smoothed, now_ns);
            }
        }
        const had_events = drained.items.len > 0;
        drained.clearRetainingCapacity();
        if (now_ns - last_summary_ns >= 2 * std.time.ns_per_s) {
            last_summary_ns = now_ns;
            try rebuildMappings(allocator, &classifier, &aggregator, &activity, &snapshot, &mapping_snapshot);
        }
        if (!had_events) std.Thread.sleep(5 * std.time.ns_per_ms);
    }
}
