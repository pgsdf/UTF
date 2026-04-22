const std = @import("std");
const posix = std.posix;
const backend = @import("backend");
const bsdinput = @import("bsdinput");

const log = std.log.scoped(.drawfs_backend);

// ioctl via libc (works on both Linux and FreeBSD)
extern "c" fn ioctl(fd: c_int, request: c_ulong, ...) c_int;

fn doIoctl(fd: posix.fd_t, request: u32, arg: usize) c_int {
    return ioctl(@intCast(fd), @intCast(request), arg);
}

// ============================================================================
// drawfs protocol constants and structures
// ============================================================================

const DRAWFS_MAGIC: u32 = 0x31575244; // 'DRW1' little-endian
const DRAWFS_VERSION: u16 = 0x0100; // v1.0
const DRAWFS_FRAME_HDR_SIZE: usize = 16;
const DRAWFS_MSG_HDR_SIZE: usize = 16;

// Message types
const REQ_HELLO: u16 = 0x0001;
const REQ_DISPLAY_LIST: u16 = 0x0010;
const REQ_DISPLAY_OPEN: u16 = 0x0011;
const REQ_SURFACE_CREATE: u16 = 0x0020;
const REQ_SURFACE_DESTROY: u16 = 0x0021;
const REQ_SURFACE_PRESENT: u16 = 0x0022;

const RPL_HELLO: u16 = 0x8001;
const RPL_DISPLAY_LIST: u16 = 0x8010;
const RPL_DISPLAY_OPEN: u16 = 0x8011;
const RPL_SURFACE_CREATE: u16 = 0x8020;
const RPL_SURFACE_DESTROY: u16 = 0x8021;
const RPL_SURFACE_PRESENT: u16 = 0x8022;
const EVT_SURFACE_PRESENTED: u16 = 0x9002;

// Pixel formats
const FMT_XRGB8888: u32 = 1;

// ============================================================================
// ioctl encoding helpers
// ============================================================================
//
// BSD/Linux ioctl command encoding (from sys/ioccom.h):
//   Bits 31-30: Direction (0=none, 1=write, 2=read, 3=read+write)
//   Bits 29-16: Size of the data structure (14 bits, max 16383 bytes)
//   Bits 15-8:  Type (magic character identifying the driver)
//   Bits 7-0:   Command number
//
// _IOWR('D', 0x02, struct) means: read+write, type='D', cmd=0x02, size=sizeof(struct)

const IOC_VOID: u32 = 0x20000000; // no parameters
const IOC_OUT: u32 = 0x40000000; // copy out (read)
const DRAWFS_EVT_KEY: u16 = 0x9010; // from drawfs_proto.h
const IOC_IN: u32 = 0x80000000; // copy in (write)
const IOC_INOUT: u32 = IOC_IN | IOC_OUT; // read+write (0xC0000000)

/// Computes ioctl command number at comptime, matching _IOC/_IOWR macros.
/// This ensures the encoding stays correct if struct size changes.
fn ioc(dir: u32, typ: u8, nr: u8, comptime T: type) u32 {
    const size: u32 = @sizeOf(T);
    return dir | (size << 16) | (@as(u32, typ) << 8) | nr;
}

/// _IOWR equivalent: read+write ioctl
fn iowr(typ: u8, nr: u8, comptime T: type) u32 {
    return ioc(IOC_INOUT, typ, nr, T);
}

const MapSurfaceReq = extern struct {
    status: i32,
    surface_id: u32,
    stride_bytes: u32,
    bytes_total: u32,
};

// Computed at comptime: _IOWR('D', 0x02, struct drawfs_map_surface)
// If MapSurfaceReq size changes, this will automatically update.
const DRAWFSGIOC_MAP_SURFACE: u32 = iowr('D', 0x02, MapSurfaceReq);

// Compile-time verification that our encoding matches the expected value
comptime {
    // Expected: 0xC0104402 = direction(0xC0) | size(0x10=16) | type('D'=0x44) | cmd(0x02)
    if (DRAWFSGIOC_MAP_SURFACE != 0xC0104402) {
        @compileError("DRAWFSGIOC_MAP_SURFACE encoding mismatch - struct size may have changed");
    }
    if (@sizeOf(MapSurfaceReq) != 16) {
        @compileError("MapSurfaceReq size mismatch - expected 16 bytes");
    }
}

// DRAWFSGIOC_BLIT_TO_EFIFB — copy surface pixels to the EFI framebuffer.
// _IOW('D', 0x04, struct drawfs_blit_to_efifb)
const BlitToEfifb = extern struct {
    src:        u64,    // userspace pointer (const uint8_t *)
    src_stride: u32,
    width:      u32,
    height:     u32,
    dst_x:      u32,
    dst_y:      u32,
    _pad:       u32 = 0,
};
const DRAWFSGIOC_BLIT_TO_EFIFB: u32 = ioc(IOC_IN, 'D', 0x04, BlitToEfifb);

// DRAWFSGIOC_GET_EFIFB_INFO — query EFI framebuffer geometry.
// _IOR('D', 0x05, struct drawfs_efifb_info)
const EfifbInfo = extern struct {
    fb_size:   u64,
    fb_width:  u32,
    fb_height: u32,
    fb_stride: u32,
    fb_bpp:    u32,
    _pad:      u32 = 0,
};
const DRAWFSGIOC_GET_EFIFB_INFO: u32 = ioc(IOC_OUT, 'D', 0x05, EfifbInfo);

// ============================================================================
// Protocol helpers
// ============================================================================

fn align4(n: u32) u32 {
    return (n + 3) & ~@as(u32, 3);
}

fn makeFrame(allocator: std.mem.Allocator, frame_id: u32, msg_type: u16, msg_id: u32, payload: []const u8) ![]u8 {
    const msg_bytes = align4(@as(u32, @intCast(DRAWFS_MSG_HDR_SIZE + payload.len)));
    const frame_bytes = align4(@as(u32, @intCast(DRAWFS_FRAME_HDR_SIZE)) + msg_bytes);

    const buf = try allocator.alloc(u8, frame_bytes);
    @memset(buf, 0);

    // Frame header
    std.mem.writeInt(u32, buf[0..4], DRAWFS_MAGIC, .little);
    std.mem.writeInt(u16, buf[4..6], DRAWFS_VERSION, .little);
    std.mem.writeInt(u16, buf[6..8], DRAWFS_FRAME_HDR_SIZE, .little);
    std.mem.writeInt(u32, buf[8..12], frame_bytes, .little);
    std.mem.writeInt(u32, buf[12..16], frame_id, .little);

    // Message header
    std.mem.writeInt(u16, buf[16..18], msg_type, .little);
    std.mem.writeInt(u16, buf[18..20], 0, .little); // flags
    std.mem.writeInt(u32, buf[20..24], msg_bytes, .little);
    std.mem.writeInt(u32, buf[24..28], msg_id, .little);
    std.mem.writeInt(u32, buf[28..32], 0, .little); // reserved

    // Payload
    if (payload.len > 0) {
        @memcpy(buf[32..][0..payload.len], payload);
    }

    return buf;
}

