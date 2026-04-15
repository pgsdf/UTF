const std = @import("std");
const semantic = @import("semantic.zig");
const aggregate = @import("device_aggregate.zig");

const TapMaxDurationNs: u64 = 250 * std.time.ns_per_ms;
const DragThreshold: i32 = 24;
const ScrollActivateThreshold: i32 = 2;
const ScrollReleaseThreshold: i32 = 1;
const ScrollEmitThreshold: i32 = 1;
const ScrollAxisDominanceMargin: i32 = 1;
const ScrollReleaseFrames: u32 = 3;
const PostScrollCooldownFrames: u32 = 4;
const PinchActivateThreshold: i32 = 8;
const PinchEmitThreshold: i32 = 2;
const PinchJitterDeadzone: i32 = 4;
const ThreeFingerSwipeActivateThreshold: i32 = 18;
const ThreeFingerSwipeEmitThreshold: i32 = 2;
const ThreeFingerArbitrationCooldownFrames: u32 = 4;
const ThreeFingerAxisLockMargin: i32 = 3;
const ThreeFingerAxisEarlyMargin: i32 = 2;
const VelocityScaleNumerator: i32 = 1;
const VelocityScaleDenominator: i32 = 2;
const MaxDeltaStep: i32 = 3;

const AxisLock = enum {
    none,
    horizontal,
    vertical,
};

pub const ContactState = struct {
    device_name: []const u8,
    contact_id: i32,
    is_active: bool,
    start_x: i32,
    start_y: i32,
    prev_x: i32,
    prev_y: i32,
    last_x: i32,
    last_y: i32,
    down_ns: u64,
    drag_started: bool,
};

pub const DeviceGestureState = struct {
    device_name: []const u8,
    last_scroll_dx: i32,
    last_scroll_dy: i32,
    multitouch_scroll_active: bool,
    scroll_locked: bool,
    release_counter: u32,
    post_scroll_cooldown_frames: u32,
    pinch_locked: bool,
    last_pinch_delta: i32,
    swipe3_locked: bool,
    swipe3_arbitrating: bool,
    swipe3_guard_frames: u32,
    swipe3_axis_lock: AxisLock,
    swipe3_axis_candidate: AxisLock,
    swipe3_start_cx: i32,
    swipe3_start_cy: i32,
    swipe3_have_anchor: bool,
    last_swipe3_dx: i32,
    last_swipe3_dy: i32,
};

