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

    // C-2: chronofs event stream ring buffers.
    const stream_mod = b.createModule(.{
        .root_source_file = b.path("src/stream.zig"),
        .target = target,
        .optimize = optimize,
    });

    const stream_tests = b.addTest(.{
        .root_module = stream_mod,
    });

    // C-3: chronofs resolver.
    const resolver_mod = b.createModule(.{
        .root_source_file = b.path("src/resolver.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "stream", .module = stream_mod },
            .{ .name = "clock",  .module = clock_mod  },
        },
    });

    const resolver_tests = b.addTest(.{
        .root_module = resolver_mod,
    });

    // C-5: chrono_dump diagnostic tool.
    const chrono_dump = b.addExecutable(.{
        .name = "chrono_dump",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/chrono_dump.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "resolver", .module = resolver_mod },
                .{ .name = "stream",   .module = stream_mod   },
                .{ .name = "clock",    .module = clock_mod    },
            },
        }),
    });
    b.installArtifact(chrono_dump);

    const run_dump = b.addRunArtifact(chrono_dump);
    if (b.args) |run_args| run_dump.addArgs(run_args);
    const run_step = b.step("run", "Run chrono_dump");
    run_step.dependOn(&run_dump.step);

    const test_step = b.step("test", "Run chronofs tests");
    test_step.dependOn(&b.addRunArtifact(clock_tests).step);
    test_step.dependOn(&b.addRunArtifact(stream_tests).step);
    test_step.dependOn(&b.addRunArtifact(resolver_tests).step);
}
