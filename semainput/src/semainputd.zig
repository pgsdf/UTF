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
const globals = @import("globals.zig");

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

    // classification_snapshot — build entirely with appendSlice, no { or } in format strings
    try outbuf.appendSlice(allocator, "{\"type\":\"classification_snapshot\",\"subsystem\":\"semainput\",\"session\":\"");
    try outbuf.appendSlice(allocator, &globals.session_hex);
    {
        var tmp: [128]u8 = undefined;
        const seqts = try std.fmt.bufPrint(&tmp, "\",\"seq\":{d},\"ts_wall_ns\":{d},\"ts_audio_samples\":{s},\"devices\":[",
            .{ globals.nextSeq(), @as(i64, @intCast(std.time.nanoTimestamp())), globals.audioSamplesJson() });
        try outbuf.appendSlice(allocator, seqts);
    }
    for (snapshot.items, 0..) |d, i| {
        if (i != 0) try outbuf.appendSlice(allocator, ",");
        try outbuf.appendSlice(allocator, "{\"source\":\"");
        try outbuf.appendSlice(allocator, d.path);
        try outbuf.appendSlice(allocator, "\",\"role\":\"");
        try outbuf.appendSlice(allocator, d.role.asString());
        try outbuf.appendSlice(allocator, "\",\"rel_x\":");
        try outbuf.appendSlice(allocator, if (d.caps.rel_x) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"rel_y\":");
        try outbuf.appendSlice(allocator, if (d.caps.rel_y) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"abs_x\":");
        try outbuf.appendSlice(allocator, if (d.caps.abs_x) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"abs_y\":");
        try outbuf.appendSlice(allocator, if (d.caps.abs_y) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"btn_left\":");
        try outbuf.appendSlice(allocator, if (d.caps.btn_left) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"btn_right\":");
        try outbuf.appendSlice(allocator, if (d.caps.btn_right) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"btn_middle\":");
        try outbuf.appendSlice(allocator, if (d.caps.btn_middle) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"touch_btn\":");
        try outbuf.appendSlice(allocator, if (d.caps.btn_touch) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"touch_tool\":");
        try outbuf.appendSlice(allocator, if (d.caps.btn_tool_finger) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"mt_tracking\":");
        try outbuf.appendSlice(allocator, if (d.caps.mt_tracking_id) "true" else "false");
        try outbuf.appendSlice(allocator, ",\"key_other\":");
        try outbuf.appendSlice(allocator, if (d.caps.key_other) "true" else "false");
        try outbuf.appendSlice(allocator, "}");
    }
    try outbuf.appendSlice(allocator, "]}\n");
    try writeStdout(outbuf.items);

    outbuf.clearRetainingCapacity();
    try aggregator.snapshot(mapping_snapshot, allocator);
    defer aggregator.freeSnapshot(mapping_snapshot, allocator);

    // identity_snapshot
    try outbuf.appendSlice(allocator, "{\"type\":\"identity_snapshot\",\"subsystem\":\"semainput\",\"session\":\"");
    try outbuf.appendSlice(allocator, &globals.session_hex);
    {
        var tmp: [128]u8 = undefined;
        const seqts = try std.fmt.bufPrint(&tmp, "\",\"seq\":{d},\"ts_wall_ns\":{d},\"ts_audio_samples\":{s},\"mappings\":[",
            .{ globals.nextSeq(), @as(i64, @intCast(std.time.nanoTimestamp())), globals.audioSamplesJson() });
        try outbuf.appendSlice(allocator, seqts);
    }
    for (mapping_snapshot.items, 0..) |m, i| {
        if (i != 0) try outbuf.appendSlice(allocator, ",");
        try outbuf.appendSlice(allocator, "{\"source\":\"");
        try outbuf.appendSlice(allocator, m.path);
        try outbuf.appendSlice(allocator, "\",\"logical_kind\":\"");
        try outbuf.appendSlice(allocator, m.kind.asString());
        var tmp: [192]u8 = undefined;
        const rest = try std.fmt.bufPrint(&tmp, "\",\"logical_id\":{d},\"stable\":\"{s}\",\"fingerprint\":\"0x{x}\",\"has_keyboard\":{s}",
            .{ m.logical_id, m.stable_name, m.fingerprint,
               if (m.kind == .keyboard) "true" else "false" });
        try outbuf.appendSlice(allocator, rest);
        try outbuf.appendSlice(allocator, "}");
    }
    try outbuf.appendSlice(allocator, "]}\n");
    try writeStdout(outbuf.items);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialise session token and sequence counter before any emission.
    globals.initGlobals();

    const daemon_start = try std.fmt.allocPrint(allocator,
        "{{\"type\":\"daemon_start\",\"subsystem\":\"semainput\",\"session\":\"{s}\",\"seq\":{d},\"ts_wall_ns\":{d},\"ts_audio_samples\":{s},\"name\":\"semainputd\",\"version\":\"v41\"}}\n",
        .{ globals.session_hex, globals.nextSeq(), @as(i64, @intCast(std.time.nanoTimestamp())), globals.audioSamplesJson() },
    );
    defer allocator.free(daemon_start);
    try writeStdout(daemon_start);

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

    const daemon_state = try std.fmt.allocPrint(allocator,
        "{{\"type\":\"daemon_state\",\"subsystem\":\"semainput\",\"session\":\"{s}\",\"seq\":{d},\"ts_wall_ns\":{d},\"ts_audio_samples\":{s},\"message\":\"spawning readers\",\"device_count\":{d}}}\n",
        .{ globals.session_hex, globals.nextSeq(), @as(i64, @intCast(std.time.nanoTimestamp())), globals.audioSamplesJson(), devices.items.items.len },
    );
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
    const start_ns: u64 = @as(u64, @intCast(@as(i64, @intCast(std.time.nanoTimestamp()))));
    var stabilized = false;
    var last_summary_ns: u64 = 0;

    while (true) {
        try queue.drainTo(&drained, allocator);
        const now_ns = @as(u64, @intCast(@as(i64, @intCast(std.time.nanoTimestamp()))));
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
