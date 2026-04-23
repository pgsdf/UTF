//! drawfs_inject.zig — injects semainput key/pointer events into the drawfs
//! kernel module via DRAWFSGIOC_INJECT_INPUT.
//!
//! This is the correct integration path between semainput and semadrawd:
//! semainput owns input policy and event classification; drawfs owns the
//! transport; semadrawd delivers events to clients.
//!
//! The adapter opens /dev/draw, queries the active surface via
//! DRAWFSGIOC_STATS to find a valid surface_id, then injects events.
//! If no surface exists yet it silently drops events until one appears.

const std = @import("std");
const posix = std.posix;

// ============================================================================
// FreeBSD ioctl constants
// ============================================================================

// _IOWR('D', 0x03, struct drawfs_inject_input)
// = _IOC(IOC_INOUT, 'D', 0x03, sizeof(drawfs_inject_input))
// IOC_INOUT = 0xC0000000, sizeof = 40, 'D'=0x44, 0x03
// = 0xC0000000 | (40 << 16) | (0x44 << 8) | 0x03
// = 0xC0000000 | 0x00280000 | 0x00004400 | 0x00000003
// = 0xC0284403
const DRAWFSGIOC_INJECT_INPUT: c_ulong = 0xC0284403;

// _IOR('D', 0x01, struct drawfs_stats)
// sizeof(drawfs_stats) = 88 bytes
// = _IOC(IOC_OUT=0x40000000, 'D', 0x01, 88)
// = 0x40000000 | (88 << 16) | (0x44 << 8) | 0x01
// = 0x40000000 | 0x00580000 | 0x00004400 | 0x00000001
// = 0x40584401
const DRAWFSGIOC_STATS: c_ulong = 0x40604401;

// Event types from drawfs_proto.h
const DRAWFS_EVT_KEY:     u16 = 0x9010;
const DRAWFS_EVT_POINTER: u16 = 0x9011;
const DRAWFS_EVT_SCROLL:  u16 = 0x9012;

const DRAWFS_INPUT_PAYLOAD_MAX: usize = 32;

const DrawfsInjectInput = extern struct {
    surface_id: u32,
    event_type:  u16,
    _pad:        u16 = 0,
    payload:     [DRAWFS_INPUT_PAYLOAD_MAX]u8,
};

// drawfs_evt_key payload (fits within DRAWFS_INPUT_PAYLOAD_MAX = 32 bytes)
const DrawfsEvtKey = extern struct {
    surface_id: u32,
    code:       u32,
    state:      u32,   // 1=down, 0=up
    mods:       u32,
    ts_wall_ns: i64,
};

// drawfs_evt_pointer payload (32 bytes, exactly fills DRAWFS_INPUT_PAYLOAD_MAX).
//
// Mirrors `struct drawfs_evt_pointer` in drawfs_proto.h. The kernel struct
// is __packed but every field is naturally aligned, so the Zig extern
// struct layout matches without packing tricks.
//
// x, y carry the cumulative cursor position; dx, dy carry the delta for
// this event. For mouse_move events, both are populated. For mouse_button
// events, dx/dy are zero (no motion in this event) and x/y reflect the
// current cursor position. The buttons bitmask reflects the *current
// state* of all buttons after this event (not just the one that
// changed): bit 0 = left, bit 1 = right, bit 2 = middle.
const DrawfsEvtPointer = extern struct {
    surface_id: u32,
    x:          i32,
    y:          i32,
    dx:         i32,
    dy:         i32,
    buttons:    u32,
    ts_wall_ns: i64,
};

// drawfs_evt_scroll payload (20 bytes).
const DrawfsEvtScroll = extern struct {
    surface_id: u32,
    dx:         i32,
    dy:         i32,
    ts_wall_ns: i64,
};

// drawfs_stats — just enough to get evq_depth (we use it to check liveness)
// Full struct is 88 bytes but we only need the first few fields.
// We read the full struct to satisfy the ioctl size check.
const DrawfsStats = extern struct {
    frames_received:      u64,
    frames_processed:     u64,
    frames_invalid:       u64,
    messages_processed:   u64,
    messages_unsupported: u64,
    events_enqueued:      u64,
    events_dropped:       u64,
    bytes_in:             u64,
    bytes_out:            u64,
    evq_depth:            u32,
    inbuf_bytes:          u32,
    evq_bytes:            u32,
    surfaces_count:       u32,
    surfaces_bytes:       u64,
};

extern "c" fn ioctl(fd: c_int, request: c_ulong, ...) c_int;

// ============================================================================
// DrawfsInjector
// ============================================================================

