const std = @import("std");
const types = @import("types.zig");
const surfaces = @import("surfaces.zig");

pub const CONTROL_SOCKET_PATH = "/tmp/semaud-control.sock";

pub const EventContext = struct {
    next_seq: u64 = 1,

    pub fn allocEventMeta(self: *EventContext) EventMeta {
        const meta = EventMeta{
            .seq = self.next_seq,
            .ts_mono_ns = std.time.nanoTimestamp(),
        };
        self.next_seq += 1;
        return meta;
    }
};

pub const EventMeta = struct {
    seq: u64,
    ts_mono_ns: i128,
};

pub const RuntimeState = struct {
    target_name: []const u8,
    selection: types.DeviceSelection,
    stream_active: bool = false,
    stop_requested: bool = false,
    flush_requested: bool = false,
    preempt_requested: bool = false,
    current_stream: ?types.StreamDescriptor = null,
    current_stream_id: u64 = 0,
    active_client_id: ?[]const u8 = null,
    active_client_label: ?[]const u8 = null,
    active_client_class: ?[]const u8 = null,
    active_client_origin: ?[]const u8 = null,
    active_uid: ?u32 = null,
    active_gid: ?u32 = null,
    active_authenticated: bool = false,
    pending_preempt_client_id: ?[]const u8 = null,
    pending_preempt_uid: ?u32 = null,
    pending_preempt_gid: ?u32 = null,
    pending_preempt_authenticated: bool = false,
    pending_preempt_client_label: ?[]const u8 = null,
    pending_preempt_client_class: ?[]const u8 = null,
    pending_preempt_client_origin: ?[]const u8 = null,
    pending_preempt_conn: ?std.posix.socket_t = null,

    pub fn renderJson(self: RuntimeState, allocator: std.mem.Allocator) ![]const u8 {
        const stream_json = try renderCurrentStreamJson(
            allocator,
            self.current_stream_id,
            self.active_client_id,
            self.active_client_label,
            self.active_client_class,
            self.active_client_origin,
            self.active_uid,
            self.active_gid,
            self.active_authenticated,
            self.current_stream,
        );

        const client_id_json = if (self.active_client_id) |v|
            try std.fmt.allocPrint(allocator, "\"{s}\"", .{v})
        else
            try allocator.dupe(u8, "null");
        defer allocator.free(client_id_json);

        const client_label_json = if (self.active_client_label) |v|
            try std.fmt.allocPrint(allocator, "\"{s}\"", .{v})
        else
            try allocator.dupe(u8, "null");
        defer allocator.free(client_label_json);

        const client_class_json = if (self.active_client_class) |v|
            try std.fmt.allocPrint(allocator, "\"{s}\"", .{v})
        else
            try allocator.dupe(u8, "null");
        defer allocator.free(client_class_json);

        const client_origin_json = if (self.active_client_origin) |v|
            try std.fmt.allocPrint(allocator, "\"{s}\"", .{v})
        else
            try allocator.dupe(u8, "null");
        defer allocator.free(client_origin_json);

        const uid_json = try renderOptionalU32Json(allocator, self.active_uid);
        defer allocator.free(uid_json);

        const gid_json = try renderOptionalU32Json(allocator, self.active_gid);
        defer allocator.free(gid_json);

        return std.fmt.allocPrint(
            allocator,
            "{{\n  \"type\": \"semaud_state\",\n  \"target\": \"{s}\",\n  \"default_pcm\": \"{s}\",\n  \"audiodev\": \"{s}\",\n  \"mixerdev\": \"{s}\",\n  \"stream_active\": {s},\n  \"stop_requested\": {s},\n  \"flush_requested\": {s},\n  \"preempt_requested\": {s},\n  \"active_client_id\": {s},\n  \"active_client_label\": {s},\n  \"active_client_class\": {s},\n  \"active_client_origin\": {s},\n  \"active_uid\": {s},\n  \"active_gid\": {s},\n  \"active_authenticated\": {s},\n  \"current_stream\": {s}\n}}\n",
            .{
                self.target_name,
                self.selection.default_pcm,
                self.selection.audiodev,
                self.selection.mixerdev,
                if (self.stream_active) "true" else "false",
                if (self.stop_requested) "true" else "false",
                if (self.flush_requested) "true" else "false",
                if (self.preempt_requested) "true" else "false",
                client_id_json,
                client_label_json,
                client_class_json,
                client_origin_json,
                uid_json,
                gid_json,
                if (self.active_authenticated) "true" else "false",
                stream_json,
            },
        );
    }

    pub fn writeJsonFile(self: RuntimeState, allocator: std.mem.Allocator) !void {
        const path = try surfaces.statePath(allocator, self.target_name);
        defer allocator.free(path);

        const json = try self.renderJson(allocator);
        defer allocator.free(json);

        var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
        defer file.close();
        try file.writeAll(json);
    }
};

