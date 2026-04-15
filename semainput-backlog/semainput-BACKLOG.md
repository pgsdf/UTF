# semainput Backlog

`semainput` is the input daemon: evdev device discovery and reading on
FreeBSD/Linux, device classification and fingerprinting, logical identity
aggregation, pointer smoothing, and gesture recognition (two-finger scroll,
pinch, three-finger swipe, drag, tap). Currently at v40.

---

## I-1 — Unified Event Log Schema Adoption

**Status**: Open
**Effort**: Small
**Depends on**: shared/S-2 (schema), shared/S-3 (session identity)

### Background

`semainput` already emits JSON-lines to stdout — it is the most aligned of the
four daemons with the target output model. The gap is that the events lack the
mandatory unified schema fields: `subsystem`, `session`, `seq`, and
`ts_audio_samples`. The `ts_wall_ns` equivalent is not currently emitted at all
(the gesture recognizer uses `now_ns` internally but does not include it in
output).

### Tasks

- [ ] Read session token at startup from `/var/run/sema/session` (shared/S-3).
      Cache it in a global at startup — it does not change during a session.
- [ ] Add a global `seq: std.atomic.Value(u64)` counter initialized to 1
- [ ] Refactor `output.emitSemanticEvent` and `gesture.GestureRecognizer.
      emitGestureEvent` to include:
  - `"subsystem": "semainput"`
  - `"session": "<token>"`
  - `"seq": N` (atomically incremented)
  - `"ts_wall_ns": N` (from `std.time.nanoTimestamp()` at emit time)
  - `"ts_audio_samples": null` (null until I-3 implements clock reading)
- [ ] Update `semainputd.zig`'s `daemon_start`, `classification_snapshot`, and
      `identity_snapshot` emissions similarly
- [ ] Confirm output remains valid JSON-lines after the change (each line is
      a complete JSON object followed by `\n`)

### Acceptance Criteria

- All emitted lines include `subsystem`, `session`, `seq`, `ts_wall_ns`,
  `ts_audio_samples`
- `seq` increments by 1 for each emitted line across all event types
- `jq` can parse the output stream without errors

---

## I-2 — Keyboard Event Passthrough

**Status**: Open
**Effort**: Small
**Depends on**: I-1 (schema adoption, so keyboard events have correct schema)

### Background

`semantic.zig` defines `key_down` and `key_up` events, and `output.zig`
handles them. However, the evdev adapter and the main pipeline need to be
verified to correctly discover and route keyboard events. The current test
hardware focus has been on pointer and touch devices; keyboard handling is
structurally present but less exercised.

### Tasks

- [ ] Verify keyboard devices are discovered by `evdev.discover()` and opened
      by `openAllEventDevices`
- [ ] Confirm that `KEY_*` evdev events are translated to `key_down`/`key_up`
      semantic events in the adapter
- [ ] Add key repeat suppression: if the same key code is held, emit `key_down`
      once and suppress repeats (evdev sends `value=2` for repeat; these should
      not generate new events)
- [ ] Emit keymap metadata in `identity_snapshot`: include a `has_keyboard`
      field per device mapping so consumers know which logical device is the
      keyboard
- [ ] Add a manual test procedure in `docs/SystemInterface.md` for verifying
      keyboard events

### Acceptance Criteria

- Pressing and releasing a key produces exactly one `key_down` and one `key_up`
- Holding a key does not produce multiple `key_down` events
- `identity_snapshot` includes keyboard devices with `has_keyboard: true`

---

## I-3 — Audio Clock Timestamping

**Status**: Open
**Effort**: Small
**Depends on**: shared/S-4 (clock publication), I-1 (unified schema adopted)

### Background

Once the semaaud sample position counter is published as a shared memory region
(S-4), semainput can read the current audio clock position at the moment of
event emission and include it as `ts_audio_samples`. This turns input events
into audio-clock-relative observations, which is what chronofs requires: input
events can be resolved to "what was happening at audio sample N" rather than
relying on wall-clock correlation.

### Tasks

- [ ] Link `shared/src/clock.zig` into the semainput build (`build.zig.zon`
      or direct path reference)
- [ ] At daemon startup, open a `ClockReader` against `/var/run/sema/clock`
      in a non-fatal way: if the file does not exist, proceed with
      `ts_audio_samples: null`
- [ ] In `output.emitSemanticEvent` and `gesture.GestureRecognizer.
      emitGestureEvent`, read the current clock position just before writing
      to stdout:
  ```zig
  const samples = if (clock_reader) |r| r.read() else null;
  ```
- [ ] If `clock_valid` is false (no audio stream active), emit null
- [ ] Update `docs/SystemInterface.md` to document `ts_audio_samples` semantics

### Acceptance Criteria

- When semaaud has an active stream, `ts_audio_samples` is a non-null u64 in
  all emitted events
- When semaaud is not running or has no active stream, `ts_audio_samples` is
  null
- The clock reader failure (file missing, mmap fails) is non-fatal and logs a
  warning to stderr

---

## I-4 — Gesture Tuning: Pinch Scale Factor

**Status**: Open
**Effort**: Small
**Depends on**: Nothing

### Background

The pinch gesture emits a `delta` value computed as
`(cur_dist² - prev_dist²) / 128`. The divisor of 128 is an untuned constant.
The `scale_hint` field emits `"in"` or `"out"` but not a calibrated scale
factor that applications could use directly. For NDE applications to implement
pinch-to-zoom, they need a usable scale value.

### Tasks

- [ ] Replace `delta / 128` with a calibrated formula that approximates the
      actual distance change in pixels: `sqrt(cur_dist²) - sqrt(prev_dist²)`.
      Zig's `std.math.sqrt` works on floats; use integer approximation if
      avoiding float is preferred.
- [ ] Add a `scale_factor` field to `pinch` events: `cur_distance /
      prev_distance` as a fixed-point f32 (e.g., `1.05` = 5% larger). This is
      the standard pinch scale contract used by most gesture APIs.
- [ ] Keep the existing `delta` field for backward compatibility
- [ ] Add `scale_factor` to `pinch_begin` as well (initial value = 1.0)
- [ ] Document the `scale_factor` semantics in `docs/GestureLayer.md`

### Acceptance Criteria

- A slow outward pinch produces `scale_factor` values incrementally above 1.0
- A fast inward pinch produces `scale_factor` values below 1.0
- `scale_factor` is always positive and finite