pub const DrawfsInjector = struct {
    fd:         posix.fd_t,
    surface_id: u32,

    const DRAWFS_DEV = "/dev/draw";

    pub fn init() !DrawfsInjector {
        const fd = posix.open(DRAWFS_DEV, .{ .ACCMODE = .RDWR }, 0) catch |err| {
            std.debug.print("drawfs_inject: failed to open {s}: {s}\n",
                .{ DRAWFS_DEV, @errorName(err) });
            return err;
        };
        std.debug.print("drawfs_inject: opened {s}\n", .{DRAWFS_DEV});
        return .{ .fd = fd, .surface_id = 0 };
    }

    pub fn deinit(self: *DrawfsInjector) void {
        posix.close(self.fd);
    }

    /// Set the target surface for injection.
    ///
    /// Hardcoded to surface_id=1 because semadraw-term always creates
    /// exactly one surface with that id in semadrawd's session, and the
    /// kernel routes injected events to whichever session owns the named
    /// surface. The STATS ioctl is intentionally NOT consulted here:
    /// STATS reports counts for *this* session's surfaces, not the
    /// kernel-wide registry, and the injector's own session has zero
    /// surfaces (it never creates any). Calling STATS and gating on its
    /// surfaces_count value caused every injection to abort with
    /// surfaces_count=0, even though semadrawd's session held the
    /// real surface 1 perfectly fine.
    ///
    /// When focus tracking lands, this becomes "look up the focused
    /// surface id from /var/run/sema/focus" or similar, replacing the
    /// hardcode without changing the call shape.
    fn refreshSurface(self: *DrawfsInjector) bool {
        if (self.surface_id == 0) {
            self.surface_id = 1;
            std.debug.print("drawfs_inject: targeting surface_id=1\n", .{});
        }
        return true;
    }

    pub fn injectKey(self: *DrawfsInjector, code: u16, state: u32, mods: u8) void {
        if (self.surface_id == 0) {
            if (!self.refreshSurface()) return;
        }

        var key_payload = std.mem.zeroes(DrawfsEvtKey);
        key_payload.surface_id = self.surface_id;
        key_payload.code       = code;
        key_payload.state      = state;
        key_payload.mods       = mods;
        key_payload.ts_wall_ns = @intCast(std.time.nanoTimestamp());

        var req = std.mem.zeroes(DrawfsInjectInput);
        req.surface_id  = self.surface_id;
        req.event_type  = DRAWFS_EVT_KEY;
        const payload_bytes = std.mem.asBytes(&key_payload);
        const copy_len = @min(payload_bytes.len, DRAWFS_INPUT_PAYLOAD_MAX);
        @memcpy(req.payload[0..copy_len], payload_bytes[0..copy_len]);

        const r = ioctl(@intCast(self.fd), DRAWFSGIOC_INJECT_INPUT, @intFromPtr(&req));
        if (r != 0) {
            // Surface may have been destroyed — clear so we refresh next time.
            std.debug.print("drawfs_inject: INJECT_INPUT failed ({}), will refresh\n", .{r});
            self.surface_id = 0;
        }
    }

    /// Inject a pointer event carrying current cursor position, this-event
    /// motion delta, and the cumulative button state. Called for both
    /// mouse_move (where dx/dy carry the motion and buttons reflects
    /// existing state) and mouse_button (where dx/dy are 0 and buttons
    /// reflects the new state after the press or release).
    pub fn injectPointer(self: *DrawfsInjector, x: i32, y: i32, dx: i32, dy: i32, buttons: u32) void {
        std.debug.print("drawfs_inject: injectPointer ENTRY x={d} y={d} dx={d} dy={d} buttons=0x{x}\n", .{ x, y, dx, dy, buttons });
        if (self.surface_id == 0) {
            if (!self.refreshSurface()) {
                std.debug.print("drawfs_inject: injectPointer ABORT — refreshSurface returned false\n", .{});
                return;
            }
        }

        var ptr_payload = std.mem.zeroes(DrawfsEvtPointer);
        ptr_payload.surface_id = self.surface_id;
        ptr_payload.x          = x;
        ptr_payload.y          = y;
        ptr_payload.dx         = dx;
        ptr_payload.dy         = dy;
        ptr_payload.buttons    = buttons;
        ptr_payload.ts_wall_ns = @intCast(std.time.nanoTimestamp());

        var req = std.mem.zeroes(DrawfsInjectInput);
        req.surface_id = self.surface_id;
        req.event_type = DRAWFS_EVT_POINTER;
        const payload_bytes = std.mem.asBytes(&ptr_payload);
        const copy_len = @min(payload_bytes.len, DRAWFS_INPUT_PAYLOAD_MAX);
        @memcpy(req.payload[0..copy_len], payload_bytes[0..copy_len]);

        const r = ioctl(@intCast(self.fd), DRAWFSGIOC_INJECT_INPUT, @intFromPtr(&req));
        std.debug.print("drawfs_inject: injectPointer IOCTL returned {d} (surface_id={d})\n", .{ r, self.surface_id });
        if (r != 0) {
            std.debug.print("drawfs_inject: INJECT_INPUT (pointer) failed ({}), will refresh\n", .{r});
            self.surface_id = 0;
        }
    }

    /// Inject a scroll event carrying horizontal and vertical scroll deltas.
    pub fn injectScroll(self: *DrawfsInjector, dx: i32, dy: i32) void {
        if (self.surface_id == 0) {
            if (!self.refreshSurface()) return;
        }

        var scr_payload = std.mem.zeroes(DrawfsEvtScroll);
        scr_payload.surface_id = self.surface_id;
        scr_payload.dx         = dx;
        scr_payload.dy         = dy;
        scr_payload.ts_wall_ns = @intCast(std.time.nanoTimestamp());

        var req = std.mem.zeroes(DrawfsInjectInput);
        req.surface_id = self.surface_id;
        req.event_type = DRAWFS_EVT_SCROLL;
        const payload_bytes = std.mem.asBytes(&scr_payload);
        const copy_len = @min(payload_bytes.len, DRAWFS_INPUT_PAYLOAD_MAX);
        @memcpy(req.payload[0..copy_len], payload_bytes[0..copy_len]);

        const r = ioctl(@intCast(self.fd), DRAWFSGIOC_INJECT_INPUT, @intFromPtr(&req));
        if (r != 0) {
            std.debug.print("drawfs_inject: INJECT_INPUT (scroll) failed ({}), will refresh\n", .{r});
            self.surface_id = 0;
        }
    }
};