pub fn renderCapabilitiesJson(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) ![]const u8 {
    return std.fmt.allocPrint(
        allocator,
        "{{\n  \"backend\": \"oss\",\n  \"target\": \"{s}\",\n  \"supported_sample_formats\": [\"s16le\"],\n  \"supported_channel_counts\": [2],\n  \"supported_sample_rates\": [48000]\n}}\n",
        .{target_name},
    );
}

pub fn renderControlCapabilitiesJson(allocator: std.mem.Allocator) ![]const u8 {
    _ = allocator;
    return std.heap.page_allocator.dupe(
        u8,
        "{\n  \"control_mode\": \"read_write_socket\",\n  \"socket\": \"/tmp/semaud-control.sock\",\n  \"supported_commands\": [\"describe\", \"state\", \"state <target>\"],\n  \"future_commands\": [\"policy-state <target>\", \"targets\"]\n}\n",
    );
}

pub fn ensureTargetLayout(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) !void {
    const base = try surfaces.baseDir(allocator, target_name);
    defer allocator.free(base);

    const stream = try surfaces.streamDir(allocator, target_name);
    defer allocator.free(stream);

    try std.fs.cwd().makePath(base);
    try std.fs.cwd().makePath(stream);
}

pub fn writeIdentityFile(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) !void {
    const path = try surfaces.identityPath(allocator, target_name);
    defer allocator.free(path);
    try writeTextFile(path, "default_output\n");
}

pub fn writeVersionFile(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) !void {
    const path = try surfaces.versionPath(allocator, target_name);
    defer allocator.free(path);
    try writeTextFile(path, "semaud-phase11\n");
}

pub fn writeBackendFile(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) !void {
    const path = try surfaces.backendPath(allocator, target_name);
    defer allocator.free(path);
    try writeTextFile(path, "oss\n");
}

pub fn writeDefaultPolicyFile(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) !void {
    const path = try surfaces.policyPath(allocator, target_name);
    defer allocator.free(path);

    if (std.mem.eql(u8, target_name, "alt")) {
        try writeTextFile(
            path,
            "# semaud durable policy\nversion=1\ndefault=allow\noverride_class=admin\nfallback_target=default\ngroup=output\n",
        );
    } else {
        try writeTextFile(
            path,
            "# semaud durable policy\nversion=1\ndefault=allow\noverride_class=admin\ngroup=output\n",
        );
    }
}


pub fn writePolicyValidationFiles(
    allocator: std.mem.Allocator,
    target_name: []const u8,
    loaded_policy: anytype,
) !void {
    const valid_path = try surfaces.policyValidPath(allocator, target_name);
    defer allocator.free(valid_path);

    const errors_path = try surfaces.policyErrorsPath(allocator, target_name);
    defer allocator.free(errors_path);

    try writeTextFile(
        valid_path,
        if (@import("policy.zig").isValid(loaded_policy)) "true\n" else "false\n",
    );

    var out = std.ArrayListUnmanaged(u8){};
    defer out.deinit(allocator);

    try out.appendSlice(allocator, "[");

    for (loaded_policy.errors.items, 0..) |item, idx| {
        if (idx != 0) try out.appendSlice(allocator, ",");
        const enc = try std.fmt.allocPrint(allocator, "\"{s}\"", .{item});
        defer allocator.free(enc);
        try out.appendSlice(allocator, enc);
    }

    try out.appendSlice(allocator, "]\n");

    const body = try out.toOwnedSlice(allocator);
    defer allocator.free(body);

    try writeTextFile(errors_path, body);
}

