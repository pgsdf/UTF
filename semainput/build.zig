const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // shared/src/session.zig — session identity module.
    const session_mod = b.createModule(.{
        .root_source_file = b.path("../shared/src/session.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "semainputd",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/semainputd.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("session", session_mod);
    b.installArtifact(exe);
}
