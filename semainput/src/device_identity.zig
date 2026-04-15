const std = @import("std");
const classify = @import("device_classify.zig");

pub fn fingerprint(obs: classify.DeviceObservation) u64 {
    var h = std.hash.Wyhash.init(0);
    h.update(obs.role.asString());
    h.update(if (obs.caps.rel_x) "1" else "0");
    h.update(if (obs.caps.rel_y) "1" else "0");
    h.update(if (obs.caps.rel_wheel) "1" else "0");
    h.update(if (obs.caps.rel_hwheel) "1" else "0");
    h.update(if (obs.caps.abs_x) "1" else "0");
    h.update(if (obs.caps.abs_y) "1" else "0");
    h.update(if (obs.caps.btn_left) "1" else "0");
    h.update(if (obs.caps.btn_right) "1" else "0");
    h.update(if (obs.caps.btn_middle) "1" else "0");
    h.update(if (obs.caps.key_other) "1" else "0");
    h.update(if (obs.caps.btn_touch) "1" else "0");
    h.update(if (obs.caps.btn_tool_finger) "1" else "0");
    h.update(if (obs.caps.mt_tracking_id) "1" else "0");
    return h.final();
}

pub fn shortName(allocator: std.mem.Allocator, obs: classify.DeviceObservation, ordinal: usize) ![]u8 {
    const role_tag = obs.role.tag();
    const rel_count: usize = (@as(usize, @intFromBool(obs.caps.rel_x))) + (@as(usize, @intFromBool(obs.caps.rel_y)));
    const button_count: usize = (@as(usize, @intFromBool(obs.caps.btn_left))) + (@as(usize, @intFromBool(obs.caps.btn_right))) + (@as(usize, @intFromBool(obs.caps.btn_middle)));
    const wheel_count: usize = (@as(usize, @intFromBool(obs.caps.rel_wheel))) + (@as(usize, @intFromBool(obs.caps.rel_hwheel)));
    const abs_count: usize = (@as(usize, @intFromBool(obs.caps.abs_x))) + (@as(usize, @intFromBool(obs.caps.abs_y)));
    const touch_count: usize = (@as(usize, @intFromBool(obs.caps.btn_touch))) + (@as(usize, @intFromBool(obs.caps.btn_tool_finger))) + (@as(usize, @intFromBool(obs.caps.mt_tracking_id)));

    return std.fmt.allocPrint(
        allocator,
        "{s}:rel-{d}-b{d}-w{d}-a{d}-t{d}-{d}",
        .{ role_tag, rel_count, button_count, wheel_count, abs_count, touch_count, ordinal },
    );
}