pub fn writeCapabilitiesFile(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) !void {
    const path = try surfaces.capabilitiesPath(allocator, target_name);
    defer allocator.free(path);

    const body = try renderCapabilitiesJson(allocator, target_name);
    defer allocator.free(body);

    try writeTextFile(path, body);
}

pub fn writeControlFile(
    allocator: std.mem.Allocator,
    target_name: []const u8,
    stream_socket: []const u8,
) !void {
    const path = try surfaces.controlPath(allocator, target_name);
    defer allocator.free(path);

    const body = try std.fmt.allocPrint(
        allocator,
        "control_plane=socket\ncontrol_socket=/tmp/semaud-control.sock\nstream_socket={s}\ntarget={s}\n",
        .{ stream_socket, target_name },
    );
    defer allocator.free(body);

    try writeTextFile(path, body);
}

pub fn writeControlCapabilitiesFile(
    allocator: std.mem.Allocator,
    target_name: []const u8,
) !void {
    const path = try surfaces.controlCapabilitiesPath(allocator, target_name);
    defer allocator.free(path);

    const body = try renderControlCapabilitiesJson(std.heap.page_allocator);
    defer std.heap.page_allocator.free(body);

    try writeTextFile(path, body);
}

pub fn writeDeviceFile(
    allocator: std.mem.Allocator,
    state: RuntimeState,
) !void {
    const path = try surfaces.devicePath(allocator, state.target_name);
    defer allocator.free(path);

    const body = try std.fmt.allocPrint(
        allocator,
        "default_pcm={s}\naudiodev={s}\nmixerdev={s}\n",
        .{
            state.selection.default_pcm,
            state.selection.audiodev,
            state.selection.mixerdev,
        },
    );
    defer allocator.free(body);

    try writeTextFile(path, body);
}

pub fn writeCurrentStreamFile(
    allocator: std.mem.Allocator,
    state: RuntimeState,
) !void {
    const path = try surfaces.streamCurrentPath(allocator, state.target_name);
    defer allocator.free(path);

    const body = try renderCurrentStreamJson(
        allocator,
        state.current_stream_id,
        state.active_client_id,
        state.active_client_label,
        state.active_client_class,
        state.active_client_origin,
        state.active_uid,
        state.active_gid,
        state.active_authenticated,
        state.current_stream,
    );
    defer allocator.free(body);

    const with_nl = try std.fmt.allocPrint(allocator, "{s}\n", .{body});
    defer allocator.free(with_nl);

    try writeTextFile(path, with_nl);
}

fn renderOptionalU32Json(allocator: std.mem.Allocator, value: ?u32) ![]u8 {
    if (value) |v| return std.fmt.allocPrint(allocator, "{}", .{v});
    return allocator.dupe(u8, "null");
}

fn renderCurrentStreamJson(
    allocator: std.mem.Allocator,
    stream_id: u64,
    active_client_id: ?[]const u8,
    active_client_label: ?[]const u8,
    active_client_class: ?[]const u8,
    active_client_origin: ?[]const u8,
    active_uid: ?u32,
    active_gid: ?u32,
    active_authenticated: bool,
    current_stream: ?types.StreamDescriptor,
) ![]const u8 {
    if (current_stream) |s| {
        const client_id = active_client_id orelse "unknown";
        const client_label = active_client_label orelse "unlabeled";
        const client_class = active_client_class orelse "unknown";
        const client_origin = active_client_origin orelse "unknown";
        const uid_json = try renderOptionalU32Json(allocator, active_uid);
        defer allocator.free(uid_json);
        const gid_json = try renderOptionalU32Json(allocator, active_gid);
        defer allocator.free(gid_json);

        return std.fmt.allocPrint(
            allocator,
            "{{\"stream_id\":{},\"client_id\":\"{s}\",\"client_label\":\"{s}\",\"client_class\":\"{s}\",\"client_origin\":\"{s}\",\"uid\":{s},\"gid\":{s},\"authenticated\":{s},\"sample_rate\":{},\"channels\":{},\"sample_format\":\"{s}\"}}",
            .{
                stream_id,
                client_id,
                client_label,
                client_class,
                client_origin,
                uid_json,
                gid_json,
                if (active_authenticated) "true" else "false",
                s.sample_rate,
                s.channels,
                @tagName(s.format),
            },
        );
    }

    return allocator.dupe(u8, "null");
}