pub const GestureRecognizer = struct {
    allocator: std.mem.Allocator,
    contacts: std.ArrayList(ContactState),
    device_states: std.ArrayList(DeviceGestureState),

    pub fn init(allocator: std.mem.Allocator) GestureRecognizer {
        return .{ .allocator = allocator, .contacts = .{}, .device_states = .{} };
    }

    pub fn deinit(self: *GestureRecognizer) void {
        for (self.contacts.items) |c| self.allocator.free(c.device_name);
        self.contacts.deinit(self.allocator);
        for (self.device_states.items) |s| self.allocator.free(s.device_name);
        self.device_states.deinit(self.allocator);
    }

    fn emitGestureEvent(self: *GestureRecognizer, device_name: []const u8, gesture_type: []const u8, fields_json: []const u8) !void {
        const line = try std.fmt.allocPrint(self.allocator, "{{{{\"type\":\"{s}\",\"device\":\"{s}\"{s}}}}}\n", .{
            gesture_type,
            device_name,
            fields_json,
        });
        defer self.allocator.free(line);

        var file = std.fs.File.stdout();
        var buf: [1024]u8 = undefined;
        var out = file.writer(&buf);
        try out.interface.writeAll(line);
        try out.interface.flush();
    }

    fn findContact(self: *GestureRecognizer, device_name: []const u8, contact_id: i32) ?*ContactState {
        for (self.contacts.items) |*c| {
            if (c.contact_id == contact_id and std.mem.eql(u8, c.device_name, device_name)) return c;
        }
        return null;
    }

    fn getOrCreateContact(self: *GestureRecognizer, device_name: []const u8, contact_id: i32) !*ContactState {
        if (self.findContact(device_name, contact_id)) |c| return c;

        const owned = try self.allocator.dupe(u8, device_name);
        try self.contacts.append(self.allocator, .{
            .device_name = owned,
            .contact_id = contact_id,
            .is_active = false,
            .start_x = 0,
            .start_y = 0,
            .prev_x = 0,
            .prev_y = 0,
            .last_x = 0,
            .last_y = 0,
            .down_ns = 0,
            .drag_started = false,
        });
        return &self.contacts.items[self.contacts.items.len - 1];
    }

    fn findDeviceState(self: *GestureRecognizer, device_name: []const u8) ?*DeviceGestureState {
        for (self.device_states.items) |*s| {
            if (std.mem.eql(u8, s.device_name, device_name)) return s;
        }
        return null;
    }

    fn getOrCreateDeviceState(self: *GestureRecognizer, device_name: []const u8) !*DeviceGestureState {
        if (self.findDeviceState(device_name)) |s| return s;

        const owned = try self.allocator.dupe(u8, device_name);
        try self.device_states.append(self.allocator, .{
            .device_name = owned,
            .last_scroll_dx = 0,
            .last_scroll_dy = 0,
            .multitouch_scroll_active = false,
            .scroll_locked = false,
            .release_counter = 0,
            .post_scroll_cooldown_frames = 0,
            .pinch_locked = false,
            .last_pinch_delta = 0,
            .swipe3_locked = false,
            .swipe3_arbitrating = false,
            .swipe3_guard_frames = 0,
            .swipe3_axis_lock = .none,
            .swipe3_axis_candidate = .none,
            .swipe3_start_cx = 0,
            .swipe3_start_cy = 0,
            .swipe3_have_anchor = false,
            .last_swipe3_dx = 0,
            .last_swipe3_dy = 0,
        });
        return &self.device_states.items[self.device_states.items.len - 1];
    }

    fn deviceNameForPath(self: *GestureRecognizer, aggregator: *aggregate.Aggregator, path: []const u8) ?[]const u8 {
        _ = self;
        const mapping = aggregator.findForPath(path) orelse return null;
        return mapping.stable_name;
    }

    fn absDiff(a: i32, b: i32) i32 {
        return if (a >= b) a - b else b - a;
    }

    fn sign(v: i32) i32 {
        return if (v > 0) 1 else if (v < 0) -1 else 0;
    }

    fn clampDeltaStep(prev: i32, next: i32) i32 {
        const diff = next - prev;
        if (diff > MaxDeltaStep) return prev + MaxDeltaStep;
        if (diff < -MaxDeltaStep) return prev - MaxDeltaStep;
        return next;
    }

    fn normalizeVelocity(v: i32) i32 {
        return @divTrunc(v * VelocityScaleNumerator, VelocityScaleDenominator);
    }

    fn accelerateVelocity(v: i32) i32 {
        const av = absDiff(v, 0);
        if (av <= 2) return v;
        if (av <= 8) return v + sign(v);
        if (av <= 16) return v + (2 * sign(v));
        return v + (3 * sign(v));
    }

    fn axisName(axis: AxisLock) []const u8 {
        return switch (axis) {
            .horizontal => "horizontal",
            .vertical => "vertical",
            .none => "none",
        };
    }

    fn activeContactsForDevice(self: *GestureRecognizer, device_name: []const u8) usize {
        var count: usize = 0;
        for (self.contacts.items) |c| {
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) count += 1;
        }
        return count;
    }

    fn averageVelocityXForDevice(self: *GestureRecognizer, device_name: []const u8) i32 {
        var total: i32 = 0;
        var count: i32 = 0;
        for (self.contacts.items) |c| {
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) {
                total += c.last_x - c.prev_x;
                count += 1;
            }
        }
        return if (count > 0) normalizeVelocity(@divTrunc(total, count)) else 0;
    }

    fn averageVelocityYForDevice(self: *GestureRecognizer, device_name: []const u8) i32 {
        var total: i32 = 0;
        var count: i32 = 0;
        for (self.contacts.items) |c| {
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) {
                total += c.last_y - c.prev_y;
                count += 1;
            }
        }
        return if (count > 0) normalizeVelocity(@divTrunc(total, count)) else 0;
    }

    fn averagePositionXForDevice(self: *GestureRecognizer, device_name: []const u8) i32 {
        var total: i32 = 0;
        var count: i32 = 0;
        for (self.contacts.items) |c| {
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) {
                total += c.last_x;
                count += 1;
            }
        }
        return if (count > 0) @divTrunc(total, count) else 0;
    }

    fn averagePositionYForDevice(self: *GestureRecognizer, device_name: []const u8) i32 {
        var total: i32 = 0;
        var count: i32 = 0;
        for (self.contacts.items) |c| {
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) {
                total += c.last_y;
                count += 1;
            }
        }
        return if (count > 0) @divTrunc(total, count) else 0;
    }

    fn averagePrevPositionXForDevice(self: *GestureRecognizer, device_name: []const u8) i32 {
        var total: i32 = 0;
        var count: i32 = 0;
        for (self.contacts.items) |c| {
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) {
                total += c.prev_x;
                count += 1;
            }
        }
        return if (count > 0) @divTrunc(total, count) else 0;
    }

    fn averagePrevPositionYForDevice(self: *GestureRecognizer, device_name: []const u8) i32 {
        var total: i32 = 0;
        var count: i32 = 0;
        for (self.contacts.items) |c| {
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) {
                total += c.prev_y;
                count += 1;
            }
        }
        return if (count > 0) @divTrunc(total, count) else 0;
    }

    fn contactsSupportScroll(self: *GestureRecognizer, device_name: []const u8) bool {
        var found: usize = 0;
        var first_dx: i32 = 0;
        var first_dy: i32 = 0;
        for (self.contacts.items) |c| {
            if (!(c.is_active and std.mem.eql(u8, c.device_name, device_name))) continue;
            const dx = c.last_x - c.prev_x;
            const dy = c.last_y - c.prev_y;
            if (found == 0) {
                first_dx = dx;
                first_dy = dy;
                found = 1;
                continue;
            }
            const x_ok = sign(dx) == 0 or sign(first_dx) == 0 or sign(dx) == sign(first_dx);
            const y_ok = sign(dy) == 0 or sign(first_dy) == 0 or sign(dy) == sign(first_dy);
            if (!(x_ok and y_ok)) return false;
            found += 1;
        }
        return found >= 2;
    }

    fn axisDominant(avg_dx: i32, avg_dy: i32) bool {
        const ax = absDiff(avg_dx, 0);
        const ay = absDiff(avg_dy, 0);
        return ax >= ay + ScrollAxisDominanceMargin or ay >= ax + ScrollAxisDominanceMargin;
    }

    fn smoothScroll(self: *GestureRecognizer, device_name: []const u8, dx: i32, dy: i32) !struct { dx: i32, dy: i32 } {
        const state = try self.getOrCreateDeviceState(device_name);
        const raw_dx = @divTrunc(dx + state.last_scroll_dx, 2);
        const raw_dy = @divTrunc(dy + state.last_scroll_dy, 2);
        const smoothed_dx = clampDeltaStep(state.last_scroll_dx, raw_dx);
        const smoothed_dy = clampDeltaStep(state.last_scroll_dy, raw_dy);
        state.last_scroll_dx = smoothed_dx;
        state.last_scroll_dy = smoothed_dy;
        return .{ .dx = smoothed_dx, .dy = smoothed_dy };
    }

    fn smoothSwipe3(self: *GestureRecognizer, device_name: []const u8, dx: i32, dy: i32) !struct { dx: i32, dy: i32 } {
        const state = try self.getOrCreateDeviceState(device_name);
        const raw_dx = @divTrunc(dx + state.last_swipe3_dx, 2);
        const raw_dy = @divTrunc(dy + state.last_swipe3_dy, 2);
        const smoothed_dx = clampDeltaStep(state.last_swipe3_dx, raw_dx);
        const smoothed_dy = clampDeltaStep(state.last_swipe3_dy, raw_dy);
        state.last_swipe3_dx = smoothed_dx;
        state.last_swipe3_dy = smoothed_dy;
        return .{ .dx = smoothed_dx, .dy = smoothed_dy };
    }

    fn applyAxisLock(lock: AxisLock, dx: i32, dy: i32) struct { dx: i32, dy: i32 } {
        return switch (lock) {
            .horizontal => .{ .dx = dx, .dy = 0 },
            .vertical => .{ .dx = 0, .dy = dy },
            .none => .{ .dx = dx, .dy = dy },
        };
    }

    fn chooseAxisLock(dx: i32, dy: i32) AxisLock {
        const ax = absDiff(dx, 0);
        const ay = absDiff(dy, 0);
        if (ax >= ay + ThreeFingerAxisLockMargin) return .horizontal;
        if (ay >= ax + ThreeFingerAxisLockMargin) return .vertical;
        return .none;
    }

    fn chooseAxisCandidate(dx: i32, dy: i32) AxisLock {
        const ax = absDiff(dx, 0);
        const ay = absDiff(dy, 0);
        if (ax >= ay + ThreeFingerAxisEarlyMargin) return .horizontal;
        if (ay >= ax + ThreeFingerAxisEarlyMargin) return .vertical;
        return .none;
    }

    fn computeConfidence(dx: i32, dy: i32, axis: AxisLock) u8 {
        const ax = absDiff(dx, 0);
        const ay = absDiff(dy, 0);
        const dominant = switch (axis) {
            .horizontal => ax,
            .vertical => ay,
            .none => @max(ax, ay),
        };
        const secondary = switch (axis) {
            .horizontal => ay,
            .vertical => ax,
            .none => @min(ax, ay),
        };
        const diff = dominant - secondary;
        var score: i32 = 50 + diff * 5;
        if (dominant >= 12) score += 15;
        if (dominant >= 20) score += 10;
        if (score < 0) score = 0;
        if (score > 100) score = 100;
        return @intCast(score);
    }

    fn emitIntentHook(self: *GestureRecognizer, device_name: []const u8, gesture: []const u8, axis: []const u8, confidence: u8) !void {
        var fields_buf: [192]u8 = undefined;
        const fields = try std.fmt.bufPrint(&fields_buf, ",\"gesture\":\"{s}\",\"axis\":\"{s}\",\"confidence\":{d}", .{
            gesture, axis, confidence,
        });
        try self.emitGestureEvent(device_name, "intent_hint", fields);
    }

    fn tickCooldown(state: *DeviceGestureState) void {
        if (state.post_scroll_cooldown_frames > 0) state.post_scroll_cooldown_frames -= 1;
    }

    fn tickSwipe3Guard(state: *DeviceGestureState) void {
        if (state.swipe3_guard_frames > 0) state.swipe3_guard_frames -= 1;
        if (state.swipe3_guard_frames == 0 and !state.swipe3_locked) {
            state.swipe3_arbitrating = false;
            state.swipe3_have_anchor = false;
        }
    }

    fn endScrollWithCooldown(self: *GestureRecognizer, state: *DeviceGestureState, device_name: []const u8) !void {
        state.multitouch_scroll_active = false;
        state.scroll_locked = false;
        state.release_counter = 0;
        state.post_scroll_cooldown_frames = PostScrollCooldownFrames;
        try self.emitGestureEvent(device_name, "scroll_end", "");
    }

    fn clearHighLevelLocks(state: *DeviceGestureState) void {
        state.multitouch_scroll_active = false;
        state.scroll_locked = false;
        state.release_counter = 0;
        state.pinch_locked = false;
        state.last_pinch_delta = 0;
        state.swipe3_locked = false;
        state.swipe3_arbitrating = false;
        state.swipe3_guard_frames = 0;
        state.swipe3_axis_lock = .none;
        state.swipe3_axis_candidate = .none;
        state.swipe3_start_cx = 0;
        state.swipe3_start_cy = 0;
        state.swipe3_have_anchor = false;
        state.last_swipe3_dx = 0;
        state.last_swipe3_dy = 0;
    }

    fn endPinch(self: *GestureRecognizer, state: *DeviceGestureState, device_name: []const u8) !void {
        if (state.pinch_locked) {
            state.pinch_locked = false;
            state.last_pinch_delta = 0;
            try self.emitGestureEvent(device_name, "pinch_end", "");
        }
    }

    fn endSwipe3(self: *GestureRecognizer, state: *DeviceGestureState, device_name: []const u8) !void {
        if (state.swipe3_locked) {
            state.swipe3_locked = false;
            state.last_swipe3_dx = 0;
            state.last_swipe3_dy = 0;
            state.swipe3_axis_lock = .none;
            try self.emitGestureEvent(device_name, "three_finger_swipe_end", "");
        }
        state.swipe3_arbitrating = false;
        state.swipe3_guard_frames = 0;
        state.swipe3_axis_candidate = .none;
        state.swipe3_start_cx = 0;
        state.swipe3_start_cy = 0;
        state.swipe3_have_anchor = false;
        if (!state.swipe3_locked) state.swipe3_axis_lock = .none;
    }

    fn startSwipe3Arbitration(self: *GestureRecognizer, state: *DeviceGestureState, device_name: []const u8) void {
        state.swipe3_arbitrating = true;
        state.swipe3_guard_frames = ThreeFingerArbitrationCooldownFrames;
        state.swipe3_axis_lock = .none;
        state.swipe3_axis_candidate = .none;
        state.swipe3_start_cx = self.averagePositionXForDevice(device_name);
        state.swipe3_start_cy = self.averagePositionYForDevice(device_name);
        state.swipe3_have_anchor = true;
        state.pinch_locked = false;
        state.last_pinch_delta = 0;
        state.multitouch_scroll_active = false;
        state.scroll_locked = false;
        state.release_counter = 0;
    }

    fn enforceStrictArbitration(self: *GestureRecognizer, device_name: []const u8) !void {
        const state = try self.getOrCreateDeviceState(device_name);
        const active = self.activeContactsForDevice(device_name);

        if (active >= 3) {
            try self.endPinch(state, device_name);
            state.multitouch_scroll_active = false;
            state.scroll_locked = false;
            state.release_counter = 0;
            if (!state.swipe3_locked and !state.swipe3_arbitrating) {
                self.startSwipe3Arbitration(state, device_name);
            }
        }

        if (active != 2) {
            try self.endPinch(state, device_name);
        }

        if (active != 3) {
            try self.endSwipe3(state, device_name);
        }

        if (active == 0) {
            Self.clearHighLevelLocks(state);
        }
    }

    fn getFirstNActiveContacts(self: *GestureRecognizer, device_name: []const u8, n: usize, out: []ContactState) usize {
        var count: usize = 0;
        for (self.contacts.items) |c| {
            if (count >= n) break;
            if (c.is_active and std.mem.eql(u8, c.device_name, device_name)) {
                out[count] = c;
                count += 1;
            }
        }
        return count;
    }

    fn pinchDistanceSquared(a: ContactState, b: ContactState) i64 {
        const dx: i64 = @as(i64, a.last_x) - @as(i64, b.last_x);
        const dy: i64 = @as(i64, a.last_y) - @as(i64, b.last_y);
        return dx * dx + dy * dy;
    }

    fn pinchPrevDistanceSquared(a: ContactState, b: ContactState) i64 {
        const dx: i64 = @as(i64, a.prev_x) - @as(i64, b.prev_x);
        const dy: i64 = @as(i64, a.prev_y) - @as(i64, b.prev_y);
        return dx * dx + dy * dy;
    }

    fn updatePinchState(self: *GestureRecognizer, device_name: []const u8) !void {
        const state = try self.getOrCreateDeviceState(device_name);
        const active = self.activeContactsForDevice(device_name);

        if (state.scroll_locked or state.multitouch_scroll_active or state.swipe3_locked or state.swipe3_arbitrating) {
            try self.endPinch(state, device_name);
            return;
        }

        if (active != 2) {
            try self.endPinch(state, device_name);
            return;
        }

        var contacts: [2]ContactState = undefined;
        if (self.getFirstNActiveContacts(device_name, 2, &contacts) != 2) return;

        const cur = pinchDistanceSquared(contacts[0], contacts[1]);
        const prev = pinchPrevDistanceSquared(contacts[0], contacts[1]);
        const delta: i32 = @intCast(@divTrunc(cur - prev, 128));

        if (!state.pinch_locked) {
            if (absDiff(delta, 0) >= PinchActivateThreshold) {
                state.pinch_locked = true;
                state.last_pinch_delta = delta;
                var fields_buf: [64]u8 = undefined;
                const fields = try std.fmt.bufPrint(&fields_buf, ",\"delta\":{d}", .{delta});
                try self.emitGestureEvent(device_name, "pinch_begin", fields);
                try self.emitIntentHook(device_name, "pinch", if (delta > 0) "out" else "in", @min(100, @as(u8, @intCast(60 + absDiff(delta, 0)))));
            }
            return;
        }

        if (absDiff(delta, 0) < PinchJitterDeadzone) return;
        if (absDiff(delta, 0) < PinchEmitThreshold) return;

        state.last_pinch_delta = delta;
        var fields_buf: [64]u8 = undefined;
        const fields = try std.fmt.bufPrint(&fields_buf, ",\"delta\":{d},\"scale_hint\":\"{s}\"", .{ delta, if (delta > 0) "out" else "in" });
        try self.emitGestureEvent(device_name, "pinch", fields);
    }

    fn updateThreeFingerSwipeState(self: *GestureRecognizer, device_name: []const u8) !void {
        const state = try self.getOrCreateDeviceState(device_name);
        const active = self.activeContactsForDevice(device_name);

        if (state.scroll_locked or state.multitouch_scroll_active or state.pinch_locked) {
            try self.endSwipe3(state, device_name);
            return;
        }

        if (active != 3) {
            try self.endSwipe3(state, device_name);
            return;
        }

        const cx = self.averagePositionXForDevice(device_name);
        const cy = self.averagePositionYForDevice(device_name);
        const step_dx = accelerateVelocity(cx - self.averagePrevPositionXForDevice(device_name));
        const step_dy = accelerateVelocity(cy - self.averagePrevPositionYForDevice(device_name));

        const total_dx = cx - state.swipe3_start_cx;
        const total_dy = cy - state.swipe3_start_cy;

        if (!state.swipe3_locked) {
            state.swipe3_axis_candidate = chooseAxisCandidate(total_dx, total_dy);

            if (state.swipe3_arbitrating and state.swipe3_guard_frames > 0) {
                Self.tickSwipe3Guard(state);
            }

            const axis = if (state.swipe3_axis_candidate != .none) state.swipe3_axis_candidate else chooseAxisLock(total_dx, total_dy);
            const locked_total = applyAxisLock(axis, total_dx, total_dy);

            if (absDiff(locked_total.dx, 0) >= ThreeFingerSwipeActivateThreshold or absDiff(locked_total.dy, 0) >= ThreeFingerSwipeActivateThreshold) {
                state.swipe3_locked = true;
                state.swipe3_arbitrating = false;
                state.swipe3_guard_frames = 0;
                state.swipe3_axis_lock = axis;
                const initial_step = applyAxisLock(axis, step_dx, step_dy);
                state.last_swipe3_dx = initial_step.dx;
                state.last_swipe3_dy = initial_step.dy;
                const confidence = computeConfidence(locked_total.dx, locked_total.dy, axis);
                var fields_buf: [160]u8 = undefined;
                const fields = try std.fmt.bufPrint(&fields_buf, ",\"dx\":{d},\"dy\":{d},\"total_dx\":{d},\"total_dy\":{d},\"axis\":\"{s}\",\"confidence\":{d}", .{
                    initial_step.dx, initial_step.dy, locked_total.dx, locked_total.dy, axisName(axis), confidence,
                });
                try self.emitGestureEvent(device_name, "three_finger_swipe_begin", fields);
                try self.emitIntentHook(device_name, "three_finger_swipe", axisName(axis), confidence);
            }
            return;
        }

        const locked_step = applyAxisLock(state.swipe3_axis_lock, step_dx, step_dy);
        const smoothed = try self.smoothSwipe3(device_name, locked_step.dx, locked_step.dy);
        if (absDiff(smoothed.dx, 0) < ThreeFingerSwipeEmitThreshold and absDiff(smoothed.dy, 0) < ThreeFingerSwipeEmitThreshold) return;

        const locked_total = applyAxisLock(state.swipe3_axis_lock, total_dx, total_dy);
        const confidence = computeConfidence(locked_total.dx, locked_total.dy, state.swipe3_axis_lock);
        var fields_buf: [160]u8 = undefined;
        const fields = try std.fmt.bufPrint(&fields_buf, ",\"dx\":{d},\"dy\":{d},\"total_dx\":{d},\"total_dy\":{d},\"axis\":\"{s}\",\"confidence\":{d}", .{
            smoothed.dx, smoothed.dy, locked_total.dx, locked_total.dy, axisName(state.swipe3_axis_lock), confidence,
        });
        try self.emitGestureEvent(device_name, "three_finger_swipe", fields);
    }

    fn updateMultitouchScrollState(self: *GestureRecognizer, device_name: []const u8) !void {
        const active_count = self.activeContactsForDevice(device_name);
        const state = try self.getOrCreateDeviceState(device_name);
        const was_locked = state.scroll_locked;

        if (active_count < 2) {
            if (was_locked or state.multitouch_scroll_active) {
                try self.endScrollWithCooldown(state, device_name);
            } else {
                Self.tickCooldown(state);
            }
            if (active_count == 0) Self.clearHighLevelLocks(state);
            return;
        }

        if (active_count == 3 or state.swipe3_locked or state.swipe3_arbitrating) {
            state.multitouch_scroll_active = false;
            state.scroll_locked = false;
            state.release_counter = 0;
            return;
        }

        const vx = self.averageVelocityXForDevice(device_name);
        const vy = self.averageVelocityYForDevice(device_name);
        const mag = @max(absDiff(vx, 0), absDiff(vy, 0));
        const coherent = self.contactsSupportScroll(device_name) and axisDominant(vx, vy);

        if (!state.scroll_locked) {
            if (state.post_scroll_cooldown_frames > 0) {
                state.multitouch_scroll_active = false;
                return;
            }

            if (!state.pinch_locked and coherent and mag >= ScrollActivateThreshold) {
                state.multitouch_scroll_active = true;
                state.scroll_locked = true;
                state.release_counter = 0;
                try self.emitGestureEvent(device_name, "scroll_begin", "");
                const axis: []const u8 = if (absDiff(vx, 0) > absDiff(vy, 0)) "horizontal" else "vertical";
                try self.emitIntentHook(device_name, "two_finger_scroll", axis, computeConfidence(vx, vy, if (std.mem.eql(u8, axis, "horizontal")) .horizontal else .vertical));
            } else {
                state.multitouch_scroll_active = false;
            }
            return;
        }

        state.multitouch_scroll_active = true;

        if (!coherent or mag < ScrollReleaseThreshold) {
            state.release_counter += 1;
        } else {
            state.release_counter = 0;
        }

        if (state.release_counter >= ScrollReleaseFrames) {
            try self.endScrollWithCooldown(state, device_name);
        }
    }

    fn maybeEmitTwoFingerScroll(self: *GestureRecognizer, device_name: []const u8) !void {
        const active_count = self.activeContactsForDevice(device_name);
        const state = try self.getOrCreateDeviceState(device_name);
        if (active_count < 2 or !state.multitouch_scroll_active or !state.scroll_locked) return;

        const vx = self.averageVelocityXForDevice(device_name);
        const vy = self.averageVelocityYForDevice(device_name);
        const smoothed = try self.smoothScroll(device_name, vx, vy);

        if (absDiff(smoothed.dx, 0) <= ScrollEmitThreshold and absDiff(smoothed.dy, 0) <= ScrollEmitThreshold) return;

        var fields_buf: [128]u8 = undefined;
        const fields = try std.fmt.bufPrint(&fields_buf, ",\"dx\":{d},\"dy\":{d}", .{ smoothed.dx, smoothed.dy });
        try self.emitGestureEvent(device_name, "two_finger_scroll", fields);
    }

    fn handleTouchDown(self: *GestureRecognizer, aggregator: *aggregate.Aggregator, e: anytype, now_ns: u64) !void {
        const device_name = self.deviceNameForPath(aggregator, e.path) orelse return;
        const c = try self.getOrCreateContact(device_name, e.contact);
        c.is_active = true;
        c.start_x = e.x;
        c.start_y = e.y;
        c.prev_x = e.x;
        c.prev_y = e.y;
        c.last_x = e.x;
        c.last_y = e.y;
        c.down_ns = now_ns;
        c.drag_started = false;
        _ = try self.getOrCreateDeviceState(device_name);

        try self.enforceStrictArbitration(device_name);
    }

    fn handleTouchMove(self: *GestureRecognizer, aggregator: *aggregate.Aggregator, e: anytype, now_ns: u64) !void {
        _ = now_ns;
        const device_name = self.deviceNameForPath(aggregator, e.path) orelse return;
        const c = try self.getOrCreateContact(device_name, e.contact);
        if (!c.is_active) return;

        c.prev_x = c.last_x;
        c.prev_y = c.last_y;
        c.last_x = e.x;
        c.last_y = e.y;

        const state = try self.getOrCreateDeviceState(device_name);

        if (state.post_scroll_cooldown_frames > 0) {
            Self.tickCooldown(state);
            return;
        }

        try self.enforceStrictArbitration(device_name);

        if (state.swipe3_arbitrating and !state.swipe3_locked) {
            try self.updateThreeFingerSwipeState(device_name);
            return;
        }

        try self.updateThreeFingerSwipeState(device_name);
        if (state.swipe3_locked) return;

        try self.updatePinchState(device_name);
        if (state.pinch_locked) return;

        try self.updateMultitouchScrollState(device_name);
        try self.maybeEmitTwoFingerScroll(device_name);
        if (state.scroll_locked or state.multitouch_scroll_active) return;

        const dx = absDiff(c.start_x, e.x);
        const dy = absDiff(c.start_y, e.y);
        var fields_buf: [128]u8 = undefined;

        if (!c.drag_started and (dx >= DragThreshold or dy >= DragThreshold)) {
            c.drag_started = true;
            const fields = try std.fmt.bufPrint(&fields_buf, ",\"contact\":{d},\"x\":{d},\"y\":{d}", .{ e.contact, e.x, e.y });
            try self.emitGestureEvent(device_name, "drag_start", fields);
        } else if (c.drag_started) {
            const fields = try std.fmt.bufPrint(&fields_buf, ",\"contact\":{d},\"x\":{d},\"y\":{d}", .{ e.contact, e.x, e.y });
            try self.emitGestureEvent(device_name, "drag_move", fields);
        }
    }

    fn handleTouchUp(self: *GestureRecognizer, aggregator: *aggregate.Aggregator, e: anytype, now_ns: u64) !void {
        const device_name = self.deviceNameForPath(aggregator, e.path) orelse return;
        const c = self.findContact(device_name, e.contact) orelse return;
        if (!c.is_active) return;

        const state = try self.getOrCreateDeviceState(device_name);
        const duration = now_ns - c.down_ns;
        const dx = absDiff(c.start_x, c.last_x);
        const dy = absDiff(c.start_y, c.last_y);
        var fields_buf: [128]u8 = undefined;

        if (!state.scroll_locked and !state.multitouch_scroll_active and !state.pinch_locked and !state.swipe3_locked and !state.swipe3_arbitrating and state.post_scroll_cooldown_frames == 0) {
            if (c.drag_started) {
                const fields = try std.fmt.bufPrint(&fields_buf, ",\"contact\":{d},\"x\":{d},\"y\":{d}", .{ e.contact, c.last_x, c.last_y });
                try self.emitGestureEvent(device_name, "drag_end", fields);
            } else if (duration <= TapMaxDurationNs and dx < DragThreshold and dy < DragThreshold) {
                const fields = try std.fmt.bufPrint(&fields_buf, ",\"contact\":{d},\"x\":{d},\"y\":{d}", .{ e.contact, c.last_x, c.last_y });
                try self.emitGestureEvent(device_name, "tap", fields);
            }
        }

        c.is_active = false;
        c.drag_started = false;

        try self.enforceStrictArbitration(device_name);
        try self.updateMultitouchScrollState(device_name);
    }

    pub fn handleEvent(self: *GestureRecognizer, aggregator: *aggregate.Aggregator, event: semantic.SemanticEvent, now_ns: u64) !void {
        switch (event) {
            .touch_down => |e| try self.handleTouchDown(aggregator, e, now_ns),
            .touch_move => |e| try self.handleTouchMove(aggregator, e, now_ns),
            .touch_up => |e| try self.handleTouchUp(aggregator, e, now_ns),
            else => {},
        }
    }
};

const Self = GestureRecognizer;
