const std = @import("std");
const posix = std.posix;

// ============================================================================
// Clock region layout
// ============================================================================
//
// The clock region is a 20-byte memory-mapped file at /var/run/sema/clock.
// semaaud writes it; all other daemons and chronofs read it.
//
// Offset  Size  Field           Description
// ------  ----  -----           -----------
//  0       4    magic           0x534D434B ("SMCK") little-endian
//  4       1    version         Region format version (currently 1)
//  5       1    clock_valid     0 = no stream ever started, 1 = clock is live
//  6       2    _pad            Reserved, must be zero
//  8       4    sample_rate     Sample frames per second of the active stream
// 12       8    samples_written Monotonic PCM sample frame counter (atomic u64)
//
// Total: 20 bytes. The u64 at offset 12 is naturally aligned.
//
// Concurrency model:
//   samples_written is written with SeqCst atomics by the semaaud stream
//   worker and read with SeqCst atomics by all readers. No mutex is required.
//   clock_valid is written once (0 → 1) and never reset.

pub const CLOCK_PATH = "/var/run/sema/clock";
pub const CLOCK_MAGIC: u32 = 0x534D434B; // "SMCK"
pub const CLOCK_VERSION: u8 = 1;
pub const CLOCK_SIZE: usize = 20;

// Byte offsets within the region.
const OFF_MAGIC: usize = 0;
const OFF_VERSION: usize = 4;
const OFF_VALID: usize = 5;
const OFF_PAD: usize = 6;
const OFF_SAMPLE_RATE: usize = 8;
const OFF_SAMPLES: usize = 12;

// ============================================================================
// ClockWriter — used by semaaud
// ============================================================================

/// Owns the memory-mapped clock file and publishes the audio clock position.
/// Create once at semaaud startup; call update() from the stream worker thread
/// after each batch of PCM frames is written to the OSS device.
pub const ClockWriter = struct {
    map: []u8,
    fd: posix.fd_t,

    /// Open or create the clock file and mmap it.
    /// Creates /var/run/sema/ if absent.
    pub fn init(path: []const u8) !ClockWriter {
        // Ensure parent directory exists.
        if (std.fs.path.dirname(path)) |dir_path| {
            std.fs.makeDirAbsolute(dir_path) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }

        // Open or create the file. Mode 0o600 per ADR 0013;
        // operators override via daemon's process group and umask.
        const fd = try std.fs.createFileAbsolute(path, .{
            .truncate = true,
            .read = true,
            .mode = 0o600,
        });
        errdefer posix.close(fd.handle);

        // Size the file.
        try fd.setEndPos(CLOCK_SIZE);

        const raw_fd = fd.handle;

        // Map it read-write.
        const map_raw = try posix.mmap(
            null,
            CLOCK_SIZE,
            posix.PROT.READ | posix.PROT.WRITE,
            .{ .TYPE = .SHARED },
            raw_fd,
            0,
        );
        errdefer posix.munmap(map_raw);

        const map: []u8 = map_raw[0..CLOCK_SIZE];
        const writer = ClockWriter{ .map = map, .fd = raw_fd };

        // Write the static header fields.
        writer.writeU32(OFF_MAGIC, CLOCK_MAGIC);
        writer.map[OFF_VERSION] = CLOCK_VERSION;
        writer.map[OFF_VALID] = 0; // not valid until first stream
        writer.map[OFF_PAD] = 0;
        writer.map[OFF_PAD + 1] = 0;
        writer.writeU32(OFF_SAMPLE_RATE, 0);
        writer.writeU64Atomic(OFF_SAMPLES, 0);

        return writer;
    }

    pub fn deinit(self: ClockWriter) void {
        posix.munmap(@alignCast(self.map));
        posix.close(self.fd);
    }

    /// Called when a stream begins. Sets sample_rate and marks the clock valid.
    /// Must be called before the first update().
    pub fn streamBegin(self: ClockWriter, sample_rate: u32) void {
        self.writeU32(OFF_SAMPLE_RATE, sample_rate);
        // Mark valid last — readers check clock_valid before reading samples.
        @atomicStore(u8, &self.map[OFF_VALID], 1, .seq_cst);
    }

    /// Update the monotonic sample counter. Call after each posix.write() to
    /// the OSS device. `total_samples` is the cumulative count, not a delta.
    pub fn update(self: ClockWriter, total_samples: u64) void {
        self.writeU64Atomic(OFF_SAMPLES, total_samples);
    }

    // -----------------------------------------------------------------------

    fn writeU32(self: ClockWriter, off: usize, v: u32) void {
        std.mem.writeInt(u32, self.map[off..][0..4], v, .little);
    }

    fn writeU64Atomic(self: ClockWriter, off: usize, v: u64) void {
        // writeInt handles any byte alignment of the underlying []u8 slice.
        // On x86_64, aligned u64 stores to shared memory are sequentially
        // consistent by the TSO memory model. The seq_cst ordering on
        // clock_valid (written last in streamBegin) provides the necessary
        // barrier for readers that check clock_valid before reading this field.
        std.mem.writeInt(u64, self.map[off..][0..8], v, .little);
    }
};

