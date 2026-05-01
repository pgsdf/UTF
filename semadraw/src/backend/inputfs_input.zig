//! inputfs_input.zig — drains the inputfs event ring and translates
//! events into the drawfs backend's KeyEvent and MouseEvent buffers.
//!
//! Replaces the legacy DRAWFSGIOC_INJECT_INPUT path that semainputd
//! used to push events through. inputfs publishes events directly to
//! /var/run/sema/input/events (per shared/INPUT_EVENTS.md and
//! shared/src/input.zig); this adapter consumes them.
//!
//! AD-2a Phase 1: this is the userland half of the cutover. The legacy
//! injection path remains in place but unconsumed; semainputd may
//! continue running but its events are ignored. Phase 3 deletes the
//! legacy paths.

const std = @import("std");
const backend = @import("backend");
const input = @import("input");
const translate = @import("inputfs_translate.zig");

const log = std.log.scoped(.inputfs_input);

// ============================================================================
// inputfs event_type constants for source_role = SOURCE_KEYBOARD / SOURCE_POINTER
// ============================================================================

// Per shared/INPUT_EVENTS.md §"Event types and payload layouts".
// Defined locally rather than in shared/src/input.zig to keep the
// public API of that module focused on the wire format; named
// dispatch values are a consumer concern.

const KEYBOARD_KEY_DOWN: u8 = 1;
const KEYBOARD_KEY_UP: u8 = 2;

const POINTER_MOTION: u8 = 1;
const POINTER_BUTTON_DOWN: u8 = 2;
const POINTER_BUTTON_UP: u8 = 3;
const POINTER_SCROLL: u8 = 4;
// 5 = enter, 6 = leave: synthesised by inputfs Stage D; not consumed
// by Phase 1 (the drawfs backend models enter/leave implicitly via
// the active surface).

// Pointer button bitmask (HID-style; matches what inputfs publishes).
const BUTTON_LEFT: u32 = 0x1;
const BUTTON_RIGHT: u32 = 0x2;
const BUTTON_MIDDLE: u32 = 0x4;

// Drain batch size. Bounded to keep the per-frame work predictable;
// at 60Hz with one event per ms this is enough headroom for a full
// keyboard rollover plus pointer activity in any single frame.
const DRAIN_BATCH: usize = 64;

// ============================================================================
// InputfsInput
// ============================================================================

