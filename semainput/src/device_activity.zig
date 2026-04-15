const std = @import("std");

pub const ActivityRecord = struct {
    path: []const u8,
    last_event_ns: u64,
    correlated_pointer_hits: u32,
};

pub const ActivityTracker = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},
    records: std.ArrayList(ActivityRecord),

    pub fn init(allocator: std.mem.Allocator) ActivityTracker {
        return .{ .allocator = allocator, .records = .{} };
    }

    pub fn deinit(self: *ActivityTracker) void {
        for (self.records.items) |r| self.allocator.free(r.path);
        self.records.deinit(self.allocator);
    }

    fn getOrCreate(self: *ActivityTracker, path: []const u8) !*ActivityRecord {
        for (self.records.items) |*r| {
            if (std.mem.eql(u8, r.path, path)) return r;
        }
        const owned = try self.allocator.dupe(u8, path);
        try self.records.append(self.allocator, .{
            .path = owned,
            .last_event_ns = 0,
            .correlated_pointer_hits = 0,
        });
        return &self.records.items[self.records.items.len - 1];
    }

    pub fn noteEvent(self: *ActivityTracker, path: []const u8, now_ns: u64) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        const rec = try self.getOrCreate(path);
        rec.last_event_ns = now_ns;
    }

    pub fn notePointerCorrelation(self: *ActivityTracker, path: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        const rec = try self.getOrCreate(path);
        rec.correlated_pointer_hits += 1;
    }

    pub fn lastEventNs(self: *ActivityTracker, path: []const u8) ?u64 {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.records.items) |r| {
            if (std.mem.eql(u8, r.path, path)) return r.last_event_ns;
        }
        return null;
    }

    pub fn pointerCorrelationHits(self: *ActivityTracker, path: []const u8) u32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.records.items) |r| {
            if (std.mem.eql(u8, r.path, path)) return r.correlated_pointer_hits;
        }
        return 0;
    }
};
