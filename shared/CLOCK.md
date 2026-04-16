# Clock Publication

## Purpose

The clock region is a small memory-mapped file written by `semaaud` and read
by all other daemons. It exposes the audio hardware clock — a monotonically
increasing count of PCM sample frames written to the OSS device — as a shared
memory region accessible without any IPC round-trip.

This is the foundation of the chronofs temporal coordination layer. All
timestamped events across the fabric carry `ts_audio_samples`, read from this
region at emission time.

## Clock file

**Default path**: `/var/run/sema/clock`

The file is created by `semaaud` at startup using `ClockWriter.init()`. The
`/var/run/sema/` directory is created if absent.

## Region layout

Total size: **20 bytes**. All fields are little-endian.

| Offset | Size | Type | Field | Description |
|--------|------|------|-------|-------------|
| 0 | 4 | u32 | `magic` | `0x534D434B` ("SMCK") |
| 4 | 1 | u8 | `version` | Region format version (currently `1`) |
| 5 | 1 | u8 | `clock_valid` | `0` = no stream started, `1` = clock is live |
| 6 | 2 | u8[2] | `_pad` | Reserved, zero |
| 8 | 4 | u32 | `sample_rate` | PCM sample frames per second |
| 12 | 8 | u64 | `samples_written` | Monotonic sample frame counter (atomic) |

The `u64` at offset 12 is naturally aligned. No additional padding is needed.

## Concurrency model

`samples_written` is written with `@atomicStore(..., .seq_cst)` by the semaaud
stream worker and read with `@atomicLoad(..., .seq_cst)` by all readers. No
mutex is required. Sequential consistency is used rather than monotonic ordering
to ensure that a reader seeing `clock_valid = 1` also sees the correct
`sample_rate` value written before it.

`clock_valid` is written once (0 → 1) by `ClockWriter.streamBegin()` and never
reset for the lifetime of the daemon. It is also written and read with
sequential consistency atomics.

## API

```zig
const clock = @import("path/to/shared/src/clock.zig");

// --- semaaud (writer) ---

var writer = try clock.ClockWriter.init(clock.CLOCK_PATH);
defer writer.deinit();

// Called when a PCM stream begins:
writer.streamBegin(48_000);  // sample_rate in Hz

// Called after each successful posix.write() to the OSS device:
writer.update(total_samples_written);  // cumulative count

// --- other daemons (reader) ---

const reader = clock.ClockReader.init(clock.CLOCK_PATH);
defer reader.deinit();

if (reader.isValid()) {
    const samples = reader.read();         // u64 sample frame count
    const rate    = reader.sampleRate();   // u32 Hz
    const ns      = clock.toNanoseconds(samples, rate);
}
```

## Lifecycle

1. `semaaud` starts and calls `ClockWriter.init()`. The file is created with
   `clock_valid = 0` and `samples_written = 0`.
2. `semainput`, `semadraw`, and chronofs start and call `ClockReader.init()`.
   `isValid()` returns false. Events carry `ts_audio_samples: null`.
3. A PCM client connects to semaaud. `ClockWriter.streamBegin(sample_rate)` is
   called. `clock_valid` becomes `1`. `isValid()` returns true on all readers.
4. The stream worker calls `ClockWriter.update(n)` after each write batch.
   Readers see the updated counter with no IPC overhead.
5. The stream ends. `clock_valid` remains `1`. `samples_written` holds the
   final position. New streams resume from that position (monotonic).
6. `semaaud` exits. The file remains on disk (unless `/var/run` is a tmpfs
   that is cleared on reboot). The next `semaaud` start overwrites it with
   `truncate = true`.

## `toNanoseconds`

```zig
pub fn toNanoseconds(samples: u64, sample_rate: u32) u64
```

Converts a sample position to nanoseconds using a u128 intermediate to avoid
overflow. Returns 0 if `sample_rate` is 0.

At 48kHz, 1 second = 48,000 samples. At 96kHz, 1 second = 96,000 samples.

## Integration with semaaud

`semaaud`'s stream worker (A-2) already maintains `Shared.samples_written` as
an `std.atomic.Value(u64)`. The S-4 integration in `main.zig` creates a
`ClockWriter` at startup and passes it to the stream worker, which calls
`writer.update(shared.samples_written.load(.monotonic))` after each write batch.

See `semaaud/BACKLOG.md` item A-3 for the full integration plan.
