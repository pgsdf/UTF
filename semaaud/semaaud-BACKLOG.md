# semaaud Backlog

`semaaud` is the audio daemon: OSS output on FreeBSD, two named targets
(`default` and `alt`), a policy engine with allow/deny/override/group
semantics, preemption, fallback routing, and filesystem-backed state. Phase 12
(durable policy validation surfaces) is the current active phase.

---

## A-1 — Complete Phase 12 Durable Policy Validation

**Status**: Done
**Effort**: Small
**Depends on**: Nothing (self-contained)

### Background

Phase 12 adds `policy-valid` and `policy-errors` surface files to the
filesystem state layout (implemented in `state.zig` as
`writePolicyValidationFiles`). The spec document
(`docs/SemaAud-Phase12-DurablePolicy-Spec.md`) describes versioned grammar,
comments in policy files, and persistent validation surfaces. The preserved base
ZIP (`README-PRESERVED-BASE.txt`) is the Phase 11 checkpoint.

### Tasks

- [ ] Confirm `policy-valid` is written correctly: `"true"` when `isValid()`
      returns true, `"false"` otherwise
- [ ] Confirm `policy-errors` lists each error from `loaded.errors.items` one
      per line
- [ ] Add support for `# comment` lines in policy files — the parser already
      skips `#`-prefixed lines, but confirm this is tested
- [ ] Add `version=1` as a recognized and validated grammar element — already
      partially implemented, confirm error on version ≠ 1
- [ ] Write a test matrix: policy files with various combinations of valid/
      invalid directives, confirm `policy-valid` and `policy-errors` reflect
      each case accurately
- [ ] Update `docs/SemaAud-Phase12-DurablePolicy-Spec.md` with the final
      grammar description and the list of recognized directives

### Acceptance Criteria

- A policy file with an unknown directive produces `policy-valid=false` and
  `policy-errors` containing the unknown directive message
- A policy file with `version=2` produces an unsupported version error
- A valid policy file with comments produces `policy-valid=true` and empty
  `policy-errors`

---

## A-2 — Audio Sample Position Counter

**Status**: Done
**Effort**: Small
**Blocks**: shared/S-4 (clock publication), chronofs C-1

### Background

The stream worker's inner loop is:
```zig
const n = posix.read(args.conn, &buf) catch break;
if (n == 0) break;
_ = try posix.write(args.audio_fd, buf[0..n]);
```
There is no accounting of how many PCM bytes have been written to the OSS
device. The chronofs architecture requires an audio-hardware-driven monotonic
clock. The sample counter is the basis of that clock: every write of `n` bytes
to a 48kHz stereo s16le stream advances the position by `n / 4` samples.

### Tasks

- [ ] Add `samples_written: std.atomic.Value(u64)` to `Shared`
- [ ] In the stream worker write loop, after each successful `posix.write`,
      compute `samples_delta = n / bytes_per_sample_frame` and atomically add
      to `samples_written`
  - `bytes_per_sample_frame` = `channels * (bit_depth / 8)` = 4 for stereo s16le
  - Already parsed from the stream header: `desc.channels` and `desc.format`
- [ ] Reset `samples_written` to 0 when a new stream begins (or keep it
      monotonic across streams — document the choice; monotonic is preferable
      for chronofs)
- [ ] Expose `samples_written` in the `RuntimeState.renderJson` output as
      `"samples_written": N`
- [ ] Expose `sample_rate` from the active `StreamDescriptor` in the state JSON

### Acceptance Criteria

- After playing 1 second of 48kHz stereo s16le audio, `samples_written` reads
  48000 (±1 for rounding)
- The counter does not reset between preemption/override transitions if monotonic
  mode is chosen
- `renderJson` includes both `samples_written` and `sample_rate`

---

## A-3 — Unified Event Log Schema Adoption

**Status**: Open
**Effort**: Medium
**Depends on**: shared/S-2 (schema), shared/S-3 (session identity)

### Background

`semaaud` currently writes events to filesystem files under
`/tmp/draw/audio/{target}/stream/events`. The format is JSON but the schema is
ad-hoc and inconsistent with what `semainput` emits. To build a unified event
log, `semaaud`'s events need to adopt the unified schema: JSON-lines to stdout,
with `subsystem`, `session`, `seq`, `ts_wall_ns`, and `ts_audio_samples` fields.

The filesystem state surfaces (`state`, `policy-state`, `policy-valid`, etc.)
are a separate concern from the event log and should be retained — they are used
by the control server for introspection, not for chronofs.

### Tasks

- [ ] Read session token at startup from `/var/run/sema/session` (shared/S-3)
- [ ] Add a stdout event emitter in `state.zig` alongside the existing
      filesystem writers:
  - `emitEvent(allocator, meta, event_type, fields_json)` — writes one JSON
    line to stdout following the unified schema
- [ ] Update each `appendStream*Event` function to also call `emitEvent` with
      the appropriate `type` string and payload fields
- [ ] Include `ts_audio_samples` in all events: read from `shared.samples_written`
      (from A-2) at the moment of event creation; null if no stream is active
- [ ] Retain all existing filesystem writes — they remain for the control server
      and for human inspection

### Acceptance Criteria

- Every `stream_begin`, `stream_end`, `stream_reject`, `stream_preempt` event
  appears on stdout as a valid JSON line
- Each line validates against the unified schema (required fields present,
  correct types)
- `ts_audio_samples` is non-null during an active stream and null otherwise
- Filesystem state files are unaffected

---

## A-4 — Sample Rate Negotiation

**Status**: Open
**Effort**: Small
**Depends on**: A-2

### Background

The stream worker's `parseHeader` function rejects any sample rate that is not
exactly 48000Hz and any channel count that is not exactly 2. This is a
reasonable default but too rigid. Different audio hardware may prefer 44100Hz or
96kHz. For chronofs, the sample rate must be known to convert sample positions to
nanoseconds — which `shared/clock.zig` (S-4) will do via
`toNanoseconds(samples, sample_rate)`.

### Tasks

- [ ] Expand `types.StreamFormat` to include at minimum `s16le` and `s32le`
- [ ] Query the OSS device's supported sample rates using `SNDCTL_DSP_SPEED`
      before accepting a stream
- [ ] Accept any sample rate that the hardware supports; reject with a clear
      error message if not supported
- [ ] Negotiate channel count: accept 1 or 2; configure OSS accordingly with
      `SNDCTL_DSP_CHANNELS`
- [ ] Write the negotiated `sample_rate` and `channels` into `shared` so that
      A-2's counter and S-4's clock publication use the correct values
- [ ] Document the negotiation flow in `docs/SemaAud-Roadmap.md`

### Acceptance Criteria

- A client submitting a 44100Hz stream is accepted if hardware supports it and
  rejected with a clear error if not
- `samples_written` remains accurate after negotiation (division uses actual
  `channels` and `format` from the negotiated descriptor)
