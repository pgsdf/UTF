const std = @import("std");
const posix = std.posix;
const types = @import("types.zig");

// ============================================================================
// OSS ioctl constants (FreeBSD sys/soundcard.h)
// ============================================================================

// Direction bits for ioctl encoding
const IOC_OUT:  u32 = 0x40000000;
const IOC_IN:   u32 = 0x80000000;
const IOC_INOUT: u32 = IOC_IN | IOC_OUT;

fn ioc(dir: u32, typ: u8, nr: u8, size: u32) u32 {
    return dir | (size << 16) | (@as(u32, typ) << 8) | nr;
}
fn iowr(typ: u8, nr: u8, comptime T: type) u32 {
    return ioc(IOC_INOUT, typ, nr, @sizeOf(T));
}

// DSP ioctls — type 'P' = 0x50, type 'S' in some BSDs; FreeBSD uses 'P' = 0x50
// SNDCTL_DSP_SETFMT   = _IOWR('P', 5, int)
// SNDCTL_DSP_CHANNELS = _IOWR('P', 6, int)
// SNDCTL_DSP_SPEED    = _IOWR('P', 2, int)
const SNDCTL_DSP_SPEED:    u32 = iowr('P', 2, c_int);
const SNDCTL_DSP_SETFMT:   u32 = iowr('P', 5, c_int);
const SNDCTL_DSP_CHANNELS: u32 = iowr('P', 6, c_int);

// AFMT constants
pub const AFMT_S16_LE: u32 = 0x00000010;
pub const AFMT_S32_LE: u32 = 0x00001000;

extern "c" fn ioctl(fd: c_int, request: c_ulong, ...) c_int;

fn dspIoctl(fd: posix.fd_t, request: u32, value: *c_int) !void {
    const ret = ioctl(@intCast(fd), @intCast(request), value);
    if (ret < 0) return error.OssIoctlFailed;
}

// ============================================================================
// OssOutput
// ============================================================================

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

// ============================================================================
// OSS negotiation
// ============================================================================

/// Negotiate sample format, channel count, and sample rate with the OSS device.
///
/// Sets the DSP to the requested format, channels, and sample rate. The kernel
/// driver may adjust the values to the nearest supported setting — the actual
/// negotiated values are written back into `desc`.
///
/// Returns error.OssIoctlFailed if the device rejects any parameter.
/// Returns error.SampleRateMismatch if the hardware cannot deliver the
/// requested sample rate within a 5% tolerance.
pub fn negotiate(fd: posix.fd_t, desc: *types.StreamDescriptor) !void {
    // Set sample format.
    var fmt: c_int = @intCast(desc.format.ossAfmt());
    try dspIoctl(fd, SNDCTL_DSP_SETFMT, &fmt);
    // Verify the driver accepted the format.
    const accepted_afmt: u32 = @intCast(fmt);
    desc.format = afmtToFormat(accepted_afmt) catch return error.UnsupportedFormat;

    // Set channel count (1 or 2).
    var ch: c_int = @intCast(desc.channels);
    try dspIoctl(fd, SNDCTL_DSP_CHANNELS, &ch);
    desc.channels = @intCast(ch);

    // Set sample rate.
    var rate: c_int = @intCast(desc.sample_rate);
    try dspIoctl(fd, SNDCTL_DSP_SPEED, &rate);
    const negotiated_rate: u32 = @intCast(rate);

    // Accept if within 5% of the requested rate.
    const req = desc.sample_rate;
    const tolerance = req / 20; // 5%
    const diff = if (negotiated_rate > req) negotiated_rate - req else req - negotiated_rate;
    if (diff > tolerance) return error.SampleRateMismatch;

    desc.sample_rate = negotiated_rate;
}

fn afmtToFormat(afmt: u32) !types.StreamFormat {
    return switch (afmt) {
        AFMT_S16_LE => .s16le,
        AFMT_S32_LE => .s32le,
        else => error.UnsupportedFormat,
    };
}
