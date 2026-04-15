pub const SemanticEvent = union(enum) {
    mouse_move: struct { path: []const u8, dx: i32, dy: i32 },
    mouse_button: struct { path: []const u8, button: []const u8, pressed: bool },
    mouse_scroll: struct { path: []const u8, dx: i32, dy: i32 },
    key_down: struct { path: []const u8, code: u16 },
    key_up: struct { path: []const u8, code: u16 },
    touch_down: struct { path: []const u8, contact: i32, x: i32, y: i32 },
    touch_move: struct { path: []const u8, contact: i32, x: i32, y: i32 },
    touch_up: struct { path: []const u8, contact: i32 },

    pub fn sourcePath(self: SemanticEvent) []const u8 {
        return switch (self) {
            .mouse_move => |e| e.path,
            .mouse_button => |e| e.path,
            .mouse_scroll => |e| e.path,
            .key_down => |e| e.path,
            .key_up => |e| e.path,
            .touch_down => |e| e.path,
            .touch_move => |e| e.path,
            .touch_up => |e| e.path,
        };
    }
};