pub fn appendStreamBeginEvent(
    allocator: std.mem.Allocator,
    state: RuntimeState,
    meta: EventMeta,
    stream_id: u64,
    desc: types.StreamDescriptor,
) !void {
    const path = try surfaces.streamEventsPath(allocator, state.target_name);
    defer allocator.free(path);

    const client_id = state.active_client_id orelse "unknown";
    const client_label = state.active_client_label orelse "unlabeled";
    const client_class = state.active_client_class orelse "unknown";
    const client_origin = state.active_client_origin orelse "unknown";
    const uid_json = try renderOptionalU32Json(allocator, state.active_uid);
    defer allocator.free(uid_json);
    const gid_json = try renderOptionalU32Json(allocator, state.active_gid);
    defer allocator.free(gid_json);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_begin\",\"target\":\"{s}\",\"stream_id\":{},\"client_id\":\"{s}\",\"client_label\":\"{s}\",\"client_class\":\"{s}\",\"client_origin\":\"{s}\",\"uid\":{s},\"gid\":{s},\"authenticated\":{s},\"policy\":\"allow\",\"default_pcm\":\"{s}\",\"audiodev\":\"{s}\",\"mixerdev\":\"{s}\",\"sample_rate\":{},\"channels\":{},\"sample_format\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            state.target_name,
            stream_id,
            client_id,
            client_label,
            client_class,
            client_origin,
            uid_json,
            gid_json,
            if (state.active_authenticated) "true" else "false",
            state.selection.default_pcm,
            state.selection.audiodev,
            state.selection.mixerdev,
            desc.sample_rate,
            desc.channels,
            @tagName(desc.format),
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, state.target_name, line);
}

pub fn appendStreamEndEvent(
    allocator: std.mem.Allocator,
    state: RuntimeState,
    meta: EventMeta,
    stream_id: u64,
) !void {
    const path = try surfaces.streamEventsPath(allocator, state.target_name);
    defer allocator.free(path);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_end\",\"target\":\"{s}\",\"stream_id\":{},\"default_pcm\":\"{s}\",\"audiodev\":\"{s}\",\"mixerdev\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            state.target_name,
            stream_id,
            state.selection.default_pcm,
            state.selection.audiodev,
            state.selection.mixerdev,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, state.target_name, line);
}

pub fn appendStreamStopEvent(
    allocator: std.mem.Allocator,
    state: RuntimeState,
    meta: EventMeta,
    stream_id: u64,
) !void {
    const path = try surfaces.streamEventsPath(allocator, state.target_name);
    defer allocator.free(path);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_stop\",\"target\":\"{s}\",\"stream_id\":{},\"default_pcm\":\"{s}\",\"audiodev\":\"{s}\",\"mixerdev\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            state.target_name,
            stream_id,
            state.selection.default_pcm,
            state.selection.audiodev,
            state.selection.mixerdev,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, state.target_name, line);
}

pub fn appendStreamFlushEvent(
    allocator: std.mem.Allocator,
    state: RuntimeState,
    meta: EventMeta,
    stream_id: u64,
) !void {
    const path = try surfaces.streamEventsPath(allocator, state.target_name);
    defer allocator.free(path);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_flush\",\"target\":\"{s}\",\"stream_id\":{},\"default_pcm\":\"{s}\",\"audiodev\":\"{s}\",\"mixerdev\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            state.target_name,
            stream_id,
            state.selection.default_pcm,
            state.selection.audiodev,
            state.selection.mixerdev,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, state.target_name, line);
}

