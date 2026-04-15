const std = @import("std");
const posix = std.posix;

pub const OssOutput = struct {
    fd: posix.fd_t,

    pub fn open(path: []const u8) !OssOutput {
        const fd = try posix.open(path, .{ .ACCMODE = .WRONLY }, 0);
        return .{ .fd = fd };
    }

    pub fn close(self: *OssOutput) void {
        posix.close(self.fd);
    }
};
