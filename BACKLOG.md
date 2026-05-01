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

- `[x] Done`: implemented, landed on `master`, acceptance criteria met.
- `[~] Fix applied, awaiting verification`: code change is in place but
  confirmation on the target host is pending. Flips to `[x]` once the
  relevant test run or smoke check comes back clean.
- `[ ] Open`: not yet started.
- `[ ] Deferred`: consciously postponed, with a note explaining why.

Priorities are **P0** (project-level invariant or blocker), **P1**
(near-term, directly unblocks downstream work), **P2** (valuable but
not on the critical path), or unset for items that don't need ranking.

All seven implementation waves (the original chronofs-anchored
dependency chain) are complete. The current theme is: **make DRM
strictly optional**, preserve the DRM-less default path as UTF's
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
4. DRM init failure at module load falls back to swap, never panics,
   never prevents load.
5. Renaming `DRAWFS_DRM_ENABLED` requires coordinating with every
   `#ifdef` in `drawfs.c`, `drawfs_drm.c`, and both Makefiles.
6. `UTF_OS` detection is informational only. Any future use that
   branches build behavior on it must be justified by a concrete,
   observable divergence on the FreeBSD target, not a speculation.
7. UTF depends only on code written with UTF's guarantees in mind.
   External dependencies are either replaced by UTF-owned code or
   explicitly accepted as named platform-transport dependencies.
   See `docs/UTF_ARCHITECTURAL_DISCIPLINE.md` for the accepted list
   and the three postures (Replace / Accept / Remove).

---

## Shared infrastructure (`shared/`)

Cross-cutting code used by all four daemons: protocol constants, the
event schema, session identity, clock publication.

### `[x]` S-1: Protocol Constants Code Generator  *(Done, Small)*

Single source of truth for protocol constants across drawfs, semadraw
IPC, and SDCS. `shared/tools/gen_constants.py` reads
`protocol_constants.json` and emits C headers and Zig constant
declarations with a validation mode that diffs against the
hand-written sources. Two of the four critical PROTOCOL_MISMATCH
findings were drift that this generator now prevents structurally.

### `[x]` S-2: Unified Event Log Schema  *(Done, Small; blocks: A-3, I-1, D-1)*

