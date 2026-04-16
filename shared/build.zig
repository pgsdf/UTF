const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Session identity module — testable standalone.
    const session_mod = b.createModule(.{
        .root_source_file = b.path("src/session.zig"),
        .target = target,
        .optimize = optimize,
    });

    const session_tests = b.addTest(.{
        .root_module = session_mod,
    });

    const test_step = b.step("test", "Run shared module tests");
    test_step.dependOn(&b.addRunArtifact(session_tests).step);
}
