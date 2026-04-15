const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "semaud",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run SemaAud");
    run_step.dependOn(&run_cmd.step);

    const policy_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/policy_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_policy_tests = b.addRunArtifact(policy_tests);
    const test_step = b.step("test", "Run semaud unit tests (Phase 12 policy validation matrix)");
    test_step.dependOn(&run_policy_tests.step);
}
