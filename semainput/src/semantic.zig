pub const SemanticEvent = union(enum) {
    mouse_move: struct { path: []const u8, dx: i32, dy: i32 },
    mouse_button: struct { path: []const u8, button: []const u8, pressed: bool, x: i32, y: i32 },
    mouse_n_click: struct { path: []const u8, button: []const u8, count: u32, x: i32, y: i32, mods: u8 },
    mouse_scroll: struct { path: []const u8, dx: i32, dy: i32 },
    key_down: struct { path: []const u8, code: u16, mods: u8 },
    key_up: struct { path: []const u8, code: u16, mods: u8 },
    touch_down: struct { path: []const u8, contact: i32, x: i32, y: i32 },
    touch_move: struct { path: []const u8, contact: i32, x: i32, y: i32 },
    touch_up: struct { path: []const u8, contact: i32 },

    pub fn sourcePath(self: SemanticEvent) []const u8 {
        return switch (self) {
            .mouse_move => |e| e.path,
            .mouse_button => |e| e.path,
            .mouse_n_click => |e| e.path,
            .mouse_scroll => |e| e.path,
            .key_down => |e| e.path,
            .key_up => |e| e.path,
            .touch_down => |e| e.path,
            .touch_move => |e| e.path,
            .touch_up => |e| e.path,
        };
    }
};