fn readFrame(fd: posix.fd_t, buf: []u8) !usize {
    // Poll for data first (kernel requires poll before read)
    var poll_fds = [_]posix.pollfd{
        .{ .fd = fd, .events = posix.POLL.IN, .revents = 0 },
    };
    const poll_result = posix.poll(&poll_fds, 5000) catch |err| {
        log.err("poll failed: {}", .{err});
        return err;
    };
    if (poll_result == 0) {
        log.err("poll timeout waiting for frame", .{});
        return error.Timeout;
    }
    if ((poll_fds[0].revents & posix.POLL.IN) == 0) {
        log.err("poll returned but no POLLIN: revents=0x{x}", .{poll_fds[0].revents});
        return error.PollError;
    }

    // Read entire frame in one syscall (kernel expects atomic read)
    const n = posix.read(fd, buf) catch |err| {
        log.err("read failed: {}", .{err});
        return err;
    };
    if (n == 0) {
        return error.EndOfFile;
    }

    // Validate header
    if (n < DRAWFS_FRAME_HDR_SIZE) {
        log.err("short read: {} bytes", .{n});
        return error.ShortRead;
    }

    const magic = std.mem.readInt(u32, buf[0..4], .little);
    if (magic != DRAWFS_MAGIC) {
        log.err("invalid magic: 0x{x:08}", .{magic});
        return error.InvalidMagic;
    }

    const frame_bytes = std.mem.readInt(u32, buf[8..12], .little);
    if (n < frame_bytes) {
        log.err("incomplete frame: got {}, expected {}", .{ n, frame_bytes });
        return error.IncompleteFrame;
    }

    return n;
}

fn parseReply(buf: []const u8) struct { msg_type: u16, msg_id: u32, payload: []const u8 } {
    const msg_type = std.mem.readInt(u16, buf[16..18], .little);
    const msg_bytes = std.mem.readInt(u32, buf[20..24], .little);
    const msg_id = std.mem.readInt(u32, buf[24..28], .little);
    const payload_len = msg_bytes - DRAWFS_MSG_HDR_SIZE;
    const payload = buf[32..][0..payload_len];
    return .{ .msg_type = msg_type, .msg_id = msg_id, .payload = payload };
}

// ============================================================================
// Render state
// ============================================================================

/// Per-session render state. Resets to defaults on RESET opcode or new session.
/// Does not leak between client sessions since each client gets its own backend.
pub const RenderState = struct {
    /// Blend mode. 0=SrcOver, 1=Src, 2=Clear, 3=Add.
    blend_mode: u32 = 0,
    /// Antialiasing enabled. When true, filled edges use alpha blending
    /// for sub-pixel coverage on the outer pixel ring.
    antialias: bool = false,
    /// Stroke join style. 0=Miter, 1=Bevel, 2=Round.
    stroke_join: u32 = 0,
    /// Stroke cap style. 0=Butt, 1=Square, 2=Round.
    stroke_cap: u32 = 0,
    /// Miter limit for miter joins (default 4.0).
    miter_limit: f32 = 4.0,

    pub fn reset(self: *RenderState) void {
        self.* = .{};
    }
};

// ============================================================================
// DrawfsBackend
// ============================================================================

