const std = @import("std");
const posix = std.posix;
const c = @cImport({
    @cInclude("unistd.h");
});
const detect = @import("device_detect.zig");
const oss = @import("oss_output.zig");
const types = @import("types.zig");
const policy_mod = @import("policy.zig");
const policy_state_mod = @import("policy_state.zig");
const control_server = @import("control_server.zig");
const state_mod = @import("state.zig");
const stream_worker = @import("stream_worker.zig");
const surfaces = @import("surfaces.zig");
const shared_clock = @import("shared_clock");

fn resolveOtherShared(
    current_name: []const u8,
    default_shared: *stream_worker.Shared,
    alt_shared: *stream_worker.Shared,
) ?*stream_worker.Shared {
    if (std.mem.eql(u8, current_name, "default")) return alt_shared;
    if (std.mem.eql(u8, current_name, "alt")) return default_shared;
    return null;
}

fn resolveFallbackShared(
    target_name: []const u8,
    default_shared: *stream_worker.Shared,
    alt_shared: *stream_worker.Shared,
) ?*stream_worker.Shared {
    if (std.mem.eql(u8, target_name, "default")) return default_shared;
    if (std.mem.eql(u8, target_name, "alt")) return alt_shared;
    return null;
}

fn resolveFallbackAudioFd(
    target_name: []const u8,
    audio_default_fd: posix.fd_t,
    audio_alt_fd: posix.fd_t,
) ?posix.fd_t {
    if (std.mem.eql(u8, target_name, "default")) return audio_default_fd;
    if (std.mem.eql(u8, target_name, "alt")) return audio_alt_fd;
    return null;
}

