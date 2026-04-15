const std = @import("std");
const types = @import("types.zig");

pub const LoadedPolicy = struct {
    policy_version: u32 = 1,
    default_allow: bool = true,
    deny_labels: std.ArrayListUnmanaged([]const u8) = .{},
    deny_classes: std.ArrayListUnmanaged([]const u8) = .{},
    allow_classes: std.ArrayListUnmanaged([]const u8) = .{},
    override_classes: std.ArrayListUnmanaged([]const u8) = .{},
    fallback_target: ?[]const u8 = null,
    group_name: ?[]const u8 = null,
    errors: std.ArrayListUnmanaged([]const u8) = .{},

    pub fn deinit(self: *LoadedPolicy, allocator: std.mem.Allocator) void {
        for (self.deny_labels.items) |item| allocator.free(item);
        for (self.deny_classes.items) |item| allocator.free(item);
        for (self.allow_classes.items) |item| allocator.free(item);
        for (self.override_classes.items) |item| allocator.free(item);
        for (self.errors.items) |item| allocator.free(item);
        self.deny_labels.deinit(allocator);
        self.deny_classes.deinit(allocator);
        self.allow_classes.deinit(allocator);
        self.override_classes.deinit(allocator);
        self.errors.deinit(allocator);
        if (self.fallback_target) |v| allocator.free(v);
        if (self.group_name) |v| allocator.free(v);
    }
};

fn addError(allocator: std.mem.Allocator, loaded: *LoadedPolicy, msg: []const u8) !void {
    try loaded.errors.append(allocator, try allocator.dupe(u8, msg));
}

pub fn isValid(policy: LoadedPolicy) bool {
    return policy.errors.items.len == 0;
}

pub fn loadPolicy(allocator: std.mem.Allocator, path: []const u8) !LoadedPolicy {
    var loaded = LoadedPolicy{};

    const data = std.fs.cwd().readFileAlloc(allocator, path, 64 * 1024) catch |err| switch (err) {
        error.FileNotFound => return loaded,
        else => return err,
    };
    defer allocator.free(data);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0) continue;
        if (line[0] == '#') continue;

        if (std.mem.startsWith(u8, line, "version=")) {
            const v = line["version=".len..];
            loaded.policy_version = std.fmt.parseInt(u32, v, 10) catch {
                try addError(allocator, &loaded, "invalid version field");
                continue;
            };
            if (loaded.policy_version != 1) try addError(allocator, &loaded, "unsupported policy version");
            continue;
        }
        if (std.mem.eql(u8, line, "default=allow")) {
            loaded.default_allow = true;
            continue;
        }
        if (std.mem.eql(u8, line, "default=deny")) {
            loaded.default_allow = false;
            continue;
        }
        if (std.mem.startsWith(u8, line, "deny_label=")) {
            const v = line["deny_label=".len..];
            try loaded.deny_labels.append(allocator, try allocator.dupe(u8, v));
            continue;
        }
        if (std.mem.startsWith(u8, line, "deny_class=")) {
            const v = line["deny_class=".len..];
            try loaded.deny_classes.append(allocator, try allocator.dupe(u8, v));
            continue;
        }
        if (std.mem.startsWith(u8, line, "allow_class=")) {
            const v = line["allow_class=".len..];
            try loaded.allow_classes.append(allocator, try allocator.dupe(u8, v));
            continue;
        }
        if (std.mem.startsWith(u8, line, "override_class=")) {
            const v = line["override_class=".len..];
            try loaded.override_classes.append(allocator, try allocator.dupe(u8, v));
            continue;
        }
        if (std.mem.startsWith(u8, line, "fallback_target=")) {
            const v = line["fallback_target=".len..];
            if (loaded.fallback_target) |old| allocator.free(old);
            loaded.fallback_target = try allocator.dupe(u8, v);
            continue;
        }
        if (std.mem.startsWith(u8, line, "group=")) {
            const v = line["group=".len..];
            if (loaded.group_name) |old| allocator.free(old);
            loaded.group_name = try allocator.dupe(u8, v);
            continue;
        }

        const err_line = try std.fmt.allocPrint(allocator, "unknown directive: {s}", .{line});
        defer allocator.free(err_line);
        try addError(allocator, &loaded, err_line);
    }

    return loaded;
}

pub fn hasOverride(policy: LoadedPolicy, client_class: []const u8) bool {
    for (policy.override_classes.items) |override_class| {
        if (std.mem.eql(u8, client_class, override_class)) return true;
    }
    return false;
}

pub fn evaluate(
    policy: LoadedPolicy,
    client_label: []const u8,
    client_class: []const u8,
) types.PolicyDecision {
    for (policy.deny_labels.items) |deny_label| {
        if (std.mem.eql(u8, client_label, deny_label)) return .deny;
    }
    for (policy.deny_classes.items) |deny_class| {
        if (std.mem.eql(u8, client_class, deny_class)) return .deny;
    }
    for (policy.allow_classes.items) |allow_class| {
        if (std.mem.eql(u8, client_class, allow_class)) return .allow;
    }
    return if (policy.default_allow) .allow else .deny;
}
