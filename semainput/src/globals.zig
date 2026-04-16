const std = @import("std");
const session = @import("session");
const clock   = @import("shared_clock");

/// Cached session token rendered as a 16-char lowercase hex string.
/// Initialized once at daemon startup by initGlobals().
pub var session_hex: [16]u8 = [_]u8{'0'} ** 16;

/// Per-daemon monotonic event sequence counter.
/// Atomically incremented by every emission site.
pub var seq: std.atomic.Value(u64) = std.atomic.Value(u64).init(1);

/// Audio clock reader. Null if the clock file could not be opened at startup.
/// Non-fatal: semainput runs without audio timestamps when semaaud is absent.
var clock_reader: ?clock.ClockReader = null;

/// Read (or create) the session token and open the audio clock reader.
/// Call once at daemon startup before any events are emitted.
pub fn initGlobals() void {
    // Session token.
    const token = session.readOrCreate(session.DEFAULT_SESSION_PATH) catch |err| blk: {
        std.debug.print(
            "semainput: warning: could not read session token: {}\n",
            .{err},
        );
        break :blk 0;
    };
    _ = session.format(token, &session_hex);

    // Audio clock — non-fatal if semaaud is not running.
    clock_reader = clock.ClockReader.init(clock.CLOCK_PATH);
}

/// Atomically increment the sequence counter and return the previous value.
pub fn nextSeq() u64 {
    return seq.fetchAdd(1, .monotonic);
}

/// Read the current audio sample position.
/// Returns null if the clock is absent or no audio stream has started yet.
pub fn readAudioSamples() ?u64 {
    const r = clock_reader orelse return null;
    if (!r.isValid()) return null;
    return r.read();
}

/// Render the current audio sample position as a JSON value string.
/// Returns either a decimal digit string or "null".
/// The returned slice points into a function-local static buffer — valid
/// only until the next call to audioSamplesJson().
pub fn audioSamplesJson() []const u8 {
    const samples = readAudioSamples() orelse return "null";
    // Static buffer: u64 max is 20 digits.
    const S = struct {
        var buf: [24]u8 = undefined;
    };
    return std.fmt.bufPrint(&S.buf, "{d}", .{samples}) catch "null";
}
