const std = @import("std");
const classify = @import("device_classify.zig");
const semantic = @import("semantic.zig");
const identity = @import("device_identity.zig");
const activity_mod = @import("device_activity.zig");

pub const LogicalKind = enum {
    pointer, keyboard, touch, button_source, unknown,

    pub fn asString(self: LogicalKind) []const u8 {
        return switch (self) {
            .pointer => "pointer",
            .keyboard => "keyboard",
            .touch => "touch",
            .button_source => "button-source",
            .unknown => "unknown",
        };
    }
};

pub const DeviceMapping = struct {
    path: []const u8,
    logical_id: usize,
    kind: LogicalKind,
    stable_name: []const u8,
    fingerprint: u64,
};

fn hasRel(obs: classify.DeviceObservation) bool {
    return obs.caps.rel_x or obs.caps.rel_y;
}

fn hasButtons(obs: classify.DeviceObservation) bool {
    return obs.caps.btn_left or obs.caps.btn_right or obs.caps.btn_middle;
}

fn isTouchLike(obs: classify.DeviceObservation) bool {
    return obs.caps.abs_x or obs.caps.abs_y or obs.caps.btn_touch or obs.caps.btn_tool_finger or obs.caps.mt_tracking_id;
}

fn withinWindow(a: ?u64, b: ?u64, window_ns: u64) bool {
    if (a == null or b == null) return false;
    const av = a.?;
    const bv = b.?;
    const diff = if (av >= bv) av - bv else bv - av;
    return diff <= window_ns;
}

