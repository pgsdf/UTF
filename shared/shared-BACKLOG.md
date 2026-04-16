# shared/ Backlog

The `shared/` directory is the cross-cutting infrastructure layer for the
Unified Temporal Fabric. It provides the single source of truth for protocol
constants, the unified event log schema, the session identity model, and
eventually the clock publication interface that all four daemons read.

---

## S-1 — Protocol Constants Code Generator

**Status**: Done
**Effort**: Small
**Blocks**: S-2, and any future protocol constant additions across any subsystem

### Background

`protocol_constants.json` already contains the canonical values for all three
protocol namespaces (drawfs, semadraw IPC, SDCS). The `shared/README.md`
describes the intent to generate language-specific bindings from it. Currently
nothing is generated — the JSON is documentation only. Two of the four critical
protocol mismatches identified in `PROTOCOL_MISMATCH_FINDINGS.md` were
doc-vs-implementation drift that a generator would have prevented.

### Tasks

- [ ] Write `shared/tools/gen_constants.py` (or `gen_constants.zig`) that reads
      `protocol_constants.json` and emits:
  - `drawfs/sys/dev/drawfs/drawfs_proto_generated.h` — C `#define` constants
    for all message type values and error codes
  - `semadraw/src/ipc/protocol_generated.zig` — Zig `pub const` declarations
    matching the Zig enum values in `protocol.zig`
  - `semadraw/src/sdcs_generated.zig` — Zig `pub const` declarations for SDCS
    opcodes
- [ ] Add a validation mode to the generator: reads the JSON, reads the
      existing hand-written source files, and diffs them. Exits non-zero on any
      discrepancy.
- [ ] Document the generator in `shared/README.md` with usage instructions
- [ ] Add a note in each generated file header: "Do not edit. Generated from
      shared/protocol_constants.json."

### Acceptance Criteria

- Running the generator produces output that matches the current hand-written
  constants exactly
- Running the generator in validation mode exits 0 against the current codebase
- The README explains how to add a new constant

---

## S-2 — Unified Event Log Schema

**Status**: Open
**Effort**: Small
**Depends on**: S-3 (session identity, for the `session` field)
**Blocks**: semaaud A-3, semainput I-2, semadraw D-1

### Background

The four daemons currently emit events in incompatible formats. `semaaud` writes
JSON to filesystem paths under `/tmp/draw/audio/{target}/`. `semainput` writes
JSON-lines to stdout. `semadraw` emits nothing. The chronofs prototype (C-1
through C-4) requires a unified timestamped event format across all domains.

### Tasks

- [ ] Define the schema in `shared/EVENT_SCHEMA.md`. Required fields for every
      event:
  - `type` (string) — event type identifier
  - `subsystem` (string) — `"semaaud"` | `"semainput"` | `"semadraw"` |
    `"drawfs"`
  - `session` (string) — session token from S-3
  - `seq` (u64) — per-subsystem monotonic sequence number
  - `ts_wall_ns` (i64) — wall-clock nanoseconds (already exists in semaaud as
    `ts_mono_ns`)
  - `ts_audio_samples` (u64 | null) — audio clock position at event time; null
    until S-4 (clock publication) is implemented
- [ ] Define the output channel convention: JSON-lines to stdout for all four
      daemons. Document that the caller (a future log aggregator or chronofs) is
      responsible for routing.
- [ ] List the per-subsystem event types in the schema document, taken from the
      current implementations:
  - semaaud: `stream_begin`, `stream_end`, `stream_reject`, `stream_preempt`,
    `stream_stop`, `stream_flush`, `stream_reroute`, `stream_group_block`,
    `stream_group_preempt`
  - semainput: `daemon_start`, `classification_snapshot`, `identity_snapshot`,
    all semantic and gesture event types
  - semadraw: (to be defined in D-1)

### Acceptance Criteria

- `shared/EVENT_SCHEMA.md` exists and is unambiguous about required fields,
  types, and nullability
- Each subsystem backlog item that adds event emission references this schema

---

## S-3 — Session Identity

**Status**: Open
**Effort**: Small
**Blocks**: S-2 (schema `session` field), all subsystem event log convergence
  items

### Background

There is no shared concept of a session that spans all four daemons. Each daemon
runs independently. The event logs cannot be correlated without a common token.
The chronofs model requires knowing that a given audio stream, set of surfaces,
and input device state all belong to the same session.

### Tasks

- [ ] Define a session token format in `shared/SESSION.md`: a
      monotonically-incrementing u64 rendered as a hex string, written to
      `/var/run/sema/session` at fabric startup. If the file already exists and
      is readable, the token is read from it; if not, a new token is generated
      from `std.crypto.random` or a startup timestamp.
- [ ] Write `shared/src/session.zig`: a small Zig module with two functions:
  - `readOrCreate(path: []const u8) !u64` — reads the token or generates and
    writes it
  - `format(token: u64, buf: []u8) []u8` — renders as lowercase hex
- [ ] Document the expected startup sequence: whichever daemon starts first
      creates the token; subsequent daemons read it.
- [ ] Document that the session token changes only on full fabric restart, not
      on individual daemon restart.

### Acceptance Criteria

- `shared/src/session.zig` compiles standalone (`zig build-lib`)
- Two processes calling `readOrCreate` on the same path always read the same
  value after the first write
- The module has no dependencies outside the Zig standard library

---

## S-4 — Clock Publication Interface

**Status**: Open
**Effort**: Small–Medium
**Depends on**: semaaud A-2 (audio sample counter must exist before it can be
  published)
**Blocks**: semainput I-3, chronofs C-1

### Background

The chronofs architecture requires a single global monotonic clock driven by
audio hardware. `semaaud`'s stream worker writes PCM bytes to the OSS device;
after A-2 is implemented, it will maintain a sample counter. S-4 exposes that
counter to other daemons as a shared memory region so they can read the current
audio clock position without any IPC round-trip.

### Tasks

- [ ] Define the clock region layout in `shared/CLOCK.md`:
  - A memory-mapped file at `/var/run/sema/clock`
  - Layout: `{ magic: u32, version: u8, _pad: [3]u8, sample_rate: u32,
    samples_written: u64 }` — 20 bytes total, naturally aligned
  - `magic`: `0x534D434B` ("SMCK")
  - `samples_written` is written with an atomic store by semaaud's stream
    worker, read with an atomic load by other daemons
- [ ] Write `shared/src/clock.zig`:
  - `ClockWriter` — opens/creates the mapped file, writes `samples_written`
    atomically. Used by semaaud.
  - `ClockReader` — opens the mapped file read-only, reads `samples_written`
    atomically. Used by semainput, semadraw, chronofs.
  - `toNanoseconds(samples: u64, sample_rate: u32) u64` — converts sample
    position to nanoseconds
- [ ] Add a `clock_valid` flag (bool in the region) that semaaud sets to true
      only after the first stream begins, so readers can distinguish "no audio
      has started yet" from "audio is at position 0"

### Acceptance Criteria

- `shared/src/clock.zig` compiles standalone
- A test program with two threads (writer and reader) confirms atomic visibility
  of `samples_written` updates
- `clock_valid` is false before any audio stream starts and true afterward
