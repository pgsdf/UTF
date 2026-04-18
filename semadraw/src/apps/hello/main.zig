//! Hello SemaDraw — minimal example using the App framework.
//!
//! Draws a colored rectangle that changes hue each frame.
//! Press any key or Ctrl-C to quit.
//!
//! Build:
//!   zig build hello
//!
//! Run (requires semadrawd running with drawfs backend):
//!   sudo semadrawd -b drawfs &
//!   ./zig-out/bin/hello

const std = @import("std");
const semadraw = @import("semadraw");

const App = semadraw.App;
const Encoder = semadraw.Encoder;

const WIDTH: f32 = 800;
const HEIGHT: f32 = 600;

/// Application state
const State = struct {
    hue: f32 = 0.0,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var state = State{};

    var app = try App.init(allocator, .{
        .title      = "Hello SemaDraw",
        .width      = WIDTH,
        .height     = HEIGHT,
        .target_fps = 60,
    });
    defer app.deinit();

    try app.run(&state, onDraw, onEvent);
}

fn onDraw(ctx: *anyopaque, enc: *Encoder, frame: u64) !void {
    const state: *State = @ptrCast(@alignCast(ctx));

    // Advance hue
    state.hue = @mod(state.hue + 0.005, 1.0);
    _ = frame;

    // Convert HSV to RGB (S=0.7, V=0.9)
    const h6 = state.hue * 6.0;
    const i: u32 = @intFromFloat(h6);
    const f = h6 - @as(f32, @floatFromInt(i));
    const p: f32 = 0.9 * (1.0 - 0.7);
    const q: f32 = 0.9 * (1.0 - 0.7 * f);
    const t: f32 = 0.9 * (1.0 - 0.7 * (1.0 - f));
    const v: f32 = 0.9;
    const rgb: [3]f32 = switch (i % 6) {
        0 => .{ v, t, p },
        1 => .{ q, v, p },
        2 => .{ p, v, t },
        3 => .{ p, q, v },
        4 => .{ t, p, v },
        else => .{ v, p, q },
    };

    // Background
    try enc.fillRect(0, 0, WIDTH, HEIGHT, 0.05, 0.05, 0.1, 1.0);

    // Colored rectangle
    const margin: f32 = 80;
    try enc.fillRect(
        margin, margin,
        WIDTH - margin * 2, HEIGHT - margin * 2,
        rgb[0], rgb[1], rgb[2], 1.0,
    );

    // Inner dark rectangle
    const inner: f32 = 160;
    try enc.fillRect(
        inner, inner,
        WIDTH - inner * 2, HEIGHT - inner * 2,
        0.05, 0.05, 0.1, 0.85,
    );
}

fn onEvent(ctx: *anyopaque, event: App.Event) !bool {
    _ = ctx;
    return switch (event) {
        .quit => false,
        .key  => |k| if (k.pressed) false else true,
        else  => true,
    };
}