pub const DrawfsBackend = struct {
    allocator: std.mem.Allocator,
    fd: posix.fd_t,
    frame_id: u32,
    msg_id: u32,

    // Display info
    display_id: u32,
    display_handle: u32,
    display_width: u32,
    display_height: u32,

    // Surface info
    surface_id: u32,
    surface_stride: u32,
    surface_bytes: u32,
    surface_map: ?[]align(4096) u8,

    // Render state
    width: u32,
    height: u32,
    frame_count: u64,
    render_state: RenderState,

    // EFI framebuffer info (zeroed if not available)
    efifb_width:  u32,
    efifb_height: u32,
    efifb_stride: u32,
    efifb_bpp:    u32,
    efifb_avail:  bool,

    // Read buffer for protocol
    read_buf: [4096]u8,
    injected_keys: [32]backend.KeyEvent = undefined,
    injected_keys_len: usize = 0,

    // Retained for ABI compatibility with the Backend vtable. Always null
    // under -b drawfs — input arrives via DRAWFSGIOC_INJECT_INPUT from
    // semainputd, not via a local evdev/libinput reader. See init() for
    // the rationale.
    input: ?*bsdinput.BsdInput,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, device_path: []const u8) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.* = .{
            .allocator = allocator,
            .fd = -1,
            .frame_id = 1,
            .msg_id = 1,
            .display_id = 0,
            .display_handle = 0,
            .display_width = 0,
            .display_height = 0,
            .surface_id = 0,
            .surface_stride = 0,
            .surface_bytes = 0,
            .surface_map = null,
            .width = 0,
            .height = 0,
            .frame_count = 0,
            .render_state = .{},
            .read_buf = undefined,
            .input = null,
            .efifb_width  = 0,
            .efifb_height = 0,
            .efifb_stride = 0,
            .efifb_bpp    = 0,
            .efifb_avail  = false,
        };

        // Open device
        log.info("opening {s}...", .{device_path});
        self.fd = posix.open(device_path, .{ .ACCMODE = .RDWR }, 0) catch {
            log.err("failed to open {s}", .{device_path});
            return error.OpenFailed;
        };
        errdefer posix.close(self.fd);
        log.info("opened {s}, fd={}", .{ device_path, self.fd });

        // Protocol handshake
        log.info("sending HELLO...", .{});
        try self.doHello();
        log.info("HELLO complete, sending DISPLAY_LIST...", .{});
        try self.doDisplayList();
        log.info("DISPLAY_LIST complete, sending DISPLAY_OPEN...", .{});
        try self.doDisplayOpen();

        log.info("connected to drawfs: display {}x{}", .{ self.display_width, self.display_height });

        // Probe EFI framebuffer availability
        self.probeEfifb();

        // Input is delivered via DRAWFSGIOC_INJECT_INPUT from semainputd — the
        // drawfs backend does not open evdev devices directly. Opening them
        // here would compete with semainputd for exclusive access (libinput
        // grabs by default) and starve its event stream. Events arrive as
        // EVT_KEY / EVT_POINTER / EVT_SCROLL / EVT_TOUCH frames on self.fd
        // and are drained into self.injected_keys by drainInjectedEvents().
        self.input = null;

        return self;
    }

    pub fn initDefault(allocator: std.mem.Allocator) !*Self {
        return init(allocator, "/dev/draw");
    }

    fn nextFrameId(self: *Self) u32 {
        const id = self.frame_id;
        self.frame_id +%= 1;
        return id;
    }

    fn nextMsgId(self: *Self) u32 {
        const id = self.msg_id;
        self.msg_id +%= 1;
        return id;
    }

    /// Parse an EVT_KEY frame into the backend's KeyEvent representation.
    /// Caller must have already verified msg_type == DRAWFS_EVT_KEY and
    /// that the frame contains the full 24-byte payload.
    fn parseEvtKey(frame: []const u8) backend.KeyEvent {
        // EVT_KEY payload is at offset 32: surface_id(4), code(4), state(4),
        // mods(4), ts(8). We only need code/state/mods.
        const p = frame[32..];
        const code  = std.mem.readInt(u32, p[4..8],  .little);
        const state = std.mem.readInt(u32, p[8..12], .little);
        const mods  = @as(u8, @truncate(std.mem.readInt(u32, p[12..16], .little)));
        return .{
            .key_code  = code,
            .modifiers = mods,
            .pressed   = state == 1,
        };
    }

    /// Stash an EVT_KEY frame in the injected_keys buffer for later
    /// delivery via getKeyEvents(). Silently drops the event if the
    /// buffer is full — the buffer is large enough that this requires
    /// several hundred keypresses between compositor frames, which is
    /// not a case we need to handle gracefully.
    fn stashEvtKey(self: *Self, frame: []const u8, n: usize) void {
        if (n < 32 + 20) return; // short frame, drop
        if (self.injected_keys_len >= backend.MAX_KEY_EVENTS) {
            std.debug.print("drawfs-backend: stash buffer full, dropping key\n", .{});
            return;
        }
        const ev = parseEvtKey(frame);
        self.injected_keys[self.injected_keys_len] = ev;
        self.injected_keys_len += 1;
        // TEMPORARY DIAGNOSTIC: log every key we stash, and who stashed it.
        // Remove once the key-loss issue is understood.
        std.debug.print("drawfs-backend: stash code={d} state={s} len={d}\n",
            .{ ev.key_code, if (ev.pressed) "down" else "up", self.injected_keys_len });
    }

    fn sendAndRecv(self: *Self, msg_type: u16, payload: []const u8, expected_reply: u16) ![]const u8 {
        const frame_id = self.nextFrameId();
        const msg_id = self.nextMsgId();

        const frame = try makeFrame(self.allocator, frame_id, msg_type, msg_id, payload);
        defer self.allocator.free(frame);

        // Send frame
        var sent: usize = 0;
        while (sent < frame.len) {
            sent += posix.write(self.fd, frame[sent..]) catch |err| {
                return err;
            };
        }

        // Read reply. The fd is multiplexed: protocol replies, EVT_SURFACE_PRESENTED
        // events emitted by our own SURFACE_PRESENT requests, and EVT_KEY /
        // EVT_POINTER / EVT_SCROLL / EVT_TOUCH events injected by semainputd
        // via DRAWFSGIOC_INJECT_INPUT all arrive on this channel. We must
        // handle all three: the reply we're waiting for, the frame events
        // that are acknowledgements of our own activity, and the injected
        // input events that are someone else's traffic passing through our
        // queue.
        while (true) {
            const n = try readFrame(self.fd, &self.read_buf);
            const reply = parseReply(self.read_buf[0..n]);

            // Skip compositor-acknowledgement events.
            if (reply.msg_type == EVT_SURFACE_PRESENTED) {
                continue;
            }

            // Stash input events in injected_keys so drainInjectedEvents can
            // return them later. Without this, an EVT_KEY arriving between
            // our write and the kernel's reply would cause UnexpectedReply
            // and silently swallow the keystroke — the root cause of the
            // "sometimes first press is lost" behaviour.
            if (reply.msg_type == DRAWFS_EVT_KEY) {
                self.stashEvtKey(self.read_buf[0..n], n);
                continue;
            }

            if (reply.msg_type != expected_reply) {
                log.err("expected reply 0x{x:04}, got 0x{x:04}", .{ expected_reply, reply.msg_type });
                return error.UnexpectedReply;
            }

            return reply.payload;
        }
    }

    fn doHello(self: *Self) !void {
        var payload: [12]u8 = undefined;
        std.mem.writeInt(u16, payload[0..2], 1, .little); // client_major
        std.mem.writeInt(u16, payload[2..4], 0, .little); // client_minor
        std.mem.writeInt(u32, payload[4..8], 0, .little); // client_flags
        std.mem.writeInt(u32, payload[8..12], 4096, .little); // max_reply_bytes

        const reply = try self.sendAndRecv(REQ_HELLO, &payload, RPL_HELLO);

        if (reply.len < 16) return error.InvalidReply;

        const status = std.mem.readInt(i32, reply[0..4], .little);
        if (status != 0) {
            log.err("HELLO failed: status={}", .{status});
            return error.HelloFailed;
        }

        const server_major = std.mem.readInt(u16, reply[4..6], .little);
        const server_minor = std.mem.readInt(u16, reply[6..8], .little);
        log.info("drawfs protocol v{}.{}", .{ server_major, server_minor });
    }

    fn doDisplayList(self: *Self) !void {
        const reply = try self.sendAndRecv(REQ_DISPLAY_LIST, &[_]u8{}, RPL_DISPLAY_LIST);

        if (reply.len < 8) return error.InvalidReply;

        const status = std.mem.readInt(i32, reply[0..4], .little);
        if (status != 0) {
            log.err("DISPLAY_LIST failed: status={}", .{status});
            return error.DisplayListFailed;
        }

        const count = std.mem.readInt(u32, reply[4..8], .little);
        if (count == 0) return error.NoDisplays;

        // Parse first display descriptor (20 bytes each: display_id, width, height, refresh_mhz, flags)
        if (reply.len < 8 + 20) return error.InvalidReply;

        self.display_id = std.mem.readInt(u32, reply[8..12], .little);
        self.display_width = std.mem.readInt(u32, reply[12..16], .little);
        self.display_height = std.mem.readInt(u32, reply[16..20], .little);
        const refresh_mhz = std.mem.readInt(u32, reply[20..24], .little);

        log.info("display {}: {}x{}@{}mHz", .{
            self.display_id,
            self.display_width,
            self.display_height,
            refresh_mhz,
        });
    }

    fn doDisplayOpen(self: *Self) !void {
        var payload: [4]u8 = undefined;
        std.mem.writeInt(u32, payload[0..4], self.display_id, .little);

        const reply = try self.sendAndRecv(REQ_DISPLAY_OPEN, &payload, RPL_DISPLAY_OPEN);

        if (reply.len < 12) return error.InvalidReply;

        const status = std.mem.readInt(i32, reply[0..4], .little);
        if (status != 0) {
            log.err("DISPLAY_OPEN failed: status={}", .{status});
            return error.DisplayOpenFailed;
        }

        self.display_handle = std.mem.readInt(u32, reply[4..8], .little);
        log.info("display opened: handle={}", .{self.display_handle});
    }

    fn createSurface(self: *Self, width: u32, height: u32) !void {
        var payload: [16]u8 = undefined;
        std.mem.writeInt(u32, payload[0..4], width, .little);
        std.mem.writeInt(u32, payload[4..8], height, .little);
        std.mem.writeInt(u32, payload[8..12], FMT_XRGB8888, .little);
        std.mem.writeInt(u32, payload[12..16], 0, .little); // flags

        const reply = try self.sendAndRecv(REQ_SURFACE_CREATE, &payload, RPL_SURFACE_CREATE);

        if (reply.len < 16) return error.InvalidReply;

        const status = std.mem.readInt(i32, reply[0..4], .little);
        if (status != 0) {
            log.err("SURFACE_CREATE failed: status={}", .{status});
            return error.SurfaceCreateFailed;
        }

        self.surface_id = std.mem.readInt(u32, reply[4..8], .little);
        self.surface_stride = std.mem.readInt(u32, reply[8..12], .little);
        self.surface_bytes = std.mem.readInt(u32, reply[12..16], .little);
        self.width = width;
        self.height = height;

        log.info("surface created: id={} stride={} bytes={}", .{
            self.surface_id,
            self.surface_stride,
            self.surface_bytes,
        });

        // Map the surface
        try self.mapSurface();
    }

    fn mapSurface(self: *Self) !void {
        var req = MapSurfaceReq{
            .status = 0,
            .surface_id = self.surface_id,
            .stride_bytes = 0,
            .bytes_total = 0,
        };

        // Call ioctl
        const result = doIoctl(self.fd, DRAWFSGIOC_MAP_SURFACE, @intFromPtr(&req));
        if (result < 0) {
            log.err("MAP_SURFACE ioctl failed: {}", .{result});
            return error.MapSurfaceFailed;
        }

        if (req.status != 0) {
            log.err("MAP_SURFACE status={}", .{req.status});
            return error.MapSurfaceFailed;
        }

        // mmap the surface
        const map = posix.mmap(
            null,
            self.surface_bytes,
            posix.PROT.READ | posix.PROT.WRITE,
            .{ .TYPE = .SHARED },
            self.fd,
            0,
        ) catch |err| {
            log.err("mmap failed: {}", .{err});
            return error.MmapFailed;
        };

        self.surface_map = @as([*]align(4096) u8, @ptrCast(@alignCast(map)))[0..self.surface_bytes];
        log.info("surface mapped: {} bytes at {*}", .{ self.surface_bytes, self.surface_map.?.ptr });
    }

    fn destroySurface(self: *Self) void {
        if (self.surface_map) |m| {
            posix.munmap(m);
            self.surface_map = null;
        }

        if (self.surface_id != 0) {
            var payload: [4]u8 = undefined;
            std.mem.writeInt(u32, payload[0..4], self.surface_id, .little);

            _ = self.sendAndRecv(REQ_SURFACE_DESTROY, &payload, RPL_SURFACE_DESTROY) catch {};
            self.surface_id = 0;
        }
    }

    /// Query the kernel for EFI framebuffer availability and geometry.
    /// Non-fatal — if the ioctl fails (ENODEV) we stay in swap-only mode.
    fn probeEfifb(self: *Self) void {
        var info = std.mem.zeroes(EfifbInfo);
        const result = doIoctl(self.fd, DRAWFSGIOC_GET_EFIFB_INFO, @intFromPtr(&info));
        if (result != 0) {
            log.info("efifb not available (ioctl returned {})", .{result});
            return;
        }
        self.efifb_width  = info.fb_width;
        self.efifb_height = info.fb_height;
        self.efifb_stride = info.fb_stride;
        self.efifb_bpp    = info.fb_bpp;
        self.efifb_avail  = true;
        log.info("efifb available: {}x{} stride={} bpp={}", .{
            info.fb_width, info.fb_height, info.fb_stride, info.fb_bpp,
        });
    }

    /// Blit the mmap'd surface buffer to the EFI framebuffer via kernel ioctl.
    /// Called after each successful present() when efifb is available.
    fn blitToEfifb(self: *Self) void {
        if (!self.efifb_avail) return;
        const map = self.surface_map orelse return;

        const req = BlitToEfifb{
            .src        = @intFromPtr(map.ptr),
            .src_stride = self.surface_stride,
            .width      = @min(self.width, self.efifb_width),
            .height     = @min(self.height, self.efifb_height),
            .dst_x      = 0,
            .dst_y      = 0,
        };

        const result = doIoctl(self.fd, DRAWFSGIOC_BLIT_TO_EFIFB, @intFromPtr(&req));
        if (result != 0) {
            log.warn("BLIT_TO_EFIFB failed: {}", .{result});
        }
    }

    fn present(self: *Self) !void {
        if (self.surface_id == 0) return error.NoSurface;

        var payload: [16]u8 = undefined;
        std.mem.writeInt(u32, payload[0..4], self.surface_id, .little);
        std.mem.writeInt(u32, payload[4..8], 0, .little); // flags
        std.mem.writeInt(u64, payload[8..16], self.frame_count, .little); // cookie

        const reply = try self.sendAndRecv(REQ_SURFACE_PRESENT, &payload, RPL_SURFACE_PRESENT);

        if (reply.len < 4) return error.InvalidReply;

        const status = std.mem.readInt(i32, reply[0..4], .little);
        if (status != 0) {
            log.warn("SURFACE_PRESENT status={}", .{status});
        }
    }

    pub fn deinit(self: *Self) void {
        // Cleanup evdev input
        if (self.input) |inp| {
            inp.deinit();
        }

        self.destroySurface();

        if (self.fd >= 0) {
            posix.close(self.fd);
            self.fd = -1;
        }

        self.allocator.destroy(self);
    }

    // ========================================================================
    // Backend interface implementation
    // ========================================================================

    fn getCapabilitiesImpl(ctx: *anyopaque) backend.Capabilities {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return .{
            .name = "drawfs",
            .max_width = if (self.display_width > 0) self.display_width else 8192,
            .max_height = if (self.display_height > 0) self.display_height else 8192,
            .supports_aa = true,
            .hardware_accelerated = false,
            .can_present = true,
        };
    }

    fn initFramebufferImpl(ctx: *anyopaque, config: backend.FramebufferConfig) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        // Destroy existing surface if different size
        if (self.surface_id != 0 and (self.width != config.width or self.height != config.height)) {
            self.destroySurface();
        }

        // Create surface if needed
        if (self.surface_id == 0) {
            try self.createSurface(config.width, config.height);
        }
    }

    fn renderImpl(ctx: *anyopaque, request: backend.RenderRequest) anyerror!backend.RenderResult {
        const self: *Self = @ptrCast(@alignCast(ctx));
        const start = std.time.nanoTimestamp();

        const buffer = self.surface_map orelse {
            return backend.RenderResult.failure(request.surface_id, "no surface mapped");
        };

        // Clear if requested (XRGB8888 format: B, G, R, X)
        if (request.clear_color) |color| {
            const r: u8 = @intFromFloat(@min(1.0, @max(0.0, color[0])) * 255.0);
            const g: u8 = @intFromFloat(@min(1.0, @max(0.0, color[1])) * 255.0);
            const b: u8 = @intFromFloat(@min(1.0, @max(0.0, color[2])) * 255.0);

            var i: usize = 0;
            while (i + 3 < buffer.len) : (i += 4) {
                buffer[i] = b;
                buffer[i + 1] = g;
                buffer[i + 2] = r;
                buffer[i + 3] = 0xFF; // X = opaque
            }
        }

        // Execute SDCS commands
        // For now, minimal SDCS parsing - just look for FILL_RECT
        self.executeSdcs(buffer, request.sdcs_data) catch |err| {
            return backend.RenderResult.failure(request.surface_id, @errorName(err));
        };

        // Present to drawfs
        self.present() catch |err| {
            log.warn("present failed: {}", .{err});
        };

        // Blit to EFI framebuffer for bare console display
        self.blitToEfifb();

        self.frame_count += 1;
        const end = std.time.nanoTimestamp();

        return backend.RenderResult.success(
            request.surface_id,
            self.frame_count,
            @intCast(end - start),
        );
    }

    fn executeSdcs(self: *Self, fb: []u8, data: []const u8) !void {
        if (data.len < 64) return; // Header too small

        // Skip SDCS header (64 bytes)
        var offset: usize = 64;

        // Process chunks
        while (offset + 32 <= data.len) {
            // ChunkHeader is 32 bytes
            const chunk_payload_bytes = std.mem.readInt(u64, data[offset + 24 ..][0..8], .little);
            offset += 32;

            if (offset + chunk_payload_bytes > data.len) break;

            // Process commands in chunk
            const chunk_end = offset + @as(usize, @intCast(chunk_payload_bytes));
            try self.executeChunkCommands(fb, data[offset..chunk_end]);

            // Align to 8 bytes for next chunk
            offset = chunk_end;
            offset = std.mem.alignForward(usize, offset, 8);
        }
    }

    fn executeChunkCommands(self: *Self, fb: []u8, commands: []const u8) !void {
        var offset: usize = 0;

        while (offset + 8 <= commands.len) {
            const opcode = std.mem.readInt(u16, commands[offset..][0..2], .little);
            const payload_len = std.mem.readInt(u32, commands[offset + 4 ..][0..4], .little);
            offset += 8;

            if (offset + payload_len > commands.len) break;

            const payload = commands[offset..][0..payload_len];

            // Execute command
            switch (opcode) {
                0x0001 => { // RESET — reset render state and clear any clip
                    self.render_state.reset();
                },
                0x0004 => { // SET_BLEND (4 bytes: u32 blend_mode)
                    if (payload.len >= 4) {
                        self.render_state.blend_mode = std.mem.readInt(u32, payload[0..4], .little);
                    }
                },
                0x0007 => { // SET_ANTIALIAS (4 bytes: u32 enabled)
                    if (payload.len >= 4) {
                        self.render_state.antialias = std.mem.readInt(u32, payload[0..4], .little) != 0;
                    }
                },
                0x0013 => { // SET_STROKE_JOIN (4 bytes: u32 join)
                    if (payload.len >= 4) {
                        self.render_state.stroke_join = std.mem.readInt(u32, payload[0..4], .little);
                    }
                },
                0x0014 => { // SET_STROKE_CAP (4 bytes: u32 cap)
                    if (payload.len >= 4) {
                        self.render_state.stroke_cap = std.mem.readInt(u32, payload[0..4], .little);
                    }
                },
                0x0015 => { // SET_MITER_LIMIT (4 bytes: f32 limit)
                    if (payload.len >= 4) {
                        self.render_state.miter_limit = readF32(payload[0..4]);
                    }
                },
                0x0010 => { // FILL_RECT (32 bytes: x, y, w, h, r, g, b, a)
                    if (payload.len >= 32) {
                        const x = readF32(payload[0..4]);
                        const y = readF32(payload[4..8]);
                        const w = readF32(payload[8..12]);
                        const h = readF32(payload[12..16]);
                        const r = readF32(payload[16..20]);
                        const g = readF32(payload[20..24]);
                        const b_val = readF32(payload[24..28]);
                        const a = readF32(payload[28..32]);

                        self.fillRect(fb, x, y, w, h, r, g, b_val, a);
                    }
                },
                0x0011 => { // STROKE_RECT (36 bytes: x, y, w, h, r, g, b, a, stroke_width)
                    if (payload.len >= 36) {
                        const x = readF32(payload[0..4]);
                        const y = readF32(payload[4..8]);
                        const w = readF32(payload[8..12]);
                        const h = readF32(payload[12..16]);
                        const r = readF32(payload[16..20]);
                        const g = readF32(payload[20..24]);
                        const b_val = readF32(payload[24..28]);
                        const a = readF32(payload[28..32]);
                        const stroke_width = readF32(payload[32..36]);

                        self.strokeRect(fb, x, y, w, h, r, g, b_val, a, stroke_width);
                    }
                },
                0x0012 => { // STROKE_LINE (36 bytes: x1, y1, x2, y2, r, g, b, a, stroke_width)
                    if (payload.len >= 36) {
                        const x1 = readF32(payload[0..4]);
                        const y1 = readF32(payload[4..8]);
                        const x2 = readF32(payload[8..12]);
                        const y2 = readF32(payload[12..16]);
                        const r = readF32(payload[16..20]);
                        const g = readF32(payload[20..24]);
                        const b_val = readF32(payload[24..28]);
                        const a = readF32(payload[28..32]);
                        const stroke_width = readF32(payload[32..36]);

                        self.strokeLine(fb, x1, y1, x2, y2, r, g, b_val, a, stroke_width);
                    }
                },
                0x00F0 => return, // END
                0x0030 => { // DRAW_GLYPH_RUN
                    // Payload layout (all little-endian):
                    //   [0..4)   base_x      f32
                    //   [4..8)   base_y      f32
                    //   [8..12)  r           f32
                    //   [12..16) g           f32
                    //   [16..20) b           f32
                    //   [20..24) a           f32
                    //   [24..28) cell_width  u32
                    //   [28..32) cell_height u32
                    //   [32..36) atlas_cols  u32
                    //   [36..40) atlas_width  u32
                    //   [40..44) atlas_height u32
                    //   [44..48) glyph_count u32
                    //   [48..48+glyph_count*12) glyphs: (index u32, x_off f32, y_off f32)
                    //   [48+glyph_count*12..)   atlas: atlas_width*atlas_height bytes (alpha)
                    if (payload.len < 48) break;

                    const base_x     = readF32(payload[0..4]);
                    const base_y     = readF32(payload[4..8]);
                    const gr         = readF32(payload[8..12]);
                    const gg         = readF32(payload[12..16]);
                    const gb         = readF32(payload[16..20]);
                    const ga         = readF32(payload[20..24]);
                    const cell_w     = std.mem.readInt(u32, payload[24..28], .little);
                    const cell_h     = std.mem.readInt(u32, payload[28..32], .little);
                    const atlas_cols = std.mem.readInt(u32, payload[32..36], .little);
                    const atlas_w    = std.mem.readInt(u32, payload[36..40], .little);
                    const atlas_h    = std.mem.readInt(u32, payload[40..44], .little);
                    const glyph_count = std.mem.readInt(u32, payload[44..48], .little);

                    if (cell_w == 0 or cell_h == 0 or atlas_cols == 0) break;
                    if (atlas_w == 0 or atlas_h == 0 or glyph_count == 0) break;

                    const glyphs_bytes: usize = @as(usize, glyph_count) * 12;
                    const atlas_bytes:  usize = @as(usize, atlas_w) * @as(usize, atlas_h);
                    if (payload.len < 48 + glyphs_bytes + atlas_bytes) break;

                    const glyphs_slice = payload[48 .. 48 + glyphs_bytes];
                    const atlas_data   = payload[48 + glyphs_bytes .. 48 + glyphs_bytes + atlas_bytes];

                    const cr8 = clampU8(gr);
                    const cg8 = clampU8(gg);
                    const cb8 = clampU8(gb);
                    const stride = self.surface_stride;
                    const fb_w = self.width;
                    const fb_h = self.height;

                    // Render each glyph.
                    var gi: usize = 0;
                    while (gi < glyph_count) : (gi += 1) {
                        const goff = gi * 12;
                        const glyph_index = std.mem.readInt(u32, glyphs_slice[goff..][0..4], .little);
                        const x_off = readF32(glyphs_slice[goff + 4 ..][0..4]);
                        const y_off = readF32(glyphs_slice[goff + 8 ..][0..4]);

                        // Atlas cell origin for this glyph.
                        const glyph_row = glyph_index / atlas_cols;
                        const glyph_col = glyph_index % atlas_cols;
                        // Unscaled glyph dimensions derived from atlas and cell dimensions.
                        // glyph_w = atlas_w / atlas_cols
                        // glyph_h = cell_h * glyph_w / cell_w  (preserves aspect via scale)
                        const glyph_w_u: usize = @as(usize, atlas_w) / @as(usize, atlas_cols);
                        const glyph_h_u: usize = if (cell_w > 0)
                            @as(usize, cell_h) * glyph_w_u / @as(usize, cell_w)
                            else glyph_w_u * 2;
                        const atlas_x: usize = @as(usize, glyph_col) * glyph_w_u;
                        const atlas_y: usize = @as(usize, glyph_row) * glyph_h_u;

                        // Destination top-left pixel (no transform matrix in drawfs backend).
                        const dst_x_f = base_x + x_off;
                        const dst_y_f = base_y + y_off;

                        // Derive pixel scale from glyph dimensions already computed above.
                        const glyph_scale: usize = if (glyph_w_u > 0)
                            @as(usize, cell_w) / glyph_w_u
                            else 1;

                        var py: usize = 0;
                        while (py < glyph_h_u) : (py += 1) {
                            var px: usize = 0;
                            while (px < glyph_w_u) : (px += 1) {
                                const src_x = atlas_x + px;
                                const src_y = atlas_y + py;
                                if (src_x >= atlas_w or src_y >= atlas_h) continue;

                                const glyph_alpha = atlas_data[src_y * @as(usize, atlas_w) + src_x];
                                if (glyph_alpha == 0) continue;

                                // Combine glyph alpha mask with color alpha.
                                const final_alpha: f32 =
                                    (@as(f32, @floatFromInt(glyph_alpha)) / 255.0) * ga;
                                const ca8 = clampU8(final_alpha);
                                if (ca8 == 0) continue;

                                // Expand each atlas pixel to glyph_scale x glyph_scale output pixels.
                                var sy: usize = 0;
                                while (sy < glyph_scale) : (sy += 1) {
                                    var sx: usize = 0;
                                    while (sx < glyph_scale) : (sx += 1) {
                                        const dx: isize = @as(isize, @intFromFloat(dst_x_f)) +
                                                          @as(isize, @intCast(px * glyph_scale + sx));
                                        const dy: isize = @as(isize, @intFromFloat(dst_y_f)) +
                                                          @as(isize, @intCast(py * glyph_scale + sy));

                                        if (dx < 0 or dy < 0) continue;
                                        if (dx >= @as(isize, @intCast(fb_w)) or
                                            dy >= @as(isize, @intCast(fb_h))) continue;

                                        const idx = @as(usize, @intCast(dy)) * stride +
                                                    @as(usize, @intCast(dx)) * 4;
                                        writePixel(fb, idx, cr8, cg8, cb8, ca8,
                                                   self.render_state.blend_mode);
                                    }
                                }
                            }
                        }
                    }
                },
                else => {}, // Ignore unknown opcodes
            }

            // Align to 8 bytes
            offset += payload_len;
            const record_bytes = 8 + payload_len;
            const pad = (8 - (record_bytes % 8)) % 8;
            offset += pad;
        }
    }

    fn fillRect(self: *Self, fb: []u8, x: f32, y: f32, w: f32, h: f32, r: f32, g: f32, b_col: f32, a: f32) void {
        const fb_w = self.width;
        const fb_h = self.height;

        // Clamp to framebuffer bounds
        const x0: i32 = @intFromFloat(@max(0, x));
        const y0: i32 = @intFromFloat(@max(0, y));
        const x1: i32 = @intFromFloat(@min(@as(f32, @floatFromInt(fb_w)), x + w));
        const y1: i32 = @intFromFloat(@min(@as(f32, @floatFromInt(fb_h)), y + h));

        if (x0 >= x1 or y0 >= y1) return;

        const stride = self.surface_stride;

        // Clear mode: zero out pixels (transparent black).
        if (self.render_state.blend_mode == 2) {
            var py: i32 = y0;
            while (py < y1) : (py += 1) {
                var px: i32 = x0;
                while (px < x1) : (px += 1) {
                    const idx = @as(usize, @intCast(py)) * stride + @as(usize, @intCast(px)) * 4;
                    if (idx + 3 < fb.len) {
                        fb[idx] = 0;
                        fb[idx + 1] = 0;
                        fb[idx + 2] = 0;
                        fb[idx + 3] = 0;
                    }
                }
            }
            return;
        }

        const cr = clampU8(r);
        const cg = clampU8(g);
        const cb = clampU8(b_col);
        const ca = clampU8(a);

        // Inner fill (all modes other than Clear).
        var py: i32 = y0;
        while (py < y1) : (py += 1) {
            var px: i32 = x0;
            while (px < x1) : (px += 1) {
                const idx = @as(usize, @intCast(py)) * stride + @as(usize, @intCast(px)) * 4;
                if (idx + 3 < fb.len) {
                    writePixel(fb, idx, cr, cg, cb, ca, self.render_state.blend_mode);
                }
            }
        }

        // Antialias: blend outer edge pixels at half coverage.
        if (self.render_state.antialias and ca > 0) {
            const half_ca = ca / 2;
            // Top edge (row above y0)
            if (y0 > 0) {
                var px: i32 = x0;
                while (px < x1) : (px += 1) {
                    const idx = @as(usize, @intCast(y0 - 1)) * stride + @as(usize, @intCast(px)) * 4;
                    if (idx + 3 < fb.len)
                        writePixel(fb, idx, cr, cg, cb, half_ca, self.render_state.blend_mode);
                }
            }
            // Bottom edge
            if (y1 < @as(i32, @intCast(fb_h))) {
                var px: i32 = x0;
                while (px < x1) : (px += 1) {
                    const idx = @as(usize, @intCast(y1)) * stride + @as(usize, @intCast(px)) * 4;
                    if (idx + 3 < fb.len)
                        writePixel(fb, idx, cr, cg, cb, half_ca, self.render_state.blend_mode);
                }
            }
            // Left edge
            if (x0 > 0) {
                var ipy: i32 = y0;
                while (ipy < y1) : (ipy += 1) {
                    const idx = @as(usize, @intCast(ipy)) * stride + @as(usize, @intCast(x0 - 1)) * 4;
                    if (idx + 3 < fb.len)
                        writePixel(fb, idx, cr, cg, cb, half_ca, self.render_state.blend_mode);
                }
            }
            // Right edge
            if (x1 < @as(i32, @intCast(fb_w))) {
                var ipy: i32 = y0;
                while (ipy < y1) : (ipy += 1) {
                    const idx = @as(usize, @intCast(ipy)) * stride + @as(usize, @intCast(x1)) * 4;
                    if (idx + 3 < fb.len)
                        writePixel(fb, idx, cr, cg, cb, half_ca, self.render_state.blend_mode);
                }
            }
        }
    }

    fn strokeRect(self: *Self, fb: []u8, x: f32, y: f32, w: f32, h: f32, r: f32, g: f32, b_col: f32, a: f32, stroke_width: f32) void {
        // Draw rectangle outline using four filled rectangles for the edges
        const sw = @max(1.0, stroke_width);
        const half_sw = sw / 2.0;

        // Top edge
        self.fillRect(fb, x - half_sw, y - half_sw, w + sw, sw, r, g, b_col, a);
        // Bottom edge
        self.fillRect(fb, x - half_sw, y + h - half_sw, w + sw, sw, r, g, b_col, a);
        // Left edge (between top and bottom)
        self.fillRect(fb, x - half_sw, y + half_sw, sw, h - sw, r, g, b_col, a);
        // Right edge (between top and bottom)
        self.fillRect(fb, x + w - half_sw, y + half_sw, sw, h - sw, r, g, b_col, a);
    }

    fn strokeLine(self: *Self, fb: []u8, x1: f32, y1: f32, x2: f32, y2: f32, r: f32, g: f32, b_col: f32, a: f32, stroke_width: f32) void {
        // Bresenham-style line drawing with stroke width
        const fb_w = self.width;
        const fb_h = self.height;
        const stride = self.surface_stride;

        const cr = clampU8(r);
        const cg = clampU8(g);
        const cb = clampU8(b_col);
        const ca = clampU8(a);

        const sw = @max(1.0, stroke_width);
        const half_sw = @as(i32, @intFromFloat(sw / 2.0));

        // Calculate line parameters
        const dx_f = x2 - x1;
        const dy_f = y2 - y1;
        const length = @sqrt(dx_f * dx_f + dy_f * dy_f);

        if (length < 0.5) {
            // Point - just draw a filled circle/square at the location
            self.fillRect(fb, x1 - sw / 2.0, y1 - sw / 2.0, sw, sw, r, g, b_col, a);
            return;
        }

        // Use integer Bresenham algorithm
        var ix1: i32 = @intFromFloat(x1);
        var iy1: i32 = @intFromFloat(y1);
        const ix2: i32 = @intFromFloat(x2);
        const iy2: i32 = @intFromFloat(y2);

        const dx: i32 = @intCast(@abs(ix2 - ix1));
        const dy: i32 = @intCast(@abs(iy2 - iy1));
        const sx: i32 = if (ix1 < ix2) @as(i32, 1) else @as(i32, -1);
        const sy: i32 = if (iy1 < iy2) @as(i32, 1) else @as(i32, -1);
        var err: i32 = dx - dy;

        while (true) {
            // Draw a square at current position for stroke width
            var py: i32 = -half_sw;
            while (py <= half_sw) : (py += 1) {
                var px: i32 = -half_sw;
                while (px <= half_sw) : (px += 1) {
                    const plot_x = ix1 + px;
                    const plot_y = iy1 + py;

                    if (plot_x >= 0 and plot_x < @as(i32, @intCast(fb_w)) and
                        plot_y >= 0 and plot_y < @as(i32, @intCast(fb_h)))
                    {
                        const idx = @as(usize, @intCast(plot_y)) * stride + @as(usize, @intCast(plot_x)) * 4;
                        if (idx + 3 < fb.len) {
                            writePixel(fb, idx, cr, cg, cb, ca, self.render_state.blend_mode);
                        }
                    }
                }
            }

            if (ix1 == ix2 and iy1 == iy2) break;

            const e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                ix1 += sx;
            }
            if (e2 < dx) {
                err += dx;
                iy1 += sy;
            }
        }
    }

    fn getPixelsImpl(ctx: *anyopaque) ?[]u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.surface_map;
    }

    fn resizeImpl(ctx: *anyopaque, width: u32, height: u32) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        if (self.width == width and self.height == height) return;

        // Destroy old surface and create new one
        self.destroySurface();
        try self.createSurface(width, height);
    }

    /// Drain any injected input events (EVT_KEY) from the drawfs fd.
    /// These are enqueued by semainput via DRAWFSGIOC_INJECT_INPUT and
    /// delivered back to the session as framed protocol messages.
    ///
    /// Appends to injected_keys; does NOT reset the buffer. The buffer
    /// is consumed and reset by getKeyEventsImpl. This matters because
    /// sendAndRecv can also stash EVT_KEY frames into injected_keys
    /// during protocol transactions — resetting here would wipe keys
    /// that the compositor's own read path has already captured.
    ///
    /// Any EVT_SURFACE_PRESENTED frames we encounter here are leftovers
    /// from a previous compositor transaction (normally sendAndRecv
    /// consumes them inline); they are discarded. Any protocol *reply*
    /// we find here indicates a protocol state bug — replies must never
    /// outlive the sendAndRecv call that expected them — but we discard
    /// them silently rather than crash the compositor loop.
    fn drainInjectedEvents(self: *Self) void {
        var pfd = [1]posix.pollfd{.{
            .fd = self.fd,
            .events = posix.POLL.IN,
            .revents = 0,
        }};
        while (self.injected_keys_len < backend.MAX_KEY_EVENTS) {
            const r = posix.poll(&pfd, 0) catch break;
            if (r == 0) break;
            if (pfd[0].revents & posix.POLL.IN == 0) break;
            var frame_buf: [256]u8 = undefined;
            const n = posix.read(self.fd, &frame_buf) catch break;
            if (n < 40) continue;
            const msg_type = std.mem.readInt(u16, frame_buf[16..18], .little);
            if (msg_type != DRAWFS_EVT_KEY) continue;
            self.stashEvtKey(frame_buf[0..n], n);
        }
    }

    fn pollEventsImpl(ctx: *anyopaque) bool {
        const self: *Self = @ptrCast(@alignCast(ctx));
        // Input under -b drawfs comes from the kernel session's read queue
        // (EVT_KEY/EVT_POINTER/EVT_SCROLL/EVT_TOUCH frames injected by
        // semainputd via DRAWFSGIOC_INJECT_INPUT). There is no local evdev
        // polling — that would grab devices away from semainputd.
        self.drainInjectedEvents();
        return true;
    }

    fn getKeyEventsImpl(ctx: *anyopaque) []const backend.KeyEvent {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (self.injected_keys_len > 0) {
            // TEMPORARY DIAGNOSTIC: log every consumption.
            std.debug.print("drawfs-backend: consume {d} events\n", .{self.injected_keys_len});
            // Snapshot the current contents and reset the buffer so the next
            // drain or sendAndRecv stash starts fresh. The returned slice is
            // safe to hold: injected_keys is a stack-allocated fixed array,
            // so resetting injected_keys_len does not invalidate the memory.
            // The caller (forwardKeyEvents) consumes the slice synchronously
            // before any further backend work can write to injected_keys.
            const events = self.injected_keys[0..self.injected_keys_len];
            self.injected_keys_len = 0;
            return events;
        }
        return &[_]backend.KeyEvent{};
    }

    fn getMouseEventsImpl(ctx: *anyopaque) []const backend.MouseEvent {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        // Mouse events under -b drawfs will arrive as EVT_POINTER frames and
        // be drained into an injected_mice buffer (TODO: mirror the
        // injected_keys pattern for pointer/scroll/touch). For now, no local
        // polling.
        return &[_]backend.MouseEvent{};
    }

    fn deinitImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.deinit();
    }

    /// Return the /dev/draw file descriptor so semadrawd's main event loop
    /// can include it in its poll() set. This lets the daemon wake
    /// immediately on injected input events instead of waiting out the
    /// poll timeout.
    fn getPollFdImpl(ctx: *anyopaque) ?posix.fd_t {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (self.fd < 0) return null;
        return self.fd;
    }

    pub const vtable = backend.Backend.VTable{
        .getCapabilities = getCapabilitiesImpl,
        .initFramebuffer = initFramebufferImpl,
        .render = renderImpl,
        .getPixels = getPixelsImpl,
        .resize = resizeImpl,
        .pollEvents = pollEventsImpl,
        .getKeyEvents = getKeyEventsImpl,
        .getMouseEvents = getMouseEventsImpl,
        .getPollFd = getPollFdImpl,
        .deinit = deinitImpl,
    };

    pub fn toBackend(self: *Self) backend.Backend {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};

