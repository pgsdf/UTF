const std = @import("std");
const posix = std.posix;
const types = @import("types.zig");
const state_mod = @import("state.zig");
const policy_mod = @import("policy.zig");
const policy_state_mod = @import("policy_state.zig");
const surfaces = @import("surfaces.zig");
const oss = @import("oss_output.zig");

pub const Shared = struct {
    mutex: std.Thread.Mutex = .{},
    runtime_state: state_mod.RuntimeState,
    event_ctx: state_mod.EventContext = .{},
    next_client_id: u64 = 1,
    /// Monotonic count of PCM sample frames written to the audio device.
    /// Written atomically by the stream worker; read atomically by any thread.
    /// Never resets between streams — monotonically increasing for the lifetime
    /// of the daemon. This is the audio clock source for chronofs.
    samples_written: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),

    pub fn snapshot(self: *Shared) state_mod.RuntimeState {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.runtime_state;
    }
};

pub const WorkerArgs = struct {
    allocator: std.mem.Allocator,
    conn: posix.socket_t,
    audio_fd: posix.fd_t,
    shared: *Shared,
    client_id: []const u8,
    client_label: []const u8,
    client_class: []const u8,
    client_origin: []const u8,
    client_uid: ?u32,
    client_gid: ?u32,
    client_authenticated: bool,
};

pub fn spawn(args: WorkerArgs) !std.Thread {
    return try std.Thread.spawn(.{}, run, .{args});
}

fn spawnPendingOverrideIfAny(allocator: std.mem.Allocator, shared: *Shared, audio_fd: posix.fd_t) !void {
    shared.mutex.lock();
    const pending_conn = shared.runtime_state.pending_preempt_conn;
    const pending_client_id = shared.runtime_state.pending_preempt_client_id;
    const pending_client_label = shared.runtime_state.pending_preempt_client_label;
    const pending_client_class = shared.runtime_state.pending_preempt_client_class;
    const pending_client_origin = shared.runtime_state.pending_preempt_client_origin;
    const pending_uid = shared.runtime_state.pending_preempt_uid;
    const pending_gid = shared.runtime_state.pending_preempt_gid;
    const pending_authenticated = shared.runtime_state.pending_preempt_authenticated;

    if (pending_conn != null) {
        shared.runtime_state.pending_preempt_conn = null;
        shared.runtime_state.pending_preempt_client_id = null;
        shared.runtime_state.pending_preempt_client_label = null;
        shared.runtime_state.pending_preempt_client_class = null;
        shared.runtime_state.pending_preempt_client_origin = null;
        shared.runtime_state.pending_preempt_uid = null;
        shared.runtime_state.pending_preempt_gid = null;
        shared.runtime_state.pending_preempt_authenticated = false;
    }
    shared.mutex.unlock();

    if (pending_conn) |conn| {
        const thread = try spawn(.{
            .allocator = allocator,
            .conn = conn,
            .audio_fd = audio_fd,
            .shared = shared,
            .client_id = pending_client_id.?,
            .client_label = pending_client_label.?,
            .client_class = pending_client_class.?,
            .client_origin = pending_client_origin.?,
            .client_uid = pending_uid,
            .client_gid = pending_gid,
            .client_authenticated = pending_authenticated,
        });
        thread.detach();
    }
}

