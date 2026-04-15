const std = @import("std");
const aggregate = @import("device_aggregate.zig");
const semantic = @import("semantic.zig");

pub const PointerSmoothing = struct {
    allocator: std.mem.Allocator,
    states: std.ArrayList(State),

    const State = struct {
        device_name: []const u8,
        last_dx: i32,
        last_dy: i32,
    };

    pub fn init(allocator: std.mem.Allocator) PointerSmoothing {
        return .{
            .allocator = allocator,
            .states = .{},
        };
    }

    pub fn deinit(self: *PointerSmoothing) void {
        for (self.states.items) |s| self.allocator.free(s.device_name);
        self.states.deinit(self.allocator);
    }

    fn getOrCreate(self: *PointerSmoothing, device_name: []const u8) !*State {
        for (self.states.items) |*s| {
            if (std.mem.eql(u8, s.device_name, device_name)) return s;
        }
        const owned = try self.allocator.dupe(u8, device_name);
        try self.states.append(self.allocator, .{
            .device_name = owned,
            .last_dx = 0,
            .last_dy = 0,
        });
        return &self.states.items[self.states.items.len - 1];
    }

    pub fn smoothEvent(
        self: *PointerSmoothing,
        aggregator: *aggregate.Aggregator,
        event: semantic.SemanticEvent,
    ) !semantic.SemanticEvent {
        switch (event) {
            .mouse_move => |e| {
                const mapping = aggregator.findForPath(e.path) orelse return event;
                const state = try self.getOrCreate(mapping.stable_name);

                const smoothed_dx = @divTrunc(e.dx + state.last_dx, 2);
                const smoothed_dy = @divTrunc(e.dy + state.last_dy, 2);

                state.last_dx = e.dx;
                state.last_dy = e.dy;

                return .{
                    .mouse_move = .{
                        .path = e.path,
                        .dx = smoothed_dx,
                        .dy = smoothed_dy,
                    },
                };
            },
            else => return event,
        }
    }
};
