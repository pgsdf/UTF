const std = @import("std");
const session = @import("session");

/// Cached session token rendered as a 16-char lowercase hex string.
/// Initialized once at daemon startup by initGlobals().
pub var session_hex: [16]u8 = [_]u8{'0'} ** 16;

/// Per-daemon monotonic event sequence counter.
/// Atomically incremented by every emission site.
pub var seq: std.atomic.Value(u64) = std.atomic.Value(u64).init(1);

/// Read (or create) the session token and cache it in session_hex.
/// Call once at daemon startup before any events are emitted.
pub fn initGlobals() void {
    const token = session.readOrCreate(session.DEFAULT_SESSION_PATH) catch |err| blk: {
        // Non-fatal: log to stderr and use a fallback zero token.
        std.debug.print(
            "semainput: warning: could not read session token: {}\n",
            .{err},
        );
        break :blk 0;
    };
    _ = session.format(token, &session_hex);
}

/// Atomically increment the sequence counter and return the previous value.
pub fn nextSeq() u64 {
    return seq.fetchAdd(1, .monotonic);
}
