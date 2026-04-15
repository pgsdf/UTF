const std = @import("std");
const types = @import("types.zig");

pub fn detectDefaultPcm(allocator: std.mem.Allocator) !types.DeviceSelection {
    const data = try std.fs.cwd().readFileAlloc(allocator, "/dev/sndstat", 1024 * 1024);
    defer allocator.free(data);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line| {
        if (std.mem.indexOf(u8, line, " default") != null and std.mem.startsWith(u8, line, "pcm")) {
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const pcm = line[0..colon];
            const suffix = pcm["pcm".len..];
            return .{
                .default_pcm = try allocator.dupe(u8, pcm),
                .audiodev = try std.fmt.allocPrint(allocator, "/dev/dsp{s}", .{suffix}),
                .mixerdev = try std.fmt.allocPrint(allocator, "/dev/mixer{s}", .{suffix}),
            };
        }
    }

    return .{
        .default_pcm = try allocator.dupe(u8, "pcm0"),
        .audiodev = try allocator.dupe(u8, "/dev/dsp0"),
        .mixerdev = try allocator.dupe(u8, "/dev/mixer0"),
    };
}
