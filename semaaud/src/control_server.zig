const std = @import("std");
const posix = std.posix;
const types = @import("types.zig");
const state_mod = @import("state.zig");

pub const TargetView = struct {
    shared: *anyopaque,
    runtime: *state_mod.RuntimeState,
    event_ctx: *state_mod.EventContext,
};

pub const ControlServer = struct {
    fd: posix.socket_t,
    socket_path: []const u8,

    pub fn init(cfg: types.ControlServerConfig) !ControlServer {
        const fd = try posix.socket(posix.AF.UNIX, posix.SOCK.STREAM, 0);
        errdefer posix.close(fd);

        std.fs.cwd().deleteFile(cfg.socket_path) catch {};

        var addr: posix.sockaddr.un = .{
            .family = posix.AF.UNIX,
            .path = [_]u8{0} ** 104,
        };

        if (cfg.socket_path.len >= addr.path.len) return error.SocketPathTooLong;
        @memcpy(addr.path[0..cfg.socket_path.len], cfg.socket_path);

        try posix.bind(fd, @ptrCast(&addr), @sizeOf(posix.sockaddr.un));
        try posix.listen(fd, 8);

        return .{ .fd = fd, .socket_path = cfg.socket_path };
    }

    pub fn deinit(self: *ControlServer) void {
        posix.close(self.fd);
        std.fs.cwd().deleteFile(self.socket_path) catch {};
    }

    pub fn serveOneAcceptedControl(
        self: *ControlServer,
        allocator: std.mem.Allocator,
        targets: []TargetView,
    ) !void {
        const conn = try posix.accept(self.fd, null, null, 0);
        defer posix.close(conn);

        var buf: [256]u8 = undefined;
        const n = try posix.read(conn, &buf);
        if (n == 0) return;

        const line = std.mem.trim(u8, buf[0..n], " \r\n\t");

        if (std.mem.eql(u8, line, "describe")) {
            const body = try state_mod.renderControlCapabilitiesJson(allocator);
            defer std.heap.page_allocator.free(body);
            _ = try posix.write(conn, body);
            return;
        }

        if (std.mem.eql(u8, line, "targets")) {
            _ = try posix.write(conn, "default\nalt\n");
            return;
        }

        if (std.mem.eql(u8, line, "state")) {
            const body = try targets[0].runtime.renderJson(allocator);
            defer allocator.free(body);
            _ = try posix.write(conn, body);
            return;
        }

        if (std.mem.startsWith(u8, line, "state ")) {
            const target_name = line["state ".len..];
            for (targets) |t| {
                if (std.mem.eql(u8, t.runtime.target_name, target_name)) {
                    const body = try t.runtime.renderJson(allocator);
                    defer allocator.free(body);
                    _ = try posix.write(conn, body);
                    return;
                }
            }
            _ = try posix.write(conn, "error: unknown target\n");
            return;
        }

        if (std.mem.startsWith(u8, line, "retarget ")) {
            var parts = std.mem.splitScalar(u8, line["retarget ".len..], ' ');
            const target_name = parts.next() orelse {
                _ = try posix.write(conn, "error: missing target\n");
                return;
            };
            const arg = parts.next() orelse {
                _ = try posix.write(conn, "error: missing device\n");
                return;
            };

            for (targets) |t| {
                if (std.mem.eql(u8, t.runtime.target_name, target_name)) {
                    if (t.runtime.stream_active) {
                        _ = try posix.write(conn, "error: retarget requires idle state\n");
                        return;
                    }
                    t.runtime.selection = try state_mod.parseRetargetSelection(allocator, arg);
                    try t.runtime.writeJsonFile(allocator);
                    try state_mod.writeDeviceFile(allocator, t.runtime.*);
                    try state_mod.writeCurrentStreamFile(allocator, t.runtime.*);
                    _ = try posix.write(conn, "ok: retarget applied\n");
                    return;
                }
            }

            _ = try posix.write(conn, "error: unknown target\n");
            return;
        }

        _ = try posix.write(conn, "error: unsupported command\n");
    }
};
