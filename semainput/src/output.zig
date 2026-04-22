const std = @import("std");
const semantic = @import("semantic.zig");
const aggregate = @import("device_aggregate.zig");
const globals = @import("globals.zig");

fn writeEscapedString(writer: anytype, value: []const u8) !void {
    try writer.writeByte('"');
    for (value) |c| {
        switch (c) {
            '"'  => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(c),
        }
    }
    try writer.writeByte('"');
}

/// Write the mandatory unified schema envelope after the opening '{'.
/// Caller must append event-specific fields and the closing '}\\n' afterward.
///
/// Emits (in schema order):
///   "type": ..., "subsystem": "semainput", "session": ..., "seq": ...,
///   "ts_wall_ns": ..., "ts_audio_samples": null
fn writeEnvelope(writer: anytype, event_type: []const u8) !void {
    const ts: i64 = @intCast(std.time.nanoTimestamp());
    const s = globals.nextSeq();

    try writer.writeAll("{\"type\":");
    try writeEscapedString(writer, event_type);
    try writer.writeAll(",\"subsystem\":\"semainput\"");
    try writer.print(",\"session\":\"{s}\"", .{globals.session_hex});
    try writer.print(",\"seq\":{d}", .{s});
    try writer.print(",\"ts_wall_ns\":{d}", .{ts});
    try writer.writeAll(",\"ts_audio_samples\":");
    if (globals.readAudioSamples()) |samples| {
        var ntmp: [24]u8 = undefined;
        const ns = std.fmt.bufPrint(&ntmp, "{d}", .{samples}) catch "null";
        try writer.writeAll(ns);
    } else {
        try writer.writeAll("null");
    }
}

/// Write the mandatory envelope followed by device and source fields.
/// Used by semantic input events.
fn writeHeader(writer: anytype, event_type: []const u8, device: []const u8, source: []const u8) !void {
    try writeEnvelope(writer, event_type);
    try writer.writeAll(",\"device\":");
    try writeEscapedString(writer, device);
    try writer.writeAll(",\"source\":");
    try writeEscapedString(writer, source);
}

fn writeStdout(bytes: []const u8) !void {
    var file = std.fs.File.stdout();
    var buf: [4096]u8 = undefined;
    var writer = file.writer(&buf);
    try writer.interface.writeAll(bytes);
    try writer.interface.flush();
}

pub fn emitSemanticEvent(aggregator: *aggregate.Aggregator, event: semantic.SemanticEvent) !void {
    const mapping = aggregator.findForPath(event.sourcePath()) orelse return;

    // 1536 bytes: 1024 original payload + ~100 envelope + headroom.
    var buf: [1536]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    const writer = stream.writer();

    switch (event) {
        .mouse_move => |e| {
            try writeHeader(writer, "mouse_move", mapping.stable_name, e.path);
            try writer.print(",\"dx\":{d},\"dy\":{d}}}\n", .{ e.dx, e.dy });
        },
        .mouse_button => |e| {
            try writeHeader(writer, "mouse_button", mapping.stable_name, e.path);
            try writer.writeAll(",\"button\":");
            try writeEscapedString(writer, e.button);
            try writer.writeAll(",\"state\":");
            try writeEscapedString(writer, if (e.pressed) "down" else "up");
            try writer.print(",\"x\":{d},\"y\":{d}}}\n", .{ e.x, e.y });
        },
        .mouse_scroll => |e| {
            try writeHeader(writer, "mouse_scroll", mapping.stable_name, e.path);
            try writer.print(",\"dx\":{d},\"dy\":{d}}}\n", .{ e.dx, e.dy });
        },
        .key_down => |e| {
            try writeHeader(writer, "key_down", mapping.stable_name, e.path);
            try writer.print(",\"code\":{d},\"mods\":{d}}}\n", .{ e.code, e.mods });
        },
        .key_up => |e| {
            try writeHeader(writer, "key_up", mapping.stable_name, e.path);
            try writer.print(",\"code\":{d},\"mods\":{d}}}\n", .{ e.code, e.mods });
        },
        .touch_down => |e| {
            try writeHeader(writer, "touch_down", mapping.stable_name, e.path);
            try writer.print(",\"contact\":{d},\"x\":{d},\"y\":{d}}}\n", .{ e.contact, e.x, e.y });
        },
        .touch_move => |e| {
            try writeHeader(writer, "touch_move", mapping.stable_name, e.path);
            try writer.print(",\"contact\":{d},\"x\":{d},\"y\":{d}}}\n", .{ e.contact, e.x, e.y });
        },
        .touch_up => |e| {
            try writeHeader(writer, "touch_up", mapping.stable_name, e.path);
            try writer.print(",\"contact\":{d}}}\n", .{e.contact});
        },
    }

    try writeStdout(stream.getWritten());
}
