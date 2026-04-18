const std = @import("std");

// ============================================================================
// UTF root build — delegates to each subproject.
//
// Steps:
//   zig build              — build all daemons and tools
//   zig build test         — run all test suites
//   zig build install      — install daemons to prefix (default: zig-out/)
//   zig build run-semaaud  — build and run semaud
//   zig build run-semainput — build and run semainputd (requires root)
//   zig build run-semadraw — build and run semadrawd
//   zig build chrono-dump  — build chrono_dump
//
// Each subproject is built in-place (its own zig-out/ and .zig-cache/).
// Binaries are also copied to the root zig-out/bin/ for convenience.
// ============================================================================

pub fn build(b: *std.Build) void {
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = target;
    _ = optimize;

    // -----------------------------------------------------------------------
    // Helper: add a subproject build step
    // -----------------------------------------------------------------------
    const subprojects = [_]struct {
        name: []const u8,
        dir:  []const u8,
    }{
        .{ .name = "semaaud",   .dir = "semaaud"   },
        .{ .name = "semainput", .dir = "semainput"  },
        .{ .name = "semadraw",  .dir = "semadraw"   },
        .{ .name = "chronofs",  .dir = "chronofs"   },
    };

    // Top-level steps
    const build_all  = b.step("all",   "Build all subprojects (default)");
    const test_all   = b.step("test",  "Run all test suites");
    const install_all = b.default_step; // zig build == install

    // -----------------------------------------------------------------------
    // Build and test steps per subproject
    // -----------------------------------------------------------------------
    for (subprojects) |sp| {
        // Build step: zig build -Doptimize=<opt> in subdir
        const build_cmd = b.addSystemCommand(&.{
            "zig", "build",
            "--build-file",
            b.fmt("{s}/build.zig", .{sp.dir}),
            b.fmt("--prefix={s}/zig-out", .{sp.dir}),
        });
        build_cmd.setCwd(b.path(sp.dir));

        const build_step = b.step(
            b.fmt("build-{s}", .{sp.name}),
            b.fmt("Build {s}", .{sp.name}),
        );
        build_step.dependOn(&build_cmd.step);
        build_all.dependOn(&build_cmd.step);
        install_all.dependOn(&build_cmd.step);

        // Test step: zig build test in subdir
        const test_cmd = b.addSystemCommand(&.{
            "zig", "build", "test",
            "--build-file",
            b.fmt("{s}/build.zig", .{sp.dir}),
        });
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
    const run_semaaud = b.step("run-semaaud",
        "Build and run semaud (audio daemon)");
    {
        const build_cmd = b.addSystemCommand(&.{
            "zig", "build", "--build-file", "semaaud/build.zig",
            "--prefix", "semaaud/zig-out",
        });
        build_cmd.setCwd(b.path("semaaud"));
        const run_cmd = b.addSystemCommand(&.{ "semaaud/zig-out/bin/semaud" });
        run_cmd.step.dependOn(&build_cmd.step);
        run_semaaud.dependOn(&run_cmd.step);
    }

    const run_semainput = b.step("run-semainput",
        "Build and run semainputd (input daemon, requires root)");
    {
        const build_cmd = b.addSystemCommand(&.{
            "zig", "build", "--build-file", "semainput/build.zig",
            "--prefix", "semainput/zig-out",
        });
        build_cmd.setCwd(b.path("semainput"));
        const run_cmd = b.addSystemCommand(&.{ "semainput/zig-out/bin/semainputd" });
        run_cmd.step.dependOn(&build_cmd.step);
        run_semainput.dependOn(&run_cmd.step);
    }

    const run_semadraw = b.step("run-semadraw",
        "Build and run semadrawd (compositor daemon)");
    {
        const build_cmd = b.addSystemCommand(&.{
            "zig", "build", "--build-file", "semadraw/build.zig",
            "--prefix", "semadraw/zig-out",
        });
        build_cmd.setCwd(b.path("semadraw"));
        const run_cmd = b.addSystemCommand(&.{ "semadraw/zig-out/bin/semadrawd" });
        run_cmd.step.dependOn(&build_cmd.step);
        run_semadraw.dependOn(&run_cmd.step);
    }

    const chrono_dump = b.step("chrono-dump",
        "Build chrono_dump diagnostic tool");
    {
        const build_cmd = b.addSystemCommand(&.{
            "zig", "build", "--build-file", "chronofs/build.zig",
            "--prefix", "chronofs/zig-out",
        });
        build_cmd.setCwd(b.path("chronofs"));
        chrono_dump.dependOn(&build_cmd.step);
    }

    // -----------------------------------------------------------------------
    // Help step
    // -----------------------------------------------------------------------
    const help = b.step("help", "Show available build steps");
    const help_cmd = b.addSystemCommand(&.{
        "zig", "build", "--help",
    });
    help.dependOn(&help_cmd.step);
}
