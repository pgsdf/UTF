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

### `[~]` AD-1: inputfs: native input substrate  *(In progress, Large; supersedes: D-6)*

**Tracks**: `inputfs/docs/inputfs-proposal.md` and
`inputfs/docs/foundations.md`.

Replace the evdev / bsdinput / libinput dependency chain with
`inputfs`, a UTF-owned kernel input substrate. Publishes input state
and events via shared memory, timestamps with the UTF dual-clock
(monotonic + audio-sync), routes events via compositor-driven focus.
Closes the coordinate-space bug (previously tracked as D-6 and
superseded by this item), eliminates device-accumulated coordinates,
and removes userspace semainputd as a component (see AD-2).

**Status**: Stage A complete (proposal, foundations,
`UTF_ARCHITECTURAL_DISCIPLINE.md`, ADRs 0001 through 0009, four
byte-level companion specs). Stage B in progress:

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
makes inputfs's internal state visible to userspace through three
shared-memory regions under `/var/run/sema/input/`. The regions
are specified in `inputfs/docs/adr/0002-shared-memory-regions.md`
with byte-level layouts in `shared/INPUT_STATE.md`,
`shared/INPUT_EVENTS.md`, and `shared/INPUT_FOCUS.md` (all already
landed as Stage A artifacts). Stage C implements against those
specs. semainputd is unchanged; evdev still drives production;
inputfs gains a user-visible output but no consumers yet.

Stage C breaks into five sub-stages, mirroring Stage B's rhythm:
each sub-stage lands independently, gets verified before the next
starts.

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

**C.2 kernel-side considerations.** The state region is 11,328
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

**C.5 verification signals (preview).** When C.2 lands the
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

### `[ ]` AD-2: Retire semainputd  *(Open, Medium; depends: AD-1)*

**Tracks**: `inputfs/docs/inputfs-proposal.md` Stage F.

Once inputfs owns input classification, device identification, and
routing, the userspace semainputd daemon has no remaining
responsibilities. Classification and device-role logic move into the
kernel module. Gesture recognition moves into the compositor or
per-client libraries. The `start.sh` sequence drops semainputd
entirely. evdev-related code in `semainput/src/adapters/` is removed.

### `[ ]` AD-3: Audio output: replace OSS dependency  *(Open, Large; not scheduled)*

semaaud currently uses OSS (FreeBSD's kernel audio framework) for
audio output. OSS is accepted as platform transport today
(`docs/UTF_ARCHITECTURAL_DISCIPLINE.md`). Direct hardware driving,
analogous to how inputfs replaces evdev, would remove this
dependency entirely.

This is substantial work. Real-time audio has harder timing
constraints than input (buffer underrun is immediately audible),
vendor-specific audio hardware programming is complex, and the
existing OSS interface is reasonably stable. No design document
exists yet. Not scheduled; listed here so the discipline is honest
about the forward implication.

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

### Priority

Rough priority ordering within this section, not strict:

1. **AD-1**: in progress; unblocks AD-2; closes the most visible
   current bug (input coordinates).
2. **AD-8**: in progress; supports AD-1's bare-metal verification
   substrate.
3. **AD-2**: follows AD-1 naturally.
4. **AD-5, AD-7**: small doc tasks; make the discipline honest.
5. **AD-6**: small-medium; applies the discipline's verification
   rule to existing code.
6. **AD-3**: large; not scheduled.
7. **AD-4**: largest; not scheduled.

"Not scheduled" here means: no commitment to start, no commitment to
an outcome date, but explicitly tracked so the discipline's forward
implications are visible.
