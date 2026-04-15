pub const StreamFormat = enum {
    s16le,
};

pub const StreamDescriptor = struct {
    sample_rate: u32,
    channels: u16,
    format: StreamFormat,
};

pub const DeviceSelection = struct {
    default_pcm: []const u8,
    audiodev: []const u8,
    mixerdev: []const u8,
};

pub const ControlServerConfig = struct {
    socket_path: []const u8,
};

pub const PolicyDecision = enum {
    allow,
    busy,
    deny,
    override,
};

pub const TargetConfig = struct {
    name: []const u8,
    stream_socket: []const u8,
    selection: DeviceSelection,
};


pub const AuthIdentity = struct {
    uid: ?u32 = null,
    gid: ?u32 = null,
    authenticated: bool = false,
};
