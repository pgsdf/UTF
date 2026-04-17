//! UTF — Unified Temporal Fabric
//!
//! Top-level build orchestrator. Delegates to each subsystem's own build.zig
//! for the userspace daemons, and shells out to drawfs/build.sh for the
//! FreeBSD kernel module (which uses bmake under the hood).
//!
//! Targets:
//!   zig build           — build all subsystems
//!   zig build test      — run all subsystem tests plus a top-level
//!                         integration test
//!   zig build install   — stage artifacts under the install prefix,
//!                         following FreeBSD hier(7) layout
//!
//! The install step is side-effect-free on the system unless --prefix
//! /usr/local (or similar) is passed together with sufficient privilege.
//! The default prefix is zig-out/, so a developer can run
//! `zig build install` without root and inspect the staged tree.

const std = @import("std");

const userspace_subsystems = [_][]const u8{
    "chronofs",
    "semaaud",
    "semainput",
    "semadraw",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -------------------------------------------------------------------
    // Default step: build everything
    // -------------------------------------------------------------------
    const build_all = b.step("all", "Build all subsystems (default)");
    b.default_step.dependOn(build_all);

    // -------------------------------------------------------------------
    // Userspace subsystems — delegate to each subsystem's build.zig
    // -------------------------------------------------------------------
    for (userspace_subsystems) |name| {
        const dep = b.dependency(name, .{
            .target = target,
            .optimize = optimize,
        });

        // Surface each subsystem's install step at the top level.
        const sub_install = dep.builder.getInstallStep();
        build_all.dependOn(sub_install);
        b.getInstallStep().dependOn(sub_install);
    }

    // -------------------------------------------------------------------
    // drawfs — shell out to build.sh
    // -------------------------------------------------------------------
    const drawfs_build = b.addSystemCommand(&.{
        "sh", "build.sh", "build",
    });
    drawfs_build.setCwd(b.path("drawfs"));
    drawfs_build.setName("drawfs: build kernel module");
    build_all.dependOn(&drawfs_build.step);

    // Stage drawfs.ko into the install prefix. FreeBSD hier(7) puts
    // third-party kernel modules under /boot/modules; we mirror that
    // under the configured prefix so packagers and dev staging both work.
    const drawfs_install = b.addInstallFile(
        b.path("drawfs/build/drawfs.ko"),
        "boot/modules/drawfs.ko",
    );
    drawfs_install.step.dependOn(&drawfs_build.step);
    b.getInstallStep().dependOn(&drawfs_install.step);

    // -------------------------------------------------------------------
    // Auxiliary files — rc.d scripts, devfs rules, default config, docs
    // -------------------------------------------------------------------
    installAuxiliaryFiles(b);

    // -------------------------------------------------------------------
    // Test step: per-subsystem plus top-level integration
    // -------------------------------------------------------------------
    const test_step = b.step("test", "Run all tests");

    for (userspace_subsystems) |name| {
        const dep = b.dependency(name, .{
            .target = target,
            .optimize = optimize,
        });
        if (dep.builder.top_level_steps.get("test")) |sub_test| {
            test_step.dependOn(&sub_test.step);
        }
    }

    // drawfs has its own test harness invoked through build.sh.
    const drawfs_test = b.addSystemCommand(&.{
        "sh", "build.sh", "test",
    });
    drawfs_test.setCwd(b.path("drawfs"));
    drawfs_test.setName("drawfs: test");
    test_step.dependOn(&drawfs_test.step);

    // Top-level integration test: spins up the daemons against a test
    // harness, exchanges SDCS / audio / input events across chronofs, and
    // confirms timestamps are coherent. Lives in tests/integration.zig.
    const integration_test = b.addTest(.{
        .root_source_file = b.path("tests/integration.zig"),
        .target = target,
        .optimize = optimize,
    });
    integration_test.setName("utf: integration");
    const run_integration = b.addRunArtifact(integration_test);
    // Ensure daemons are built before integration test runs.
    run_integration.step.dependOn(build_all);
    test_step.dependOn(&run_integration.step);
}

/// Install rc.d scripts, devfs rules, default config, and man pages into
/// the prefix, following FreeBSD hier(7).
fn installAuxiliaryFiles(b: *std.Build) void {
    // rc.d scripts — /usr/local/etc/rc.d/
    const rc_scripts = [_][]const u8{
        "chronofs",
        "semaaud",
        "semainput",
        "semadrawd",
    };
    for (rc_scripts) |name| {
        const src = b.fmt("scripts/rc.d/{s}", .{name});
        const dst = b.fmt("etc/rc.d/{s}", .{name});
        const step = b.addInstallFileWithMode(
            b.path(src),
            dst,
            .{ .executable = true },
        );
        b.getInstallStep().dependOn(&step.step);
    }

    // devfs rules — /usr/local/etc/devfs.rules.d/
    const devfs_rule = b.addInstallFile(
        b.path("scripts/devfs/utf-drawfs.rules"),
        "etc/devfs.rules.d/utf-drawfs.rules",
    );
    b.getInstallStep().dependOn(&devfs_rule.step);

    // Default configuration — /usr/local/etc/utf/
    const config = b.addInstallFile(
        b.path("scripts/etc/utf.conf.sample"),
        "etc/utf/utf.conf.sample",
    );
    b.getInstallStep().dependOn(&config.step);

    // Wrapper shell scripts — /usr/local/sbin/
    const wrappers = [_][]const u8{ "utf-up", "utf-down" };
    for (wrappers) |name| {
        const src = b.fmt("scripts/{s}.sh", .{name});
        const dst = b.fmt("sbin/{s}", .{name});
        const step = b.addInstallFileWithMode(
            b.path(src),
            dst,
            .{ .executable = true },
        );
        b.getInstallStep().dependOn(&step.step);
    }
}