pub const InputfsInput = struct {
    reader: input.EventRingReader,
    /// last_button_state tracks the cumulative pointer button bitmask
    /// as published by inputfs. Pointer events from inputfs include
    /// the absolute (x, y) and (in MOTION events) deltas, but button
    /// transitions in MOTION events are inferred by diffing against
    /// this state. inputfs also publishes BUTTON_DOWN/BUTTON_UP events
    /// directly; this state lets us synthesise transitions in the
    /// motion-only case without double-counting.
    last_button_state: u32,
    /// last_modifiers tracks the most recent modifier bitmask seen
    /// from a keyboard event. Mouse events from inputfs do not carry
    /// modifier state; the backend's MouseEvent type does. Carry-
    /// forward is the simplest faithful behaviour (matches what
    /// semainputd was doing implicitly).
    last_modifiers: u8,

    const Self = @This();

    /// Open the inputfs event ring and skip to the current writer
    /// position so historical events are not replayed at startup.
    /// Returns null on any open or validation failure; caller treats
    /// null as "inputfs not available" and proceeds without input
    /// from this source. inputfs may not be loaded; the compositor
    /// must not refuse to start because of it.
    pub fn init() ?Self {
        var reader = input.EventRingReader.init(input.EVENTS_PATH);
        if (reader.map == null) {
            log.warn("inputfs ring at {s} unavailable; no input from inputfs", .{input.EVENTS_PATH});
            return null;
        }
        if (!reader.isValid()) {
            log.warn("inputfs ring at {s} not valid; no input from inputfs", .{input.EVENTS_PATH});
            reader.deinit();
            return null;
        }

        // Skip historical events. The reader's last_consumed starts
        // at 0; setting it to writer_seq means the first drain returns
        // only events published after this point.
        reader.last_consumed = reader.writerSeq();

        log.info("inputfs ring opened, starting from seq {}", .{reader.last_consumed});

        return .{
            .reader = reader,
            .last_button_state = 0,
            .last_modifiers = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        self.reader.deinit();
    }

    /// Drain all newly published events from the inputfs ring and
    /// dispatch them into the provided KeyEvent and MouseEvent
    /// stash buffers. Caller is responsible for resetting the
    /// stash buffers after consumption (matches the existing
    /// drawfs backend convention; see getKeyEventsImpl).
    ///
    /// Returns the count of events drained from the ring (not the
    /// count appended to the buffers; some inputfs events do not
    /// produce backend events, e.g. MOTION with dx==0 dy==0).
    pub fn drain(
        self: *Self,
        keys: []backend.KeyEvent,
        keys_len: *usize,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) usize {
        var batch: [DRAIN_BATCH]input.Event = undefined;
        const result = self.reader.drain(&batch) catch |err| switch (err) {
            error.NotOpen => return 0,
        };

        if (result.overrun) {
            log.warn("inputfs ring overrun; some events lost", .{});
            // last_consumed has been repositioned by the reader;
            // continue with the new batch.
        }

        const events = batch[0..result.events_consumed];
        for (events) |ev| {
            self.dispatch(ev, keys, keys_len, mice, mice_len);
        }
        return result.events_consumed;
    }

    fn dispatch(
        self: *Self,
        ev: input.Event,
        keys: []backend.KeyEvent,
        keys_len: *usize,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) void {
        switch (ev.source_role) {
            input.SOURCE_KEYBOARD => self.dispatchKeyboard(ev, keys, keys_len),
            input.SOURCE_POINTER => self.dispatchPointer(ev, mice, mice_len),
            // Touch (3), pen (4), lighting (5), device-lifecycle (6):
            // not consumed by Phase 1. Touch and pen are deferred per
            // AD-1's Status block; the others are not relevant to
            // KeyEvent/MouseEvent forwarding.
            else => return,
        }
    }

    // ------------------------------------------------------------------------
    // Keyboard dispatch
    // ------------------------------------------------------------------------

    fn dispatchKeyboard(
        self: *Self,
        ev: input.Event,
        keys: []backend.KeyEvent,
        keys_len: *usize,
    ) void {
        // Payload (per INPUT_EVENTS.md §Keyboard, source_role=2):
        //   hid_usage(u32 0-3), positional(u32 4-7),
        //   modifiers(u32 8-11), session_id(u32 12-15)
        const hid_usage = std.mem.readInt(u32, ev.payload[0..4], .little);
        const modifiers = @as(u8, @truncate(std.mem.readInt(u32, ev.payload[8..12], .little)));
        // session_id at offset 12 dropped on the floor in Phase 1
        // (single-session model; whatever inputfs routes to is "us").

        const evdev_code = translate.hidUsageToEvdev(hid_usage);
        if (evdev_code == 0) {
            // Unmapped HID usage. Drop rather than forward as
            // key_code = 0; clients consume key_code as authoritative.
            return;
        }

        const pressed = switch (ev.event_type) {
            KEYBOARD_KEY_DOWN => true,
            KEYBOARD_KEY_UP => false,
            else => return, // unknown event_type per spec §Failure modes: skip
        };

        self.last_modifiers = modifiers;

        if (keys_len.* >= keys.len) return; // buffer full, drop
        keys[keys_len.*] = .{
            .key_code = evdev_code,
            .modifiers = modifiers,
            .pressed = pressed,
        };
        keys_len.* += 1;
    }

    // ------------------------------------------------------------------------
    // Pointer dispatch
    // ------------------------------------------------------------------------

    fn dispatchPointer(
        self: *Self,
        ev: input.Event,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) void {
        switch (ev.event_type) {
            POINTER_MOTION => self.dispatchPointerMotion(ev, mice, mice_len),
            POINTER_BUTTON_DOWN => self.dispatchPointerButton(ev, true, mice, mice_len),
            POINTER_BUTTON_UP => self.dispatchPointerButton(ev, false, mice, mice_len),
            POINTER_SCROLL => self.dispatchPointerScroll(ev, mice, mice_len),
            // 5/6 enter/leave: not consumed (see comment in dispatch()).
            else => return, // unknown event_type: skip per spec §Failure modes
        }
    }

    fn dispatchPointerMotion(
        self: *Self,
        ev: input.Event,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) void {
        // Payload: x(i32 0-3), y(i32 4-7), dx(i32 8-11), dy(i32 12-15),
        //          buttons(u32 16-19), session_id(u32 20-23)
        const x = std.mem.readInt(i32, ev.payload[0..4], .little);
        const y = std.mem.readInt(i32, ev.payload[4..8], .little);
        const dx = std.mem.readInt(i32, ev.payload[8..12], .little);
        const dy = std.mem.readInt(i32, ev.payload[12..16], .little);
        const buttons = std.mem.readInt(u32, ev.payload[16..20], .little);

        // Only emit a motion event if there was actual movement. inputfs
        // may publish motion events for button-state-only changes; those
        // are handled by the BUTTON_DOWN/BUTTON_UP path.
        if (dx != 0 or dy != 0) {
            if (mice_len.* >= mice.len) return;
            mice[mice_len.*] = .{
                .x = x,
                .y = y,
                .button = .left, // unused for motion events per backend.zig
                .event_type = .motion,
                .modifiers = self.last_modifiers,
            };
            mice_len.* += 1;
        }

        // Synthesise transitions if the buttons mask changed without a
        // separate BUTTON_DOWN/BUTTON_UP event arriving. Defensive: in
        // most flows inputfs will send explicit button events. Diffing
        // here costs little and prevents lost transitions if the wire
        // format ever embeds them in MOTION.
        const changed = buttons ^ self.last_button_state;
        if (changed != 0) {
            self.synthesiseButtonTransitions(x, y, buttons, changed, mice, mice_len);
        }
        self.last_button_state = buttons;
    }

    fn dispatchPointerButton(
        self: *Self,
        ev: input.Event,
        is_press: bool,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) void {
        // Payload: x(i32 0-3), y(i32 4-7), button(u32 8-11),
        //          buttons(u32 12-15), session_id(u32 16-19)
        const x = std.mem.readInt(i32, ev.payload[0..4], .little);
        const y = std.mem.readInt(i32, ev.payload[4..8], .little);
        const button_bit = std.mem.readInt(u32, ev.payload[8..12], .little);
        const buttons = std.mem.readInt(u32, ev.payload[12..16], .little);

        if (mice_len.* >= mice.len) return;
        const btn = mapButtonBit(button_bit) orelse {
            // Unknown button bit (e.g. side buttons on gaming mice).
            // Phase 1 forwards only left/middle/right; broader support
            // is a Phase 4 cleanup.
            self.last_button_state = buttons;
            return;
        };
        mice[mice_len.*] = .{
            .x = x,
            .y = y,
            .button = btn,
            .event_type = if (is_press) .press else .release,
            .modifiers = self.last_modifiers,
        };
        mice_len.* += 1;
        self.last_button_state = buttons;
    }

    fn dispatchPointerScroll(
        self: *Self,
        ev: input.Event,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) void {
        // Payload: x(i32 0-3), y(i32 4-7), scroll_dx(i32 8-11),
        //          scroll_dy(i32 12-15), delta_unit(u32 16-19),
        //          session_id(u32 20-23)
        // delta_unit dropped on the floor in Phase 1 (lines vs pixels);
        // backend's MouseEvent has no delta-unit concept.
        const scroll_dx = std.mem.readInt(i32, ev.payload[8..12], .little);
        const scroll_dy = std.mem.readInt(i32, ev.payload[12..16], .little);

        // Match the legacy stashEvtScroll convention: emit press+release
        // pairs of scroll_up/down/left/right MouseButton variants. The
        // MouseEvent schema has no scroll-delta field; magnitude becomes
        // event count if/when a future cut adds it.
        if (scroll_dy != 0) {
            self.pushScrollPair(if (scroll_dy > 0) .scroll_up else .scroll_down, mice, mice_len);
        }
        if (scroll_dx != 0) {
            self.pushScrollPair(if (scroll_dx > 0) .scroll_right else .scroll_left, mice, mice_len);
        }
    }

    fn pushScrollPair(
        self: *Self,
        btn: backend.MouseButton,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) void {
        if (mice_len.* + 2 > mice.len) return;
        mice[mice_len.*] = .{
            .x = 0, .y = 0,
            .button = btn,
            .event_type = .press,
            .modifiers = self.last_modifiers,
        };
        mice_len.* += 1;
        mice[mice_len.*] = .{
            .x = 0, .y = 0,
            .button = btn,
            .event_type = .release,
            .modifiers = self.last_modifiers,
        };
        mice_len.* += 1;
    }

    fn synthesiseButtonTransitions(
        self: *Self,
        x: i32,
        y: i32,
        buttons: u32,
        changed: u32,
        mice: []backend.MouseEvent,
        mice_len: *usize,
    ) void {
        const button_map = [_]struct { bit: u32, btn: backend.MouseButton }{
            .{ .bit = BUTTON_LEFT, .btn = .left },
            .{ .bit = BUTTON_RIGHT, .btn = .right },
            .{ .bit = BUTTON_MIDDLE, .btn = .middle },
        };
        for (button_map) |entry| {
            if (changed & entry.bit == 0) continue;
            if (mice_len.* >= mice.len) return;
            const is_press = (buttons & entry.bit) != 0;
            mice[mice_len.*] = .{
                .x = x,
                .y = y,
                .button = entry.btn,
                .event_type = if (is_press) .press else .release,
                .modifiers = self.last_modifiers,
            };
            mice_len.* += 1;
        }
    }
};

fn mapButtonBit(bit: u32) ?backend.MouseButton {
    return switch (bit) {
        BUTTON_LEFT => .left,
        BUTTON_RIGHT => .right,
        BUTTON_MIDDLE => .middle,
        else => null,
    };
}

// ============================================================================
// Tests
// ============================================================================

test "mapButtonBit recognises canonical buttons" {
    const testing = std.testing;
    try testing.expectEqual(@as(?backend.MouseButton, .left), mapButtonBit(BUTTON_LEFT));
    try testing.expectEqual(@as(?backend.MouseButton, .right), mapButtonBit(BUTTON_RIGHT));
    try testing.expectEqual(@as(?backend.MouseButton, .middle), mapButtonBit(BUTTON_MIDDLE));
    try testing.expectEqual(@as(?backend.MouseButton, null), mapButtonBit(0x10)); // side button
}
