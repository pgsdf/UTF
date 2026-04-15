const std = @import("std");
const SemanticEvent = @import("semantic.zig").SemanticEvent;

pub const EventQueue = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},
    list: std.ArrayList(SemanticEvent),

    pub fn init(allocator: std.mem.Allocator) EventQueue {
        return .{ .allocator = allocator, .list = .{} };
    }

    pub fn deinit(self: *EventQueue) void {
        self.list.deinit(self.allocator);
    }

    pub fn push(self: *EventQueue, event: SemanticEvent) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.list.append(self.allocator, event);
    }

    pub fn drainTo(self: *EventQueue, out: *std.ArrayList(SemanticEvent), allocator: std.mem.Allocator) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.list.items) |event| try out.append(allocator, event);
        self.list.clearRetainingCapacity();
    }
};
