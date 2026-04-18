const std = @import("std");

// ============================================================================
// UTF root build — delegates to each subproject via shell commands.
//
// Steps:
//   zig build              — build all subprojects
//   zig build test         — run all test suites
//   zig build build-semaaud / build-semainput / build-semadraw / build-chronofs
//   zig build test-semaaud / test-semainput / test-semadraw / test-chronofs
//   zig build run-semaaud  — build and run semaaud
//   zig build run-semainput — build and run semainputd (requires root)
//   zig build run-semadraw — build and run semadrawd
//   zig build chrono-dump  — build chrono_dump
//
// VirtualBox / headless:
//   zig build -Dgpu=false  — disable GPU backends (X11, Vulkan, Wayland, bsdinput)
// ============================================================================

pub fn build(b: *std.Build) void {
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = target;
    _ = optimize;

    // GPU flag — passed through to semadraw subproject.
    // Default: auto-detect. Set false explicitly to skip all GPU backends.
    const want_gpu = b.option(bool, "gpu",
        "Enable GPU-dependent backends in semadraw (default: true; set false for VirtualBox/headless)")
        orelse true;

    // Build semadraw args: conditionally add -Dgpu=false
    const semadraw_args: []const []const u8 = if (want_gpu)
        &.{ "zig", "build" }
    else
        &.{ "zig", "build", "-Dgpu=false" };

    const subprojects = [_]struct {
        name: []const u8,
        dir:  []const u8,
    }{
        .{ .name = "semaaud",   .dir = "semaaud"  },
        .{ .name = "semainput", .dir = "semainput" },
        .{ .name = "semadraw",  .dir = "semadraw"  },
        .{ .name = "chronofs",  .dir = "chronofs"  },
    };

    const build_all   = b.step("all",  "Build all subprojects (default)");
    const test_all    = b.step("test", "Run all test suites");
    const install_all = b.default_step;

    for (subprojects) |sp| {
        // Choose args: semadraw gets the GPU-aware command, others get plain
        const args = if (std.mem.eql(u8, sp.name, "semadraw"))
            semadraw_args
        else
            &[_][]const u8{ "zig", "build" };

        const build_cmd = b.addSystemCommand(args);
        build_cmd.setCwd(b.path(sp.dir));

        const build_step = b.step(
            b.fmt("build-{s}", .{sp.name}),
            b.fmt("Build {s}", .{sp.name}),
        );
        build_step.dependOn(&build_cmd.step);
        build_all.dependOn(&build_cmd.step);
        install_all.dependOn(&build_cmd.step);

        const test_args: []const []const u8 = &.{ "zig", "build", "test" };
        const test_cmd = b.addSystemCommand(test_args);
        test_cmd.setCwd(b.path(sp.dir));

        const test_step = b.step(
            b.fmt("test-{s}", .{sp.name}),
            b.fmt("Test {s}", .{sp.name}),
        );
        test_step.dependOn(&test_cmd.step);
        test_all.dependOn(&test_cmd.step);
    }

    // -----------------------------------------------------------------------
    // Convenience run steps
    // -----------------------------------------------------------------------
    const run_semaaud = b.step("run-semaaud", "Build and run semaaud (audio daemon)");
    {
        const build_cmd = b.addSystemCommand(&.{ "zig", "build" });
        build_cmd.setCwd(b.path("semaaud"));
        const run_cmd = b.addSystemCommand(&.{ "zig-out/bin/semaaud" });
        run_cmd.setCwd(b.path("semaaud"));
        run_cmd.step.dependOn(&build_cmd.step);
        run_semaaud.dependOn(&run_cmd.step);
    }

    const run_semainput = b.step("run-semainput", "Build and run semainputd (requires root)");
    {
        const build_cmd = b.addSystemCommand(&.{ "zig", "build" });
        build_cmd.setCwd(b.path("semainput"));
        const run_cmd = b.addSystemCommand(&.{ "zig-out/bin/semainputd" });
        run_cmd.setCwd(b.path("semainput"));
        run_cmd.step.dependOn(&build_cmd.step);
        run_semainput.dependOn(&run_cmd.step);
    }

    const run_semadraw = b.step("run-semadraw", "Build and run semadrawd (compositor)");
    {
        const build_cmd = b.addSystemCommand(semadraw_args);
        build_cmd.setCwd(b.path("semadraw"));
        const run_cmd = b.addSystemCommand(&.{ "zig-out/bin/semadrawd" });
        run_cmd.setCwd(b.path("semadraw"));
        run_cmd.step.dependOn(&build_cmd.step);
        run_semadraw.dependOn(&run_cmd.step);
    }

    const chrono_dump = b.step("chrono-dump", "Build chrono_dump diagnostic tool");
    {
        const build_cmd = b.addSystemCommand(&.{ "zig", "build" });
        build_cmd.setCwd(b.path("chronofs"));
        chrono_dump.dependOn(&build_cmd.step);
    }
}