// ============================================================================
// Helper functions
// ============================================================================

/// Write one XRGB8888 pixel applying the given blend mode.
/// blend_mode: 0=SrcOver, 1=Src, 2=Clear, 3=Add
fn writePixel(fb: []u8, idx: usize, r: u8, g: u8, b: u8, a: u8, blend_mode: u32) void {
    if (idx + 3 >= fb.len) return;
    switch (blend_mode) {
        2 => { // Clear
            fb[idx] = 0; fb[idx+1] = 0; fb[idx+2] = 0; fb[idx+3] = 0;
        },
        1 => { // Src — write directly, no blending
            fb[idx+0] = b; fb[idx+1] = g; fb[idx+2] = r; fb[idx+3] = a;
        },
        3 => { // Add — saturating add
            fb[idx+0] = @intCast(@min(255, @as(u32, fb[idx+0]) + b));
            fb[idx+1] = @intCast(@min(255, @as(u32, fb[idx+1]) + g));
            fb[idx+2] = @intCast(@min(255, @as(u32, fb[idx+2]) + r));
            fb[idx+3] = 0xFF;
        },
        else => { // SrcOver (default)
            if (a == 255) {
                fb[idx+0] = b; fb[idx+1] = g; fb[idx+2] = r; fb[idx+3] = 0xFF;
            } else if (a > 0) {
                const sa: f32 = @as(f32, @floatFromInt(a)) / 255.0;
                const inv_sa = 1.0 - sa;
                fb[idx+0] = @intFromFloat(@min(255.0, @as(f32, @floatFromInt(b)) * sa + @as(f32, @floatFromInt(fb[idx+0])) * inv_sa));
                fb[idx+1] = @intFromFloat(@min(255.0, @as(f32, @floatFromInt(g)) * sa + @as(f32, @floatFromInt(fb[idx+1])) * inv_sa));
                fb[idx+2] = @intFromFloat(@min(255.0, @as(f32, @floatFromInt(r)) * sa + @as(f32, @floatFromInt(fb[idx+2])) * inv_sa));
                fb[idx+3] = 0xFF;
            }
        },
    }
}

