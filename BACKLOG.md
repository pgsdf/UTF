# UTF Backlog

This is the **single, consolidated backlog** for the Unified Temporal
Fabric. It replaces the per-subsystem backlogs that previously lived at
`drawfs/drawfs-BACKLOG.md`, `semadraw/semadraw-BACKLOG.md`,
`semaaud/semaaud-BACKLOG.md`, `semainput/semainput-BACKLOG.md`,
`chronofs/chronofs-BACKLOG.md`, and `shared/shared-BACKLOG.md`.

Those files remain as short pointers to this one, so existing links and
references continue to resolve, but they are no longer the source of
truth for tasks. This file is.

---

## How to read this

Work is grouped by substrate, with each item numbered in its historical
ID (e.g. `DF-1`, `C-3`, `A-2`) so external references don't break.
Status is tracked per item:

- `[x] Done` — implemented, landed on `master`, acceptance criteria met.
- `[~] Fix applied, awaiting verification` — code change is in place but
  confirmation on the target host is pending. Flips to `[x]` once the
  relevant test run or smoke check comes back clean.
- `[ ] Open` — not yet started.
- `[ ] Deferred` — consciously postponed, with a note explaining why.

Priorities are **P0** (project-level invariant or blocker), **P1**
(near-term, directly unblocks downstream work), **P2** (valuable but
not on the critical path), or unset for items that don't need ranking.

All seven implementation waves (the original chronofs-anchored
dependency chain) are complete. The current theme is: **make DRM
strictly optional** — preserve the DRM-less default path as UTF's
unbreakable invariant while allowing opt-in DRM for users who want it.

---

## Current theme: make DRM strictly optional

The goal is that the DRM-less swap path remains the unbreakable default
and that DRM/KMS support is a strictly optional add-on. A user running
`sh configure.sh` and accepting defaults must produce a `drawfs.ko`
with no DRM references, no `drm-kmod` build dependency, and no
`drm-kmod` load dependency.

### Non-goals

- Making DRM the default. It will never be the default.
- Detecting drm-kmod automatically. Autodetection leaks the opinion
  that "DRM is better" into the build; it is not.
- Removing `drawfs_drm.c` or the kernel-side `#ifdef
  DRAWFS_DRM_ENABLED` gates. They are correct already.
- Surfacing DRM backend selection through `semadrawd` CLI. `semadrawd
  -b drawfs` is agnostic to the kernel backend.

---

## Project-level invariants

These hold across all changes. Any future work that would break one
needs its own backlog item first, documenting why the invariant is
changing.

1. `sh configure.sh` with all defaults → swap-only `drawfs.ko`.
2. `drm-kmod` is never a build-time or load-time hard dependency.
3. `hw.drawfs.backend` defaults to `"swap"` at module load.
4. DRM init failure at module load falls back to swap — never panics,
   never prevents load.
5. Renaming `DRAWFS_DRM_ENABLED` requires coordinating with every
   `#ifdef` in `drawfs.c`, `drawfs_drm.c`, and both Makefiles.
6. `UTF_OS` detection is informational only. Any future use that
   branches build behavior on it must be justified by a concrete,
   observable divergence between FreeBSD and GhostBSD, not a
   speculation.

---

## Shared infrastructure (`shared/`)

Cross-cutting code used by all four daemons: protocol constants, the
event schema, session identity, clock publication.

### `[x]` S-1 — Protocol Constants Code Generator  *(Done, Small)*

Single source of truth for protocol constants across drawfs, semadraw
IPC, and SDCS. `shared/tools/gen_constants.py` reads
`protocol_constants.json` and emits C headers and Zig constant
declarations with a validation mode that diffs against the
hand-written sources. Two of the four critical PROTOCOL_MISMATCH
findings were drift that this generator now prevents structurally.

### `[x]` S-2 — Unified Event Log Schema  *(Done, Small; blocks: A-3, I-1, D-1)*

