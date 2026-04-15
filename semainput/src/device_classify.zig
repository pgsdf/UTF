const std = @import("std");

pub const Role = enum {
    unknown, pointer, keyboard, touch, companion_button_source,

    pub fn asString(self: Role) []const u8 {
        return switch (self) {
            .unknown => "unknown",
            .pointer => "pointer",
            .keyboard => "keyboard",
            .touch => "touch",
            .companion_button_source => "companion-button-source",
        };
    }

    pub fn tag(self: Role) []const u8 {
        return switch (self) {
            .unknown => "unknown",
            .pointer => "pointer",
            .keyboard => "keyboard",
            .touch => "touch",
            .companion_button_source => "button-source",
        };
    }
};

pub const ObservedCaps = packed struct(u32) {
    rel_x: bool = false,
    rel_y: bool = false,
    rel_wheel: bool = false,
    rel_hwheel: bool = false,
    abs_x: bool = false,
    abs_y: bool = false,
    btn_left: bool = false,
    btn_right: bool = false,
    btn_middle: bool = false,
    key_other: bool = false,
    btn_touch: bool = false,
    btn_tool_finger: bool = false,
    mt_tracking_id: bool = false,
    _reserved: u19 = 0,
};

pub const DeviceObservation = struct {
    path: []const u8,
    caps: ObservedCaps = .{},
    role: Role = .unknown,
};

pub const Classifier = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},
    devices: std.ArrayList(DeviceObservation),

    pub fn init(allocator: std.mem.Allocator) Classifier {
        return .{ .allocator = allocator, .devices = .{} };
    }

    pub fn deinit(self: *Classifier) void {
        for (self.devices.items) |d| self.allocator.free(d.path);
        self.devices.deinit(self.allocator);
    }

    fn getOrCreate(self: *Classifier, path: []const u8) !*DeviceObservation {
        for (self.devices.items) |*d| {
            if (std.mem.eql(u8, d.path, path)) return d;
        }
        const owned = try self.allocator.dupe(u8, path);
        try self.devices.append(self.allocator, .{ .path = owned });
        return &self.devices.items[self.devices.items.len - 1];
    }

    fn classifyCaps(caps: ObservedCaps) Role {
        const has_rel = caps.rel_x or caps.rel_y;
        const has_pointer_buttons = caps.btn_left or caps.btn_right or caps.btn_middle;
        const has_wheel = caps.rel_wheel or caps.rel_hwheel;
        const has_abs = caps.abs_x or caps.abs_y;
        const has_touch_markers = caps.btn_touch or caps.btn_tool_finger or caps.mt_tracking_id;
        const has_key_other = caps.key_other;

        if (has_abs and has_touch_markers) return .touch;
        if (has_touch_markers and !has_rel and !has_pointer_buttons and !has_wheel) return .touch;
        if (has_rel and has_pointer_buttons) return .pointer;
        if (has_rel and has_wheel) return .pointer;
        if (has_key_other and !has_rel and !has_pointer_buttons and !has_touch_markers and !has_abs) return .keyboard;
        if (!has_rel and has_pointer_buttons and !has_key_other and !has_abs) return .companion_button_source;
        return .unknown;
    }

    pub fn observeRel(self: *Classifier, path: []const u8, code: u16) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        const d = try self.getOrCreate(path);
        switch (code) {
            0 => d.caps.rel_x = true,
            1 => d.caps.rel_y = true,
            6 => d.caps.rel_hwheel = true,
            8 => d.caps.rel_wheel = true,
            else => {},
        }
        d.role = classifyCaps(d.caps);
    }

    pub fn observeAbs(self: *Classifier, path: []const u8, code: u16) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        const d = try self.getOrCreate(path);
        switch (code) {
            0, 53 => d.caps.abs_x = true,
            1, 54 => d.caps.abs_y = true,
            57 => d.caps.mt_tracking_id = true,
            else => {},
        }
        d.role = classifyCaps(d.caps);
    }

    pub fn observeKey(self: *Classifier, path: []const u8, code: u16) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        const d = try self.getOrCreate(path);
        switch (code) {
            0x110 => d.caps.btn_left = true,
            0x111 => d.caps.btn_right = true,
            0x112 => d.caps.btn_middle = true,
            330 => d.caps.btn_touch = true,
            325 => d.caps.btn_tool_finger = true,
            else => d.caps.key_other = true,
        }
        d.role = classifyCaps(d.caps);
    }

    pub fn snapshot(self: *Classifier, out: *std.ArrayList(DeviceObservation), allocator: std.mem.Allocator) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        out.clearRetainingCapacity();
        for (self.devices.items) |d| {
            const owned = try allocator.dupe(u8, d.path);
            try out.append(allocator, .{ .path = owned, .caps = d.caps, .role = d.role });
        }
    }

    pub fn freeSnapshot(self: *Classifier, out: *std.ArrayList(DeviceObservation), allocator: std.mem.Allocator) void {
        _ = self;
        for (out.items) |d| allocator.free(d.path);
        out.clearRetainingCapacity();
    }
};