// ============================================================================
// ClockReader — used by semainput, semadraw, chronofs
// ============================================================================

/// Reads the shared clock region. Open is non-fatal: if the file is absent
/// (semaaud not running), isValid() returns false and read() returns 0.
pub const ClockReader = struct {
    map: ?[]const u8,
    fd: posix.fd_t,

    /// Attempt to open the clock file. Does not fail if absent.
    pub fn init(path: []const u8) ClockReader {
        const file = std.fs.openFileAbsolute(path, .{}) catch {
            return .{ .map = null, .fd = -1 };
        };
        const raw_fd = file.handle;

        const map_raw = posix.mmap(
            null,
            CLOCK_SIZE,
            posix.PROT.READ,
            .{ .TYPE = .SHARED },
            raw_fd,
            0,
        ) catch {
            posix.close(raw_fd);
            return .{ .map = null, .fd = -1 };
        };

        const map: []const u8 = map_raw[0..CLOCK_SIZE];

        // Validate magic and version before trusting the region.
        const magic = std.mem.readInt(u32, map[OFF_MAGIC..][0..4], .little);
        if (magic != CLOCK_MAGIC or map[OFF_VERSION] != CLOCK_VERSION) {
            posix.munmap(@alignCast(map_raw));
            posix.close(raw_fd);
            return .{ .map = null, .fd = -1 };
        }

        return .{ .map = map, .fd = raw_fd };
    }

    pub fn deinit(self: ClockReader) void {
        if (self.map) |m| posix.munmap(@alignCast(@constCast(m)));
        if (self.fd >= 0) posix.close(self.fd);
    }

    /// True if the clock file is open, valid, and at least one audio stream
    /// has started (i.e. samples_written is meaningful).
    pub fn isValid(self: ClockReader) bool {
        const m = self.map orelse return false;
        return @atomicLoad(u8, &m[OFF_VALID], .seq_cst) != 0;
    }

    /// Read the current sample position. Returns 0 if the clock is not valid.
    pub fn read(self: ClockReader) u64 {
        const m = self.map orelse return 0;
        if (@atomicLoad(u8, &m[OFF_VALID], .seq_cst) == 0) return 0;
        return std.mem.readInt(u64, m[OFF_SAMPLES..][0..8], .little);
    }

    /// Read the sample rate of the active stream. Returns 0 if not valid.
    pub fn sampleRate(self: ClockReader) u32 {
        const m = self.map orelse return 0;
        if (@atomicLoad(u8, &m[OFF_VALID], .seq_cst) == 0) return 0;
        return std.mem.readInt(u32, m[OFF_SAMPLE_RATE..][0..4], .little);
    }
};

// ============================================================================
// toNanoseconds
// ============================================================================

/// Convert a sample position to nanoseconds.
/// Uses u128 intermediate to avoid overflow at large sample counts.
/// At 48kHz, u64 samples overflow after ~384,000 years, so overflow of
/// the final u64 result is not a practical concern.
pub fn toNanoseconds(samples: u64, sample_rate: u32) u64 {
    if (sample_rate == 0) return 0;
    const ns = (@as(u128, samples) * 1_000_000_000) / @as(u128, sample_rate);
    return @intCast(@min(ns, std.math.maxInt(u64)));
}

// ============================================================================
// Tests
// ============================================================================

