const std = @import("std");
const policy_mod = @import("policy.zig");
const state_mod = @import("state.zig");
const surfaces = @import("surfaces.zig");

const TEST_TARGET = "__phase12_test";

fn writePolicyFile(dir: []const u8, content: []const u8) !void {
    try std.fs.cwd().makePath(dir);
    const path = try std.fmt.allocPrint(
        std.testing.allocator,
        "{s}/policy",
        .{dir},
    );
    defer std.testing.allocator.free(path);
    var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(content);
}

fn readSurface(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return std.fs.cwd().readFileAlloc(allocator, path, 64 * 1024);
}

fn ensureTestLayout() !struct {
    dir: []const u8,
    policy_path: []const u8,
    valid_path: []const u8,
    errors_path: []const u8,
} {
    const allocator = std.testing.allocator;
    const dir = try surfaces.baseDir(allocator, TEST_TARGET);
    errdefer allocator.free(dir);
    const policy_path = try surfaces.policyPath(allocator, TEST_TARGET);
    errdefer allocator.free(policy_path);
    const valid_path = try surfaces.policyValidPath(allocator, TEST_TARGET);
    errdefer allocator.free(valid_path);
    const errors_path = try surfaces.policyErrorsPath(allocator, TEST_TARGET);
    errdefer allocator.free(errors_path);
    try std.fs.cwd().makePath(dir);
    return .{
        .dir = dir,
        .policy_path = policy_path,
        .valid_path = valid_path,
        .errors_path = errors_path,
    };
}

fn freeLayout(layout: anytype) void {
    std.testing.allocator.free(layout.dir);
    std.testing.allocator.free(layout.policy_path);
    std.testing.allocator.free(layout.valid_path);
    std.testing.allocator.free(layout.errors_path);
}

fn writePolicyAndRun(content: []const u8) !struct {
    valid_body: []u8,
    errors_body: []u8,
    loaded_valid: bool,
    loaded_error_count: usize,
} {
    const allocator = std.testing.allocator;
    const layout = try ensureTestLayout();
    defer freeLayout(layout);

    {
        var file = try std.fs.cwd().createFile(layout.policy_path, .{ .truncate = true });
        defer file.close();
        try file.writeAll(content);
    }

    var loaded = try policy_mod.loadPolicy(allocator, layout.policy_path);
    defer loaded.deinit(allocator);

    try state_mod.writePolicyValidationFiles(allocator, TEST_TARGET, loaded);

    const valid_body = try readSurface(allocator, layout.valid_path);
    errdefer allocator.free(valid_body);
    const errors_body = try readSurface(allocator, layout.errors_path);
    errdefer allocator.free(errors_body);

    return .{
        .valid_body = valid_body,
        .errors_body = errors_body,
        .loaded_valid = policy_mod.isValid(loaded),
        .loaded_error_count = loaded.errors.items.len,
    };
}

fn freeResult(result: anytype) void {
    std.testing.allocator.free(result.valid_body);
    std.testing.allocator.free(result.errors_body);
}

test "empty policy is valid with empty errors surface" {
    const result = try writePolicyAndRun("");
    defer freeResult(result);

    try std.testing.expect(result.loaded_valid);
    try std.testing.expectEqual(@as(usize, 0), result.loaded_error_count);
    try std.testing.expectEqualStrings("true\n", result.valid_body);
    try std.testing.expectEqualStrings("", result.errors_body);
}

test "comments-only policy is valid" {
    const result = try writePolicyAndRun(
        \\# leading comment
        \\# another comment
        \\
    );
    defer freeResult(result);

    try std.testing.expect(result.loaded_valid);
    try std.testing.expectEqualStrings("true\n", result.valid_body);
    try std.testing.expectEqualStrings("", result.errors_body);
}

test "version=1 plus comments produces valid surface" {
    const result = try writePolicyAndRun(
        \\# semaud durable policy
        \\version=1
        \\default=allow
        \\override_class=admin
        \\# trailing comment
        \\
    );
    defer freeResult(result);

    try std.testing.expect(result.loaded_valid);
    try std.testing.expectEqualStrings("true\n", result.valid_body);
    try std.testing.expectEqualStrings("", result.errors_body);
}