pub fn appendStreamPreemptEvent(
    allocator: std.mem.Allocator,
    state: RuntimeState,
    meta: EventMeta,
    old_stream_id: u64,
    old_client_id: []const u8,
    old_client_label: []const u8,
    new_client_id: []const u8,
    new_client_label: []const u8,
    new_client_class: []const u8,
    new_client_origin: []const u8,
) !void {
    const path = try surfaces.streamEventsPath(allocator, state.target_name);
    defer allocator.free(path);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_preempt\",\"target\":\"{s}\",\"old_stream_id\":{},\"old_client_id\":\"{s}\",\"old_client_label\":\"{s}\",\"new_client_id\":\"{s}\",\"new_client_label\":\"{s}\",\"new_client_class\":\"{s}\",\"new_client_origin\":\"{s}\",\"policy\":\"override\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            state.target_name,
            old_stream_id,
            old_client_id,
            old_client_label,
            new_client_id,
            new_client_label,
            new_client_class,
            new_client_origin,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, state.target_name, line);
}

pub fn appendStreamRejectEvent(
    allocator: std.mem.Allocator,
    state: RuntimeState,
    meta: EventMeta,
    client_id: []const u8,
    client_label: []const u8,
    client_class: []const u8,
    client_origin: []const u8,
    client_uid: ?u32,
    client_gid: ?u32,
    client_authenticated: bool,
    reason: []const u8,
) !void {
    const path = try surfaces.streamEventsPath(allocator, state.target_name);
    defer allocator.free(path);

    const uid_json = try renderOptionalU32Json(allocator, client_uid);
    defer allocator.free(uid_json);
    const gid_json = try renderOptionalU32Json(allocator, client_gid);
    defer allocator.free(gid_json);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_reject\",\"target\":\"{s}\",\"client_id\":\"{s}\",\"client_label\":\"{s}\",\"client_class\":\"{s}\",\"client_origin\":\"{s}\",\"uid\":{s},\"gid\":{s},\"authenticated\":{s},\"policy\":\"{s}\",\"default_pcm\":\"{s}\",\"audiodev\":\"{s}\",\"mixerdev\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            state.target_name,
            client_id,
            client_label,
            client_class,
            client_origin,
            uid_json,
            gid_json,
            if (client_authenticated) "true" else "false",
            reason,
            state.selection.default_pcm,
            state.selection.audiodev,
            state.selection.mixerdev,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, state.target_name, line);
}

pub fn appendStreamRerouteEvent(
    allocator: std.mem.Allocator,
    from_target: []const u8,
    to_target: []const u8,
    meta: EventMeta,
    client_id: []const u8,
    client_label: []const u8,
    client_class: []const u8,
    client_origin: []const u8,
    client_uid: ?u32,
    client_gid: ?u32,
    client_authenticated: bool,
    reason: []const u8,
) !void {
    const path = try surfaces.streamEventsPath(allocator, from_target);
    defer allocator.free(path);

    const uid_json = try renderOptionalU32Json(allocator, client_uid);
    defer allocator.free(uid_json);
    const gid_json = try renderOptionalU32Json(allocator, client_gid);
    defer allocator.free(gid_json);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_reroute\",\"from_target\":\"{s}\",\"to_target\":\"{s}\",\"client_id\":\"{s}\",\"client_label\":\"{s}\",\"client_class\":\"{s}\",\"client_origin\":\"{s}\",\"uid\":{s},\"gid\":{s},\"authenticated\":{s},\"reason\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            from_target,
            to_target,
            client_id,
            client_label,
            client_class,
            client_origin,
            uid_json,
            gid_json,
            if (client_authenticated) "true" else "false",
            reason,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, from_target, line);
}

