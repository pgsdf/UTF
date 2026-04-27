const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // shared/src/input.zig: the C.1 publication-region library.
    const shared_input_mod = b.createModule(.{
        .root_source_file = b.path("../shared/src/input.zig"),
        .target = target,
        .optimize = optimize,
    });

    // C.2 verification helper: inputstate-check.
    // Throwaway tool, will be removed when C.4 (inputdump) lands.
    const inputstate_check = b.addExecutable(.{
        .name = "inputstate-check",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/inputstate-check.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "input", .module = shared_input_mod },
            },
        }),
    });
    b.installArtifact(inputstate_check);

    const run_check = b.addRunArtifact(inputstate_check);
    if (b.args) |run_args| run_check.addArgs(run_args);
    const run_step = b.step("run", "Run inputstate-check");
    run_step.dependOn(&run_check.step);
}
