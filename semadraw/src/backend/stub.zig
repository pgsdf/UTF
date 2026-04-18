/// Disabled backend stub.
///
/// This file is compiled in place of a backend that was disabled at build
/// time via a feature flag (e.g. -Dvulkan=false, -Dgpu=false).
///
/// The backend module is still imported by backend.zig so the import graph
/// is structurally valid, but attempting to actually create this backend at
/// runtime will return error.BackendNotAvailable.
///
/// No external libraries are linked when this stub is active.

const std = @import("std");
const backend = @import("backend");

pub fn create(_: std.mem.Allocator) !backend.Backend {
    return error.BackendNotAvailable;
}
