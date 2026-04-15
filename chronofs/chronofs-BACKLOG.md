# chronofs Backlog

`chronofs` is the temporal coordination layer described in `docs/Thoughts.md`.
It does not yet exist as code. This backlog defines the implementation in
dependency order, starting from the clock primitive and building up to the
audio-driven frame scheduler integration.

All items in this backlog depend on the shared/ and subsystem backlogs being
complete: the clock must be published (S-4), events must carry
`ts_audio_samples` (A-3, I-3, D-1), and the frame scheduler must be clock-
abstracted (D-3).

---

## C-1 — Clock Module

**Status**: Open
**Effort**: Small
**Depends on**: shared/S-4 (clock publication interface exists)

### Background

The chronofs clock is a thin wrapper around the shared memory region written by
semaaud. Its role is to give any module a single canonical `now()` function
that returns the current audio position in samples. This module is the
foundation everything else in chronofs builds on.

### Tasks

- [ ] Create `chronofs/src/clock.zig`
- [ ] Implement `Clock` struct:
  ```zig
  pub const Clock = struct {
      reader: shared.clock.ClockReader,

      pub fn init(path: []const u8) !Clock
      pub fn now(self: Clock) u64        // returns samples_written
      pub fn isValid(self: Clock) bool   // returns clock_valid
      pub fn toNs(self: Clock, samples: u64) u64  // samples → nanoseconds
      pub fn sampleRate(self: Clock) u32
  };
  ```
- [ ] Implement a `MockClock` for testing:
  ```zig
  pub const MockClock = struct {
      samples: u64,
      rate: u32,

      pub fn advance(self: *MockClock, samples: u64) void
      pub fn now(self: MockClock) u64
      pub fn isValid(self: MockClock) bool  // always true
      pub fn toNs(self: MockClock, samples: u64) u64
      pub fn sampleRate(self: MockClock) u32
  };
  ```
- [ ] Add `build.zig` for the chronofs module with a test step

### Acceptance Criteria

- `MockClock.advance(48000)` followed by `now()` returns 48000
- `Clock.toNs(48000)` with a 48kHz clock returns 1_000_000_000 (1 second in ns)
- `Clock.isValid()` returns false before semaaud starts and true after

---

## C-2 — Event Stream Buffers

**Status**: Open
**Effort**: Medium
**Depends on**: C-1

### Background

The `chronofs.write(stream, event)` and `chronofs.read(stream, t_range)` API
from `Thoughts.md` requires per-domain append-only buffers indexed by audio
sample position. These are the core data structure of chronofs: a ring buffer
where each entry is a time-stamped event from one of the four domains.

### Tasks

- [ ] Create `chronofs/src/stream.zig`
- [ ] Implement `EventStream(T)` generic:
  - Backed by a fixed-capacity ring buffer (compile-time capacity parameter)
  - Each entry: `{ t: u64, payload: T }`
  - `append(t: u64, payload: T) !void` — adds an entry; overwrites oldest if
    full (ring behavior)
  - `query(t_start: u64, t_end: u64, out: []Entry) usize` — fills `out` with
    all entries where `t_start <= t <= t_end`, returns count
  - `latest() ?Entry` — returns the most recent entry
  - `at(t: u64) ?Entry` — returns the latest entry with `entry.t <= t`
    (state resolution: "what was true at time t")
- [ ] Implement a `DomainStreams` struct that owns one stream per domain:
  ```zig
  pub const DomainStreams = struct {
      audio:  EventStream(AudioEvent),
      visual: EventStream(VisualEvent),
      input:  EventStream(InputEvent),
  };
  ```
- [ ] Define the event payload types:
  - `AudioEvent`: `{ stream_id: u64, samples_written: u64, active: bool }`
  - `VisualEvent`: `{ surface_id: u32, frame_number: u64 }`
  - `InputEvent`: mirrors semantic.SemanticEvent from semainput
- [ ] Add thread-safety: a `std.Thread.Mutex` per stream, since writers and
      readers are on different threads

### Acceptance Criteria

- `append` followed by `at(t)` returns the appended entry when `t >= entry.t`
- Ring overflow: after filling the buffer, the oldest entry is evicted and
  `at(oldest_t)` returns null
- Concurrent append and query from separate threads does not deadlock or
  corrupt data (test with `std.Thread`)

---

## C-3 — Resolver

**Status**: Open
**Effort**: Medium
**Depends on**: C-2

### Background

`chronofs.resolve(domain, t)` is described in `Thoughts.md` as the defining
abstraction: "Rendering = evaluate visual state at t. Audio = sample signal at
t. Input = query latest events ≤ t." The resolver is the function that makes
this concrete for each domain.

### Tasks