test "version=2 produces unsupported policy version error" {
    const result = try writePolicyAndRun("version=2\n");
    defer freeResult(result);

    try std.testing.expect(!result.loaded_valid);
    try std.testing.expectEqualStrings("false\n", result.valid_body);
    try std.testing.expectEqualStrings("unsupported policy version\n", result.errors_body);
}

test "non-numeric version produces invalid version field error" {
    const result = try writePolicyAndRun("version=abc\n");
    defer freeResult(result);

    try std.testing.expect(!result.loaded_valid);
    try std.testing.expectEqualStrings("false\n", result.valid_body);
    try std.testing.expectEqualStrings("invalid version field\n", result.errors_body);
}

test "unknown directive yields error with one-line-per-error surface" {
    const result = try writePolicyAndRun(
        \\version=1
        \\mystery_directive=42
        \\
    );
    defer freeResult(result);

    try std.testing.expect(!result.loaded_valid);
    try std.testing.expectEqualStrings("false\n", result.valid_body);
    try std.testing.expectEqualStrings(
        "unknown directive: mystery_directive=42\n",
        result.errors_body,
    );
}

test "multiple errors produce one line per error in surface file" {
    const result = try writePolicyAndRun(
        \\version=9
        \\bogus
        \\also_bogus=1
        \\
    );
    defer freeResult(result);

    try std.testing.expect(!result.loaded_valid);
    try std.testing.expectEqual(@as(usize, 3), result.loaded_error_count);
    try std.testing.expectEqualStrings("false\n", result.valid_body);
    try std.testing.expectEqualStrings(
        \\unsupported policy version
        \\unknown directive: bogus
        \\unknown directive: also_bogus=1
        \\
    , result.errors_body);
}

test "full valid policy with every directive class" {
    const result = try writePolicyAndRun(
        \\# full test
        \\version=1
        \\default=deny
        \\deny_label=noisy-client
        \\deny_class=background
        \\allow_class=interactive
        \\override_class=admin
        \\fallback_target=alt
        \\group=output
        \\
    );
    defer freeResult(result);

    try std.testing.expect(result.loaded_valid);
    try std.testing.expectEqualStrings("true\n", result.valid_body);
    try std.testing.expectEqualStrings("", result.errors_body);
}

test "loadPolicy populates parsed fields" {
    const allocator = std.testing.allocator;
    const layout = try ensureTestLayout();
    defer freeLayout(layout);

    {
        var file = try std.fs.cwd().createFile(layout.policy_path, .{ .truncate = true });
        defer file.close();
        try file.writeAll(
            \\version=1
            \\default=deny
            \\deny_class=background
            \\allow_class=interactive
            \\override_class=admin
            \\fallback_target=alt
            \\group=output
            \\
        );
    }

    var loaded = try policy_mod.loadPolicy(allocator, layout.policy_path);
    defer loaded.deinit(allocator);

    try std.testing.expectEqual(@as(u32, 1), loaded.policy_version);
    try std.testing.expect(!loaded.default_allow);
    try std.testing.expectEqual(@as(usize, 1), loaded.deny_classes.items.len);
    try std.testing.expectEqualStrings("background", loaded.deny_classes.items[0]);
    try std.testing.expectEqual(@as(usize, 1), loaded.allow_classes.items.len);
    try std.testing.expectEqualStrings("interactive", loaded.allow_classes.items[0]);
    try std.testing.expectEqual(@as(usize, 1), loaded.override_classes.items.len);
    try std.testing.expectEqualStrings("admin", loaded.override_classes.items[0]);
    try std.testing.expect(loaded.fallback_target != null);
    try std.testing.expectEqualStrings("alt", loaded.fallback_target.?);
    try std.testing.expect(loaded.group_name != null);
    try std.testing.expectEqualStrings("output", loaded.group_name.?);
}