pub fn appendStreamGroupBlockEvent(
    allocator: std.mem.Allocator,
    target: []const u8,
    group_name: []const u8,
    blocking_target: []const u8,
    meta: EventMeta,
    client_id: []const u8,
    client_label: []const u8,
    client_class: []const u8,
    client_origin: []const u8,
    client_uid: ?u32,
    client_gid: ?u32,
    client_authenticated: bool,
    reason: []const u8,
) !void {
    const path = try surfaces.streamEventsPath(allocator, target);
    defer allocator.free(path);

    const uid_json = try renderOptionalU32Json(allocator, client_uid);
    defer allocator.free(uid_json);
    const gid_json = try renderOptionalU32Json(allocator, client_gid);
    defer allocator.free(gid_json);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_group_block\",\"target\":\"{s}\",\"group\":\"{s}\",\"blocking_target\":\"{s}\",\"client_id\":\"{s}\",\"client_label\":\"{s}\",\"client_class\":\"{s}\",\"client_origin\":\"{s}\",\"uid\":{s},\"gid\":{s},\"authenticated\":{s},\"reason\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            target,
            group_name,
            blocking_target,
            client_id,
            client_label,
            client_class,
            client_origin,
            uid_json,
            gid_json,
            if (client_authenticated) "true" else "false",
            reason,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, target, line);
}

pub fn appendStreamGroupPreemptEvent(
    allocator: std.mem.Allocator,
    target: []const u8,
    group_name: []const u8,
    preempted_target: []const u8,
    meta: EventMeta,
    client_id: []const u8,
    client_label: []const u8,
    client_class: []const u8,
    client_origin: []const u8,
    client_uid: ?u32,
    client_gid: ?u32,
    client_authenticated: bool,
    reason: []const u8,
) !void {
    const path = try surfaces.streamEventsPath(allocator, target);
    defer allocator.free(path);

    const uid_json = try renderOptionalU32Json(allocator, client_uid);
    defer allocator.free(uid_json);
    const gid_json = try renderOptionalU32Json(allocator, client_gid);
    defer allocator.free(gid_json);

    const line = try std.fmt.allocPrint(
        allocator,
        "{{\"seq\":{},\"ts_mono_ns\":{},\"type\":\"stream_group_preempt\",\"target\":\"{s}\",\"group\":\"{s}\",\"preempted_target\":\"{s}\",\"client_id\":\"{s}\",\"client_label\":\"{s}\",\"client_class\":\"{s}\",\"client_origin\":\"{s}\",\"uid\":{s},\"gid\":{s},\"authenticated\":{s},\"reason\":\"{s}\"}}\n",
        .{
            meta.seq,
            meta.ts_mono_ns,
            target,
            group_name,
            preempted_target,
            client_id,
            client_label,
            client_class,
            client_origin,
            uid_json,
            gid_json,
            if (client_authenticated) "true" else "false",
            reason,
        },
    );
    defer allocator.free(line);

    try appendLine(path, line);
    try writeLastEvent(allocator, target, line);
}

pub fn parseRetargetSelection(
    allocator: std.mem.Allocator,
    arg: []const u8,
) !types.DeviceSelection {
    if (std.mem.startsWith(u8, arg, "pcm")) {
        const suffix = arg["pcm".len..];
        return .{
            .default_pcm = try allocator.dupe(u8, arg),
            .audiodev = try std.fmt.allocPrint(allocator, "/dev/dsp{s}", .{suffix}),
            .mixerdev = try std.fmt.allocPrint(allocator, "/dev/mixer{s}", .{suffix}),
        };
    }

    if (std.mem.startsWith(u8, arg, "/dev/dsp")) {
        const suffix = arg["/dev/dsp".len..];
        return .{
            .default_pcm = try std.fmt.allocPrint(allocator, "pcm{s}", .{suffix}),
            .audiodev = try allocator.dupe(u8, arg),
            .mixerdev = try std.fmt.allocPrint(allocator, "/dev/mixer{s}", .{suffix}),
        };
    }

    return error.InvalidRetargetTarget;
}

fn writeLastEvent(
    allocator: std.mem.Allocator,
    target_name: []const u8,
    line: []const u8,
) !void {
    const path = try surfaces.lastEventPath(allocator, target_name);
    defer allocator.free(path);

    var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(line);
}

fn writeTextFile(path: []const u8, body: []const u8) !void {
    var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(body);
}

fn appendLine(path: []const u8, line: []const u8) !void {
    var file = std.fs.cwd().openFile(path, .{ .mode = .write_only }) catch |err| switch (err) {
        error.FileNotFound => try std.fs.cwd().createFile(path, .{}),
        else => return err,
    };
    defer file.close();
    try file.seekFromEnd(0);
    try file.writeAll(line);
}
