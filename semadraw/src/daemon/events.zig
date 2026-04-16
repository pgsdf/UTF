const std = @import("std");
const session_mod = @import("session");

// ============================================================================
// Event emitter — unified schema stdout emission for semadraw
//
// All events follow shared/EVENT_SCHEMA.md:
//   {"type":"...","subsystem":"semadraw","session":"...","seq":N,
//    "ts_wall_ns":N,"ts_audio_samples":null,...event fields...}
//
// ts_audio_samples is always null in D-1. I-3 / C-4 will wire the clock.
// ============================================================================

/// Cached session token (16-char lowercase hex). Initialised once at startup.
var session_hex: [16]u8 = [_]u8{'0'} ** 16;

/// Per-daemon monotonic event sequence counter.
var seq: std.atomic.Value(u64) = std.atomic.Value(u64).init(1);

/// Initialise the session token from the shared session file.
/// Call once at daemon startup before any events are emitted.
pub fn initSession() void {
    const token = session_mod.readOrCreate(session_mod.DEFAULT_SESSION_PATH) catch 0;
    _ = session_mod.format(token, &session_hex);
}

// ============================================================================
// Internal helpers
// ============================================================================

fn nextSeq() u64 {
    return seq.fetchAdd(1, .monotonic);
}

/// Write a complete unified-schema JSON line to stdout.
/// `event_type`  — the schema type string, e.g. "client_connected"
/// `fields_json` — event-specific JSON fragment starting with a comma,
///                 e.g. `,"client_id":1,"surface_id":2`
///                 Pass empty slice for lifecycle events with no extra fields.
fn emit(event_type: []const u8, fields_json: []const u8) void {
    const ts: i64 = @intCast(std.time.nanoTimestamp());
    const s = nextSeq();

    var line_buf: [2048]u8 = undefined;
    var stream = std.io.fixedBufferStream(&line_buf);
    const w = stream.writer();

    w.writeAll("{\"type\":\"") catch return;
    w.writeAll(event_type) catch return;
    w.writeAll("\",\"subsystem\":\"semadraw\",\"session\":\"") catch return;
    w.writeAll(&session_hex) catch return;
    w.writeByte('"') catch return;

    var tmp: [64]u8 = undefined;
    const seqts = std.fmt.bufPrint(&tmp,
        ",\"seq\":{d},\"ts_wall_ns\":{d},\"ts_audio_samples\":null",
        .{ s, ts }) catch return;
    w.writeAll(seqts) catch return;
    w.writeAll(fields_json) catch return;
    w.writeAll("}\n") catch return;

    var file = std.fs.File.stdout();
    var out_buf: [2048]u8 = undefined;
    var out = file.writer(&out_buf);
    out.interface.writeAll(stream.getWritten()) catch return;
    out.interface.flush() catch return;
}

// ============================================================================
// Typed event emitters
// ============================================================================

/// Emitted when a client completes the HELLO handshake.
pub fn emitClientConnected(client_id: u64, version_major: u16, version_minor: u16) void {
    var buf: [64]u8 = undefined;
    const fields = std.fmt.bufPrint(&buf,
        ",\"client_id\":{d},\"client_version_major\":{d},\"client_version_minor\":{d}",
        .{ client_id, version_major, version_minor }) catch return;
    emit("client_connected", fields);
}

/// Emitted when a client session ends (disconnect or error).
pub fn emitClientDisconnected(client_id: u64, reason: []const u8) void {
    var buf: [128]u8 = undefined;
    const fields = std.fmt.bufPrint(&buf,
        ",\"client_id\":{d},\"reason\":\"{s}\"",
        .{ client_id, reason }) catch return;
    emit("client_disconnected", fields);
}

/// Emitted when a surface is created.
pub fn emitSurfaceCreated(client_id: u64, surface_id: u32, width: f32, height: f32) void {
    var buf: [96]u8 = undefined;
    const fields = std.fmt.bufPrint(&buf,
        ",\"client_id\":{d},\"surface_id\":{d},\"width\":{d:.0},\"height\":{d:.0}",
        .{ client_id, surface_id, width, height }) catch return;
    emit("surface_created", fields);
}

/// Emitted when a surface is destroyed.
pub fn emitSurfaceDestroyed(client_id: u64, surface_id: u32) void {
    var buf: [64]u8 = undefined;
    const fields = std.fmt.bufPrint(&buf,
        ",\"client_id\":{d},\"surface_id\":{d}",
        .{ client_id, surface_id }) catch return;
    emit("surface_destroyed", fields);
}

/// Emitted once per rendered frame (on COMMIT reply).
pub fn emitFrameComplete(surface_id: u32, frame_number: u64, backend_name: []const u8) void {
    var buf: [128]u8 = undefined;
    const fields = std.fmt.bufPrint(&buf,
        ",\"surface_id\":{d},\"frame_number\":{d},\"backend\":\"{s}\"",
        .{ surface_id, frame_number, backend_name }) catch return;
    emit("frame_complete", fields);
}