fn clampU8(v: f32) u8 {
    var x = v;
    if (x < 0.0) x = 0.0;
    if (x > 1.0) x = 1.0;
    return @intFromFloat(@round(x * 255.0));
}

fn readF32(bytes: *const [4]u8) f32 {
    const u = std.mem.readInt(u32, bytes, .little);
    return @bitCast(u);
}

// ============================================================================
// Public API
// ============================================================================

/// Create drawfs backend with default device path (/dev/draw)
pub fn create(allocator: std.mem.Allocator) !backend.Backend {
    const drawfs_backend = try DrawfsBackend.initDefault(allocator);
    return drawfs_backend.toBackend();
}

/// Create drawfs backend with specific device path
pub fn createWithDevice(allocator: std.mem.Allocator, device_path: []const u8) !backend.Backend {
    const drawfs_backend = try DrawfsBackend.init(allocator, device_path);
    return drawfs_backend.toBackend();
}

// ============================================================================
// Tests
// ============================================================================

test "DrawfsBackend struct size" {
    try std.testing.expect(@sizeOf(DrawfsBackend) > 0);
}

test "align4" {
    try std.testing.expectEqual(@as(u32, 0), align4(0));
    try std.testing.expectEqual(@as(u32, 4), align4(1));
    try std.testing.expectEqual(@as(u32, 4), align4(4));
    try std.testing.expectEqual(@as(u32, 8), align4(5));
}

test "clampU8" {
    try std.testing.expectEqual(@as(u8, 0), clampU8(-1.0));
    try std.testing.expectEqual(@as(u8, 0), clampU8(0.0));
    try std.testing.expectEqual(@as(u8, 128), clampU8(0.5));
    try std.testing.expectEqual(@as(u8, 255), clampU8(1.0));
    try std.testing.expectEqual(@as(u8, 255), clampU8(2.0));
}
