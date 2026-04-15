const std = @import("std");
const types = @import("types.zig");
const policy_mod = @import("policy.zig");

fn renderStringArray(allocator: std.mem.Allocator, items: []const []const u8) ![]u8 {
    var out = std.ArrayListUnmanaged(u8){};
    errdefer out.deinit(allocator);

    try out.appendSlice(allocator, "[");
    for (items, 0..) |item, idx| {
        if (idx != 0) try out.appendSlice(allocator, ",");
        const enc = try std.fmt.allocPrint(allocator, "\"{s}\"", .{item});
        defer allocator.free(enc);
        try out.appendSlice(allocator, enc);
    }
    try out.appendSlice(allocator, "]");
    return out.toOwnedSlice(allocator);
}

pub fn writePolicyState(
    allocator: std.mem.Allocator,
    path: []const u8,
    loaded: policy_mod.LoadedPolicy,
    last_client_id: ?[]const u8,
    last_client_label: ?[]const u8,
    last_client_class: ?[]const u8,
    last_client_origin: ?[]const u8,
    last_decision: ?types.PolicyDecision,
    last_route_decision: ?[]const u8,
    last_group_decision: ?[]const u8,
    last_uid: ?u32,
    last_gid: ?u32,
    last_authenticated: bool,
) !void {
    const default_policy = if (loaded.default_allow) "allow" else "deny";

    const deny_labels_json = try renderStringArray(allocator, loaded.deny_labels.items);
    defer allocator.free(deny_labels_json);
    const deny_classes_json = try renderStringArray(allocator, loaded.deny_classes.items);
    defer allocator.free(deny_classes_json);
    const allow_classes_json = try renderStringArray(allocator, loaded.allow_classes.items);
    defer allocator.free(allow_classes_json);
    const override_classes_json = try renderStringArray(allocator, loaded.override_classes.items);
    defer allocator.free(override_classes_json);

    const client_id_json = if (last_client_id) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(client_id_json);
    const client_label_json = if (last_client_label) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(client_label_json);
    const client_class_json = if (last_client_class) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(client_class_json);
    const client_origin_json = if (last_client_origin) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(client_origin_json);
    const decision_json = if (last_decision) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{@tagName(v)}) else try allocator.dupe(u8, "null");
    defer allocator.free(decision_json);
    const fallback_json = if (loaded.fallback_target) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(fallback_json);
    const group_json = if (loaded.group_name) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(group_json);
    const group_mode_json = if (loaded.group_name != null) try allocator.dupe(u8, "\"exclusive\"") else try allocator.dupe(u8, "null");
    defer allocator.free(group_mode_json);
    const route_json = if (last_route_decision) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(route_json);
    const group_decision_json = if (last_group_decision) |v| try std.fmt.allocPrint(allocator, "\"{s}\"", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(group_decision_json);
    const uid_json = if (last_uid) |v| try std.fmt.allocPrint(allocator, "{}", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(uid_json);
    const gid_json = if (last_gid) |v| try std.fmt.allocPrint(allocator, "{}", .{v}) else try allocator.dupe(u8, "null");
    defer allocator.free(gid_json);

    const body = try std.fmt.allocPrint(
        allocator,
        "{{\n  \"default_policy\": \"{s}\",\n  \"deny_labels\": {s},\n  \"deny_classes\": {s},\n  \"allow_classes\": {s},\n  \"override_classes\": {s},\n  \"fallback_target\": {s},\n  \"group\": {s},\n  \"group_mode\": {s},\n  \"last_client_id\": {s},\n  \"last_client_label\": {s},\n  \"last_client_class\": {s},\n  \"last_client_origin\": {s},\n  \"last_uid\": {s},\n  \"last_gid\": {s},\n  \"last_authenticated\": {s},\n  \"last_decision\": {s},\n  \"last_route_decision\": {s},\n  \"last_group_decision\": {s}\n}}\n",
        .{
            default_policy,
            deny_labels_json,
            deny_classes_json,
            allow_classes_json,
            override_classes_json,
            fallback_json,
            group_json,
            group_mode_json,
            client_id_json,
            client_label_json,
            client_class_json,
            client_origin_json,
            uid_json,
            gid_json,
            if (last_authenticated) "true" else "false",
            decision_json,
            route_json,
            group_decision_json,
        },
    );
    defer allocator.free(body);

    var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(body);
}
