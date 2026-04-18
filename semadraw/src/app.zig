const std = @import("std");
const client = @import("semadraw_client");
const Encoder = @import("encoder.zig").Encoder;

const log = std.log.scoped(.semadraw_app);

pub const KeyEvent = struct {
    key_code: u32,
    pressed: bool,
    modifiers: u8,
};

pub const MouseEvent = struct {
    x: f32,
    y: f32,
    button: u8,
    pressed: bool,
    modifiers: u8,
};

pub const Event = union(enum) {
    quit,
    frame: struct { frame_number: u64, timestamp_ns: u64 },
    key: KeyEvent,
    mouse: MouseEvent,
};

pub const AppDesc = struct {
    title: []const u8 = "SemaDraw App",
    width: f32 = 1280,
    height: f32 = 720,
    scale: f32 = 1.0,
    z_order: i32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    socket_path: ?[]const u8 = null,
    target_fps: u32 = 60,
};

pub const DrawFn  = *const fn (ctx: *anyopaque, enc: *Encoder, frame: u64) anyerror!void;
pub const EventFn = *const fn (ctx: *anyopaque, event: Event) anyerror!bool;

pub const App = struct {
    allocator: std.mem.Allocator,
    desc: AppDesc,
    conn: *client.Connection,
    surface: *client.Surface,
    encoder: Encoder,
    frame: u64,
    running: bool,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, desc: AppDesc) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        log.info("connecting to semadrawd...", .{});
        const conn = if (desc.socket_path) |path|
            try client.Connection.connectTo(allocator, path)
        else
            try client.Connection.connect(allocator);
        errdefer conn.disconnect();

        log.info("connected, creating surface {}x{}...", .{ desc.width, desc.height });

        const surface = try client.Surface.createWithScale(
            conn, desc.width, desc.height, desc.scale);
        errdefer surface.destroy();

        try surface.setZOrder(desc.z_order);
        try surface.setPosition(desc.x, desc.y);
        try surface.show();

        self.* = .{
            .allocator = allocator,
            .desc      = desc,
            .conn      = conn,
            .surface   = surface,
            .encoder   = Encoder.init(allocator),
            .frame     = 0,
            .running   = true,
        };

        log.info("surface ready ({s})", .{desc.title});
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.encoder.deinit();
        self.surface.destroy();
        self.conn.disconnect();
        self.allocator.destroy(self);
    }

    pub fn run(self: *Self, ctx: *anyopaque, onDraw: DrawFn, onEvent: EventFn) !void {
        const frame_ns: u64 = if (self.desc.target_fps > 0)
            @divTrunc(std.time.ns_per_s, self.desc.target_fps)
        else 0;

        while (self.running) {
            const frame_start = std.time.nanoTimestamp();

            try self.encoder.reset();
            try onDraw(ctx, &self.encoder, self.frame);
            const sdcs_data = try self.encoder.finishBytesWithHeader();
            defer self.allocator.free(sdcs_data);
            try self.surface.attachAndCommit(sdcs_data);
            self.frame += 1;

            self.running = try self.drainEvents(ctx, onEvent);

            if (frame_ns > 0) {
                const elapsed: u64 = @intCast(std.time.nanoTimestamp() - frame_start);
                if (elapsed < frame_ns) std.time.sleep(frame_ns - elapsed);
            }
        }
    }

    fn drainEvents(self: *Self, ctx: *anyopaque, onEvent: EventFn) !bool {
        const fd = self.conn.getFd();
        var pfd = [1]std.posix.pollfd{.{
            .fd = fd,
            .events = std.posix.POLL.IN,
            .revents = 0,
        }};

        while (true) {
            const ready = std.posix.poll(&pfd, 0) catch break;
            if (ready == 0) break;
            if ((pfd[0].revents & std.posix.POLL.IN) == 0) break;

            const ev = self.conn.waitEvent() catch |err| {
                if (err == error.EndOfStream or err == error.BrokenPipe) return false;
                break;
            };

            const app_ev: ?Event = switch (ev) {
                .frame_complete => |fc| Event{ .frame = .{
                    .frame_number = fc.frame_number,
                    .timestamp_ns = fc.timestamp_ns,
                }},
                .disconnected => Event{ .quit = {} },
                .key_press => |kp| Event{ .key = .{
                    .key_code  = kp.key_code,
                    .pressed   = kp.pressed != 0,
                    .modifiers = kp.modifiers,
                }},
                .mouse_event => |me| Event{ .mouse = .{
                    .x         = @as(f32, @floatFromInt(me.x)),
                    .y         = @as(f32, @floatFromInt(me.y)),
                    .button    = @intFromEnum(me.button),
                    .pressed   = me.event_type == .press,
                    .modifiers = me.modifiers,
                }},
                else => null,
            };

            if (app_ev) |e| {
                const keep_running = try onEvent(ctx, e);
                if (!keep_running) return false;
            }
        }
        return true;
    }
};