fn run(args: WorkerArgs) !void {
    defer posix.close(args.conn);

    // Parse the client's requested stream descriptor.
    var desc = try readHeader(args.conn);

    // Negotiate format, channels, and sample rate with the OSS device.
    // This updates desc with the actual values the hardware accepted.
    oss.negotiate(args.audio_fd, &desc) catch |err| {
        const msg = switch (err) {
            error.UnsupportedFormat      => "error: unsupported sample format\n",
            error.SampleRateMismatch     => "error: sample rate not supported by hardware\n",
            else                         => "error: OSS negotiation failed\n",
        };
        _ = posix.write(args.conn, msg) catch {};
        return err;
    };
    var stream_id: u64 = 0;

    {
        args.shared.mutex.lock();
        defer args.shared.mutex.unlock();

        args.shared.runtime_state.current_stream_id += 1;
        stream_id = args.shared.runtime_state.current_stream_id;
        args.shared.runtime_state.stream_active = true;
        args.shared.runtime_state.current_stream = desc;
        args.shared.runtime_state.stop_requested = false;
        args.shared.runtime_state.flush_requested = false;
        args.shared.runtime_state.preempt_requested = false;
        args.shared.runtime_state.active_client_id = args.client_id;
        args.shared.runtime_state.active_client_label = args.client_label;
        args.shared.runtime_state.active_client_class = args.client_class;
        args.shared.runtime_state.active_client_origin = args.client_origin;
        args.shared.runtime_state.active_uid = args.client_uid;
        args.shared.runtime_state.active_gid = args.client_gid;
        args.shared.runtime_state.active_authenticated = args.client_authenticated;
    }

    try persistBegin(args.allocator, args.shared, stream_id, desc);

    // Bytes per sample frame: channels × bytes_per_sample.
    const bytes_per_frame: u64 = @as(u64, desc.channels) * @as(u64, desc.format.bytesPerSample());

    var buf: [4096]u8 = undefined;
    var stopped_by_control = false;
    var flushed_by_control = false;
    var preempted = false;

    while (true) {
        {
            args.shared.mutex.lock();
            const stop_now = args.shared.runtime_state.stop_requested;
            const flush_now = args.shared.runtime_state.flush_requested;
            const preempt_now = args.shared.runtime_state.preempt_requested;
            args.shared.mutex.unlock();

            if (stop_now) { stopped_by_control = true; break; }
            if (flush_now) { flushed_by_control = true; break; }
            if (preempt_now) { preempted = true; break; }
        }

        const n = posix.read(args.conn, &buf) catch break;
        if (n == 0) break;
        _ = try posix.write(args.audio_fd, buf[0..n]);

        // Advance the monotonic sample counter. Integer division truncates any
        // partial frame, which is correct — we only count fully written frames.
        const frames: u64 = @as(u64, n) / bytes_per_frame;
        if (frames > 0) {
            _ = args.shared.samples_written.fetchAdd(frames, .monotonic);
        }
    }

    if (stopped_by_control) {
        args.shared.mutex.lock();
        const stop_state = args.shared.runtime_state;
        const meta = args.shared.event_ctx.allocEventMeta(args.shared.samples_written.load(.monotonic));
        args.shared.runtime_state.stop_requested = false;
        args.shared.mutex.unlock();
        try state_mod.appendStreamStopEvent(args.allocator, stop_state, meta, stream_id);
    }

    if (flushed_by_control) {
        args.shared.mutex.lock();
        const flush_state = args.shared.runtime_state;
        const meta = args.shared.event_ctx.allocEventMeta(args.shared.samples_written.load(.monotonic));
        args.shared.runtime_state.flush_requested = false;
        args.shared.mutex.unlock();
        try state_mod.appendStreamFlushEvent(args.allocator, flush_state, meta, stream_id);
    }

    if (preempted) {
        args.shared.mutex.lock();
        const meta = args.shared.event_ctx.allocEventMeta(args.shared.samples_written.load(.monotonic));
        const snap = args.shared.runtime_state;
        const old_stream_id = stream_id;
        const old_client_id = snap.active_client_id orelse "unknown";
        const old_client_label = snap.active_client_label orelse "unlabeled";
        const new_client_id = snap.pending_preempt_client_id orelse "unknown";
        const new_client_label = snap.pending_preempt_client_label orelse "unlabeled";
        const new_client_class = snap.pending_preempt_client_class orelse "unknown";
        const new_client_origin = snap.pending_preempt_client_origin orelse "unknown";
        args.shared.runtime_state.preempt_requested = false;
        args.shared.mutex.unlock();

        try state_mod.appendStreamPreemptEvent(args.allocator, snap, meta, old_stream_id, old_client_id, old_client_label, new_client_id, new_client_label, new_client_class, new_client_origin);
    }

    {
        args.shared.mutex.lock();
        args.shared.runtime_state.stream_active = false;
        args.shared.runtime_state.current_stream = null;
        args.shared.runtime_state.stop_requested = false;
        args.shared.runtime_state.flush_requested = false;
        args.shared.runtime_state.preempt_requested = false;
        args.shared.runtime_state.active_client_id = null;
        args.shared.runtime_state.active_client_label = null;
        args.shared.runtime_state.active_client_class = null;
        args.shared.runtime_state.active_client_origin = null;
        args.shared.runtime_state.active_uid = null;
        args.shared.runtime_state.active_gid = null;
        args.shared.runtime_state.active_authenticated = false;
        var end_state = args.shared.runtime_state;
        const meta = args.shared.event_ctx.allocEventMeta(args.shared.samples_written.load(.monotonic));
        args.shared.mutex.unlock();

        // Snapshot the final sample count and clear the active rate.
        end_state.samples_written = args.shared.samples_written.load(.monotonic);
        end_state.active_sample_rate = 0;

        try persistState(args.allocator, end_state);
        try state_mod.appendStreamEndEvent(args.allocator, end_state, meta, stream_id);
    }

    try spawnPendingOverrideIfAny(args.allocator, args.shared, args.audio_fd);
}

