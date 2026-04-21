const std = @import("std");
const semantic = @import("../semantic.zig");
const queue_mod = @import("../event_queue.zig");
const classify = @import("../device_classify.zig");

pub const EV_SYN: u16 = 0;
pub const EV_KEY: u16 = 1;
pub const EV_REL: u16 = 2;
pub const EV_ABS: u16 = 3;

pub const SYN_REPORT: u16 = 0;

pub const REL_X: u16 = 0;
pub const REL_Y: u16 = 1;
pub const REL_HWHEEL: u16 = 6;
pub const REL_WHEEL: u16 = 8;

pub const ABS_X: u16 = 0;
pub const ABS_Y: u16 = 1;
pub const ABS_MT_SLOT: u16 = 47;
pub const ABS_MT_POSITION_X: u16 = 53;
pub const ABS_MT_POSITION_Y: u16 = 54;
pub const ABS_MT_TRACKING_ID: u16 = 57;

pub const BTN_LEFT: u16 = 0x110;
pub const BTN_RIGHT: u16 = 0x111;
pub const BTN_MIDDLE: u16 = 0x112;
pub const BTN_TOUCH: u16 = 330;
pub const BTN_TOOL_FINGER: u16 = 325;

// EVIOCGRAB — grab exclusive access to evdev device, preventing vt(4) from
// also receiving the events. Value: _IOW('E', 0x90, c_int) = 0x40044590.
// FreeBSD: _IOWINT('E', 0x90) = _IOC(IOC_VOID=0x20000000, 'E'=0x45, 0x90, sizeof(int)=4)
// = 0x20000000 | (4<<16) | (0x45<<8) | 0x90 = 0x20044590
const EVIOCGRAB: c_ulong = 0x20044590;
extern "c" fn ioctl(fd: c_int, request: c_ulong, ...) c_int;

pub const InputEvent = extern struct {
    time_sec: i64,
    time_usec: i64,
    typ: u16,
    code: u16,
    value: i32,
};

pub const DeviceHandle = struct {
    path: []u8,
    file: std.fs.File,
};

pub const DeviceList = struct {
    allocator: std.mem.Allocator,
    items: std.ArrayList(DeviceHandle),

    pub fn init(allocator: std.mem.Allocator) DeviceList {
        return .{ .allocator = allocator, .items = .{} };
    }

    pub fn deinit(self: *DeviceList) void {
        for (self.items.items) |dev| {
            dev.file.close();
            self.allocator.free(dev.path);
        }
        self.items.deinit(self.allocator);
    }

    pub fn add(self: *DeviceList, path: []const u8, file: std.fs.File) !void {
        const owned = try self.allocator.dupe(u8, path);
        try self.items.append(self.allocator, .{ .path = owned, .file = file });
    }
};

pub const ReaderContext = struct {
    path: []const u8,
    file: *std.fs.File,
    queue: *queue_mod.EventQueue,
    classifier: *classify.Classifier,
};

const PendingPointer = struct {
    dx: i32 = 0,
    dy: i32 = 0,
    scroll_x: i32 = 0,
    scroll_y: i32 = 0,
};

const TouchContact = struct {
    active: bool = false,
    tracking_id: i32 = -1,
    x: i32 = 0,
    y: i32 = 0,
    dirty: bool = false,
    just_down: bool = false,
    just_up: bool = false,
};

const PendingTouch = struct {
    current_slot: usize = 0,
    contacts: [8]TouchContact = [_]TouchContact{.{}} ** 8,
};

fn isMouseButton(code: u16) bool {
    return code == BTN_LEFT or code == BTN_RIGHT or code == BTN_MIDDLE;
}

fn isTouchMarker(code: u16) bool {
    return code == BTN_TOUCH or code == BTN_TOOL_FINGER or code == 333;
}

fn buttonName(code: u16) []const u8 {
    return switch (code) {
        BTN_LEFT => "left",
        BTN_RIGHT => "right",
        BTN_MIDDLE => "middle",
        else => "unknown",
    };
}

pub fn discover() !void {
    var dir = std.fs.cwd().openDir("/dev/input", .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("evdev: /dev/input not found\n", .{});
            return;
        },
        else => return err,
    };
    defer dir.close();

    var it = dir.iterate();
    var found_any = false;
    while (try it.next()) |entry| {
        if (!std.mem.startsWith(u8, entry.name, "event")) continue;
        found_any = true;
        std.debug.print("evdev: found /dev/input/{s}\n", .{entry.name});
    }

    if (!found_any) std.debug.print("evdev: no event devices found\n", .{});
}

pub fn openAllEventDevices(allocator: std.mem.Allocator) !DeviceList {
    var result = DeviceList.init(allocator);

    var dir = std.fs.cwd().openDir("/dev/input", .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("evdev: /dev/input not found\n", .{});
            return result;
        },
        else => return err,
    };
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (!std.mem.startsWith(u8, entry.name, "event")) continue;

        const full_path = try std.fmt.allocPrint(allocator, "/dev/input/{s}", .{entry.name});
        defer allocator.free(full_path);

        const file = std.fs.openFileAbsolute(full_path, .{ .mode = .read_only }) catch |err| {
            std.debug.print("evdev: failed to open {s}: {s}\n", .{ full_path, @errorName(err) });
            continue;
        };

        // Grab exclusive access so vt(4) does not also receive these events.
        // This allows semainput to receive F-keys and modifier combinations
        // that vt(4) would otherwise intercept. Failure is non-fatal — the
        // device will still work, just without exclusive access.
        const grab_result = ioctl(@intCast(file.handle), EVIOCGRAB, @as(c_int, 1));
        if (grab_result != 0) {
            std.debug.print("evdev: EVIOCGRAB failed for {s} (non-fatal)\n", .{full_path});
        } else {
            std.debug.print("evdev: grabbed {s}\n", .{full_path});
        }

        try result.add(full_path, file);
        std.debug.print("evdev: opened {s}\n", .{full_path});
    }

    std.debug.print("evdev: opened {d} event devices\n", .{result.items.items.len});
    return result;
}