All four daemons emit JSON-lines to stdout with a common envelope:
`type`, `subsystem`, `session`, `seq`, `ts_wall_ns`,
`ts_audio_samples`. Documented in `shared/EVENT_SCHEMA.md`.
Filesystem state surfaces (e.g. semaaud's `/tmp/draw/audio/…`) are a
separate concern — retained for introspection, not for chronofs.

### `[x]` S-3 — Session Identity  *(Done, Small; blocks: S-2, all event-log convergence)*

`u64` token rendered as 16 hex chars, written to
`/var/run/sema/session` at fabric startup. Whichever daemon starts
first calls `readOrCreate`; the rest read the existing token. Survives
individual daemon restarts, dies with the tmpfs on reboot.
`shared/src/session.zig`.

### `[x]` S-4 — Clock Publication Interface  *(Done, Small–Medium; depends: A-2; blocks: I-3, C-1)*

20-byte mmap region at `/var/run/sema/clock` with magic `SMCK`, version,
`clock_valid`, `sample_rate`, `samples_written`. Seq-cst atomic stores
by semaaud; atomic loads by every other daemon — no IPC round-trip.
`shared/src/clock.zig` provides `ClockWriter`, `ClockReader`, and
`toNanoseconds(samples, sample_rate)`.

---

## `drawfs` — kernel spatial substrate

`/dev/draw` character device, surface lifecycle, mmap-backed pixel
buffers, framed binary protocol, input event injection.

### `[x]` DF-1 — Verify Integration Against Repaired semadraw Backend  *(Done, Small)*

Integration smoke test covering `RESET`, `SET_BLEND`, `SET_ANTIALIAS`,
`FILL_RECT`, `STROKE_RECT`, `STROKE_LINE`, `END` against a loaded
`drawfs.ko`. Surface pixel output matches software renderer golden
images. Python integration test lives in `drawfs/tests/`.

### `[x]` DF-2 — Input Event Delivery  *(Done, Medium; depends: I-1)*

Kernel-side input injection via `DRAWFSGIOC_INJECT_INPUT` ioctl. Event
types `EVT_KEY`, `EVT_POINTER`, `EVT_SCROLL`, `EVT_TOUCH` in the
`0x9xxx` event range. Delivery is non-blocking on the rendering path
and observes the existing surface-event backpressure rules.

### `[x]` DF-3 — DRM/KMS Display Bring-up (Phase 2)  *(Done — skeleton, Large; depends: DF-1)*

`drawfs_drm.c` skeleton present: connector/CRTC enumeration, mode set
on `DISPLAY_OPEN`, dumb buffer allocation, page flip on
`SURFACE_PRESENT`. Gated behind `hw.drawfs.backend` sysctl. **The
skeleton compiles only when `DRAWFS_DRM_ENABLED` is passed to
make(1)**, which is the build-system change tracked under the
DRM-optional theme below. Actual hardware bring-up is deferred until
someone has matching hardware to exercise it.

### `[ ]` DF-4 — Verify on FreeBSD 15 debug kernel (WITNESS)  *(Deferred, Small)*

Rerun the drawfs test suite against a FreeBSD 15 kernel built with
`WITNESS`, `WITNESS_SKIPSPIN`, and `INVARIANTS` enabled. This stresses
the locking-order discipline in `drawfs.c` and `drawfs_surface.c`
(session mutex, surface mutex, vm_object lock) in a way that the
release kernel does not.

**Deferred**: requires access to a host or VM running a debug-built
FreeBSD 15 kernel. None currently available. Pick this up when one is.
Migrated from `drawfs/docs/ROADMAP.md` as part of B5.3.

### `[x]` DF-5 — Fix async-event drain races in input-injection tests  *(Done; depends: DF-2)*

Running the full test suite (after SPRINT-04a's `build.sh` test-verb
fix made that possible) surfaced four pre-existing failures, all with
the same shape: tests expect a specific reply message but read an
asynchronous event that arrived in the queue first — plus a fourth
test (`test_event_queue_backpressure`) whose underlying design was
incompatible with normative coalescing behavior.

**Root cause**: `drawfs_test.py` already had the infrastructure to
skip events (`drain_until`, `skip_events=True` parameters on
`surface_destroy` / `surface_present`). The input-injection tests
just didn't use it after paths that enqueue events — but one of them
had a queue too large for `drain_until`'s default `max_msgs=20` to
handle. The `test_limits.py` backpressure test fought the protocol:
per `docs/PROTOCOL.md` line 167, "Multiple SURFACE_PRESENTED events
for the same surface may be coalesced under backpressure" — coalescing
is normative, and a test loop that read one reply per present could
never accumulate enough queue pressure to hit ENOSPC with a single
surface.

**Fixes**:

- `test_input_injection.py::test_evt_touch_delivery` — cleanup
  destroy uses `skip_events=True`.
- `test_input_injection.py::test_event_delivery_does_not_block_present`
  — replaced a hand-rolled event-skip loop (which had a subtle bug
  where it swallowed events without reading past them on the
  "other event" branch) with `drain_until(fd, RPL_SURFACE_PRESENT,
  max_msgs=40)`; cleanup destroy uses `skip_events=True`.
- `test_input_injection.py::test_backpressure_enospc` — explicit
  `receiver.drain_all()` before cleanup destroy (queue of ~200
  events exceeds `drain_until`'s default message cap).
- `test_limits.py::test_event_queue_backpressure` — rewritten per
  the specification. The test now does what `docs/TEST_PLAN.md`
  § Step 19 actually says: write presents without reading, catch
  ENOSPC as an `OSError` from `write(2)` itself (matching the
  kernel's behavior at `drawfs.c:997-999`), drain the queue, send
  one more write to verify recovery. No helper, no reading during
  accumulation, no fighting with coalescing.

**Verification**: full 11/11 test suite green on GhostBSD 15.
Backpressure test hits ENOSPC after 169 presents (= 169 × 48 byte
replies + overhead ≈ `max_evq_bytes=8192`) and recovers cleanly
after drain.

**Not a regression** from B3.1–B3.3 pass 1. The validator added in
pass 1 still has no callers, so it cannot affect any code path.
These failures reached the surface only because `./build.sh test`
had been broken long enough that the full suite hadn't been
exercised in a while.

---

## `semadraw` — semantic rendering substrate

`libsemadraw` for clients, `semadrawd` compositor, SDCS command stream
format, backends (software, drawfs, Vulkan, DRM/KMS, X11, Wayland,
vulkan_console, headless).

### `[x]` D-1 — Event Emission in Unified Schema  *(Done, Small–Medium; depends: S-2, S-3)*

`surface_created`, `surface_destroyed`, `frame_complete`,
`client_connected`, `client_disconnected` events emitted on stdout in
the unified schema. `frame_complete` includes `ts_audio_samples` taken
from the frame scheduler's target sample position, not the wall clock.

### `[x]` D-2 — drawfs Backend Render State  *(Done, Small; depends: DF-1)*

`RenderState` in `src/backend/drawfs.zig` tracks `blend_mode`,
`antialias`, `stroke_join`, `stroke_cap`. Golden-image parity with the
software renderer for state-change mid-sequence scenes. Render state
does not leak between client sessions.

### `[x]` D-3 — Frame Scheduler Clock Abstraction  *(Done, Small; blocks: C-4)*

`ClockSource` interface in `src/compositor/frame_scheduler.zig`;
`WallClockSource` is the default, `MockClockSource` supports
deterministic testing. No `std.time` calls remain directly in the
scheduler. This was the preparatory refactor for audio-driven
scheduling.

### `[x]` D-4 — `DRAW_GLYPH_RUN` in drawfs Backend  *(Done, Medium; depends: D-2)*

Opcode `0x0030` implemented in the drawfs backend with correct CJK
double-width handling. `semadraw-term` now runs on the drawfs backend.
Output matches software-renderer golden images within a 1-pixel
tolerance.

### `[x]` D-5 — Remote Transport Hardening  *(Done, Small)*

TCP loopback round-trip test; abrupt-disconnect test does not crash
`semadrawd` or leak surfaces; read timeout prevents stalled remote
clients from holding surfaces indefinitely. `docs/API_OVERVIEW.md`
documents the TCP transport alongside the Unix socket.

---

## `semaaud` — audio daemon

OSS output, two named targets (`default`, `alt`), policy engine with
allow/deny/override/group semantics, preemption, fallback routing.

### `[x]` A-1 — Phase 12 Durable Policy Validation  *(Done, Small)*

`policy-valid` and `policy-errors` surface files; `#` comment support;
`version=1` recognised and validated; unknown-directive and unsupported-
version errors surface correctly. Spec in
`docs/SemaAud-Phase12-DurablePolicy-Spec.md`.

### `[x]` A-2 — Audio Sample Position Counter  *(Done, Small; blocks: S-4, C-1)*

`samples_written: std.atomic.Value(u64)` in `Shared`, advanced by
`n / bytes_per_sample_frame` after every successful
`posix.write(audio_fd)`. Monotonic across streams (does not reset on
preempt/override). Exposed in `RuntimeState.renderJson` alongside
`sample_rate`.

### `[x]` A-3 — Unified Event Log Schema Adoption  *(Done, Medium; depends: S-2, S-3)*

`emitEvent` in `state.zig` writes JSON-lines to stdout in the unified
schema. Every `stream_begin`/`stream_end`/`stream_reject`/
`stream_preempt`/… event appears on stdout in addition to the
filesystem surfaces. `ts_audio_samples` is non-null during an active
stream and null otherwise.

### `[x]` A-4 — Sample Rate Negotiation  *(Done, Small; depends: A-2)*

`parseHeader` no longer hardcodes 48000Hz/stereo/s16le. `SNDCTL_DSP_SPEED`
and `SNDCTL_DSP_CHANNELS` negotiate with the OSS device; `s16le` and
`s32le` are both accepted. Clients are rejected with a clear error on
unsupported rates. `samples_written` remains accurate because the
division uses the negotiated `channels` and `format`.

---

## `semainput` — input daemon

evdev device discovery, classification and fingerprinting, logical
identity aggregation, pointer smoothing, gesture recognition.

### `[x]` I-1 — Unified Event Log Schema Adoption  *(Done, Small; depends: S-2, S-3)*

`emitSemanticEvent` and `emitGestureEvent` include `subsystem`,
`session`, `seq`, `ts_wall_ns`, and (initially null) `ts_audio_samples`.
`seq` increments monotonically across all event types. `jq` parses the
stream without errors.

### `[x]` I-2 — Keyboard Event Passthrough  *(Done, Small; depends: I-1)*

Keyboard discovery verified; `KEY_*` evdev events translate to
`key_down`/`key_up`; key-repeat suppression (evdev `value=2` ignored);
`identity_snapshot` includes `has_keyboard` per logical device.

### `[x]` I-3 — Audio Clock Timestamping  *(Done, Small; depends: S-4, I-1)*

`ClockReader` opened at startup against `/var/run/sema/clock`;
`ts_audio_samples` populated at event emission time when
`clock_valid == 1`, null otherwise. Clock-reader failure is non-fatal.

### `[x]` I-4 — Gesture Tuning: Pinch Scale Factor  *(Done, Small)*

`scale_factor = cur_distance / prev_distance` added to `pinch_begin`
and `pinch` events as f32. The `delta` formula recalibrated to
`sqrt(cur²) - sqrt(prev²)`. Backward-compatible `delta` and
`scale_hint` retained.

---

## `chronofs` — temporal coordination layer

Clock, event streams, resolver, audio-driven frame scheduler, diagnostic
tool. All items below are complete; chronofs is the working realisation
of the `docs/Thoughts.md` design.

### `[x]` C-1 — Clock Module  *(Done, Small; depends: S-4)*

`chronofs/src/clock.zig` wraps `shared.clock.ClockReader` with `now()`,
`isValid()`, `toNs()`, `sampleRate()`. `MockClock` for deterministic
tests.

### `[x]` C-2 — Event Stream Buffers  *(Done, Medium; depends: C-1)*

`EventStream(T, capacity)` generic ring buffer with thread-safe
`append`, `query(t_start, t_end)`, `at(t)`, `latest()`. `DomainStreams`
owns one per domain (audio/visual/input). Event payload types defined:
`AudioEvent`, `VisualEvent`, `InputEvent`.

### `[x]` C-3 — Resolver  *(Done, Medium; depends: C-2)*

`Resolver` with `resolveVisual`/`resolveInput`/`resolveAudio`/
`currentTime`. JSON-lines ingest helpers per subsystem
(`ingestSemaaudLine`, `ingestSemainputLine`, `ingestSemadrawLine`).
Ingestion driver spawns a thread per subsystem reading a pipe.

### `[x]` C-4 — Audio-Driven Frame Scheduler Integration  *(Done, Medium; depends: C-3, D-3)*

`ChronofsClockSource` adapts `chronofs.Clock` to the `ClockSource`
interface. `nextFrameTarget(clock, refresh_rate_hz)` computes the next
sample-aligned frame boundary (800 samples at 48kHz/60Hz). Frames are
rendered at the target position, not the current one. `ts_audio_samples`
in `frame_complete` events derives from the same counter — drift-free
AV synchronisation by construction.

### `[x]` C-5 — `chrono_dump` Diagnostic Tool  *(Done, Small; depends: C-3)*

Live timeline view; `--drift` computes frame-vs-audio-position deltas;
`--replay <file>` reads a recorded log and prints resolved state at
1000-sample intervals. Drift during steady-state playback < 1 frame
period.

---

## DRM-optional build system

Makes the DRM/KMS path a strictly opt-in feature while preserving the
swap-backed default as the unbreakable invariant.

### `[x]` B1.1 — `configure.sh` DRM checklist item  *(Done)*

Adds `drawfs_drm` to the bsddialog checklist (default off), writes
`DRAWFS_DRM=true|false` to `.config`.

### `[x]` B1.2 — `build.sh` reads DRAWFS_DRM  *(Done)*

Exports `DRAWFS_DRM` from `.config` to the environment so
`drawfs/build.sh` and any nested make(1) invocations see it.

### `[x]` B1.3 — `install.sh` propagates DRAWFS_DRM  *(Done)*

Reads `.config` before the kernel build so `drawfs/build.sh` inherits
the flag via environment.

### `[x]` B1.4 — `drawfs/build.sh` honors DRAWFS_DRM  *(Done)*

Translates `DRAWFS_DRM=true` into `DRAWFS_DRM_ENABLED=1` on the
`make(1)` command line for both the dev and modules kernel builds.

### `[x]` B1.5 — Kernel Makefile conditional  *(Done)*

Both `sys/dev/drawfs/Makefile` and `sys/modules/drawfs/Makefile` guard
`drawfs_drm.c` and `-DDRAWFS_DRM_ENABLED` behind
`.if defined(DRAWFS_DRM_ENABLED)`. Default builds produce a
`drawfs.ko` with zero DRM references.

### `[x]` B2.1 — `hw.drawfs.backend` sysctl  *(Already implemented; drawfs.c:1164)*

Defaults to `"swap"`, 16-byte string, `CTLFLAG_RW`.

### `[x]` B2.2 — DRM init fallback-to-swap  *(Already implemented; drawfs.c:1189)*

`MOD_LOAD` calls `drawfs_drm_init()` only when backend is `"drm"`.
Failure logs a warning and resets the sysctl to `"swap"`. Broken drm
drivers cannot prevent `drawfs.ko` from loading.

### `[x]` B2.3 — Regression test for `hw.drawfs.backend`

`drawfs/tests/test_backend_sysctl.py`. Asserts the sysctl exists,
defaults to `"swap"`, is read/write, and round-trips both `"swap"` and
`"drm"` as plain strings. Protects invariants 2.2, 3, and 4 above.

### `[x]` B4.1–B4.4 — OS detection (FreeBSD vs GhostBSD)  *(Done)*

`scripts/detect-os.sh` exports `UTF_OS` and `UTF_OS_VERSION` by
probing for `ghostbsd-version(1)`. `configure.sh` records them in
`.config` and tailors the drm-kmod advisory. `build.sh` re-detects at
build time and warns on a host mismatch. `install.sh` and
`drawfs/build.sh` inherit or re-detect.

### `[x]` B5.1 — README "Graphics Backends" section  *(Done)*
### `[x]` B5.2 — Consolidated root `BACKLOG.md`  *(Done — this file)*

### `[x]` B5.3 — Cross-link from `drawfs/docs/ROADMAP.md`  *(Done)*

`drawfs/docs/ROADMAP.md` now carries a blockquote at the top pointing
at this file as the source of truth for task tracking, and its
bottom-of-file `## Backlog` section has been removed. The surviving
"Remaining" item (WITNESS debug-kernel verification) was migrated to
DF-4 above.

---

## Deferred

### `[x]` B3.1 — Design `DRAWFS_REQ_SURFACE_PRESENT_REGION`  *(Done)*

Opcode assignment, wire format, semantics, error conditions, backward-
compatibility analysis, and design-alternatives writeup. Full spec lives
at `drawfs/docs/DESIGN-surface-present-region.md`. Key choices:

- New opcode `0x0023` with reply `0x8023` and event `0x9003`, rather
  than extending `SURFACE_PRESENT` (0x0022) via its reserved `flags`
  field. Preserves the fixed-size invariant of the existing struct.
- New shared `drawfs_rect` type (16 bytes).
- `DRAWFS_MAX_PRESENT_RECTS = 16` as a protocol-level cap.
- Server-side coalescing controlled by a 75% area threshold
  (`hw.drawfs.region_coalesce_threshold`).
- Clients are free to receive `EVT_SURFACE_PRESENTED_REGION` even for
  requests made via the old opcode (server-side flexibility).

Implementation (B3.2–B3.5) remains deferred pending sprint scheduling.

### `[x]` B3.2 — Protocol constants and struct headers  *(Done; depends: B3.1)*

Three entries added to `shared/protocol_constants.json`
(`REQ_SURFACE_PRESENT_REGION = 0x0023`,
`RPL_SURFACE_PRESENT_REGION = 0x8023`,
`EVT_SURFACE_PRESENTED_REGION = 0x9003`). Headers regenerated by
`shared/tools/gen_constants.py` — no generator changes needed. Struct
definitions (`drawfs_rect`, request, reply, event) hand-added to
`drawfs_proto.h` outside the sentinel blocks. `DRAWFS_MAX_PRESENT_RECTS
= 16` defined. Python test helpers in `drawfs/tests/drawfs_test.py`
updated with matching constants. Struct sizes verified by compile:
`drawfs_rect` 16 B, request header 24 B, reply 16 B, event header 16 B.
A pre-existing cosmetic drift on `EVT_POINTER`'s description was fixed
as a side effect of running the generator.

### `[x]` B3.3 — Damage / partial-update swap-path implementation  *(Done; depends: B3.2)*

Three-pass implementation of `DRAWFS_REQ_SURFACE_PRESENT_REGION` in
the swap-backed kernel path:

1. **Pass 1** (validator): pure function
   `drawfs_req_surface_present_region_validate` in `drawfs_frame.c`
   enforcing the full error table from the design doc. 15 userspace
   unit tests pass; kernel compile clean on GhostBSD 15.
2. **Pass 2** (dispatch + coalescing + sysctl): handler
   `drawfs_reply_surface_present_region` in `drawfs.c` with rect
   clamping, area-sum threshold coalescing, and event emission. New
   sysctl `hw.drawfs.region_coalesce_threshold` (int 0–100,
   default 75). 18 userspace unit tests on clamp and threshold
   arithmetic pass; kernel compile clean, sysctl exposed on target.
3. **Pass 3** (integration tests): `test_surface_present_region.py`
   exercising 18 cases — 8 error-table rows, 9
   happy-path/clamping/coalescing scenarios (including both
   threshold extremes), and the N=1-full-surface equivalence
   invariant. All pass on GhostBSD 15 target.

Design choices documented in
`drawfs/docs/DESIGN-surface-present-region.md`:
sum-of-areas coalescing (not true union), single event type
(`EVT_SURFACE_PRESENTED_REGION`) regardless of collapse, no
cross-request region-event coalescing.

### `[ ]` B3.4–B3.5 — Damage / partial-update: DRM path and semadraw emitter  *(Deferred, P2; depends: B3.3)*

With the swap path complete (B3.3), the remaining implementation is:

1. **B3.4** — DRM path. `drmModeDirtyFB` when the kernel DRM driver
   supports it, full-present fallback otherwise. Only meaningful
   with `DRAWFS_DRM_ENABLED`. Requires access to a drm-kmod-enabled
   FreeBSD 15 host to exercise end-to-end.
2. **B3.5** — semadraw emitter. Extend
   `semadraw/src/backend/drawfs.zig` to emit region presents when
   the compositor's damage tracker produces a bounded rect set.
   Requires B3.4 to be landed first for end-to-end testing.

**Non-goals** and **acceptance criteria** are documented in full at
`drawfs/docs/DESIGN-surface-present-region.md`.

---

## Implementation waves (historical)

The dependency chain that got chronofs to working order. Retained here
as an audit trail; every item is now closed above.

| Wave | Items | Dependency |
|------|-------|-----------|
| 1 | A-1, S-1, D-3, D-5, I-4 | None |
| 2 | S-3, A-2, DF-1 | Wave 1 |
| 3 | S-2, S-4, DF-2, D-2, A-4 | Wave 2 |
| 4 | I-1, A-3, D-1, C-1 | Wave 3 |
| 5 | I-2, I-3, D-4, DF-3, C-2 | Wave 4 |
| 6 | C-3 | Wave 5 |
| 7 | C-4, C-5 | Wave 6 |