test "toNanoseconds basic" {
    // 48000 samples at 48kHz = exactly 1 second = 1_000_000_000 ns
    try std.testing.expectEqual(
        @as(u64, 1_000_000_000),
        toNanoseconds(48_000, 48_000),
    );

    // 0 samples = 0 ns
    try std.testing.expectEqual(@as(u64, 0), toNanoseconds(0, 48_000));

    // 0 sample_rate = 0 ns (guard against division by zero)
    try std.testing.expectEqual(@as(u64, 0), toNanoseconds(48_000, 0));

    // 96000 samples at 48kHz = 2 seconds
    try std.testing.expectEqual(
        @as(u64, 2_000_000_000),
        toNanoseconds(96_000, 48_000),
    );

    // 44100 samples at 44100Hz = exactly 1 second
    try std.testing.expectEqual(
        @as(u64, 1_000_000_000),
        toNanoseconds(44_100, 44_100),
    );
}

test "toNanoseconds no overflow at large sample counts" {
    // 2^63 samples at 48kHz — should not panic or wrap
    const large: u64 = std.math.maxInt(u64) / 2;
    const result = toNanoseconds(large, 48_000);
    try std.testing.expect(result > 0);
}

test "ClockWriter and ClockReader two-thread atomic visibility" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const tmp_path = try tmp.dir.realpath(".", &path_buf);
    var full_buf: [std.fs.max_path_bytes]u8 = undefined;
    const clock_path = try std.fmt.bufPrint(&full_buf, "{s}/clock", .{tmp_path});

    // Writer side: init, stream begins, write samples.
    var writer = try ClockWriter.init(clock_path);
    defer writer.deinit();

    // Before streamBegin: clock_valid must be 0.
    var reader = ClockReader.init(clock_path);
    defer reader.deinit();
    try std.testing.expect(!reader.isValid());
    try std.testing.expectEqual(@as(u64, 0), reader.read());

    // Simulate stream begin at 48kHz.
    writer.streamBegin(48_000);
    try std.testing.expect(reader.isValid());
    try std.testing.expectEqual(@as(u32, 48_000), reader.sampleRate());
    try std.testing.expectEqual(@as(u64, 0), reader.read());

    // Write sample counts and confirm reader sees them.
    writer.update(1_000);
    try std.testing.expectEqual(@as(u64, 1_000), reader.read());

    writer.update(48_000);
    try std.testing.expectEqual(@as(u64, 48_000), reader.read());

    writer.update(std.math.maxInt(u64) / 2);
    try std.testing.expectEqual(std.math.maxInt(u64) / 2, reader.read());
}

test "ClockReader is non-fatal when file absent" {
    const reader = ClockReader.init("/var/run/sema/clock_does_not_exist_test");
    defer reader.deinit();
    try std.testing.expect(!reader.isValid());
    try std.testing.expectEqual(@as(u64, 0), reader.read());
    try std.testing.expectEqual(@as(u32, 0), reader.sampleRate());
}

test "ClockWriter creates parent directory" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const tmp_path = try tmp.dir.realpath(".", &path_buf);
    var full_buf: [std.fs.max_path_bytes]u8 = undefined;
    // Subdirectory that doesn't exist yet.
    const clock_path = try std.fmt.bufPrint(&full_buf, "{s}/sema/clock", .{tmp_path});

    var writer = try ClockWriter.init(clock_path);
    writer.deinit();

    // Confirm the file exists and is the correct size.
    var check = try tmp.dir.openFile("sema/clock", .{});
    defer check.close();
    const stat = try check.stat();
    try std.testing.expectEqual(@as(u64, CLOCK_SIZE), stat.size);
}

test "ClockReader rejects wrong magic" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const tmp_path = try tmp.dir.realpath(".", &path_buf);
    var full_buf: [std.fs.max_path_bytes]u8 = undefined;
    const clock_path = try std.fmt.bufPrint(&full_buf, "{s}/clock", .{tmp_path});

    // Write a file with wrong magic.
    var f = try tmp.dir.createFile("clock", .{});
    try f.writeAll(&[_]u8{0} ** CLOCK_SIZE);
    f.close();

    const reader = ClockReader.init(clock_path);
    defer reader.deinit();
    try std.testing.expect(!reader.isValid());
}