All four daemons emit JSON-lines to stdout with a common envelope:
`type`, `subsystem`, `session`, `seq`, `ts_wall_ns`,
`ts_audio_samples`. Documented in `shared/EVENT_SCHEMA.md`.
Filesystem state surfaces (e.g. semaaud's `/tmp/draw/audio/…`) are a
separate concern, retained for introspection, not for chronofs.

### `[x]` S-3: Session Identity  *(Done, Small; blocks: S-2, all event-log convergence)*

`u64` token rendered as 16 hex chars, written to
`/var/run/sema/session` at fabric startup. Whichever daemon starts
first calls `readOrCreate`; the rest read the existing token. Survives
individual daemon restarts, dies with the tmpfs on reboot.
`shared/src/session.zig`.

### `[x]` S-4: Clock Publication Interface  *(Done, Small–Medium; depends: A-2; blocks: I-3, C-1)*

20-byte mmap region at `/var/run/sema/clock` with magic `SMCK`, version,
`clock_valid`, `sample_rate`, `samples_written`. Seq-cst atomic stores
by semaaud; atomic loads by every other daemon, no IPC round-trip.
`shared/src/clock.zig` provides `ClockWriter`, `ClockReader`, and
`toNanoseconds(samples, sample_rate)`.

---

## `drawfs`: kernel spatial substrate

`/dev/draw` character device, surface lifecycle, mmap-backed pixel
buffers, framed binary protocol, input event injection.

### `[x]` DF-1: Verify Integration Against Repaired semadraw Backend  *(Done, Small)*

Integration smoke test covering `RESET`, `SET_BLEND`, `SET_ANTIALIAS`,
`FILL_RECT`, `STROKE_RECT`, `STROKE_LINE`, `END` against a loaded
`drawfs.ko`. Surface pixel output matches software renderer golden
images. Python integration test lives in `drawfs/tests/`.

### `[x]` DF-2: Input Event Delivery  *(Done, Medium; depends: I-1)*

Kernel-side input injection via `DRAWFSGIOC_INJECT_INPUT` ioctl. Event
types `EVT_KEY`, `EVT_POINTER`, `EVT_SCROLL`, `EVT_TOUCH` in the
`0x9xxx` event range. Delivery is non-blocking on the rendering path
and observes the existing surface-event backpressure rules.

### `[x]` DF-3: DRM/KMS Display Bring-up (Phase 2)  *(Done, skeleton, Large; depends: DF-1)*

`drawfs_drm.c` skeleton present: connector/CRTC enumeration, mode set
on `DISPLAY_OPEN`, dumb buffer allocation, page flip on
`SURFACE_PRESENT`. Gated behind `hw.drawfs.backend` sysctl. **The
skeleton compiles only when `DRAWFS_DRM_ENABLED` is passed to
make(1)**, which is the build-system change tracked under the
DRM-optional theme below. Actual hardware bring-up is deferred until
someone has matching hardware to exercise it.

### `[ ]` DF-4: Verify on FreeBSD 15 debug kernel (WITNESS)  *(Deferred, Small)*

Rerun the drawfs test suite against a FreeBSD 15 kernel built with
`WITNESS`, `WITNESS_SKIPSPIN`, and `INVARIANTS` enabled. This stresses
the locking-order discipline in `drawfs.c` and `drawfs_surface.c`
(session mutex, surface mutex, vm_object lock) in a way that the
release kernel does not.

**Deferred**: requires access to a host or VM running a debug-built
FreeBSD 15 kernel. None currently available. Pick this up when one is.
Migrated from `drawfs/docs/ROADMAP.md` as part of B5.3.

### `[x]` DF-5: Fix async-event drain races in input-injection tests  *(Done; depends: DF-2)*

Running the full test suite (after SPRINT-04a's `build.sh` test-verb
fix made that possible) surfaced four pre-existing failures, all with
the same shape: tests expect a specific reply message but read an
asynchronous event that arrived in the queue first, plus a fourth
test (`test_event_queue_backpressure`) whose underlying design was
incompatible with normative coalescing behavior.

**Root cause**: `drawfs_test.py` already had the infrastructure to
skip events (`drain_until`, `skip_events=True` parameters on
`surface_destroy` / `surface_present`). The input-injection tests
just didn't use it after paths that enqueue events, but one of them
had a queue too large for `drain_until`'s default `max_msgs=20` to
handle. The `test_limits.py` backpressure test fought the protocol:
per `docs/PROTOCOL.md` line 167, "Multiple SURFACE_PRESENTED events
for the same surface may be coalesced under backpressure", coalescing
is normative, and a test loop that read one reply per present could
never accumulate enough queue pressure to hit ENOSPC with a single
surface.

**Fixes**:

- `test_input_injection.py::test_evt_touch_delivery`: cleanup
  destroy uses `skip_events=True`.
- `test_input_injection.py::test_event_delivery_does_not_block_present`:
  replaced a hand-rolled event-skip loop (which had a subtle bug
  where it swallowed events without reading past them on the
  "other event" branch) with `drain_until(fd, RPL_SURFACE_PRESENT,
  max_msgs=40)`; cleanup destroy uses `skip_events=True`.
- `test_input_injection.py::test_backpressure_enospc`: explicit
  `receiver.drain_all()` before cleanup destroy (queue of ~200
  events exceeds `drain_until`'s default message cap).
- `test_limits.py::test_event_queue_backpressure`: rewritten per
  the specification. The test now does what `docs/TEST_PLAN.md`
  § Step 19 actually says: write presents without reading, catch
  ENOSPC as an `OSError` from `write(2)` itself (matching the
  kernel's behavior at `drawfs.c:997-999`), drain the queue, send
  one more write to verify recovery. No helper, no reading during
  accumulation, no fighting with coalescing.

**Verification**: full 11/11 test suite green on the FreeBSD target.
Backpressure test hits ENOSPC after 169 presents (= 169 × 48 byte
replies + overhead ≈ `max_evq_bytes=8192`) and recovers cleanly
after drain.

**Not a regression** from B3.1–B3.3 pass 1. The validator added in
pass 1 still has no callers, so it cannot affect any code path.
These failures reached the surface only because `./build.sh test`
had been broken long enough that the full suite hadn't been
exercised in a while.

---

## `semadraw`: semantic rendering substrate

`libsemadraw` for clients, `semadrawd` compositor, SDCS command stream
format, backends (software, drawfs, Vulkan, DRM/KMS, X11, Wayland,
vulkan_console, headless).

### `[x]` D-1: Event Emission in Unified Schema  *(Done, Small–Medium; depends: S-2, S-3)*

`surface_created`, `surface_destroyed`, `frame_complete`,
`client_connected`, `client_disconnected` events emitted on stdout in
the unified schema. `frame_complete` includes `ts_audio_samples` taken
from the frame scheduler's target sample position, not the wall clock.

### `[x]` D-2: drawfs Backend Render State  *(Done, Small; depends: DF-1)*

`RenderState` in `src/backend/drawfs.zig` tracks `blend_mode`,
`antialias`, `stroke_join`, `stroke_cap`. Golden-image parity with the
software renderer for state-change mid-sequence scenes. Render state
does not leak between client sessions.

### `[x]` D-3: Frame Scheduler Clock Abstraction  *(Done, Small; blocks: C-4)*

`ClockSource` interface in `src/compositor/frame_scheduler.zig`;
`WallClockSource` is the default, `MockClockSource` supports
deterministic testing. No `std.time` calls remain directly in the
scheduler. This was the preparatory refactor for audio-driven
scheduling.

### `[x]` D-4: `DRAW_GLYPH_RUN` in drawfs Backend  *(Done, Medium; depends: D-2)*

Opcode `0x0030` implemented in the drawfs backend with correct CJK
double-width handling. `semadraw-term` now runs on the drawfs backend.
Output matches software-renderer golden images within a 1-pixel
tolerance.

### `[x]` D-5: Remote Transport Hardening  *(Done, Small; revised 2026-04-23)*

TCP loopback round-trip test; abrupt-disconnect test does not crash
`semadrawd` or leak surfaces; read timeout prevents stalled remote
clients from holding surfaces indefinitely. `docs/API_OVERVIEW.md`
documents the TCP transport alongside the Unix socket.

**Latent regressions, found and fixed 2026-04-23.** The original
acceptance for "abrupt-disconnect test does not crash `semadrawd`"
held against the specific test harness that exercised it but did
not generalise. Two pre-existing use-after-free bugs reached the
surface during unrelated mouse-pipeline work, when frequent
test-driven restarts of `semadraw-term` gave the disconnect path
many opportunities to fire. Both presented as repeating segfaults
at addresses ending in `...20b0` (byte 176 of a freed allocation)
immediately after a `failed to send key event to client N:
error.BrokenPipe` warning. 27 such segfaults accumulated in
`/var/log/semadrawd.log` across multiple daemon lifetimes before
the pattern was investigated.

**Bug 1:** borrowed `inline_data` (`semadraw/src/daemon/surface_registry.zig`):
`SurfaceRegistry.attachInlineBuffer`'s "not compositing" branch
borrowed the caller's `data` slice into `AttachedBuffer.inline_data`
without copying. Both call sites (`semadrawd.zig:477` and
`semadrawd.zig:793`) pass `session.sdcs_buffer.?`, which is owned by
the client session and freed when the session is destroyed during
disconnect. The next composite read the stale `inline_data` pointer
at the SDCS header offset and segfaulted. The deferred (compositing)
branch already copied correctly, but its copy was never freed at
buffer-replace or surface-destroy time, a separate latent leak.

  Fix: `attachInlineBuffer` now always copies, whether compositing
  or not; both paths converge on the same ownership story (the
  surface owns the copy). `AttachedBuffer.deinit` now takes an
  allocator and frees `inline_data` when non-null, closing both the
  use-after-free and the leak.

**Bug 2:** session double-disconnect race (`semadraw/src/daemon/semadrawd.zig`):
The poll loop's local-client-event branch ran `handleClientMessage`
under `POLL.IN` and called `disconnectClient(session.id)` on error;
it then unconditionally checked `POLL.HUP | POLL.ERR` and called
`disconnectClient(session.id)` again, dereferencing the now-freed
`session` pointer to read `session.id`. `POLL.IN | POLL.HUP` is the
normal kernel response when a client closes its end of a socket
that still has readable data pending, so this race fired on every
clean disconnect with any in-flight message.

  Fix: capture `session.id` into a local `sid` before any disconnect
  call, and track a `disconnected` flag so the HUP branch is skipped
  if the IN branch already cleaned up. Same pattern applied
  symmetrically to the parallel remote-client branch (which had the
  same hazard via `disconnectRemoteClient`).

**Verification**: three back-to-back `pkill -KILL -x semadraw-term`
runs with no growth in the segfault count (29 → 29 → 29 → 29), where
previously each disconnect grew the count by one. `semadrawd`
remains alive and producing `frame_complete` heartbeats across
client respawns, which is what the original D-5 acceptance was
trying to assert.

**Why D-5's original acceptance missed this.** The "abrupt-disconnect
test" in the original D-5 work exercised the *remote* transport
(TCP) path, where the disconnect arrives as a clean `recv`-returns-
zero on a separate fd that the daemon polls in isolation. That path
does not see `POLL.IN | POLL.HUP` in the same revents and never hits
the local-client double-disconnect race. The `inline_data` path was
also not exercised because the original test client did not attach
inline buffers between connect and disconnect. Both bugs were latent
behind test gaps rather than recent regressions; they had been
shipping in `master` for the entire history of the affected code.

### `[ ]` D-6: Mouse coordinate translation  *(Superseded, 2026-04-23)*

**Superseded by**: `inputfs/docs/inputfs-proposal.md`, tracked as
AD-1 in the Architectural Discipline section of this backlog.

This item proposed a compositor-side shim in
`semadrawd.forwardMouseEvents` to translate device-accumulated
coordinates into surface-local pixels. The `inputfs` proposal replaces
the entire evdev-based input path and produces screen-absolute
coordinates at source; the compositor-side shim is unnecessary under
that architecture. Mouse coordinates will remain wrong in production
until `inputfs` Stage D lands. This is an accepted transient bug, not
work to schedule.

The original scope and acceptance criteria are preserved below for
traceability and will not be revived. A fresh `inputfs`-era item will
supersede this when the relevant stage begins.

---

**Original scope** (superseded, retained for history):

**Depends on**: D-1 (event emission), mouse pipeline through `forwardMouseEvents` (landed 2026-04-22 via commit 6be3a74).
**ADR**: `semadraw/docs/adr/0003-mouse-coordinate-translation.md` (Superseded).

semainputd injects device-accumulated coordinates (running sum of
evdev REL_X/REL_Y since device open) via the kernel. semadrawd
forwards these unchanged to clients, which expect surface-local
pixels. `semadraw-term`'s cell-index math divides by cell size and
clamps to `[0, cols)`/`[0, rows)`; negative device-accumulated
values (observed `y=-568`) collapse every click to row 0. Chord
menus, drag selection, and any coordinate-sensitive gesture are
therefore broken despite the full event pipeline being verified
end-to-end.

Fix location: `semadrawd.forwardMouseEvents`. Translate
`event.x`/`event.y` to surface-local pixels using the target
surface's `position_x`/`position_y` and scale before constructing
the `MouseEventMsg`. Motion deltas (`dx`/`dy`) pass through
unchanged; they are frame-local.

**Acceptance**:
- Hold left mouse button, click middle → chord menu appears at the
  cursor position (not at the top-left corner).
- Drag a selection → highlighted cells correspond to the actual
  cursor path.
- No client handler receives negative `x` or `y` for any mouse
  event.
- Motion tracking in `vttest` mouse mode (or equivalent) reports
  sensible cell coordinates.

**Out of scope** for this item (tracked separately when reached):
- Initial offset seeding for the evdev accumulator (`y=-568` arose
  because the accumulator starts at zero and the test setup drove
  it upward relative to that origin; the right seed depends on
  display center vs focused-surface center and is deferred).
- Routing to the surface under the cursor rather than
  `getTopVisibleSurface`. Depends on focus tracking, which depends
  on NDE-1.
- Scaling semantics when `rend.scale` differs per surface; current
  translation assumes a single scale factor.

---

## `semaaud`: audio daemon

OSS output, two named targets (`default`, `alt`), policy engine with
allow/deny/override/group semantics, preemption, fallback routing.

### `[x]` A-1: Phase 12 Durable Policy Validation  *(Done, Small)*

`policy-valid` and `policy-errors` surface files; `#` comment support;
`version=1` recognised and validated; unknown-directive and unsupported-
version errors surface correctly. Spec in
`docs/SemaAud-Phase12-DurablePolicy-Spec.md`.

### `[x]` A-2: Audio Sample Position Counter  *(Done, Small; blocks: S-4, C-1)*

`samples_written: std.atomic.Value(u64)` in `Shared`, advanced by
`n / bytes_per_sample_frame` after every successful
`posix.write(audio_fd)`. Monotonic across streams (does not reset on
preempt/override). Exposed in `RuntimeState.renderJson` alongside
`sample_rate`.

### `[x]` A-3: Unified Event Log Schema Adoption  *(Done, Medium; depends: S-2, S-3)*

`emitEvent` in `state.zig` writes JSON-lines to stdout in the unified
schema. Every `stream_begin`/`stream_end`/`stream_reject`/
`stream_preempt`/… event appears on stdout in addition to the
filesystem surfaces. `ts_audio_samples` is non-null during an active
stream and null otherwise.

### `[x]` A-4: Sample Rate Negotiation  *(Done, Small; depends: A-2)*

`parseHeader` no longer hardcodes 48000Hz/stereo/s16le. `SNDCTL_DSP_SPEED`
and `SNDCTL_DSP_CHANNELS` negotiate with the OSS device; `s16le` and
`s32le` are both accepted. Clients are rejected with a clear error on
unsupported rates. `samples_written` remains accurate because the
division uses the negotiated `channels` and `format`.

---

## `semainput`: input daemon

evdev device discovery, classification and fingerprinting, logical
identity aggregation, pointer smoothing, gesture recognition.

### `[x]` I-1: Unified Event Log Schema Adoption  *(Done, Small; depends: S-2, S-3)*

`emitSemanticEvent` and `emitGestureEvent` include `subsystem`,
`session`, `seq`, `ts_wall_ns`, and (initially null) `ts_audio_samples`.
`seq` increments monotonically across all event types. `jq` parses the
stream without errors.

### `[x]` I-2: Keyboard Event Passthrough  *(Done, Small; depends: I-1)*

Keyboard discovery verified; `KEY_*` evdev events translate to
`key_down`/`key_up`; key-repeat suppression (evdev `value=2` ignored);
`identity_snapshot` includes `has_keyboard` per logical device.

### `[x]` I-3: Audio Clock Timestamping  *(Done, Small; depends: S-4, I-1)*

`ClockReader` opened at startup against `/var/run/sema/clock`;
`ts_audio_samples` populated at event emission time when
`clock_valid == 1`, null otherwise. Clock-reader failure is non-fatal.

### `[x]` I-4: Gesture Tuning: Pinch Scale Factor  *(Done, Small)*

`scale_factor = cur_distance / prev_distance` added to `pinch_begin`
and `pinch` events as f32. The `delta` formula recalibrated to
`sqrt(cur²) - sqrt(prev²)`. Backward-compatible `delta` and
`scale_hint` retained.

---

## `chronofs`: temporal coordination layer

Clock, event streams, resolver, audio-driven frame scheduler, diagnostic
tool. All items below are complete; chronofs is the working realisation
of the `docs/Thoughts.md` design.

### `[x]` C-1: Clock Module  *(Done, Small; depends: S-4)*

`chronofs/src/clock.zig` wraps `shared.clock.ClockReader` with `now()`,
`isValid()`, `toNs()`, `sampleRate()`. `MockClock` for deterministic
tests.

### `[x]` C-2: Event Stream Buffers  *(Done, Medium; depends: C-1)*

`EventStream(T, capacity)` generic ring buffer with thread-safe
`append`, `query(t_start, t_end)`, `at(t)`, `latest()`. `DomainStreams`
owns one per domain (audio/visual/input). Event payload types defined:
`AudioEvent`, `VisualEvent`, `InputEvent`.

### `[x]` C-3: Resolver  *(Done, Medium; depends: C-2)*

`Resolver` with `resolveVisual`/`resolveInput`/`resolveAudio`/
`currentTime`. JSON-lines ingest helpers per subsystem
(`ingestSemaaudLine`, `ingestSemainputLine`, `ingestSemadrawLine`).
Ingestion driver spawns a thread per subsystem reading a pipe.

### `[x]` C-4: Audio-Driven Frame Scheduler Integration  *(Done, Medium; depends: C-3, D-3)*

`ChronofsClockSource` adapts `chronofs.Clock` to the `ClockSource`
interface. `nextFrameTarget(clock, refresh_rate_hz)` computes the next
sample-aligned frame boundary (800 samples at 48kHz/60Hz). Frames are
rendered at the target position, not the current one. `ts_audio_samples`
in `frame_complete` events derives from the same counter, drift-free
AV synchronisation by construction.

### `[x]` C-5: `chrono_dump` Diagnostic Tool  *(Done, Small; depends: C-3)*

Live timeline view; `--drift` computes frame-vs-audio-position deltas;
`--replay <file>` reads a recorded log and prints resolved state at
1000-sample intervals. Drift during steady-state playback < 1 frame
period.

---

## DRM-optional build system

Makes the DRM/KMS path a strictly opt-in feature while preserving the
swap-backed default as the unbreakable invariant.

### `[x]` B1.1: `configure.sh` DRM checklist item  *(Done)*

Adds `drawfs_drm` to the bsddialog checklist (default off), writes
`DRAWFS_DRM=true|false` to `.config`.

### `[x]` B1.2: `build.sh` reads DRAWFS_DRM  *(Done)*

Exports `DRAWFS_DRM` from `.config` to the environment so
`drawfs/build.sh` and any nested make(1) invocations see it.

### `[x]` B1.3: `install.sh` propagates DRAWFS_DRM  *(Done)*

Reads `.config` before the kernel build so `drawfs/build.sh` inherits
the flag via environment.

### `[x]` B1.4: `drawfs/build.sh` honors DRAWFS_DRM  *(Done)*

Translates `DRAWFS_DRM=true` into `DRAWFS_DRM_ENABLED=1` on the
`make(1)` command line for both the dev and modules kernel builds.

### `[x]` B1.5: Kernel Makefile conditional  *(Done)*

Both `sys/dev/drawfs/Makefile` and `sys/modules/drawfs/Makefile` guard
`drawfs_drm.c` and `-DDRAWFS_DRM_ENABLED` behind
`.if defined(DRAWFS_DRM_ENABLED)`. Default builds produce a
`drawfs.ko` with zero DRM references.

### `[x]` B2.1: `hw.drawfs.backend` sysctl  *(Already implemented; drawfs.c:1164)*

Defaults to `"swap"`, 16-byte string, `CTLFLAG_RW`.

### `[x]` B2.2: DRM init fallback-to-swap  *(Already implemented; drawfs.c:1189)*

`MOD_LOAD` calls `drawfs_drm_init()` only when backend is `"drm"`.
Failure logs a warning and resets the sysctl to `"swap"`. Broken drm
drivers cannot prevent `drawfs.ko` from loading.

### `[x]` B2.3: Regression test for `hw.drawfs.backend`

`drawfs/tests/test_backend_sysctl.py`. Asserts the sysctl exists,
defaults to `"swap"`, is read/write, and round-trips both `"swap"` and
`"drm"` as plain strings. Protects invariants 2.2, 3, and 4 above.

### `[x]` B4.1–B4.4 OS detection  *(Done; simplified for FreeBSD-only target)*

`scripts/detect-os.sh` exports `UTF_OS` and `UTF_OS_VERSION` by
checking `uname -s`. `configure.sh` records them in `.config` and
tailors the drm-kmod advisory. `build.sh` re-detects at build time
and warns on a host mismatch. `install.sh` and `drawfs/build.sh`
inherit or re-detect. The original implementation distinguished
multiple BSD variants; with PGSD-on-FreeBSD as the single target,
the detection collapsed to FreeBSD-versus-unknown.

### `[x]` B5.1: README "Graphics Backends" section  *(Done)*
### `[x]` B5.2: Consolidated root `BACKLOG.md`  *(Done, this file)*

### `[x]` B5.3: Cross-link from `drawfs/docs/ROADMAP.md`  *(Done)*

`drawfs/docs/ROADMAP.md` now carries a blockquote at the top pointing
at this file as the source of truth for task tracking, and its
bottom-of-file `## Backlog` section has been removed. The surviving
"Remaining" item (WITNESS debug-kernel verification) was migrated to
DF-4 above.

---

## Deferred

### `[x]` B3.1: Design `DRAWFS_REQ_SURFACE_PRESENT_REGION`  *(Done)*

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

### `[x]` B3.2: Protocol constants and struct headers  *(Done; depends: B3.1)*

Three entries added to `shared/protocol_constants.json`
(`REQ_SURFACE_PRESENT_REGION = 0x0023`,
`RPL_SURFACE_PRESENT_REGION = 0x8023`,
`EVT_SURFACE_PRESENTED_REGION = 0x9003`). Headers regenerated by
`shared/tools/gen_constants.py`, no generator changes needed. Struct
definitions (`drawfs_rect`, request, reply, event) hand-added to
`drawfs_proto.h` outside the sentinel blocks. `DRAWFS_MAX_PRESENT_RECTS
= 16` defined. Python test helpers in `drawfs/tests/drawfs_test.py`
updated with matching constants. Struct sizes verified by compile:
`drawfs_rect` 16 B, request header 24 B, reply 16 B, event header 16 B.
A pre-existing cosmetic drift on `EVT_POINTER`'s description was fixed
as a side effect of running the generator.

### `[x]` B3.3: Damage / partial-update swap-path implementation  *(Done; depends: B3.2)*

Three-pass implementation of `DRAWFS_REQ_SURFACE_PRESENT_REGION` in
the swap-backed kernel path:

1. **Pass 1** (validator): pure function
   `drawfs_req_surface_present_region_validate` in `drawfs_frame.c`
   enforcing the full error table from the design doc. 15 userspace
   unit tests pass; kernel compile clean on the FreeBSD target.
2. **Pass 2** (dispatch + coalescing + sysctl): handler
   `drawfs_reply_surface_present_region` in `drawfs.c` with rect
   clamping, area-sum threshold coalescing, and event emission. New
   sysctl `hw.drawfs.region_coalesce_threshold` (int 0–100,
   default 75). 18 userspace unit tests on clamp and threshold
   arithmetic pass; kernel compile clean, sysctl exposed on target.
3. **Pass 3** (integration tests): `test_surface_present_region.py`
   exercising 18 cases, 8 error-table rows, 9
   happy-path/clamping/coalescing scenarios (including both
   threshold extremes), and the N=1-full-surface equivalence
   invariant. All pass on the FreeBSD target.

Design choices documented in
`drawfs/docs/DESIGN-surface-present-region.md`:
sum-of-areas coalescing (not true union), single event type
(`EVT_SURFACE_PRESENTED_REGION`) regardless of collapse, no
cross-request region-event coalescing.

### `[ ]` B3.4–B3.5: Damage / partial-update: DRM path and semadraw emitter  *(Deferred, P2; depends: B3.3)*

With the swap path complete (B3.3), the remaining implementation is:

1. **B3.4**: DRM path. `drmModeDirtyFB` when the kernel DRM driver
   supports it, full-present fallback otherwise. Only meaningful
   with `DRAWFS_DRM_ENABLED`. Requires access to a drm-kmod-enabled
   FreeBSD 15 host to exercise end-to-end.
2. **B3.5**: semadraw emitter. Extend
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

---

## Long-term: Quartz Equivalent on UTF

These items represent the path toward a native GNUstep/AppKit display
stack on UTF, a Quartz equivalent that requires no X11. They are
long-term architectural goals, not near-term sprint items.

**Background.** UTF already provides the lower half of this stack:
drawfs owns the framebuffer (`/dev/draw`), semadrawd is the compositor,
SDCS is the drawing command stream, and the EFI framebuffer backend
means the stack runs on any UEFI machine without a GPU driver. What is
missing is the retained-mode layer model above SDCS that Quartz
Compositor provides, and a GNUstep display backend that targets
semadraw rather than X11.

### `[ ]` LT-1: Layer Tree Protocol on top of SDCS  *(Open, Large)*

**Depends on**: SDCS stable, semadrawd compositor operational

Surfaces become layers with transform, opacity, clip, and z-order
properties. Clients describe a retained scene graph rather than pushing
raw pixel commands each frame. semadrawd composites the layer tree
rather than blitting each surface independently.

Key design points:

- Extend the semadraw IPC protocol with `SET_LAYER_TRANSFORM`,
  `SET_LAYER_OPACITY`, `SET_LAYER_CLIP` messages
- semadrawd maintains a retained layer tree per client session
- Only damaged layers are re-rendered each frame
- Layer properties are animatable (see LT-2)
- Implementation lives in `semadraw/src/daemon/layer_tree.zig`

### `[ ]` LT-2: Animation Engine driven by the chronofs Clock  *(Open, Large)*

**Depends on**: LT-1, chronofs `ChronofsClockSource` wired into
semadrawd frame scheduler

An animation engine that interpolates layer properties between frames,
driven by the chronofs audio-hardware clock. This is the UTF equivalent
of Core Animation's display link and implicit transaction model.

Key design points:

- Animations are submitted as `(property, from, to, duration, curve)`
  tuples via the semadraw IPC protocol
- The frame scheduler calls `nextFrameTarget()` from chronofs to
  determine the next sample-aligned frame boundary
- Property values are interpolated at each frame boundary and applied
  to the layer tree before compositing
- Animations are drift-free by construction, clocked against audio
  hardware rather than wall time, eliminating audio/visual skew
- Easing curves: linear, ease-in, ease-out, ease-in-out, spring

### `[ ]` LT-3: GNUstep Backend targeting semadraw instead of X11  *(Open, Large)*

**Depends on**: LT-1, LT-2; libs-opal and libs-quartzcore in GNUstep
upstream

A GNUstep display backend (`back-semadraw`) that implements
`GSDisplayServer` against semadraw rather than X11. This allows the
full GNUstep/AppKit application stack to run natively on UTF without
X11 as an intermediary, on any UEFI machine including older hardware
with no GPU driver.

Key design points:

- `back-semadraw` implements `GSDisplayServer` using the semadraw
  client library (`libsemadraw`)
- Opal (2D drawing, PDF model) maps its drawing operations to SDCS
  commands
- QuartzCore (layer compositing, Core Animation) maps to the LT-1
  layer tree protocol and LT-2 animation engine
- Applications run unmodified on bare metal FreeBSD via any UTF
  backend: EFI framebuffer (any UEFI machine, no GPU driver required),
  Vulkan (GPU-accelerated), or X11 (compatibility mode)
- Makes UTF the FreeBSD analog of Quartz Compositor on macOS, with
  GNUstep as the application framework above it

---

## NDE: Native Desktop Environment

NDE is the policy and user experience layer above semadraw and drawfs.
It lives at https://github.com/pgsdf/NDE and defines versioned contracts
for windowing policy, input, settings, session management, and
compatibility. NDE does not redefine kernel graphics transport or
semantic rendering; those remain the responsibility of drawfs and
semadraw respectively.

NDE Milestone 0 (vocabulary freeze, charter, design specification,
repository skeleton) is complete. The items below correspond to NDE
Milestone 1 (substrate validation) and beyond.

**Relationship to LT-1 through LT-3.** NDE is usable today without
the long-term Quartz equivalent items; it can manage semadraw-term
sessions and basic SDCS applications using the current immediate-mode
rendering model. LT-1 (layer tree) would make NDE's own UI smoother
and enable proper animated transitions. LT-3 (GNUstep backend) would
make GNUstep applications first-class NDE citizens without X11.

### `[ ]` NDE-1: Surface Manager  *(Open, Medium)*

**Depends on**: semadrawd compositor operational (done)
**Tracks**: NDE Milestone 1, substrate validation

Implement the NDE windowing policy contract (DESIGN.md §3.2): toplevel
surfaces, popups, stacking rules, focus transitions, server-side
decorations. NDE acts as a privileged semadraw client that manages
surface z-order and focus on behalf of all other clients.

Key design points:

- NDE registers with semadrawd as the window manager client
- Surface stacking is controlled via `SET_Z_ORDER` messages
- Focus ownership follows DESIGN.md §3.2 semantics
- Server-side decorations rendered as NDE-owned surfaces overlaid on
  application surfaces

### `[ ]` NDE-2: System Bar  *(Open, Small–Medium)*

**Depends on**: NDE-1
**Tracks**: NDE Milestone 2, daily driver core

A persistent surface at a fixed screen edge showing: active
application name, workspace indicator, clock, and system status.
Rendered entirely in SDCS via libsemadraw.

### `[ ]` NDE-3: Launcher  *(Open, Medium)*

**Depends on**: NDE-1
**Tracks**: NDE Milestone 2, daily driver core

Application discovery and launch. Reads a manifest of installed NDE
applications, presents a keyboard-navigable launcher surface, and
spawns selected applications as managed semadraw clients.

### `[ ]` NDE-4: Session Manager  *(Open, Small–Medium)*

**Depends on**: NDE-1
**Tracks**: NDE Milestone 1, substrate validation

Startup sequence, lifecycle events, crash recovery. Integrates with
UTF's `start.sh` / rc.d startup order: semaaud → semainputd →
semadrawd → NDE. Handles application crash restart and clean shutdown.

### `[ ]` NDE-5: X11 Compatibility Bridge  *(Open, Large)*

**Depends on**: NDE-1, NDE-4
**Tracks**: NDE Milestone 3, compatibility

Rootless X11 server integration: map X windows to semadraw surfaces,
translate input and clipboard, integrate drag and drop. IME integration
path required for international use.

**Classification note**: the NDE DESIGN.md originally described the
X11 bridge as "mandatory for usability." This has been revised to
**required for compatibility**. UTF now has a native terminal
(`semadraw-term`) and the long-term path (LT-3) provides native
GNUstep application support without X11. The X11 bridge remains
important for running existing legacy X11 applications but is no
longer a prerequisite for the environment to be usable.

## Architectural Discipline

The project's discipline (UTF depends only on code written with UTF's
guarantees in mind) is stated in full at
`docs/UTF_ARCHITECTURAL_DISCIPLINE.md`. This section tracks the work
streams that apply the discipline to subsystems where external
dependencies currently sit inside UTF's guarantee path. Items here
represent multi-stage replacements, not individual features; each
item typically has its own design document or proposal that details
the stages.

### `[~]` AD-1: inputfs: native input substrate  *(In progress, Large)*

**Tracks**: `inputfs/docs/inputfs-proposal.md` and
`inputfs/docs/foundations.md`.

Replace the evdev / bsdinput / libinput dependency chain with
`inputfs`, a UTF-owned kernel input substrate. Publishes input state
and events via shared memory, timestamps with the UTF dual-clock
(monotonic + audio-sync), routes events via compositor-driven focus.
Closes the coordinate-space bug (previously tracked as D-6 and
superseded by this item), eliminates device-accumulated coordinates,
and removes userspace semainputd as a component (see AD-2).

**Status**: Stages A, B, C, and D complete (all eight Stage D
sub-stages landed: D.0a, D.0b, D.1, D.2, D.3, D.4, D.5, D.6).
Two AD-1 sub-items remain post-Stage-D and keep this entry at
`[~]` rather than `[x]`: chronofs `ts_sync` integration
(small; no new hardware required; currently `ts_sync` is
published as zero in every event, see `inputfs.c` line 57
comment) and touch/pen event support (medium-large; requires
touchscreen or pen tablet for bare-metal verification; the
wire-format spec in `shared/INPUT_EVENTS.md` is complete and
the role taxonomy in ADR 0004 covers both, but the
HUP_DIGITIZERS parser implementation is the deferred work).
Both items appear in their longer form near the end of this
entry. Stage E (semainputd retirement, AD-2) is now
possible; AD-9 hardening complete.

Stage A delivered the proposal, foundations,
`UTF_ARCHITECTURAL_DISCIPLINE.md`, ADRs 0001 through 0011, and
four byte-level companion specs (`shared/INPUT_STATE.md`,
`shared/INPUT_EVENTS.md`, `shared/INPUT_FOCUS.md`, and
`shared/INPUT_IOCTL.md`). Stage B delivered HID attachment via
hidbus, descriptor parsing, interrupt handler registration, raw
report hex logging, and per-device role classification. Stage C
delivered userspace publication of the state region and event
ring. Stage B and Stage C sub-stage detail follows.

Stage B sub-stages:

- **B.1** module skeleton loads and unloads cleanly: landed,
  verified.
- **B.2** device attachment on `hidbus` with HID TLC matching
  per ADR 0007: landed, verified on Razer Viper (live system)
  and VirtualBox USB Tablet (VM).
- **B.3** HID report descriptor fetch and walk per ADR 0008:
  landed, verified on VirtualBox USB Tablet (85-byte descriptor,
  11 input items, depth 2).
- **B.4** interrupt handler registration via `hidbus_set_intr`
  and raw report hex logging per ADR 0009: landed, verified on a
  physical USB mouse passed through to a FreeBSD VirtualBox VM.
  Live reports flow with non-zero motion deltas during use;
  `inputfs0: detached` on unplug; clean `kldunload` with no dmesg
  warnings.
- **B.5** per-device role classification into softc bitmask
  per ADR 0004 and ADR 0010: landed, verified on the PGSD kernel
  on bare metal. Six USB HID devices across three TLC classes
  attached and classified correctly: ELECOM BlueLED Mouse
  (vendor=0x056e, product=0x00e3, roles=pointer); HAILUCK
  touchpad keyboard TLC (vendor=0x258a, product=0x000c,
  roles=keyboard); HAILUCK touchpad mouse TLC (same vendor:product,
  roles=pointer); Broadcom Bluetooth keyboard TLC
  (vendor=0x05ac, product=0x8294, roles=keyboard); Broadcom
  Bluetooth mouse TLC (same vendor:product, roles=pointer);
  Apple Keyboard (vendor=0x05ac, product=0x021d, roles=keyboard).
  Report flow verified at 640 lines for sustained mouse input.
  Clean `kldunload` produced six `detached` lines and no dmesg
  warnings.

ADR 0006 was drafted against legacy `ukbd`/`ums` reference
drivers that are not loaded on modern FreeBSD 15; it is superseded
by ADR 0007 (hidbus attachment). The shipped code attaches at
`hidbus` and works against the modern HID stack. ADR 0008 carries
an errata section recording a `hid_start_parse` kindset correction
made during B.3 verification.

**Verification environment note (B.5).** Bare-metal verification
on stock FreeBSD is structurally blocked: stock FreeBSD compiles
`hkbd` statically into the GENERIC kernel and ships `hms`, `hkbd`,
`hcons`, `hsctrl`, and other competing HID drivers as auto-loadable
modules with `linker.hints` registrations. The ADR 0009 workflow
of unloading competing drivers cannot succeed against statically
compiled code, and even when modules are unloaded at runtime the
kernel auto-load machinery reloads them on the next USB event.
The PGSD kernel resolves this: `nodevice` lines remove the
competing drivers from the static kernel image (see
`pgsd-kernel/PGSD`), and the build-produced `.ko` files in
`/boot/kernel/` are moved aside before verification so
`linker.hints` cannot find them to autoload (a stopgap; the durable
answer is `WITHOUT_MODULES` in `/etc/src.conf`, tracked under
AD-8). With both kernel image and module files clean of
competitors, `inputfs` binds at `hidbus` without contention and
all four B.5 signals pass. Earlier VirtualBox-based verification
in this project's history exercised the mouse path on a Razer
Viper but is no longer the reference: PGSD targets bare-metal
FreeBSD, and B.5's verifying evidence is the bare-metal PGSD-kernel
run captured in `b5-pass2-baremetal.log`. The verification
protocol in `inputfs/docs/B5_VERIFICATION.md` documents the
workflow.

**Stage C: state publication.** Per the inputfs proposal, Stage C
made inputfs's internal state visible to userspace through three
shared-memory regions under `/var/run/sema/input/`. The regions
are specified in `inputfs/docs/adr/0002-shared-memory-regions.md`
with byte-level layouts in `shared/INPUT_STATE.md`,
`shared/INPUT_EVENTS.md`, and `shared/INPUT_FOCUS.md` (all
landed as Stage A artifacts). Stage C implemented against those
specs. semainputd remained unchanged; evdev still drove
production; inputfs gained a user-visible output but no
consumers yet.

Stage C broke into five sub-stages, mirroring Stage B's rhythm:
each sub-stage landed and was verified independently before the
next started. Sub-stage detail follows.

- **C.1** `shared/src/input.zig` library: `StateWriter`/`StateReader`,
  `EventRingWriter`/`EventRingReader`, `FocusWriter`/`FocusReader`.
  Mirrors the `clock.zig` pattern. Pure Zig, userspace-testable
  with unit tests. No kernel work, no hardware dependency. Lands
  the API surface that the kernel writer (C.2, C.3) and the CLI
  reader (C.4) both build against. Landed 2026-04-27 with 15
  passing unit tests covering size constants, parent dir creation,
  magic rejection, pointer and device round-trips, ring drain
  ordering, ring overrun, and focus pointer resolution.
- **C.2** kernel state-region writer in `inputfs.c`: creates
  `/var/run/sema/input/state` on module load per the byte layout
  in `shared/INPUT_STATE.md` and the regions decision in
  `inputfs/docs/adr/0002-shared-memory-regions.md`. Publishes
  device inventory from B.5's softc role bitmask, updates the
  seqlock-protected fields on every event admission. Pointer
  position is published in raw device space; coordinate transform
  to compositor space is Stage D work (per ADR 0002 §Decision item 5,
  the transform mechanism is deferred). Landed 2026-04-27 with
  end-to-end verification on PGSD-bare-metal: six HID devices
  (ELECOM mouse, HAILUCK touchpad keyboard and pointer, Broadcom
  Bluetooth keyboard and pointer, Apple Keyboard) reporting correct
  vendor, product, roles, and names. Architecture: 11,328-byte
  module-global live buffer, MTX_SPIN serialization, kthread
  worker syncing via vn_rdwr.
- **C.3** kernel event-ring writer in `inputfs.c`: creates
  `/var/run/sema/input/events`, appends events to the ring on
  every interrupt callback (the path that currently logs hex to
  dmesg in B.4). Sequence numbers strictly monotonic. `ts_ordering`
  comes from the kernel monotonic clock; `ts_sync` either wired
  to chronofs (preferred, gives ADR 0011 measurement substrate)
  or left zero (the spec allows it). Pollable fd via `kqueue`.
  Landed 2026-04-27 with verification on PGSD-bare-metal: 224
  pointer.motion events plus left and right button cycles, all
  with strictly monotonic seqs and timestamps. Per-event
  publication uses partial vn_rdwr writes (slot plus header,
  ~128 bytes per typical sync). The pollable fd is deferred to
  a follow-on sub-stage. ts_sync left zero; chronofs integration
  also deferred. Keyboard, touch, and pen events deferred (need
  descriptor-driven parsing).
- **C.4** `inputdump` CLI tool in Zig under `inputfs/tools/`,
  parallel to `chronofs/tools/chrono_dump.zig`. Reads the state
  region and event ring, presents them. Useful for verification
  end-to-end and for ad-hoc debugging. Landed 2026-04-27 with
  four subcommands (`state`, `events`, `watch`, `devices`),
  human-readable and `--json` output, and event filtering by
  role, device slot, and event type. The C.2/C.3 throwaway
  `inputstate-check.zig` was deleted in the same commit.
- **C.5** verification protocol (`inputfs/docs/C_VERIFICATION.md`)
  plus scripts under `inputfs/test/c/`: signals for region
  creation, header validity, device inventory publication, event
  ring monotonicity, pollable-fd wakeups, clean unload. Pattern
  follows B.5's verification protocol. Landed 2026-04-27 with
  `c-verify.sh` (top-level orchestrator running seven phases
  end-to-end) and `c-fixtures.sh` (sourced helper library).
  Pollable-fd verification deferred along with the pollable fd
  itself; the protocol document notes the placeholder.

The Stage A focus region (`shared/INPUT_FOCUS.md`) is part of C.1's
library deliverable: `FocusWriter`/`FocusReader` belong in
`shared/src/input.zig` because the API surface is shared. The
kernel-side *use* of `FocusReader` (consuming compositor focus to
route events) is Stage D work, not Stage C.

The state region's spec describes `pointer_x`/`pointer_y` as
compositor-space. Stage C publishes them in raw device space
because inputfs has no transform machinery yet; that machinery
arrives in Stage D. The state region remains structurally correct
across the transition; only the semantics of what's in those
two fields changes.

**C.2 kernel-side considerations** *(historical, pre-implementation
design notes; the choices below were made and the implementation
landed accordingly)*. The state region is 11,328
bytes on disk, single-writer (the kernel), multiple-reader
(userspace). Userspace consumers mmap the file shared and read
via `StateReader` from `shared/src/input.zig`; the kernel
cannot link userspace Zig and instead writes the same byte
layout from kernel context. Several FreeBSD-specific decisions
shape the implementation:

- **File creation and write path.** The kernel cannot mmap a
  userland filesystem path the way userspace does. The two viable
  patterns are (a) `vn_open` plus `vn_rdwr` from a kthread
  context, opening `/var/run/sema/input/state` as a regular file
  and overwriting it byte-for-byte on every state update, or
  (b) maintaining the canonical state in a kernel-resident buffer
  and bouncing updates to userland via a helper. Neither pattern
  has precedent in the UTF codebase: existing userland files
  under `/var/run/sema/` (the audio clock, the session token)
  are written by userspace daemons. inputfs C.2 is the first
  kernel-context writer of a `/var/run/sema/` file. Pattern (a)
  is the simpler path. C.2 will start with (a) and measure;
  pattern (b) becomes a tractable optimisation if (a)'s overhead
  is intolerable.
- **Mutex strategy.** B.5's `sc_mtx` per softc protects per-device
  state during attach, classification, and the interrupt path.
  The state region adds a global resource: the seqlock counter,
  the device inventory array, and the per-event `last_sequence`
  value all need atomic-multi-field-update semantics. A new
  module-global mutex (provisionally `inputfs_state_mtx`) will
  bracket seqlock increments and field writes; the per-softc
  `sc_mtx` remains for per-device state. Order is
  `sc_mtx` then `inputfs_state_mtx` to avoid deadlock on attach.
- **Writer context.** State updates land from interrupt callback
  context (B.4's `inputfs_intr` path). Vnode I/O from interrupt
  context is forbidden in FreeBSD; that means the writer cannot
  call `vn_rdwr` directly from `inputfs_intr`. The interrupt
  handler must enqueue the state update onto a kthread-backed
  worker that performs the vnode write outside interrupt context.
  This is a non-trivial dispatch boundary and is the chief
  reason C.2 is sized larger than C.1.
- **Unload semantics.** On `kldunload`, the state region file
  is left in place (per the spec's "file persists; next load
  resets it" lifecycle note). The kthread worker must drain
  pending writes before the module unloads to avoid use-after-free
  on the softc state.
- **Module-load message.** `inputfs_modevent`'s current
  `MOD_LOAD` `printf` advertises Stage B.5. C.2's commit
  updates that string to reflect state-region publication and
  drops the "no userspace event delivery" qualifier (which
  becomes false at C.3, not C.2; C.2 publishes state but not
  yet the event ring).

**C.5 verification signals (preview)** *(historical, pre-implementation
design notes; the verification protocol that landed in C.5 covers
all of these signals plus several more)*. When C.2 lands the
verification protocol in `inputfs/docs/C_VERIFICATION.md` should
exercise, in the pattern established by `b5-verify-reports.sh`:

- State file presence and permissions: `/var/run/sema/input/state`
  exists after `kldload inputfs`, is `STATE_SIZE` bytes (11,328),
  is readable by the user account that runs userspace tools.
- Header validity: magic decodes to `INST` (`0x494E5354`),
  version is 1, `state_valid` transitions 0 to 1 once the first
  device attaches.
- Device inventory: the populated slots in the device array
  match the attached devices observed in `dmesg` after `B.5`'s
  `roles=` lines, with `roles` bitmasks consistent with B.5's
  classification.
- Seqlock toggling: under sustained input, `seqlock` advances
  by even pairs (writer increments twice per update); a
  userspace `inputdump` (C.4) capturing N snapshots over a
  recorded interval observes monotonic advance.
- Clean unload: `kldunload inputfs` completes without panics,
  the kthread worker drains, the state file persists with
  `state_valid = 1` until the next load truncates it.

These signals are concrete enough to write the verification
script against once C.2 and C.4 are both landed.

**Stage C closeout (2026-04-27).** All five sub-stages landed
and were verified end-to-end on PGSD-bare-metal with six HID
devices: the ELECOM BlueLED Mouse, HAILUCK touchpad keyboard
and pointer TLCs, Broadcom Bluetooth keyboard and pointer TLCs,
and Apple Keyboard. State region and event ring publish
correctly, magic and version match the spec, device inventory
matches dmesg, lifecycle events fire one per attaching device
with monotonic seqs, pointer.motion events stream from the
ELECOM mouse, button transitions emit pointer.button_down and
pointer.button_up correctly. Module load, unload, and reload
cycles are clean with no `M_INPUTFS` leaks. The verification
protocol at `inputfs/docs/C_VERIFICATION.md` captures the full
test recipe; `inputfs/test/c/c-verify.sh` reports 26 of 26
automated checks passing.

**Stage C deferred items.** Three items were scoped out of Stage
C and remain to be done before Stage D, after Stage D, or rolled
into Stage D as it scopes. They are tracked here as sub-items of
AD-1 rather than separate AD entries:

- *Pollable fd.* The `/dev/inputfs` cdev with `kqfilter` and
  `EVFILT_READ` support, so userspace consumers can block on
  events instead of polling the ring. Stage C's userspace
  consumers poll at an interval (the inputdump default is 100 ms);
  this is fine for a diagnostic tool but inadequate for production
  consumers. Likely a focused sub-stage of its own.
- *chronofs `ts_sync` integration.* Every event currently
  publishes `ts_sync = 0`; Stage C publishes only `ts_ordering`
  via `nanouptime`. Wiring `ts_sync` to the audio-clock-stamped
  value from chronofs is the measurement substrate ADR 0011
  needs, and is itself a non-trivial sub-stage (the kernel must
  read the chronofs userland clock file, likely via a kernel-side
  mmap or a periodic vnode read).
- *Descriptor-driven event generation for keyboard, touch, pen,
  and scroll.* Stage C's interrupt path emits pointer.motion and
  pointer.button events using the boot-protocol mouse layout. To
  emit keyboard, touch, pen, and scroll events the interrupt
  path needs to consult the report descriptor walked in B.3.
  This is the largest of the three deferred items by code volume
  and is naturally Stage D work.

**Stage D: focus routing and coordinate transform.** Stage C
publishes input data in raw device space; Stage D adds the
transform machinery that maps device coordinates to compositor
space, and consumes the focus region to route events to the
correct session. Stage D is scoped in
`inputfs/docs/adr/0012-stage-d-scope.md`, which records the
design decisions made during Stage D scoping (sysctl-based
geometry exposure from drawfs, kernel-side focus routing in
inputfs, stamp-and-filter session_id placement, transform_active
byte for coordinate semantics signaling, `hw.inputfs.enable`
tunable semantics, and descriptor-driven event scope).

Stage D breaks into eight sub-stages, each landed and verified
independently before the next starts. The dependency order is
approximately D.0a or D.0b first (independent of each other),
then D.1 and D.2 (independent of each other), then D.3 and D.4
(D.3 depends on D.2 and D.0a; D.4 depends on D.1), then D.5,
then D.6.

- **D.0a** descriptor-driven pointer events: replace
  boot-protocol parsing with `hid_locate`-based extraction at
  attach + `hid_get_data` calls at interrupt time. Adds
  report-ID dispatch for devices with multiple top-level
  collections. Adds scroll-wheel event type if `HUG_WHEEL` is
  present. *Landed (commits `123a2b4` and `309329d`).*
- **D.0b** descriptor-driven keyboard events: emit
  `keyboard.key_down` / `keyboard.key_up` from descriptor-driven
  parsing of the modifier byte and the keys-held array under
  HUP_KEYBOARD. Tracks held keys in the softc to compute
  transitions. Modifiers carried in each event's payload field
  (per existing `shared/INPUT_EVENTS.md` spec); no separate
  modifier-transition events. *Landed (commit `42dfd57`).*
- **D.1** kernel-side `FocusReader` equivalent in C: mmap the
  focus file at module load (or first use), retry until
  `focus_valid = 1`, snapshot under the seqlock retry protocol,
  surface `keyboard_focus`, `pointer_grab`, and `surface_map`
  for routing. *Landed (commits `35ab475` and `948d346`).
  Implementation uses `vn_rdwr` against a cached buffer rather
  than mmap; the kthread refreshes via bounded `msleep_spin`
  every ~100 ms, and `inputfs_focus_snapshot` is safe to call
  from interrupt context under spin lock. Seqlock retry is
  folded into the refresh-then-validate cycle.*
- **D.2** drawfs geometry sysctl: drawfs publishes display
  geometry under `hw.drawfs.efifb.*`; inputfs reads at module
  load via `kernel_sysctlbyname`, falls back to a conservative
  default if the sysctls are absent. *Landed (commits `f7cb38f`,
  `8804e60`, and `732f737`).*
- **D.3** coordinate transform: clamp pointer position to
  display bounds learned from D.2, publish in compositor
  pixel space, set `transform_active = 1` in the state region
  header. Seed pointer to display centre on first activation.
  *Landed (commit `e644594`).*
- **D.4** routing application: stamp events with
  `session_id` from the focus snapshot, synthesise
  `pointer.enter` and `pointer.leave` events when
  surface-under-cursor changes between successive pointer
  events. Apply keyboard-focus routing (events delivered to
  `keyboard_focus` if non-zero). *Landed (commit `0c610fd`).*
- **D.5** `hw.inputfs.enable` tunable: gate publication.
  When `0`, inputfs is fully inert (no state updates, no
  ring updates, `state_valid = 0`, `events_valid = 0`).
  When `1`, full publication. Clean valid-byte transitions
  on flip. *Landed (commit `d0dd1fc`).*
- **D.6** Stage D verification protocol: extend
  `c-verify.sh` (or write a new `d-verify.sh`) and a
  `D_VERIFICATION.md` document. Mirrors C.5's automated
  phases plus a manual checklist for keyboard events
  (D.0b), transform behaviour (D.3), routing (D.4), and
  the tunable's transitions (D.5). *Landed (commit
  `f5e2ada`); chose new `d-verify.sh` rather than
  extending `c-verify.sh`.*

Touch and pen events are explicitly out of scope for Stage D
(per ADR 0012); they are tracked as a separate AD-1 sub-item
post Stage D. The chronofs `ts_sync` integration (Stage C
deferred item) also stays separate from Stage D unless D.6
verification surfaces a need for it.

### `[~]` AD-2: Retire semainputd  *(In progress, Medium; depends: AD-1; AD-9 hardening complete)*

**Tracks**: `inputfs/docs/inputfs-proposal.md` Stage E (cutover).

Once inputfs owns input classification, device identification, and
routing, the userspace semainputd daemon has no remaining
responsibilities. Classification and device-role logic move into the
kernel module. Gesture recognition moves into the compositor or
per-client libraries. The `start.sh` sequence drops semainputd
entirely. evdev-related code in `semainput/src/adapters/` is removed.

**Hardening precondition cleared** (2026-04-30): AD-9 closed.
The inputfs HID parser is both crash-resistant (no faults on
24 corpus entries under AddressSanitizer) and output-correct
(14 of those entries have explicit expected outputs that the
parser produces). The button-bitmap truncation bug found by
AD-9.4 was fixed in commit `3887091`. Stage E cutover may now
proceed without inheriting known-unsafe parser behaviour.

**AD-2 sub-structure** (2026-05-01): the original "gesture
recognition moves into the compositor or per-client libraries"
sentence above is resolved into two concrete sub-items:

- **AD-2a: libsemainput reshape and semainputd retirement.**
  Strip evdev reader, classification, aggregation, identity,
  and event-queue code from semainput (all owned by inputfs
  after Stage D). Promote `gesture.zig` (1,044 lines) into
  `libsemainput`, a userland library consumed by clients and
  by semadrawd. Retire the standalone `semainputd` daemon
  binary. semadrawd hosts system-level gesture recognition
  (three-finger swipe etc.) using the same library. Open;
  no design ADR required (no new shared-memory contract).

- **AD-2b: Per-user pointer smoothing via published region.**
  Design landed (2026-05-01) in
  `inputfs/docs/adr/0015-per-user-pointer-smoothing.md` and
  `shared/INPUT_SMOOTHING.md` (commit `329197b`). Discipline-
  doc addendum landed (2026-05-01) in
  `docs/UTF_ARCHITECTURAL_DISCIPLINE.md` (commit `1285753`).
  Implementation pending: `shared/src/input.zig` writer/reader
  types, `inputfs_smooth.c` (Q16.16 algorithms), semadrawd
  config reader and publisher, `smoothing-inspect` diagnostic
  CLI, verification protocol. Deletes
  `semainput/src/smoother.zig` as part of the kernel-side
  implementation commit.

AD-2a and AD-2b are independent and may proceed in either
order. AD-2a has no design dependency on AD-2b; AD-2b's
implementation does not depend on the daemon retirement.

### `[ ]` AD-3: Audio output: replace OSS dependency  *(Open, Large; not scheduled)*

**Tracks**: `audiofs/docs/audiofs-proposal.md` (Stage F).

semaaud currently uses OSS (FreeBSD's kernel audio framework) for
audio output. OSS is accepted as platform transport today
(`docs/UTF_ARCHITECTURAL_DISCIPLINE.md`). Direct hardware driving,
analogous to how inputfs replaces evdev, would remove this
dependency entirely.

The native substrate is named **audiofs** on the kernel side and
**semasound** on the userland side, mirroring inputfs / semainput.
audiofs attaches to PCM hardware via FreeBSD's `snd(4)` framework,
publishes `/var/run/sema/audio/{state,events}`, and takes over
clock-writing duty from semaaud (the kernel knows the actual
sample position more accurately than userland readback). semasound
inherits semaaud's durable-policy work (Phase 12), named-target
topology, mixer logic, control socket, and runtime UI state, but
talks to audiofs instead of `/dev/dsp*`. semaaud retires once
semasound is verified end-to-end (analogous to AD-2 for semainput).

This is substantial work. Real-time audio has harder timing
constraints than input (buffer underrun is immediately audible),
vendor-specific audio hardware programming is complex, and the
existing OSS interface is reasonably stable. The proposal landed
2026-04-29 (commit `88b9405`) and identifies six open
architectural questions that subsequent ADRs will resolve before
any kernel code is written: Q1 data path (tmpfs ring vs
kernel-mapped DMA vs hybrid), Q2 mixer location, Q3 OSS
coexistence model, Q4 format negotiation, Q5 latency targets,
and Q6 serialization format for semasound's userland surfaces.
The pre-survey BACKLOG entry counted only four; Q5 (latency)
and Q6 (serialization) were added to the proposal during
review and the BACKLOG entry is corrected here.

Stage F.0 (architectural ADRs) is in progress under
`audiofs/docs/adr/`. ADR 0001 establishes the per-question
ADR structure; ADR 0002 resolves Q3 (OSS coexistence) with
end-state Exclusive, migration-time per-device sysctl
assignment, Layered rejected. Q1, Q2, Q4, Q5, and Q6 remain
open as of this commit.

Implementation (Stage F.1 onward) depends on AD-2 closing
first and on F.0's six ADRs being accepted. F.0 ADR work
itself is documentation, not implementation, and can proceed
in parallel with AD-2 thinking.

### `[ ]` AD-4: Graphics output: replace efifb / DRM dependency  *(Open, Large; not scheduled)*

drawfs currently uses efifb (or DRM/KMS on capable hardware) for
display output. Both are accepted as platform transport today. Direct
GPU programming would be the largest dependency replacement UTF
could undertake.

This is the biggest scope item in the discipline's "in scope for
review" list. Vendor-specific GPU programming, command submission,
power management, and multi-vendor support make this a multi-year
undertaking even for a single vendor. No design document exists yet.
Not scheduled.

### `[ ]` AD-5: Formalise ZFS as accepted dependency  *(Open, Small)*

**Tracks**: `docs/UTF_ARCHITECTURAL_DISCIPLINE.md` accepted-dependency
list.

The discipline doc lists ZFS as an accepted platform-transport
dependency, but there is no explicit statement of *how* UTF depends
on ZFS: which ZFS features are in use, what UTF does if ZFS fails or
is unavailable, and what UTF does not rely on ZFS to provide. This
item writes that down as a short document under `docs/` or as an ADR,
making the acceptance explicit rather than implicit.

Doc task, not code work.

### `[ ]` AD-6: Audit Zig stdlib usage at determinism boundaries  *(Open, Small–Medium)*

**Tracks**: `docs/UTF_ARCHITECTURAL_DISCIPLINE.md` Operating rule
(verification over assumption).

Today's session revealed two cases where UTF code at or near a
determinism boundary depended on Zig stdlib behaviour that was not
what UTF needed: `std.posix.read` panicking on `ENXIO` (fixed via
`safeRead`), and the `std.posix.system.read` signature uncertainty
when writing `safeRead`.

This item performs a targeted audit of Zig stdlib calls in
UTF's daemons and kernel-adjacent code, identifies calls whose
behaviour is sensitive to stdlib implementation choices, and
either verifies the behaviour or wraps the call in a UTF-owned
helper with documented semantics. Not a wholesale stdlib
replacement (the discipline accepts the Zig stdlib) but a
codification of the "verify rather than assume" operating rule.

### `[ ]` AD-7: Audit and document USB / HID dependency boundary  *(Open, Small)*

**Tracks**: `docs/UTF_ARCHITECTURAL_DISCIPLINE.md` accepted-dependency
list.

The discipline accepts FreeBSD's USB stack and the USB controller
drivers as platform transport. This item documents the boundary
explicitly: which USB APIs UTF uses, which behaviours UTF depends
on, and what UTF does if those behaviours change. Relevant to AD-1
because inputfs will be the first UTF component to exercise the USB
boundary heavily.

Doc task, not code work. Can happen in parallel with AD-1 Stage B.

### `[~]` AD-8: PGSD kernel: omit drivers superseded by inputfs  *(In progress, Small)*

**Tracks**: `pgsd-kernel/PGSD` and `pgsd-kernel/README.md`.

PGSD ships its own FreeBSD-derived kernel that omits drivers
inputfs supersedes. The current config at `pgsd-kernel/PGSD`
includes GENERIC and `nodevice`s the eight HID class drivers ADR
0007 enumerates plus `hidmap` (the HID-to-evdev framework, which
PGSD excludes as a structural commitment per ADR 0001). `hidbus`,
`usbhid`, and the generic `hid` layer remain.

**Status:** kernel config landed and built. Bare-metal verification
of B.5 ran successfully on the PGSD kernel (see AD-1 Stage B
status).

**Open work:**

- The `nodevice` directives remove drivers from the static kernel
  image but the FreeBSD build still produces `.ko` files for them
  under `/boot/kernel/`. `linker.hints` registers their PNP
  signatures and the kernel auto-loads them at boot when matching
  USB devices appear, putting the system back in the contested
  state. The verification workflow currently moves the `.ko` files
  aside as a stopgap. The durable answer is `WITHOUT_MODULES` in
  `/etc/src.conf` before `make buildkernel`, which omits the
  modules from the build entirely. To land.
- A future `pkg upgrade` of `FreeBSD-kernel-generic` will
  reinstall the omitted modules. PGSD eventually needs its own
  pkg repository (or a `pkg-lock(8)` discipline). Out of scope
  for the immediate work but tracked here.
- Removing `evdev`, `uinput`, and `EVDEV_SUPPORT` from the kernel
  is a separate decision deserving its own track. Not folded into
  AD-8.

### `[x]` AD-9: HID descriptor and report fuzzing  *(Done, Medium)*

**Tracks**: `inputfs/docs/adr/0014-hid-fuzzing-scope.md`.

Harden inputfs's parser-output consumer code against
malformed HID descriptors and reports. ADR 0014 establishes
the scope precisely: the fuzz target is *not* the HID
descriptor walker (which is FreeBSD's `hid_locate` /
`hid_get_data` / `hid_start_parse` etc., accepted as
platform transport), but inputfs's locate phase
(`inputfs_pointer_locate`, `inputfs_keyboard_locate`) and
extract phase (`inputfs_extract_pointer`,
`inputfs_keyboard_diff_emit`), which trust the walker's
outputs and read HID reports using cached bit-positions
those outputs produced.

Bug surfaces: trust assumptions about `hid_locate` outputs,
report-buffer bounds checks, modifier and keys-array bit
walking, descriptor-derived state used as bounds. The fuzz
oracle treats assert failures, segfaults, infinite loops,
and allocation explosions as bugs; incorrect-but-non-crashing
parses are out of scope (they need correctness oracles, not
crash oracles).

**Sub-stages** (full detail in ADR 0014):

- AD-9.1 *(landed, `b79e8d6`)*: parser-state refactor in
  `inputfs.c`. Extracted 25 parser-output fields into
  `struct inputfs_parser_state` embedded in softc as
  `sc_parser`. Four pure-parser functions take
  `inputfs_parser_state *` directly. Production behaviour
  unchanged; verified by C.5 (26/26) and D.6 (14/14) on
  PGSD-bare-metal.
- AD-9.2a *(landed, `64cd245`+`5071ad7`)*: extracted the
  four parser functions and `inputfs_report_id_matches`
  helper from `inputfs.c` into a new translation unit
  `inputfs_parser.c`, with `struct inputfs_parser_state`
  declared in `inputfs_parser.h`. `inputfs.c` shrank by
  395 lines net; the kernel module Makefile compiles both
  files. Production behaviour unchanged; verified by C.5
  (26/26), D.6 (14/14), and a comprehensive smoke test on
  PGSD-bare-metal (pointer motion + buttons + scroll plus
  keyboard key_down/up events). The linkage-fix follow-up
  removed `static` from the four function definitions
  after the kernel build caught the linkage conflict.
- AD-9.2b *(landed, `7d4eaec`)*: harness build
  infrastructure under `inputfs/test/fuzz/` (kernel_shim.h,
  shim_includes/ including 8 empty kernel-header stubs and
  the opt_hid.h / hid_if.h replacements, vendored
  hid.c/hid.h/hidquirk.h byte-identical to upstream,
  main.c, Makefile, README.md, corpus/known-good.bin from
  the USB HID 1.11 boot-protocol mouse spec).
  AddressSanitizer enabled. Verified on PGSD-bare-metal:
  `make` builds clean, `make smoke` passes all three
  checks (empty input, known-good descriptor, 4 KiB
  random data).
- AD-9.2c *(landed, this commit)*: retrospective ADR 0014
  update marking AD-9.2a, AD-9.2b, and AD-9.2 itself as
  landed. The harness README originally planned for
  AD-9.2c shipped in AD-9.2b instead, because it
  documented files landing in the same change; AD-9.2c is
  therefore the doc retrospective only.
- AD-9.3 *(landed, `b480432`)*: 23-entry hand-rolled
  malformed-input corpus under `inputfs/test/fuzz/corpus/`
  with five-line `.txt` companions (CATEGORY, TARGETS,
  INPUT, EXPECTED BEHAVIOR, EXPECTED FAILURE MODE IF
  BROKEN). Coverage by ADR 0014 category: 5 truncated
  descriptors, 3 recursive-collection cases, 3 out-of-range
  usages, 3 lying descriptors, 5 pathological reports, 2
  cross-paired blobs, 2 baselines (boot mouse, boot
  keyboard). Generated declaratively from
  `gen-corpus.py`. `fuzz-verify.sh` runs the harness against
  every entry; result on PGSD-bare-metal: 23/23 PASS, exit
  0, no ASan reports. Same commit also fixed a leaked
  6 MB `inputfs-fuzz` binary tracked accidentally by
  AD-9.2b (root cause: heredoc-escaping bug in the AD-9.2b
  commit script's safety regex; AD-9.3's commit script uses
  a self-testing regex without backslash escapes).
- AD-9.4 *(landed, `3887091`)*: ran the AD-9.3 corpus
  through the parser with output-value inspection; found
  and fixed one bug. `inputfs_extract_pointer` was reading
  only the low bit of the button bitmap because
  `loc_buttons.size = 1` (the location of Button 1 alone)
  rather than `button_count` (the parser's count of all
  button usages). Effect: every multi-button mouse on UTF
  systems would lose buttons 2-N once inputfs becomes the
  active input path, post-Stage E cutover. Fix is 10 lines
  in `inputfs_extract_pointer`'s button block: build a
  temporary `hid_location` at `loc_buttons.pos` with
  `size = button_count`, read via `hid_get_udata`. Same
  commit shipped output-correctness infrastructure
  (verbose mode in `main.c` triggered by
  `INPUTFS_FUZZ_VERBOSE=1`, `check-corpus.py` runner with
  per-entry expected values, regression test entry
  `23-multi-button-mouse`, `findings.md` documenting the
  bug). Verified on PGSD-bare-metal: 24/24 crash-resistance
  PASS, 14/14 output-correctness PASS, identical to the
  Linux dev environment.

**Out of scope:** coverage-guided (AFL-style) fuzzing,
state-leak detection across extract calls, fuzzing FreeBSD's
hid.c upstream. Each is named in ADR 0014 with a reopen
criterion.

**Why before AD-2:** AD-2 makes inputfs the sole input path
on UTF systems. Panics in the parser become load-bearing
once semainputd is retired. AD-9.1's refactor and AD-9.4's
fixes are cheaper to land while semainputd still exists as
a fallback against inputfs misbehaviour (it is a fallback
that operators can return to without losing input
entirely). Hardening before cutover, not after.

**Depends on:** none. Can land independently of AD-2; the
ordering is preference, not a hard dependency.

**Status:** AD-9 closed. All four sub-stages (AD-9.1,
AD-9.2 a/b/c, AD-9.3, AD-9.4) landed and verified on
PGSD-bare-metal across 14 commits between `4ec0d3b`
(initial ADR) and `3887091` (AD-9.4 with the bug fix),
plus this doc-update commit making 15.
One bug found and fixed (button-bitmap truncation in
`inputfs_extract_pointer`). The corpus +
`fuzz-verify.sh` (24/24 crash-resistance) +
`check-corpus.py` (14/14 output-correctness) form a
regression gate for future parser changes. AD-2 is now
unblocked.

### `[ ]` AD-10: drawfs negotiates framebuffer ownership with `vt(4)`  *(Open, Medium)*

**Tracks**: `drawfs/dev/drawfs/drawfs_efifb.c` and a new ADR
to be written.

When drawfs maps the EFI framebuffer for its own use,
FreeBSD's `vt(4)` console keeps writing to the same
physical memory. Boot messages, daemon startup logs, and
`dmesg` entries written after semadrawd takes over flash
across the screen behind the UTF surface, and typing into
semadraw-term may produce visible artifacts as `vt(4)`
redraws its scrollback over the just-rendered cells.

**Operator workaround**: `sudo conscontrol mute on` silences
the console immediately without restarting any daemon. This
is documented in INSTALL.md Hazard 7 and is the recommended
mitigation until AD-10 lands.

**Why this is structural, not a quick fix**: `vt(4)` and
drawfs both believe they own the framebuffer. Neither side
currently performs the handshake that would make ownership
exclusive. X11 servers do this with the FreeBSD-specific
`VT_GETMODE` / `VT_SETMODE` ioctl pair (process-controlled
VT switching with `VT_PROCESS` mode and `VT_RELDISP`
acknowledgements). Wayland compositors do the same thing.
UTF needs the same dance — but at the drawfs layer rather
than per-client, since drawfs is the framebuffer owner from
the kernel's perspective.

**Sub-stages** (sketch, to be expanded in the ADR):

- AD-10.1: write the ADR. Capture the design space, why
  drawfs is the right layer for the takeover (versus
  per-client), and the lifecycle: who acquires, who releases,
  what happens on crash.
- AD-10.2: implement `VT_PROCESS`-mode acquisition in
  drawfs's efifb attach. Drawfs registers itself as the VT
  owner via `VT_SETMODE`, suspends `vt(4)` output, and
  unmaps the console's framebuffer view. Release on
  drawfs unload or panic-recovery.
- AD-10.3: handle the VT-switch signals (`SIGUSR1` /
  `SIGUSR2` in classic Linux semantics; FreeBSD uses a
  similar but not identical model). Drawfs needs to
  cooperate with operator-initiated VT switches if any
  remain meaningful in a UTF system, or document why it
  doesn't.
- AD-10.4: bare-metal verification. Boot, take over, write
  to dmesg from another SSH session, confirm no flashes
  appear in the UTF surface. Reverse: release ownership,
  confirm `vt(4)` resumes drawing correctly.

**Risks**: getting this wrong manifests as either
(a) `vt(4)` and drawfs both drawing (the current state,
visible flashing), or (b) neither drawing (black screen,
no recovery without serial or SSH). The latter is worse.
Test with serial console available, or with `conscontrol
mute on` already set as a fallback so the failure mode is
the milder one.

**Depends on**: nothing structural. Can land anytime.
Practical ordering: lower priority than AD-2 Phase 2/3
(libsemainput extraction and semainputd retirement), since
AD-10 is a cosmetic/operator-experience fix while AD-2
closes a substrate-level architectural debt.

**Discovered**: bare-metal verification on 2026-05-02.
Symptom: kernel log messages flashing across the screen
behind semadraw-term during the first end-to-end Phase 1
test. Workaround verified on the same session: `conscontrol
mute on` silenced the console without disturbing the
already-running compositor.

**2026-05-04 follow-up**: the operator workaround documented
in INSTALL.md Hazard 7 — adding `conscontrol mute on` to
`/etc/rc.local` to make the mute persist across reboots —
has a real operational cost we did not name in the original
hazard text. With the console muted from boot, the vt(4)
login prompt is also invisible. A bare-metal PGSD machine
configured this way comes up with no working physical
console: SSH access is the only login path. For
single-user dev machines this is acceptable; for multi-user
systems or unattended bare metal it is a footgun. Hazard 7
should reflect this, and AD-10's structural fix (proper
VT_PROCESS-mode handshake) becomes more valuable because it
preserves vt(4)'s login functionality while suppressing
vt(4)'s draw on the framebuffer only when drawfs is the
active owner. The cooperation model is correct precisely
because total mute is operationally too coarse.

There is also a contributing factor that AD-13 names
separately: inputfs's interrupt handler emits a
`device_printf` for every HID report received, which means
typing produces console writes regardless of whether
anything else is logging. Even on an otherwise silent
system, the inputfs spam would make the login prompt
unusable without muting. AD-13 removes that source.
With AD-13 closed and AD-10 not yet landed, the residual
flashing is only legitimate boot/dmesg traffic — annoying
but not constant — and the rc.local mute may not even be
desirable. AD-13 lands first as a correctness fix; AD-10
afterward addresses what remains.

### `[ ]` AD-11: Console output: replace `vt(4)` for UTF sessions  *(Open, Large; not scheduled)*

**Tracks**: a future ADR to be written; depends on AD-10
landing first and on AD-4 progress.

`vt(4)` is FreeBSD's kernel virtual terminal: it owns the
framebuffer at boot, displays kernel messages, hosts
`ttyv0..ttyvN`, accepts keyboard input via the `kbdmux` /
`kbd` subsystem, and is the path through which an operator
reaches single-user mode after a failed boot. Today UTF
treats `vt(4)` as accepted platform transport. AD-10 will
make UTF and `vt(4)` cooperate over framebuffer ownership;
AD-11 asks the longer question: should UTF own the console
itself, on the same discipline grounds that motivated
inputfs (replaces evdev), drawfs (replaces Xlib), and
audiofs / semasound (replaces OSS, AD-3)?

**Discipline argument for replacement**: kernel messages
that race with UTF surface presentation are exactly the
"external code that does not share UTF's commitments"
shape the discipline doc warns about. Even with AD-10's
handshake landed, `vt(4)` remains in the path during boot
(before drawfs loads), during recovery (after drawfs is
released), and during any panic that drops UTF off the
display. A UTF-native console would render kernel messages
through the same surface protocol semadraw clients use,
eliminating the competition by construction.

**Discipline argument against replacement, today**: `vt(4)`
is the recovery path. When `kldload drawfs` panics — and
2026-05-01's reinstall is proof this can happen — operators
need a working console to reach single-user mode and undo
the change. A replacement console would have to provide
that same recovery affordance, which is a much larger
commitment than "owns the user's session". Replacing
`vt(4)` means UTF owns the boot console and the panic
console — kinds of code with much higher reliability bars
than session-time userland.

**Asymmetry vs AD-1, AD-3, AD-4**: those replace userspace
abstractions (evdev, OSS, Xlib, libinput) or extend
kernel-side ownership (audiofs talks to `snd(4)`-equivalent
hardware below OSS). `vt(4)` is the boot console itself,
not a userspace abstraction over hardware. Replacing it
changes the kind of thing UTF is — from a session-layer
substrate to a system that owns the console-of-last-resort.
That is not wrong, but it is a deliberate widening of UTF's
scope and deserves its own architectural discussion before
implementation.

**Sub-stages** (sketch, expanded later in the ADR):

- AD-11.1: write the ADR. Position UTF's console-replacement
  posture explicitly: what UTF takes over, what stays with
  the FreeBSD kernel as accepted transport, what the
  recovery path looks like when UTF's console layer is
  unavailable. Settle whether UTF aims to own boot messages
  (early kernel printf to the framebuffer before drawfs
  loads), panic messages (KDB_TRACE output post-fault),
  single-user mode, or only post-init session console.
  Each scope choice has different downstream cost.
- AD-11.2: kernel-side console layer (name TBD, perhaps
  `consfs` to mirror inputfs / audiofs / drawfs naming).
  Implements the FreeBSD `cn_*` console interface so it
  can be selected as the system console at compile or
  boot time. Renders messages through drawfs's surface
  protocol or directly to the framebuffer drawfs has
  released ownership of. Coexists with `vt(4)` during
  the migration window.
- AD-11.3: userspace `getty`-equivalent for UTF sessions.
  Replaces the `ttyvN` model with UTF surfaces hosting
  shell sessions, with the discipline question of whether
  to retain TTY semantics at all (line discipline, job
  control) or replace them with a UTF-native session
  abstraction.
- AD-11.4: bare-metal verification across the boot →
  panic → recovery lifecycle. Includes deliberate panic
  injection and confirmation that UTF's console renders
  the panic readable, since recovery without that is
  worse than `vt(4)` today.

**Risks**: this scope failure-mode is "no console at all,"
which is dramatically worse than AD-10's "screen flashes"
or AD-2's "wrong input routing." A bug in the UTF console
during a panic produces an unreadable system. Mitigation
strategy: keep `vt(4)` available on a separate VT as a
fallback console during the entire AD-11 window; only
remove `vt(4)` from PGSD kernel after multiple cycles of
real-world recovery testing pass. Same posture AD-2 took
with semainputd (kept available during AD-1 verification,
removed only after Stage E cutover proved out).

**Depends on**:

- **AD-10** (framebuffer ownership handshake) — must
  land first. AD-11 is the question that arises after
  AD-10's "cooperate" answer turns into "replace
  entirely". Without AD-10, AD-11 has nothing to build
  on; with AD-10 working well, AD-11 may turn out to
  be unnecessary if the handshake suffices.
- **AD-4** (graphics output: replace efifb/DRM) —
  partial dependency. AD-11 needs a path to render
  console messages without going through the FreeBSD
  display layer, which is precisely AD-4's scope. If
  AD-4 lands first, AD-11 inherits its display
  mechanism. If AD-11 attempts before AD-4, it relies
  on `efifb` for its own rendering, which is the same
  accepted-dependency posture UTF currently has — so
  ordering matters but isn't strict.
- **AD-3** (audiofs) — independent. Listed only because
  it represents the same discipline pattern (UTF
  replaces a kernel-adjacent abstraction) and the
  experience of building AD-3 informs AD-11's design
  choices around hardware-level kernel programming.

**Why this is filed as a long-term plan, not scheduled**:
AD-11 is the largest "console-and-display" reframing UTF
could undertake. AD-10's handshake may be sufficient for
all practical purposes, in which case AD-11 stays open
as a documented direction without ever being implemented.
Treating AD-11 as "scheduled" would imply a commitment to
take on the recovery-console reliability bar, and that
commitment should follow real evidence that AD-10's
cooperation model is insufficient — not anticipation.

**What this entry does not claim**:

- It does not claim `vt(4)` is broken. `vt(4)` works
  correctly within its design; the flashing surfaced
  in 2026-05-02 testing is a UTF-side coordination
  failure, not a `vt(4)` bug.
- It does not claim `efifb` should be deprecated as a
  separate item. AD-4 already covers the display-output
  replacement question; adding a separate "deprecate
  efifb" item would duplicate that scope.
- It does not commit UTF to owning the boot console,
  panic console, or single-user console. AD-11.1
  (ADR) decides that scope. The implementation
  sub-stages assume the maximal reading; the ADR
  may settle on a smaller scope.

**Discovered**: discussion 2026-05-04, prompted by the
AD-10 framing — AD-10 settles "cooperate" but the
discipline grounds for "replace entirely" are real and
deserve explicit documentation rather than implicit
acceptance.

### `[~]` AD-12: Service lifecycle: starts, stops, and dependency ordering  *(In progress, Medium)*

**Tracks**: `install.sh` rc.d generation, `start.sh`,
`inputfs/` (no rc.d service today), and a future ADR
covering daemon-under-dependency-absence behaviour.

UTF's daemons (`semaaud`, `semainput`, `semadrawd`) and
kernel modules (`drawfs`, `inputfs`) have real ordering
relationships — clock publication, surface ownership,
event ring consumption — that are not declared anywhere
the operating system can act on. Friday's bare-metal
verification (2026-05-02) surfaced four distinct symptoms
that all share the same root cause: services start without
their preconditions in place, stop without confirming
death, and accumulate as zombies across debug cycles.

**Symptoms observed** during 2026-05-02 verification:

1. **Zombie semadrawd accumulation across debug sessions.**
   Multiple foreground `sudo semadrawd -b drawfs` invocations
   from earlier debug cycles never died on Ctrl+C. Each
   subsequent service start added another semadrawd to
   `sockstat -u`, each bound to the same socket path.
   Bug 1's fix (commit `f7c71af`) prevents the *symptom*
   (silent displacement) but does not address the orphaning.
   The orphaning is itself a lifecycle problem: stop happens,
   the daemon does not actually die, the next start spawns
   alongside it.

2. **`install.sh` "Text file busy" on running daemons.**
   `cp` cannot replace a binary that is currently being
   executed. `install.sh` does not stop services before
   replacing their binaries, so an upgrade workflow requires
   the operator to stop services manually, run `install.sh`,
   then start services manually. The operator-side dance
   is unnecessary.

3. **rc.d daemon-wrapper edge cases.** `service status` on
   2026-05-02 claimed `semadrawd is running as pid X` while
   `sockstat -u` showed no listener and `lsof` showed no
   process holding the socket fd. The daemon process existed
   but was hot-spinning with no useful work — possibly a
   poll race between fork and bind under `daemon -f`'s
   stdio redirection. We never fully understood this; the
   workaround was to kill the wrapper and run semadrawd in
   the foreground.

4. **"Bug 4": input dead and rendering stuck.** End of
   session 2026-05-02. semadraw-term reaches "session 1
   started", surface allocates, but no rendering and no
   input acceptance. Plausibly a service-ordering issue:
   semadrawd connected before inputfs had attached devices
   or before keystrokes started flowing through the ring,
   and the compositor sat in a state where input was
   nominally enabled but no event delivery happened.

   **2026-05-04 update**: AD-12.3 (rc.d service for inputfs)
   landed and was verified across a reboot. inputfs loads
   automatically before the daemons; semadrawd connects to
   a populated ring with six HID devices attached and 81
   events on the ring. Pointer position confirmed moving
   from default (1920,1080) to (3171,955) under real
   hardware input — the substrate path works end-to-end.
   But typed keystrokes still do not reach the
   semadraw-term prompt. "Bug 4" therefore is **not** a
   service-ordering issue; AD-12.3 closed the
   lifecycle-shaped variant of it without resolving the
   underlying symptom. The remaining "Bug 4" is a real
   input-routing issue downstream of the inputfs ring,
   investigated separately. AD-12.5
   (daemon-under-dependency-absence ADR) is still
   relevant to "what does semadrawd do when the ring
   exists but is silent for too long" but that is a
   different question from "events flow but the prompt
   does not see them."

5. **"Bug 2": semadraw-term `screen.zig:380` panic.**
   Discovered 2026-05-02; characterized 2026-05-04 as
   timing-sensitive. On non-instrumented release builds,
   semadraw-term panics with `index out of bounds: index
   N, len M` at the first character of prompt rendering.
   Three reproductions on 2026-05-02 produced three
   different N/M pairs (`1,1`; `5,4`; `0,0`); the
   2026-05-04 reproduction was `0,0` again. Adding
   `std.debug.print` instrumentation at every array
   access in `putCharWithWidth` makes the panic stop
   reproducing — the prompt renders correctly with the
   instrumented build, no panic on any character.
   Hypothesis: the bug is timing-sensitive, and the
   added latency from print statements on the
   per-character path closes whatever race window
   exists. The interrupt-side per-report
   `device_printf` from inputfs (see AD-13) adds
   similar latency on a different path, and may be a
   confounding factor in why timing has been hard to
   pin down. Filed as a known bug; needs a different
   diagnostic approach (counter-based instrumentation
   rather than print-based, or post-mortem on a
   release-build core dump). Not blocking AD-12
   sub-stages.

These symptoms are not bugs in the daemons themselves.
They are bugs in the *lifecycle* — what happens during
start, what happens during stop, what each daemon does
when its preconditions are absent.

**The dependency graph that should be declared:**

```
drawfs.ko        (loaded by /boot/loader.conf at boot)
   |
   v
semadrawd        REQUIRE: FILESYSTEMS
   ^
   |
inputfs.ko       (currently /etc/rc.local; should be rc.d)
   ^
   |
semaaud          REQUIRE: FILESYSTEMS  PROVIDES: utf_clock
   ^                                   (via /var/run/sema/clock)
   |
semadrawd        REQUIRE: utf_clock inputfs_loaded
   |
   v
semainputd       REQUIRE: semadraw    (legacy; retiring under AD-2)
```

The drawfs.ko load happens at loader time, so all rc.d
services are guaranteed to start after it. The other
relationships are all currently undeclared.

**Sub-stages**:

- **AD-12.1** *(landed, this commit)*: install.sh hardening
  for upgrade. Stop services before copying binaries; copy
  to temp file and rename for atomicity; restart services
  in the correct order; skip restart if the service was not
  previously running. The `stop_service_if_running` helper
  uses `pgrep -x` (catches both rc.d-managed and direct
  invocations), tries `service NAME stop` first, waits with
  a 5-second timeout, falls through to SIGKILL on timeout.
  The atomic-copy `install_bin` writes to a `.NEW.$$` temp
  path then renames over the destination. The post-install
  restart block restarts in dependency order (`semaaud`
  before `semadraw` before `semainput`) regardless of the
  order services were stopped in. Services that were not
  running before the install are deliberately not started:
  install.sh is an upgrade tool, not a "start everything"
  tool. Also: BINARIES list grew to include `semadraw-term`
  (terminal client documented in INSTALL.md Step 9) and
  `inputdump` (inputfs diagnostic CLI), neither of which
  was being installed despite documentation referencing
  them.

- **AD-12.2**: rc.d scripts declare REQUIRE/PROVIDE.
  install.sh's rc.d generators emit `# REQUIRE:` and
  `# PROVIDE:` lines per FreeBSD rc.d conventions.
  `semaaud` provides `utf_clock`; `semadrawd` requires
  `utf_clock` and `FILESYSTEMS`; `semainputd` requires
  `semadraw`. The dependency graph above gets written
  as actual rc.d metadata, and `rcorder(8)` orders
  things deterministically.

- **AD-12.3** *(landed, this commit)*: rc.d service for
  inputfs. `install.sh` now generates
  `/usr/local/etc/rc.d/inputfs` with `REQUIRE: FILESYSTEMS`
  (so `kldload` runs only after `/var/run` is mounted,
  avoiding Hazard 1's early-boot panic) and
  `BEFORE: semadraw semainput` (so `rcorder(8)` runs
  inputfs before the daemons that read its ring). Enables
  `inputfs_enable="YES"` in `/etc/rc.conf`. install.sh's
  AD-12.1 stop-and-restart sequence detects whether
  inputfs was loaded before the install and, if so, does
  `kldunload` then `kldload` after the userland daemons
  stop and before they restart, so semadrawd is never left
  holding a stale ring view. INSTALL.md Step 7 reduced to
  just drawfs; Step 8 starts inputfs alongside the
  daemons. Hazard 1 rewritten to point at the rc.d
  service as the supported path; the
  `kldload inputfs` in `/etc/rc.local` recipe explicitly
  superseded.

- **AD-12.4**: stop-with-confirmation. rc.d stop scripts
  send SIGTERM, wait with timeout (e.g. 5 seconds),
  send SIGKILL on timeout, reap. Today's stop scripts
  send SIGTERM and trust the daemon to die; if it
  doesn't, the service is reported as stopped while
  the process keeps running.

- **AD-12.5**: daemon-under-dependency-absence ADR.
  Decide what each daemon does when a dependency is
  missing: retry with backoff, exit cleanly so rc.d can
  restart, or run in clearly-marked degraded mode. This
  is the question Friday's "Bug 4" surfaces — semadrawd
  reaching "session 1 started" but doing nothing useful
  is the worst of the three options. The ADR resolves
  this for all UTF daemons uniformly.

- **AD-12.6**: bare-metal verification. Boot a clean
  PGSD system, observe rc.d ordering produces correct
  starts. Verify install.sh upgrades work without
  manual stop/start dance. Verify SIGTERM-then-SIGKILL
  stop behavior. Run the deliberate-misordering case
  (start semadrawd before inputfs is loaded) and
  confirm degraded-mode behaviour matches the ADR.

**What this entry does not claim**:

- It does not claim Bugs 2, 3, or 4 from 2026-05-02 are
  *all* lifecycle issues. Bug 2 (semadraw-term putChar
  panic) is plausibly a screen.zig off-by-one that
  reproduces on certain timings; Bug 3 (`/bin/sh`
  silent exit) is plausibly TIOCSCTTY semantics. Both
  may be lifecycle-adjacent (they reproduce only when
  certain timing happens), but they have their own
  investigation paths separate from AD-12. AD-12
  addresses the *class* of issues that arise when
  daemons start without preconditions; some specific
  bugs may dissolve as a side effect, but that's not
  AD-12's commitment.

- It does not propose replacing FreeBSD's rc.d
  framework. rc.d is the platform mechanism for
  service ordering and UTF accepts it as platform
  transport. AD-12 makes UTF use rc.d *correctly*
  rather than working around it.

- It does not commit AD-12 to landing before AD-2
  Phase 2/3 (libsemainput extraction, semainputd
  retirement). AD-12.1 is small enough to land
  immediately; the larger sub-stages can interleave
  with AD-2 work as scheduling permits.

**Discovered**: bare-metal verification 2026-05-02
surfaced symptoms 1-4 above. Discussion 2026-05-04
named the common root cause and filed this entry.
The naming itself is the first piece of work; the
sub-stages are the next.

### `[ ]` AD-13: inputfs debug logging audit  *(Open, Small)*

**Tracks**: `inputfs/sys/dev/inputfs/inputfs.c`, specifically
the per-report `device_printf` in `inputfs_intr`
(line 2237 as of `e680358`).

inputfs's interrupt handler logs every HID report to the
kernel console:

```
inputfs5: inputfs: report id=0x00 len=8 data=00 00 0e 00 00 00 00 00
```

The line above is from a real keystroke during 2026-05-04
bare-metal verification; the byte at offset 2 (`0x0e`) is the
HID keycode for the letter 'k'. **inputfs is logging every
keypress and pointer report to /dev/console.** With `vt(4)`
active, those console lines flash across the framebuffer in
real time, including over a vt(4) login prompt. The flashing
"Bug 4" symptom that surfaced 2026-05-02 is partially this:
typing produces console writes that displace whatever was
under the framebuffer, including the legitimate login.

**Impact** has two dimensions:

1. **Operational.** A bare-metal PGSD machine with vt(4)
   visible at boot shows kernel log spam over its login
   prompt as soon as the operator starts typing. The
   workaround (`conscontrol mute on` in `/etc/rc.local`)
   silences the spam but also silences the legitimate
   login prompt — a multi-user machine becomes effectively
   headless. Documented as the AD-10 follow-up below.

2. **Latency.** `device_printf` from interrupt context is
   technically safe on FreeBSD but takes a non-trivial
   amount of CPU per call: a sprintf into the message
   buffer, a console-lock acquire, a memcpy into the
   ring, a `cnputs` per receiver (vt + serial if
   present). On every HID report. For a fast scrolling
   mouse or a typing burst, this adds measurable latency
   to the interrupt path — which is precisely the kind
   of latency that may be implicated in Bug 2's
   timing-sensitive panic, since instrumentation in
   semadraw-term that adds similar latency masks the
   panic. The hypothesis is testable: silencing the
   per-report `device_printf` may be the timing change
   that closes Bug 2 without any further work in
   semadraw-term.

**Origin**: this print is a Stage B/C verification
artifact. During inputfs's bring-up, raw HID report
visibility was useful for confirming the interrupt path
worked end-to-end and that descriptor parsing produced
the expected report shapes. The post-verification
expectation was that this print would be gated behind a
sysctl flag, default off. The gating did not happen and
the print landed in production.

**Sub-stages**:

- **AD-13.1**: gate the per-report print behind a sysctl
  `hw.inputfs.debug_reports` (or similar; settle the name
  in the commit). Default off. Five-line code change in
  `inputfs.c`. Test by toggling the sysctl on a running
  system and confirming console output starts and stops.

- **AD-13.2**: audit `inputfs.c` for *other* high-frequency
  `device_printf` calls. The "calling hid_intr_start"
  logs are once-per-attach, fine. The "report id="
  log is per-report, not fine. Anything else
  per-report or per-event needs the same gating
  treatment. Producing a list and applying the
  pattern.

- **AD-13.3**: same audit for `drawfs.c`, `chronofs/`,
  and the userspace daemons. Less likely to find
  per-event prints to /dev/console (userland writes
  go to log files, not console), but worth a sweep
  to keep the discipline.

**Why this matters for AD-2 verification**: AD-2 Phase 1
verification has consistently shown semadraw-term reaching
"session 1 started" but input-routing producing strange
behaviour ("Bug 4"). The inputfs logging makes every
keystroke a console write that competes with the
framebuffer surface, *and* adds latency to the interrupt
path that may or may not be implicated in Bug 2. Closing
AD-13 removes a confounding variable from the Bug 4
investigation: with no console spam from inputfs, the
remaining "input doesn't reach the prompt" symptom is
unambiguously a semadrawd-or-semadraw-term issue, not a
substrate issue.

**What this entry does not claim**:

- Does not claim AD-13 closes Bug 2 or Bug 4. The
  hypothesis that latency reduction will close Bug 2
  is testable but unproven; the hypothesis that
  removing the spam makes Bug 4 visible is also
  testable. Either way, AD-13 is on its own merits a
  correctness fix (production drivers should not
  emit per-event console writes), independent of
  whether it dissolves either bug.

- Does not propose removing the print entirely. The
  per-report visibility is genuinely useful during
  development; the fix is a sysctl gate, not a
  deletion. ADR 0009 (interrupt handler registration)
  treats per-report logging as a verification feature;
  AD-13 makes it a verification feature that is opt-in
  rather than always-on.

- Does not address `dmesg`-archived messages. The
  console-spam issue is about live writes during
  operation; what remains in `dmesg` after the fact is
  fine. The fix is to stop *new* lines from appearing
  per HID report, not to suppress retrospective viewing.

**Discovered**: bare-metal verification 2026-05-04.
Symptom: physical-console login on PGSD shows kernel log
spam interleaved with the login prompt while typing.
`dmesg | tail` revealed the source. Same line that
displaces the login prompt also displaces UTF surfaces,
which is part of the "Bug 4" symptom we have been
chasing as a semadrawd issue.

### Priority

Rough priority ordering within this section, not strict:

1. **AD-1**: in progress; unblocks AD-2; closes the most visible
   current bug (input coordinates).
2. **AD-8**: in progress; supports AD-1's bare-metal verification
   substrate.
3. **AD-9**: done; hardened AD-1's parser before AD-2 makes it
   load-bearing. One bug found and fixed (button-bitmap
   truncation) plus regression-test infrastructure left in
   place.
4. **AD-2**: now unblocked; cutover after AD-9 hardening (which
   produced one real fix). The recommended ordering held: the
   button-bitmap bug would have manifested as silently-dropped
   mouse buttons post-cutover.
5. **AD-5, AD-7**: small doc tasks; make the discipline honest.
6. **AD-6**: small-medium; applies the discipline's verification
   rule to existing code.
7. **AD-10**: medium; cosmetic/operator-experience fix for
   `vt(4)` console writing through the drawfs surface. Workaround
   exists (`conscontrol mute on`); structural fix can wait.
8. **AD-12**: medium; service lifecycle (rc.d ordering, install.sh
   stop-before-copy, inputfs as rc.d service, daemon-under-
   dependency-absence ADR). In progress; AD-12.1 (install.sh
   hardening) lands first as it removes the most painful
   recurring operator pain point.
9. **AD-13**: small; inputfs interrupt handler logs every HID
   report to /dev/console. Discovered 2026-05-04. Five-line
   sysctl gate. Lands ahead of further Bug 2 and Bug 4
   investigation because it removes a confounding latency
   source from the interrupt path and resolves the
   physical-console-unusable consequence of the rc.local
   `conscontrol mute on` workaround.
10. **AD-3**: large; not scheduled.
11. **AD-4**: largest; not scheduled.
12. **AD-11**: large; not scheduled. Long-term replacement of
    `vt(4)` for UTF sessions; depends on AD-10 working and on
    AD-4 progress. Filed as documented direction; may stay open
    indefinitely if AD-10's cooperation model proves sufficient.

"Not scheduled" here means: no commitment to start, no commitment to
an outcome date, but explicitly tracked so the discipline's forward
implications are visible.
