const std = @import("std");
const semantic = @import("semantic.zig");
const aggregate = @import("device_aggregate.zig");

fn writeEscapedString(writer: anytype, value: []const u8) !void {
    try writer.writeByte('"');
    for (value) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(c),
        }
    }
    try writer.writeByte('"');
}

fn writeHeader(writer: anytype, event_type: []const u8, device: []const u8, source: []const u8) !void {
    try writer.writeAll("{\"type\":");
    try writeEscapedString(writer, event_type);
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

    var buf: [1024]u8 = undefined;
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
            try writer.writeAll("}\n");
        },
        .mouse_scroll => |e| {
            try writeHeader(writer, "mouse_scroll", mapping.stable_name, e.path);
            try writer.print(",\"dx\":{d},\"dy\":{d}}}\n", .{ e.dx, e.dy });
        },
        .key_down => |e| {
            try writeHeader(writer, "key_down", mapping.stable_name, e.path);
            try writer.print(",\"code\":{d}}}\n", .{e.code});
        },
        .key_up => |e| {
            try writeHeader(writer, "key_up", mapping.stable_name, e.path);
            try writer.print(",\"code\":{d}}}\n", .{e.code});
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
