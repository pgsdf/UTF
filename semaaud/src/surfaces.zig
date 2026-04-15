const std = @import("std");

pub fn baseDir(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}", .{target_name});
}
pub fn streamDir(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/stream", .{target_name});
}
pub fn identityPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/identity", .{target_name});
}
pub fn versionPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/version", .{target_name});
}
pub fn backendPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/backend", .{target_name});
}
pub fn devicePath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/device", .{target_name});
}
pub fn policyPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/policy", .{target_name});
}
pub fn policyStatePath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/policy-state", .{target_name});
}
pub fn policyValidPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/policy-valid", .{target_name});
}
pub fn policyErrorsPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/policy-errors", .{target_name});
}
pub fn statePath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/state", .{target_name});
}
pub fn capabilitiesPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/capabilities", .{target_name});
}
pub fn controlPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/control", .{target_name});
}
pub fn controlCapabilitiesPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/control-capabilities", .{target_name});
}
pub fn lastEventPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/last-event", .{target_name});
}
pub fn streamCurrentPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/stream/current", .{target_name});
}
pub fn streamEventsPath(allocator: std.mem.Allocator, target_name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "/tmp/draw/audio/{s}/stream/events", .{target_name});
}
