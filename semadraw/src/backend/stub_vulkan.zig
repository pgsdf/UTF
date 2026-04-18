/// Stub for the vulkan backend — disabled at build time.
/// Returns error.BackendNotAvailable if called at runtime.
const std = @import("std");
const backend = @import("backend");
pub fn create(_: std.mem.Allocator) !backend.Backend {
    return error.BackendNotAvailable;
}