fn touchEmit(path: []const u8, queue: *queue_mod.EventQueue, touch: *PendingTouch) !void {
    for (&touch.contacts, 0..) |*c, idx| {
        const contact_id: i32 = if (c.tracking_id >= 0) c.tracking_id else @intCast(idx);
        if (c.just_down) {
            try queue.push(.{ .touch_down = .{ .path = path, .contact = contact_id, .x = c.x, .y = c.y } });
            c.just_down = false;
            c.dirty = false;
        } else if (c.just_up) {
            try queue.push(.{ .touch_up = .{ .path = path, .contact = contact_id } });
            c.just_up = false;
            c.dirty = false;
        } else if (c.active and c.dirty) {
            try queue.push(.{ .touch_move = .{ .path = path, .contact = contact_id, .x = c.x, .y = c.y } });
            c.dirty = false;
        }
    }
}

pub fn readerMain(ctx: ReaderContext) !void {
    var buf: [16]InputEvent = undefined;
    var pending = PendingPointer{};
    var touch = PendingTouch{};

    while (true) {
        const bytes = try ctx.file.read(std.mem.asBytes(&buf));
        if (bytes == 0) {
            std.debug.print("evdev: end of stream on {s}\n", .{ctx.path});
            return;
        }

        const count = bytes / @sizeOf(InputEvent);
        if (count == 0) continue;

        for (buf[0..count]) |ev| {
            switch (ev.typ) {
                EV_REL => {
                    try ctx.classifier.observeRel(ctx.path, ev.code);
                    switch (ev.code) {
                        REL_X => pending.dx += ev.value,
                        REL_Y => pending.dy += ev.value,
                        REL_HWHEEL => pending.scroll_x += ev.value,
                        REL_WHEEL => pending.scroll_y += ev.value,
                        else => {},
                    }
                },
                EV_ABS => {
                    try ctx.classifier.observeAbs(ctx.path, ev.code);
                    switch (ev.code) {
                        ABS_MT_SLOT => {
                            if (ev.value >= 0 and ev.value < touch.contacts.len) {
                                touch.current_slot = @intCast(ev.value);
                            }
                        },
                        ABS_MT_POSITION_X => {
                            touch.contacts[touch.current_slot].x = ev.value;
                            touch.contacts[touch.current_slot].dirty = true;
                        },
                        ABS_MT_POSITION_Y => {
                            touch.contacts[touch.current_slot].y = ev.value;
                            touch.contacts[touch.current_slot].dirty = true;
                        },
                        ABS_MT_TRACKING_ID => {
                            if (ev.value >= 0) {
                                touch.contacts[touch.current_slot].tracking_id = ev.value;
                                touch.contacts[touch.current_slot].active = true;
                                touch.contacts[touch.current_slot].just_down = true;
                                touch.contacts[touch.current_slot].dirty = true;
                            } else {
                                touch.contacts[touch.current_slot].active = false;
                                touch.contacts[touch.current_slot].just_up = true;
                            }
                        },
                        ABS_X => {
                            touch.contacts[0].x = ev.value;
                            touch.contacts[0].dirty = true;
                        },
                        ABS_Y => {
                            touch.contacts[0].y = ev.value;
                            touch.contacts[0].dirty = true;
                        },
                        else => {},
                    }
                },
                EV_KEY => {
                    try ctx.classifier.observeKey(ctx.path, ev.code);

                    if (isMouseButton(ev.code)) {
                        try ctx.queue.push(.{
                            .mouse_button = .{
                                .path = ctx.path,
                                .button = buttonName(ev.code),
                                .pressed = ev.value != 0,
                            },
                        });
                    } else if (isTouchMarker(ev.code)) {
                        // Touch marker keys are intentionally absorbed here.
                    } else {
                        // ev.value: 1=press, 0=release, 2=repeat (autorepeat).
                        // Suppress repeats — emit key_down only on initial press.
                        if (ev.value == 1) {
                            try ctx.queue.push(.{ .key_down = .{ .path = ctx.path, .code = ev.code } });
                        } else if (ev.value == 0) {
                            try ctx.queue.push(.{ .key_up = .{ .path = ctx.path, .code = ev.code } });
                        }
                        // ev.value == 2 (repeat) is intentionally ignored.
                    }
                },
                EV_SYN => {
                    if (ev.code == SYN_REPORT) {
                        if (pending.dx != 0 or pending.dy != 0) {
                            try ctx.queue.push(.{
                                .mouse_move = .{
                                    .path = ctx.path,
                                    .dx = pending.dx,
                                    .dy = pending.dy,
                                },
                            });
                        }
                        if (pending.scroll_x != 0 or pending.scroll_y != 0) {
                            try ctx.queue.push(.{
                                .mouse_scroll = .{
                                    .path = ctx.path,
                                    .dx = pending.scroll_x,
                                    .dy = pending.scroll_y,
                                },
                            });
                        }
                        try touchEmit(ctx.path, ctx.queue, &touch);
                        pending = .{};
                    }
                },
                else => {},
            }
        }
    }
}
