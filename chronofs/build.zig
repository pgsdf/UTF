const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // shared/src/clock.zig — dependency for all chronofs modules.
    const shared_clock_mod = b.createModule(.{
        .root_source_file = b.path("../shared/src/clock.zig"),
        .target = target,
        .optimize = optimize,
    });

    // C-1: chronofs clock module.
    const clock_mod = b.createModule(.{
        .root_source_file = b.path("src/clock.zig"),
        .target = target,
        .optimize = optimize,
    });
    clock_mod.addImport("shared_clock", shared_clock_mod);

    const clock_tests = b.addTest(.{
        .root_module = clock_mod,
    });

    const test_step = b.step("test", "Run chronofs tests");
    test_step.dependOn(&b.addRunArtifact(clock_tests).step);
}