pub const Aggregator = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},
    mappings: std.ArrayList(DeviceMapping),

    pub fn init(allocator: std.mem.Allocator) Aggregator {
        return .{ .allocator = allocator, .mappings = .{} };
    }

    pub fn deinit(self: *Aggregator) void {
        for (self.mappings.items) |m| {
            self.allocator.free(m.path);
            self.allocator.free(m.stable_name);
        }
        self.mappings.deinit(self.allocator);
    }

    fn clearMappings(self: *Aggregator) void {
        for (self.mappings.items) |m| {
            self.allocator.free(m.path);
            self.allocator.free(m.stable_name);
        }
        self.mappings.clearRetainingCapacity();
    }

    fn appendMapping(
        self: *Aggregator,
        seen_paths: *std.StringHashMap(void),
        obs: classify.DeviceObservation,
        logical_id: usize,
        kind: LogicalKind,
        ordinal: usize,
        name_obs: classify.DeviceObservation,
    ) !void {
        if (seen_paths.contains(obs.path)) return;

        const owned_path = try self.allocator.dupe(u8, obs.path);
        const fp = identity.fingerprint(name_obs);
        const stable_name = try identity.shortName(self.allocator, name_obs, ordinal);
        try self.mappings.append(self.allocator, .{
            .path = owned_path,
            .logical_id = logical_id,
            .kind = kind,
            .stable_name = stable_name,
            .fingerprint = fp,
        });
        try seen_paths.put(owned_path, {});
    }

    pub fn rebuild(
        self: *Aggregator,
        observations: []const classify.DeviceObservation,
        activity: *activity_mod.ActivityTracker,
    ) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.clearMappings();

        var pointer_count: usize = 0;
        var keyboard_count: usize = 0;
        var touch_count: usize = 0;
        var button_count: usize = 0;
        var unknown_count: usize = 0;

        var pointer_motion: std.ArrayList(classify.DeviceObservation) = .{};
        defer pointer_motion.deinit(self.allocator);

        var pointer_buttons: std.ArrayList(classify.DeviceObservation) = .{};
        defer pointer_buttons.deinit(self.allocator);

        var seen_paths = std.StringHashMap(void).init(self.allocator);
        defer seen_paths.deinit();

        for (observations) |obs| {
            if (hasRel(obs) and !isTouchLike(obs) and !obs.caps.key_other) {
                try pointer_motion.append(self.allocator, obs);
            }
            if (hasButtons(obs) and !isTouchLike(obs) and !obs.caps.key_other) {
                try pointer_buttons.append(self.allocator, obs);
            }
        }

        const correlation_window_ns: u64 = 1500 * std.time.ns_per_ms;
        const sticky_threshold: u32 = 2;

        if (pointer_motion.items.len > 0) {
            var merged_caps = classify.ObservedCaps{};
            var correlated_button_count: usize = 0;

            for (pointer_motion.items) |obs| {
                merged_caps.rel_x = merged_caps.rel_x or obs.caps.rel_x;
                merged_caps.rel_y = merged_caps.rel_y or obs.caps.rel_y;
                merged_caps.rel_wheel = merged_caps.rel_wheel or obs.caps.rel_wheel;
                merged_caps.rel_hwheel = merged_caps.rel_hwheel or obs.caps.rel_hwheel;
                merged_caps.btn_left = merged_caps.btn_left or obs.caps.btn_left;
                merged_caps.btn_right = merged_caps.btn_right or obs.caps.btn_right;
                merged_caps.btn_middle = merged_caps.btn_middle or obs.caps.btn_middle;
            }

            const anchor = pointer_motion.items[0];
            const anchor_ts = activity.lastEventNs(anchor.path);

            for (pointer_buttons.items) |obs| {
                const button_ts = activity.lastEventNs(obs.path);
                const sticky_hits = activity.pointerCorrelationHits(obs.path);
                const correlated_now = withinWindow(anchor_ts, button_ts, correlation_window_ns);
                const high_confidence = correlated_now and pointer_motion.items.len == 1 and pointer_buttons.items.len <= 2;
                const sticky = sticky_hits >= sticky_threshold;

                if (high_confidence or sticky) {
                    merged_caps.btn_left = merged_caps.btn_left or obs.caps.btn_left;
                    merged_caps.btn_right = merged_caps.btn_right or obs.caps.btn_right;
                    merged_caps.btn_middle = merged_caps.btn_middle or obs.caps.btn_middle;
                    correlated_button_count += 1;
                    try activity.notePointerCorrelation(obs.path);
                }
            }

            const name_obs = classify.DeviceObservation{
                .path = if (correlated_button_count > 0) "pointer-correlated-fast" else "pointer-fallback",
                .caps = merged_caps,
                .role = .pointer,
            };

            std.debug.print(
                "aggregation: pointer motion sources={d} button sources={d} correlated_buttons={d} decision={s}\n",
                .{
                    pointer_motion.items.len,
                    pointer_buttons.items.len,
                    correlated_button_count,
                    if (correlated_button_count > 0) "correlate+promote-fast" else "promote-rel-only",
                },
            );

            for (pointer_motion.items) |obs| {
                try self.appendMapping(&seen_paths, obs, pointer_count, .pointer, pointer_count, name_obs);
            }
            for (pointer_buttons.items) |obs| {
                const button_ts = activity.lastEventNs(obs.path);
                const sticky_hits = activity.pointerCorrelationHits(obs.path);
                const correlated_now = withinWindow(anchor_ts, button_ts, correlation_window_ns);
                const high_confidence = correlated_now and pointer_motion.items.len == 1 and pointer_buttons.items.len <= 2;
                const sticky = sticky_hits >= sticky_threshold;

                if (high_confidence or sticky) {
                    try self.appendMapping(&seen_paths, obs, pointer_count, .pointer, pointer_count, name_obs);
                }
            }
            pointer_count += 1;
        }

        for (observations) |obs| {
            if (seen_paths.contains(obs.path)) continue;

            switch (obs.role) {
                .pointer => {
                    try self.appendMapping(&seen_paths, obs, pointer_count, .pointer, pointer_count, obs);
                    pointer_count += 1;
                },
                .keyboard => {
                    try self.appendMapping(&seen_paths, obs, keyboard_count, .keyboard, keyboard_count, obs);
                    keyboard_count += 1;
                },
                .touch => {
                    try self.appendMapping(&seen_paths, obs, touch_count, .touch, touch_count, obs);
                    touch_count += 1;
                },
                .companion_button_source => {
                    try self.appendMapping(&seen_paths, obs, button_count, .button_source, button_count, obs);
                    button_count += 1;
                },
                .unknown => {
                    if (hasRel(obs) and !isTouchLike(obs) and !obs.caps.key_other) {
                        const name_obs = classify.DeviceObservation{
                            .path = "pointer-fallback",
                            .caps = obs.caps,
                            .role = .pointer,
                        };
                        std.debug.print(
                            "aggregation: fallback-promote source={s} reason=rel-only\n",
                            .{obs.path},
                        );
                        try self.appendMapping(&seen_paths, obs, pointer_count, .pointer, pointer_count, name_obs);
                        pointer_count += 1;
                    } else {
                        try self.appendMapping(&seen_paths, obs, unknown_count, .unknown, unknown_count, obs);
                        unknown_count += 1;
                    }
                },
            }
        }
    }

    pub fn snapshot(self: *Aggregator, out: *std.ArrayList(DeviceMapping), allocator: std.mem.Allocator) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        out.clearRetainingCapacity();
        for (self.mappings.items) |m| {
            const owned_path = try allocator.dupe(u8, m.path);
            const owned_name = try allocator.dupe(u8, m.stable_name);
            try out.append(allocator, .{
                .path = owned_path,
                .logical_id = m.logical_id,
                .kind = m.kind,
                .stable_name = owned_name,
                .fingerprint = m.fingerprint,
            });
        }
    }

    pub fn freeSnapshot(self: *Aggregator, out: *std.ArrayList(DeviceMapping), allocator: std.mem.Allocator) void {
        _ = self;
        for (out.items) |m| {
            allocator.free(m.path);
            allocator.free(m.stable_name);
        }
        out.clearRetainingCapacity();
    }

    pub fn findForPath(self: *Aggregator, path: []const u8) ?DeviceMapping {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.mappings.items) |m| {
            if (std.mem.eql(u8, m.path, path)) return m;
        }
        return null;
    }

    pub fn hasMappingForPath(self: *Aggregator, path: []const u8) bool {
        return self.findForPath(path) != null;
    }

    pub fn writeMappedEvent(self: *Aggregator, event: semantic.SemanticEvent) void {
        const path = event.sourcePath();
        const mapping = self.findForPath(path) orelse return;

        switch (event) {
            .mouse_move => |e| std.debug.print("semantic: dev={s} mouse_move dx={d} dy={d} source={s}\n", .{ mapping.stable_name, e.dx, e.dy, path }),
            .mouse_button => |e| std.debug.print("semantic: dev={s} mouse_button button={s} state={s} x={d} y={d} source={s}\n", .{ mapping.stable_name, e.button, if (e.pressed) "down" else "up", e.x, e.y, path }),
            .mouse_scroll => |e| std.debug.print("semantic: dev={s} mouse_scroll dx={d} dy={d} source={s}\n", .{ mapping.stable_name, e.dx, e.dy, path }),
            .key_down => |e| std.debug.print("semantic: dev={s} key_down code={d} source={s}\n", .{ mapping.stable_name, e.code, path }),
            .key_up => |e| std.debug.print("semantic: dev={s} key_up code={d} source={s}\n", .{ mapping.stable_name, e.code, path }),
            .touch_down => |e| std.debug.print("semantic: dev={s} touch_down contact={d} x={d} y={d} source={s}\n", .{ mapping.stable_name, e.contact, e.x, e.y, path }),
            .touch_move => |e| std.debug.print("semantic: dev={s} touch_move contact={d} x={d} y={d} source={s}\n", .{ mapping.stable_name, e.contact, e.x, e.y, path }),
            .touch_up => |e| std.debug.print("semantic: dev={s} touch_up contact={d} source={s}\n", .{ mapping.stable_name, e.contact, path }),
        }
    }
};