fn persistBegin(allocator: std.mem.Allocator, shared: *Shared, stream_id: u64, desc: types.StreamDescriptor) !void {
    shared.mutex.lock();
    var state = shared.runtime_state;
    const meta = shared.event_ctx.allocEventMeta(shared.samples_written.load(.monotonic));
    shared.mutex.unlock();
    // Snapshot the current sample counter and rate into the state copy.
    state.samples_written = shared.samples_written.load(.monotonic);
    state.active_sample_rate = desc.sample_rate;
    try persistState(allocator, state);
    try state_mod.appendStreamBeginEvent(allocator, state, meta, stream_id, desc);
}

fn persistState(allocator: std.mem.Allocator, state: state_mod.RuntimeState) !void {
    try state.writeJsonFile(allocator);
    try state_mod.writeDeviceFile(allocator, state);
    try state_mod.writeCurrentStreamFile(allocator, state);
}

fn readHeader(conn: posix.socket_t) !types.StreamDescriptor {
    var header_buf: [1024]u8 = undefined;
    var used: usize = 0;

    while (used < header_buf.len) {
        const n = try posix.read(conn, header_buf[used .. used + 1]);
        if (n == 0) return error.UnexpectedEof;
        if (header_buf[used] == '\n') return try parseHeader(header_buf[0..used]);
        used += 1;
    }
    return error.HeaderTooLarge;
}

fn parseHeader(line: []const u8) !types.StreamDescriptor {
    if (std.mem.indexOf(u8, line, "\"type\":\"pcm_stream_begin\"") == null and
        std.mem.indexOf(u8, line, "\"type\": \"pcm_stream_begin\"") == null)
    {
        return error.InvalidHeaderType;
    }

    const sample_rate_u64 = try parseUnsignedField(line, "sample_rate");
    const channels_u64 = try parseUnsignedField(line, "channels");
    const format = try parseFormatField(line, "sample_format");

    // Validate ranges before attempting OSS negotiation.
    if (sample_rate_u64 < 8_000 or sample_rate_u64 > 384_000)
        return error.UnsupportedSampleRate;
    if (channels_u64 < 1 or channels_u64 > 2)
        return error.UnsupportedChannelCount;

    return .{
        .sample_rate = @intCast(sample_rate_u64),
        .channels = @intCast(channels_u64),
        .format = format,
    };
}

fn parseUnsignedField(line: []const u8, key: []const u8) !u64 {
    var pattern_buf: [64]u8 = undefined;
    const pattern = try std.fmt.bufPrint(&pattern_buf, "\"{s}\":", .{key});
    const idx = std.mem.indexOf(u8, line, pattern) orelse return error.MissingField;
    var i = idx + pattern.len;
    while (i < line.len and line[i] == ' ') : (i += 1) {}
    var end = i;
    while (end < line.len and std.ascii.isDigit(line[end])) : (end += 1) {}
    if (end == i) return error.InvalidNumber;
    return try std.fmt.parseInt(u64, line[i..end], 10);
}

fn parseFormatField(line: []const u8, key: []const u8) !types.StreamFormat {
    var pattern_buf: [64]u8 = undefined;
    const pattern = try std.fmt.bufPrint(&pattern_buf, "\"{s}\":", .{key});
    const idx = std.mem.indexOf(u8, line, pattern) orelse return error.MissingField;
    var i = idx + pattern.len;
    while (i < line.len and line[i] == ' ') : (i += 1) {}
    if (i >= line.len or line[i] != '"') return error.InvalidFormat;
    i += 1;
    const end = std.mem.indexOfScalarPos(u8, line, i, '"') orelse return error.InvalidFormat;
    const value = line[i..end];
    if (std.mem.eql(u8, value, "s16le")) return .s16le;
    if (std.mem.eql(u8, value, "s32le")) return .s32le;
    return error.UnsupportedFormat;
}