fn initTarget(
    allocator: std.mem.Allocator,
    name: []const u8,
    stream_socket: []const u8,
    selection: types.DeviceSelection,
) !stream_worker.Shared {
    try state_mod.ensureTargetLayout(allocator, name);
    try state_mod.writeIdentityFile(allocator, name);
    try state_mod.writeVersionFile(allocator, name);
    try state_mod.writeBackendFile(allocator, name);
    try state_mod.writeDefaultPolicyFile(allocator, name);
    try state_mod.writeCapabilitiesFile(allocator, name);
    try state_mod.writeControlFile(allocator, name, stream_socket);
    try state_mod.writeControlCapabilitiesFile(allocator, name);

    const events_path = try surfaces.streamEventsPath(allocator, name);
    defer allocator.free(events_path);
    std.fs.cwd().deleteFile(events_path) catch {};

    var shared = stream_worker.Shared{
        .runtime_state = .{
            .target_name = try allocator.dupe(u8, name),
            .selection = selection,
        },
    };

    const policy_path = try surfaces.policyPath(allocator, name);
    const policy_state_path = try surfaces.policyStatePath(allocator, name);
    defer allocator.free(policy_path);
    defer allocator.free(policy_state_path);

    var loaded_policy = try policy_mod.loadPolicy(allocator, policy_path);
    defer loaded_policy.deinit(allocator);
    try state_mod.writePolicyValidationFiles(allocator, name, loaded_policy);

    try policy_state_mod.writePolicyState(
        allocator,
        policy_state_path,
        loaded_policy,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        false,
    );

    try shared.runtime_state.writeJsonFile(allocator);
    try state_mod.writeDeviceFile(allocator, shared.runtime_state);
    try state_mod.writeCurrentStreamFile(allocator, shared.runtime_state);
    return shared;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const selection = try detect.detectDefaultPcm(allocator);
    const alt_selection: types.DeviceSelection = .{
        .default_pcm = try allocator.dupe(u8, selection.default_pcm),
        .audiodev = try allocator.dupe(u8, selection.audiodev),
        .mixerdev = try allocator.dupe(u8, selection.mixerdev),
    };

    var audio_default = try oss.OssOutput.open(selection.audiodev);
    defer audio_default.close();
    var audio_alt = try oss.OssOutput.open(alt_selection.audiodev);
    defer audio_alt.close();

    var default_shared = try initTarget(
        allocator,
        "default",
        "/tmp/semaud-default.sock",
        selection,
    );
    var alt_shared = try initTarget(
        allocator,
        "alt",
        "/tmp/semaud-alt.sock",
        alt_selection,
    );

    // Initialise session token for event log emission.
    default_shared.event_ctx.initSession();
    alt_shared.event_ctx.initSession();

    // Clock publication. semaaud is the sole writer of /var/run/sema/clock;
    // all other UTF daemons consume it via ClockReader. We designate the
    // "default" target as the clock-owning target: its stream worker is
    // the one that calls streamBegin() on first stream and update() after
    // each PCM write. The "alt" target participates in audio routing but
    // not in clock publication — when alt is active and default is idle,
    // the clock region reports its last-known state. This is a known
    // limitation; revisit once dual-active playback becomes a real use
    // case (today it doesn't).
    //
    // Opening the clock writer is fatal if it fails: semaaud's role in
    // UTF is precisely to publish this region, so a failure here is a
    // startup failure, not a warning.
    var clock_writer = try shared_clock.ClockWriter.init(shared_clock.CLOCK_PATH);
    defer clock_writer.deinit();
    default_shared.clock_writer = &clock_writer;
    std.debug.print("clock region published at {s}\n", .{shared_clock.CLOCK_PATH});

    var ctl_server = try control_server.ControlServer.init(.{
        .socket_path = state_mod.CONTROL_SOCKET_PATH,
    });
    defer ctl_server.deinit();

    const stream_socket_paths = [_][]const u8{
        "/tmp/semaud-default.sock",
        "/tmp/semaud-alt.sock",
    };
    var stream_fds: [2]posix.socket_t = undefined;

    for (stream_socket_paths, 0..) |sock_path, i| {
        const fd = try posix.socket(posix.AF.UNIX, posix.SOCK.STREAM, 0);
        stream_fds[i] = fd;
        std.fs.cwd().deleteFile(sock_path) catch {};

        var addr: posix.sockaddr.un = .{
            .family = posix.AF.UNIX,
            .path = [_]u8{0} ** 104,
        };
        if (sock_path.len >= addr.path.len) return error.SocketPathTooLong;
        @memcpy(addr.path[0..sock_path.len], sock_path);

        try posix.bind(fd, @ptrCast(&addr), @sizeOf(posix.sockaddr.un));
        try posix.listen(fd, 16);
    }
    defer {
        for (stream_fds) |fd| posix.close(fd);
    }

    std.debug.print("default stream listening on /tmp/semaud-default.sock\n", .{});
    std.debug.print("alt stream listening on /tmp/semaud-alt.sock\n", .{});
    std.debug.print("control listening on /tmp/semaud-control.sock\n", .{});

    while (true) {
        var fds = [_]posix.pollfd{
            .{ .fd = ctl_server.fd, .events = posix.POLL.IN, .revents = 0 },
            .{ .fd = stream_fds[0], .events = posix.POLL.IN, .revents = 0 },
            .{ .fd = stream_fds[1], .events = posix.POLL.IN, .revents = 0 },
        };

        _ = try posix.poll(&fds, -1);

        if ((fds[0].revents & posix.POLL.IN) != 0) {
            var targets = [_]control_server.TargetView{
                .{
                    .shared = @ptrCast(&default_shared),
                    .runtime = &default_shared.runtime_state,
                    .event_ctx = &default_shared.event_ctx,
                },
                .{
                    .shared = @ptrCast(&alt_shared),
                    .runtime = &alt_shared.runtime_state,
                    .event_ctx = &alt_shared.event_ctx,
                },
            };
            try ctl_server.serveOneAcceptedControl(allocator, targets[0..]);
        }

        var idx: usize = 0;
        while (idx < 2) : (idx += 1) {
            if ((fds[idx + 1].revents & posix.POLL.IN) == 0) continue;

            const shared = if (idx == 0) &default_shared else &alt_shared;
            const audio_fd = if (idx == 0) audio_default.fd else audio_alt.fd;

            shared.mutex.lock();
            const busy = shared.runtime_state.stream_active;
            const reject_state = shared.runtime_state;
            const reject_meta = shared.event_ctx.allocEventMeta(null);
            const client_num = shared.next_client_id;
            shared.next_client_id += 1;
            shared.mutex.unlock();

            const client_id = try std.fmt.allocPrint(allocator, "cli-{}", .{client_num});
            const client_label = try std.fmt.allocPrint(allocator, "stream-client-{}", .{client_num});
            const client_class = if ((client_num % 2) == 0)
                try allocator.dupe(u8, "admin")
            else
                try allocator.dupe(u8, "interactive");
            const client_origin = try allocator.dupe(u8, "local");
            const client_uid: u32 = @intCast(c.getuid());
            const client_gid: u32 = @intCast(c.getgid());
            const client_authenticated = true;

            const policy_path = try surfaces.policyPath(allocator, shared.runtime_state.target_name);
            const policy_state_path = try surfaces.policyStatePath(allocator, shared.runtime_state.target_name);
            defer allocator.free(policy_path);
            defer allocator.free(policy_state_path);

            var loaded_policy = try policy_mod.loadPolicy(allocator, policy_path);
            defer loaded_policy.deinit(allocator);
            try state_mod.writePolicyValidationFiles(allocator, shared.runtime_state.target_name, loaded_policy);

            if (loaded_policy.group_name) |group_name| {
                const other_shared = resolveOtherShared(
                    shared.runtime_state.target_name,
                    &default_shared,
                    &alt_shared,
                );
                if (other_shared != null) {
                    const other_policy_path = try surfaces.policyPath(
                        allocator,
                        other_shared.?.runtime_state.target_name,
                    );
                    defer allocator.free(other_policy_path);

                    var other_loaded_policy = try policy_mod.loadPolicy(allocator, other_policy_path);
                    defer other_loaded_policy.deinit(allocator);
                    try state_mod.writePolicyValidationFiles(allocator, other_shared.?.runtime_state.target_name, other_loaded_policy);

                    if (other_loaded_policy.group_name) |other_group_name| {
                        if (std.mem.eql(u8, group_name, other_group_name)) {
                            other_shared.?.mutex.lock();
                            const other_active = other_shared.?.runtime_state.stream_active;
                            const blocking_target_name = other_shared.?.runtime_state.target_name;
                            other_shared.?.mutex.unlock();

                            if (other_active) {
                                if (policy_mod.hasOverride(loaded_policy, client_class)) {
                                    const conn = try posix.accept(stream_fds[idx], null, null, 0);

                                    other_shared.?.mutex.lock();
                                    other_shared.?.runtime_state.preempt_requested = true;
                                    other_shared.?.runtime_state.pending_preempt_client_id = client_id;
                                    other_shared.?.runtime_state.pending_preempt_client_label = client_label;
                                    other_shared.?.runtime_state.pending_preempt_client_class = client_class;
                                    other_shared.?.runtime_state.pending_preempt_client_origin = client_origin;
                                    other_shared.?.runtime_state.pending_preempt_uid = client_uid;
                                    other_shared.?.runtime_state.pending_preempt_gid = client_gid;
                                    other_shared.?.runtime_state.pending_preempt_authenticated = client_authenticated;
                                    other_shared.?.mutex.unlock();

                                    const group_route = try std.fmt.allocPrint(
                                        allocator,
                                        "preempted:{s}",
                                        .{blocking_target_name},
                                    );
                                    defer allocator.free(group_route);

                                    try policy_state_mod.writePolicyState(
                                        allocator,
                                        policy_state_path,
                                        loaded_policy,
                                        client_id,
                                        client_label,
                                        client_class,
                                        client_origin,
                                        .override,
                                        null,
                                        group_route,
                                        client_uid,
                                        client_gid,
                                        client_authenticated,
                                    );

                                    const group_meta = shared.event_ctx.allocEventMeta(null);
                                    try state_mod.appendStreamGroupPreemptEvent(
                                        allocator,
                                        shared.runtime_state.target_name,
                                        group_name,
                                        blocking_target_name,
                                        group_meta,
                                        client_id,
                                        client_label,
                                        client_class,
                                        client_origin,
                                        client_uid,
                                        client_gid,
                                        client_authenticated,
                                        "group_override",
                                    );

                                    var tries: usize = 0;
                                    while (tries < 200) : (tries += 1) {
                                        other_shared.?.mutex.lock();
                                        const still_active = other_shared.?.runtime_state.stream_active;
                                        other_shared.?.mutex.unlock();
                                        if (!still_active) break;
                                        std.Thread.sleep(10 * std.time.ns_per_ms);
                                    }

                                    other_shared.?.mutex.lock();
                                    const still_active = other_shared.?.runtime_state.stream_active;
                                    other_shared.?.mutex.unlock();

                                    if (still_active) {
                                        defer posix.close(conn);
                                        _ = try posix.write(conn, "error: group override timeout\n");

                                        const reject_group_meta = shared.event_ctx.allocEventMeta(null);
                                        try state_mod.appendStreamRejectEvent(
                                            allocator,
                                            reject_state,
                                            reject_group_meta,
                                            client_id,
                                            client_label,
                                            client_class,
                                            client_origin,
                                            client_uid,
                                            client_gid,
                                            client_authenticated,
                                            "group_override_timeout",
                                        );
                                        continue;
                                    }

                                    const thread = try stream_worker.spawn(.{
                                        .allocator = allocator,
                                        .conn = conn,
                                        .audio_fd = audio_fd,
                                        .shared = shared,
                                        .client_id = client_id,
                                        .client_label = client_label,
                                        .client_class = client_class,
                                        .client_origin = client_origin,
                                        .client_uid = client_uid,
                                        .client_gid = client_gid,
                                        .client_authenticated = client_authenticated,
                                    });
                                    thread.detach();
                                    continue;
                                }

                                const conn = try posix.accept(stream_fds[idx], null, null, 0);
                                defer posix.close(conn);
                                _ = try posix.write(conn, "error: target group busy\n");

                                const group_route = try std.fmt.allocPrint(
                                    allocator,
                                    "blocked_by:{s}",
                                    .{blocking_target_name},
                                );
                                defer allocator.free(group_route);

                                try policy_state_mod.writePolicyState(
                                    allocator,
                                    policy_state_path,
                                    loaded_policy,
                                    client_id,
                                    client_label,
                                    client_class,
                                    client_origin,
                                    .deny,
                                    null,
                                    group_route,
                                    client_uid,
                                    client_gid,
                                    client_authenticated,
                                );

                                const group_meta = shared.event_ctx.allocEventMeta(null);
                                try state_mod.appendStreamGroupBlockEvent(
                                    allocator,
                                    shared.runtime_state.target_name,
                                    group_name,
                                    blocking_target_name,
                                    group_meta,
                                    client_id,
                                    client_label,
                                    client_class,
                                    client_origin,
                                    client_uid,
                                    client_gid,
                                    client_authenticated,
                                    "group_busy",
                                );

                                const reject_group_meta = shared.event_ctx.allocEventMeta(null);
                                try state_mod.appendStreamRejectEvent(
                                    allocator,
                                    reject_state,
                                    reject_group_meta,
                                    client_id,
                                    client_label,
                                    client_class,
                                    client_origin,
                                    client_uid,
                                    client_gid,
                                    client_authenticated,
                                    "group_busy",
                                );
                                continue;
                            }
                        }
                    }
                }
            }

            if (busy) {
                if (policy_mod.hasOverride(loaded_policy, client_class)) {
                    const conn = try posix.accept(stream_fds[idx], null, null, 0);

                    shared.mutex.lock();
                    shared.runtime_state.preempt_requested = true;
                    shared.runtime_state.pending_preempt_conn = conn;
                    shared.runtime_state.pending_preempt_client_id = client_id;
                    shared.runtime_state.pending_preempt_client_label = client_label;
                    shared.runtime_state.pending_preempt_client_class = client_class;
                    shared.runtime_state.pending_preempt_client_origin = client_origin;
                    shared.runtime_state.pending_preempt_uid = client_uid;
                    shared.runtime_state.pending_preempt_gid = client_gid;
                    shared.runtime_state.pending_preempt_authenticated = client_authenticated;
                    shared.mutex.unlock();

                    try policy_state_mod.writePolicyState(
                        allocator,
                        policy_state_path,
                        loaded_policy,
                        client_id,
                        client_label,
                        client_class,
                        client_origin,
                        .override,
                        null,
                        null,
                        client_uid,
                        client_gid,
                        client_authenticated,
                    );
                    continue;
                }

                const conn = try posix.accept(stream_fds[idx], null, null, 0);
                defer posix.close(conn);
                _ = try posix.write(conn, "error: stream already active\n");

                try policy_state_mod.writePolicyState(
                    allocator,
                    policy_state_path,
                    loaded_policy,
                    client_id,
                    client_label,
                    client_class,
                    client_origin,
                    .busy,
                    null,
                    null,
                    client_uid,
                    client_gid,
                    client_authenticated,
                );
                try state_mod.appendStreamRejectEvent(
                    allocator,
                    reject_state,
                    reject_meta,
                    client_id,
                    client_label,
                    client_class,
                    client_origin,
                    client_uid,
                    client_gid,
                    client_authenticated,
                    "busy",
                );
                continue;
            }

            const decision = policy_mod.evaluate(loaded_policy, client_label, client_class);
            if (decision == .deny) {
                const conn = try posix.accept(stream_fds[idx], null, null, 0);

                var route_buf: ?[]const u8 = null;
                if (loaded_policy.fallback_target) |fallback| {
                    const reroute_meta = shared.event_ctx.allocEventMeta(null);
                    try state_mod.appendStreamRerouteEvent(
                        allocator,
                        shared.runtime_state.target_name,
                        fallback,
                        reroute_meta,
                        client_id,
                        client_label,
                        client_class,
                        client_origin,
                        client_uid,
                        client_gid,
                        client_authenticated,
                        "deny",
                    );

                    const fallback_shared = resolveFallbackShared(
                        fallback,
                        &default_shared,
                        &alt_shared,
                    );
                    const fallback_audio_fd = resolveFallbackAudioFd(
                        fallback,
                        audio_default.fd,
                        audio_alt.fd,
                    );

                    if (fallback_shared != null and fallback_audio_fd != null) {
                        const fallback_policy_path = try surfaces.policyPath(allocator, fallback);
                        const fallback_policy_state_path = try surfaces.policyStatePath(allocator, fallback);
                        defer allocator.free(fallback_policy_path);
                        defer allocator.free(fallback_policy_state_path);

                        var fallback_loaded_policy = try policy_mod.loadPolicy(allocator, fallback_policy_path);
                        defer fallback_loaded_policy.deinit(allocator);
                        try state_mod.writePolicyValidationFiles(allocator, fallback, fallback_loaded_policy);

                        fallback_shared.?.mutex.lock();
                        const fallback_busy = fallback_shared.?.runtime_state.stream_active;
                        fallback_shared.?.mutex.unlock();

                        if (!fallback_busy) {
                            const fallback_decision = policy_mod.evaluate(
                                fallback_loaded_policy,
                                client_label,
                                client_class,
                            );
                            if (fallback_decision != .deny) {
                                route_buf = try std.fmt.allocPrint(allocator, "routed:{s}", .{fallback});

                                try policy_state_mod.writePolicyState(
                                    allocator,
                                    policy_state_path,
                                    loaded_policy,
                                    client_id,
                                    client_label,
                                    client_class,
                                    client_origin,
                                    .deny,
                                    route_buf,
                                    null,
                                    client_uid,
                                    client_gid,
                                    client_authenticated,
                                );

                                try policy_state_mod.writePolicyState(
                                    allocator,
                                    fallback_policy_state_path,
                                    fallback_loaded_policy,
                                    client_id,
                                    client_label,
                                    client_class,
                                    client_origin,
                                    .allow,
                                    null,
                                    null,
                                    client_uid,
                                    client_gid,
                                    client_authenticated,
                                );

                                const thread = try stream_worker.spawn(.{
                                    .allocator = allocator,
                                    .conn = conn,
                                    .audio_fd = fallback_audio_fd.?,
                                    .shared = fallback_shared.?,
                                    .client_id = client_id,
                                    .client_label = client_label,
                                    .client_class = client_class,
                                    .client_origin = client_origin,
                                    .client_uid = client_uid,
                                    .client_gid = client_gid,
                                    .client_authenticated = client_authenticated,
                                });
                                thread.detach();

                                if (route_buf) |r| allocator.free(r);
                                continue;
                            } else {
                                route_buf = try std.fmt.allocPrint(
                                    allocator,
                                    "reroute_failed:{s}:deny",
                                    .{fallback},
                                );
                            }
                        } else {
                            route_buf = try std.fmt.allocPrint(
                                allocator,
                                "reroute_failed:{s}:busy",
                                .{fallback},
                            );
                        }
                    } else {
                        route_buf = try std.fmt.allocPrint(
                            allocator,
                            "reroute_failed:{s}:unknown_target",
                            .{fallback},
                        );
                    }
                }

                defer posix.close(conn);
                _ = try posix.write(conn, "error: denied by policy\n");

                try policy_state_mod.writePolicyState(
                    allocator,
                    policy_state_path,
                    loaded_policy,
                    client_id,
                    client_label,
                    client_class,
                    client_origin,
                    .deny,
                    route_buf,
                    null,
                    client_uid,
                    client_gid,
                    client_authenticated,
                );

                const reject_event_meta = shared.event_ctx.allocEventMeta(null);
                try state_mod.appendStreamRejectEvent(
                    allocator,
                    reject_state,
                    reject_event_meta,
                    client_id,
                    client_label,
                    client_class,
                    client_origin,
                    client_uid,
                    client_gid,
                    client_authenticated,
                    "deny",
                );
                if (route_buf) |r| allocator.free(r);
                continue;
            }

            try policy_state_mod.writePolicyState(
                allocator,
                policy_state_path,
                loaded_policy,
                client_id,
                client_label,
                client_class,
                client_origin,
                .allow,
                null,
                null,
                client_uid,
                client_gid,
                client_authenticated,
            );

            const conn = try posix.accept(stream_fds[idx], null, null, 0);
            const thread = try stream_worker.spawn(.{
                .allocator = allocator,
                .conn = conn,
                .audio_fd = audio_fd,
                .shared = shared,
                .client_id = client_id,
                .client_label = client_label,
                .client_class = client_class,
                .client_origin = client_origin,
                .client_uid = client_uid,
                .client_gid = client_gid,
                .client_authenticated = client_authenticated,
            });
            thread.detach();
        }
    }
}
