# semadraw Backlog

`semadraw` is the semantic rendering substrate: `libsemadraw` for clients,
`semadrawd` as the compositor daemon, the SDCS binary command stream format,
and multiple rendering backends. Protocol-level critical fixes are already
complete (see `semadraw/BACKLOG.md`, all items marked done).

---

## D-1 — Event Emission in Unified Schema

**Status**: Open
**Effort**: Small–Medium
**Depends on**: shared/S-2 (schema), shared/S-3 (session identity)

### Background

`semadraw` currently emits no observable events. The compositor, surface
registry, and client sessions all have internal state transitions that are
invisible to the fabric. For the unified event log and for chronofs (which needs
to know when frames are produced), `semadraw` needs to emit JSON-lines events.

### Tasks

- [ ] Add `src/daemon/events.zig`: a module that owns the stdout event emitter,
      following the unified schema from `shared/EVENT_SCHEMA.md`. Fields:
      `type`, `subsystem="semadraw"`, `session`, `seq`, `ts_wall_ns`,
      `ts_audio_samples` (null initially)
- [ ] Emit `surface_created` on `CREATE_SURFACE` (include surface_id, client_id,
      width, height)
- [ ] Emit `surface_destroyed` on `DESTROY_SURFACE`
- [ ] Emit `frame_complete` from the compositor after each frame is rendered
      (include surface_id, frame_number, backend name)
- [ ] Emit `client_connected` and `client_disconnected` from the daemon's client
      session lifecycle
- [ ] Read the session token from `/var/run/sema/session` at daemon startup
      (shared/S-3). Include in all events.
- [ ] Add `seq` counter per the unified schema

### Acceptance Criteria

- Running `semadrawd` and connecting a client produces JSON-lines on stdout
  matching the unified schema
- `frame_complete` is emitted exactly once per rendered frame
- Events are valid JSON (test with `python3 -c "import json; json.loads(line)"`)

---

## D-2 — drawfs Backend Render State

**Status**: Open
**Effort**: Small
**Depends on**: drawfs DF-1 (integration verified)

### Background

The drawfs backend currently acknowledges `SET_BLEND` and `SET_ANTIALIAS` with
placeholder handlers — it records nothing and applies nothing. The software
backend has a full render state struct. For the drawfs backend to produce correct
output it needs to track at minimum blend mode and antialias state and pass them
through when constructing drawfs surface operations.

### Tasks

- [ ] Define `RenderState` struct in `src/backend/drawfs.zig`:
  - `blend_mode: u32` (default SrcOver = 0)
  - `antialias: bool` (default false)
  - `stroke_join: u32` (default Miter = 0)
  - `stroke_cap: u32` (default Butt = 0)
- [ ] Wire `SET_BLEND` to update `blend_mode`
- [ ] Wire `SET_ANTIALIAS` to update `antialias`
- [ ] Wire `SET_STROKE_JOIN` and `SET_STROKE_CAP` similarly
- [ ] Pass current render state when dispatching draw operations to the surface
- [ ] Add golden image test comparing drawfs backend output against software
      renderer output for a stream that changes blend and antialias state mid-
      sequence

### Acceptance Criteria

- A scene rendered with `SET_ANTIALIAS=1` through the drawfs backend produces
  visually smooth edges
- Blend mode `Clear` produces a transparent result on a surface with alpha
- Render state does not leak between client sessions

---

## D-3 — Frame Scheduler Clock Abstraction

**Status**: Done
**Effort**: Small
**Depends on**: Nothing (preparatory refactor)
**Blocks**: chronofs C-4 (audio-driven scheduling)

### Background

`src/compositor/frame_scheduler.zig` currently drives frame timing against vsync
alone. C-4 will replace this with audio-clock-driven scheduling. Before that
substitution can be made cleanly, the scheduler needs to be refactored to accept
a clock source as a dependency rather than calling `std.time` directly. This
decouples the scheduling logic from the clock implementation.

### Tasks

- [ ] Define a `ClockSource` interface in `frame_scheduler.zig`:
  ```zig
  pub const ClockSource = struct {
      context: *anyopaque,
      nowFn: *const fn (context: *anyopaque) u64,
  };
  ```
- [ ] Refactor `FrameScheduler.init` to accept a `ClockSource` parameter
- [ ] Implement `WallClockSource` (wraps `std.time.nanoTimestamp()`) as the
      default
- [ ] Ensure all existing tests pass against `WallClockSource`
- [ ] Add a `MockClockSource` for deterministic testing: a clock whose value is
      set explicitly by the test

### Acceptance Criteria

- Existing frame scheduling behavior is unchanged with `WallClockSource`
- A test using `MockClockSource` can advance time step by step and confirm
  correct frame timing decisions
- No `std.time` calls remain directly in `frame_scheduler.zig`

---

## D-4 — DRAW_GLYPH_RUN in drawfs Backend

**Status**: Open
**Effort**: Medium
**Depends on**: D-2 (render state in place)

### Background

`DRAW_GLYPH_RUN` (opcode 0x0030) is implemented in the software renderer and
used by `semadraw-term`. The drawfs backend does not implement it, meaning the
terminal emulator cannot use the drawfs backend. Since the terminal is the
primary text-output application in the NDE stack, this is a meaningful gap.

### Tasks

- [ ] Add `DRAW_GLYPH_RUN` handler to `src/backend/drawfs.zig`
- [ ] Parse the glyph run payload per the SDCS spec: header (48 bytes), per-
      glyph data (N × 12 bytes), atlas data
- [ ] Blit each glyph cell to the mapped surface buffer using the current
      transform and color
- [ ] Confirm CJK double-width handling: a glyph at column position X with
      `width=2` should occupy 2 × `cell_width` pixels
- [ ] Add a test that renders a short ASCII string and a CJK string and compares
      against software renderer output

### Acceptance Criteria

- `semadraw-term` can start with the drawfs backend selected and render a shell
  session
- CJK characters occupy the correct width
- Output matches software renderer golden images within a 1-pixel tolerance
  (rounding differences acceptable)

---

## D-5 — Remote Transport Hardening

**Status**: Open
**Effort**: Small
**Depends on**: Nothing

### Background

`src/ipc/tcp_server.zig` and `src/client/remote_connection.zig` implement the
optional TCP transport for network clients. The inline buffer transfer path (no
fd passing over network) is structurally different from the local shared-memory
path. It has had less testing. With the drawfs backend now operational locally,
the remote path deserves a hardening pass before it is used in any multi-machine
scenario.

### Tasks

- [ ] Add a test: connect a remote client over TCP loopback, submit an SDCS
      stream, confirm the frame appears on the local surface
- [ ] Test disconnection handling: abrupt TCP disconnect mid-SDCS stream should
      not crash `semadrawd` or leave a dangling surface
- [ ] Add a read timeout to the remote connection so a stalled client does not
      hold a surface indefinitely
- [ ] Confirm that remote client IDs (0x80000000+) do not collide with local
      client IDs under concurrent load
- [ ] Document the TCP transport in `docs/API_OVERVIEW.md` (currently mentions
      only the Unix socket)

### Acceptance Criteria

- Loopback TCP test passes
- Abrupt disconnect test passes without crash or leak
- Documentation updated
