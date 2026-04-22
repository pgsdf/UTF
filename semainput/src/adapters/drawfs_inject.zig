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
        // surface_id=1 is the first surface any session (including semadrawd's)
        // creates, and DRAWFSGIOC_INJECT_INPUT in the kernel looks up the target
        // session from a global surface registry — our own session's surfaces
        // are irrelevant, so no stats-query gate is needed. If the surface
        // doesn't exist yet, INJECT_INPUT returns ENOENT and the call is a
        // no-op until semadraw-term creates it.
        // TODO: replace with focus-tracking once semadrawd publishes focused_surface_id.
        std.debug.print("drawfs_inject: opened {s}, targeting surface_id=1\n", .{DRAWFS_DEV});
        return .{ .fd = fd, .surface_id = 1 };
    }

    pub fn deinit(self: *DrawfsInjector) void {
        posix.close(self.fd);
    }

    /// Query DRAWFSGIOC_STATS to find a live surface to inject into.
    /// Returns true if a surface was found.
    ///
    /// Currently unused — `init()` hardcodes surface_id=1 and the kernel
    /// validates existence via its global registry on each INJECT_INPUT.
    /// Retained as scaffolding for focus-tracking: the correct future
    /// behaviour is to read focused_surface_id from a surface published by
    /// semadrawd, not to query our own session's stats (which will always
    /// show surfaces_count=0 because the injector session doesn't create
    /// surfaces).
    fn refreshSurface(self: *DrawfsInjector) bool {
        var stats = std.mem.zeroes(DrawfsStats);
        const r = ioctl(@intCast(self.fd), DRAWFSGIOC_STATS, @intFromPtr(&stats));
        if (r != 0) return false;
        if (stats.surfaces_count == 0) {
            self.surface_id = 0;
            return false;
        }
        if (self.surface_id == 0) {
            self.surface_id = 1;
            std.debug.print("drawfs_inject: targeting surface_id=1\n", .{});
        }
        return true;
    }

    pub fn injectKey(self: *DrawfsInjector, code: u16, state: u32, mods: u8) void {
        // If a prior call cleared surface_id after an error, restore it. The
        // kernel rejects injection for surfaces that don't exist yet (ENOENT)
        // and for sessions whose queue is full (ENOSPC); neither is fatal,
        // so we keep trying with surface_id=1.
        if (self.surface_id == 0) self.surface_id = 1;

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
            // ENOENT if the surface doesn't exist yet (semadraw-term hasn't
            // started or just crashed); ENOSPC if its event queue is full.
            // Either way we log once and continue — the next keypress retries.
            const errno: c_int = std.c._errno().*;
            std.debug.print("drawfs_inject: INJECT_INPUT errno={d} (code={d} state={d})\n",
                .{ errno, code, state });
        }
    }
};