- [ ] Create `chronofs/src/resolver.zig`
- [ ] Implement `Resolver` struct that holds a reference to `DomainStreams` and
      a `Clock`:
  ```zig
  pub const Resolver = struct {
      streams: *DomainStreams,
      clock: Clock,

      pub fn resolveVisual(self: Resolver, t: u64) ?VisualEvent
      pub fn resolveInput(self: Resolver, t: u64) ?InputEvent
      pub fn resolveAudio(self: Resolver, t: u64) ?AudioEvent
      pub fn currentTime(self: Resolver) u64  // delegates to clock.now()
  };
  ```
- [ ] Implement ingestion helpers that parse the unified JSON-lines event format
      from each subsystem's stdout and `append` them to the correct stream:
  - `ingestSemaaudLine(streams: *DomainStreams, line: []const u8) !void`
  - `ingestSemainputLine(streams: *DomainStreams, line: []const u8) !void`
  - `ingestSemadrawLine(streams: *DomainStreams, line: []const u8) !void`
- [ ] Add an ingestion driver: a thread per subsystem that reads from a pipe
      (the subsystem's stdout) and calls the appropriate ingest function

### Acceptance Criteria

- `resolveInput(t)` returns the most recent input event at or before `t`
- After ingesting a `frame_complete` event at time T, `resolveVisual(T)` returns
  that frame
- Ingestion parses the unified schema correctly and ignores unknown `type`
  values gracefully

---

## C-4 — Audio-Driven Frame Scheduler Integration

**Status**: Open
**Effort**: Medium
**Depends on**: C-3, semadraw/D-3 (clock abstraction in frame scheduler)

### Background

This is the final integration step: replacing semadraw's wall-clock vsync
scheduler with a chronofs `Clock`-driven one. The scheduler asks "what audio
sample position corresponds to the next display refresh?" and produces a frame
that will be presented at that position. This is the architectural change that
achieves drift-free AV synchronization.

The display refresh interval in samples is: `sample_rate / refresh_rate`. At
48kHz and 60Hz, this is 800 samples per frame. The scheduler targets the next
multiple of this interval above `clock.now()`.

### Tasks

- [ ] Implement `ChronofsClockSource` in `semadraw/src/compositor/
      frame_scheduler.zig` that adapts `chronofs.Clock` to the `ClockSource`
      interface defined in D-3:
  ```zig
  pub fn ChronofsClockSource(clock: *chronofs.Clock) semadraw.ClockSource
  ```
- [ ] Implement `nextFrameTarget(clock: Clock, refresh_rate_hz: u32) u64`:
      returns the sample position of the next frame boundary
- [ ] Replace the vsync wait in `FrameScheduler` with a sleep until
      `nextFrameTarget` expressed as wall-clock nanoseconds via `clock.toNs()`
- [ ] Pass the target frame sample position into `resolveVisual` at render time:
      the compositor renders the scene state at that position, not the current
      position
- [ ] Emit `ts_audio_samples` in `frame_complete` events (D-1) using the
      target frame sample position, not the wall clock

### Acceptance Criteria

- With semaaud playing audio, `frame_complete` events and audio stream events
  have `ts_audio_samples` values that are within one frame period of each other
- No systematic drift accumulates over 60 seconds of continuous playback (measure
  by comparing `ts_audio_samples` of frame events against expected audio positions)
- Stopping semaaud (no active stream) causes the scheduler to fall back to
  `WallClockSource` — no rendering interruption

---

## C-5 — chronofs Diagnostic Tool

**Status**: Open
**Effort**: Small
**Depends on**: C-3

### Background

The chronofs model is only trustworthy if it can be inspected. A diagnostic tool
that reads the live domain streams and prints a timeline view is necessary for
debugging synchronization issues.

### Tasks

- [ ] Create `chronofs/tools/chrono_dump.zig`
- [ ] The tool connects to all three subsystem pipes (or reads from a recorded
      log file), ingests events, and emits a merged timeline to stdout:
  ```
  t=48000  [audio]  stream_begin  stream_id=1
  t=48032  [input]  mouse_move    dx=3 dy=-1
  t=48800  [visual] frame_complete surface_id=1 frame=1
  t=96000  [audio]  samples=96000 (2.000s)
  ```
- [ ] Add a `--drift` flag that computes and prints the delta between expected
      and actual frame times relative to the audio clock
- [ ] Add a `--replay <file>` mode that reads a recorded log and replays it
      through the resolver, printing the resolved state at each 1000-sample
      interval

### Acceptance Criteria

- `chrono_dump` runs against a live fabric and produces a parseable timeline
- `--drift` output shows < 1 frame period (< 800 samples at 48kHz/60Hz) of
  drift during steady-state playback
- `--replay` mode produces deterministic output for the same input file
