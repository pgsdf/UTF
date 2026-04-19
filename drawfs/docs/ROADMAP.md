# ROADMAP

> **Task tracking has moved.** Per-task status for drawfs (and for every
> other UTF subsystem) now lives in the consolidated root backlog at
> [`../../BACKLOG.md`](../../BACKLOG.md). This file retains the phase-level
> roadmap and completed-work summary; individual open tasks should be
> added to the root backlog, not to this file.

## Phase 0: Specification
- Protocol definition
- State machines
- Error semantics
- Test harness

## Phase 1: Kernel Prototype (current)
- Character device protocol
- Blocking reads and poll semantics
- Display discovery and open
- Surface lifecycle
- mmap-backed surface memory
- Event queue backpressure (Step 19)
- Surface resource limits (Step 18)

### Completed work

1. Hardening and DoS resistance
   - [x] Surface size limits (EFBIG for >64MB surfaces)
   - [x] Per-session surface count limits (ENOSPC after 64 surfaces)
   - [x] Event queue backpressure (ENOSPC when queue full, recovery after drain)
   - [x] Regression tests for limits (Step 18, Step 19)

2. Test ergonomics
   - [x] Shared Python helper module (`tests/drawfs_test.py`) for framing, request building, and event parsing
   - [x] DrawSession context manager for cleaner test code
   - [x] Select-based reads to avoid indefinite blocking
   - [x] Debug tool to dump decoded frames from raw read buffer (tests/drawfs_dump.py)

### Remaining optional work

1. Code quality
   - [x] Split protocol and validation logic into dedicated C files (drawfs_frame.c, drawfs_surface.c)
   - [x] Verified consistent formatting (tabs for indentation, BSD brace style)
   - [x] Added locking rule comments to drawfs.c and drawfs_surface.c

2. Security posture
   - [x] Device node permissions configurable via sysctl (hw.drawfs.dev_uid/gid/mode)
   - [x] mmap gated by sysctl (hw.drawfs.mmap_enabled)

3. Tuning
   - [x] Event queue and surface limits tunable via sysctl (hw.drawfs.max_*)

## Phase 2: Real Display Bring-up (DF-3 — Skeleton Complete)
- [x] drawfs_drm.c skeleton with full FreeBSD KPI annotations
- [x] hw.drawfs.backend sysctl gate (swap/drm)
- [x] Connector enumeration and mode selection
- [x] Dumb buffer allocation and framebuffer objects
- [x] Initial mode set via DRM_IOCTL_MODE_SETCRTC
- [x] Page-flip present path via DRM_IOCTL_MODE_PAGE_FLIP

`drawfs_drm.c` is excluded from the default build — it requires `drm-kmod`
headers (`<drm/drm_device.h>`) which are not part of the FreeBSD base system.
To enable, install `drm-kmod`, add `CFLAGS+=-DDRAWFS_DRM_ENABLED` and
`drawfs_drm.c` to `SRCS` in the Makefile.

Hardware bring-up items for when drm-kmod is available are tracked in
the root `BACKLOG.md` (see the "Deferred" section and the DRM-optional
theme). Summary:

- [ ] Flip completion event handler (kthread to clear flip_pending)
- [ ] Damage rect filtering in SURFACE_PRESENT (partial update optimisation)
- [ ] Atomic modesetting (drmModeAtomicCommit) for HDR and VRR support
- [ ] Multi-GPU / multi-connector enumeration

## Operational Status

drawfs Phase 1 is verified operational on bare metal FreeBSD 15.0-RELEASE-p5
at 1920x1080@60Hz using the swap backend. The module builds cleanly, loads
via `kldload`, creates `/dev/draw`, and semadrawd successfully negotiates
the protocol, creates a surface, and maps it for rendering.

## Phase 3: User Environment
- Reference compositor
- Window management
- Input integration

## Phase 4: Optimization
- Zero-copy paths
- GPU acceleration
- Scheduling and batching
