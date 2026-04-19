# UTF Backlog

This is the project-level backlog. Subsystem-level backlogs
(`drawfs/drawfs-BACKLOG.md`, `semadraw/semadraw-BACKLOG.md`, etc.)
track work inside a single component. This file tracks work that
crosses components or changes project-wide invariants.

---

## Current theme: make DRM strictly optional

The goal is that the DRM-less swap path remains the unbreakable default
and that DRM/KMS support is a strictly optional add-on. A user running
`sh configure.sh` and accepting defaults must produce a `drawfs.ko` with
no DRM references, no `drm-kmod` build dependency, and no `drm-kmod`
load dependency.

### Non-goals

- Making DRM the default. It will never be the default.
- Detecting drm-kmod automatically. Autodetection leaks the opinion
  that "DRM is better" into the build; it is not.
- Removing `drawfs_drm.c` or the kernel-side `#ifdef DRAWFS_DRM_ENABLED`
  gates. They are correct already.
- Surfacing DRM backend selection through `semadrawd` CLI. `semadrawd
  -b drawfs` is agnostic to the kernel backend.

---

## Wave 1 — Build-system gating  [DONE]

**Priority**: P0. Everything else depends on this.

- [x] **B1.1** `configure.sh` adds `drawfs_drm` checklist item, default off,
      writes `DRAWFS_DRM=true|false` to `.config`.
- [x] **B1.2** `build.sh` reads `DRAWFS_DRM` from `.config`, exports it.
- [x] **B1.3** `install.sh` reads `DRAWFS_DRM` and propagates to
      `drawfs/build.sh`.
- [x] **B1.4** `drawfs/build.sh` honors `DRAWFS_DRM` (env or `.config`),
      translates to `DRAWFS_DRM_ENABLED=1` on the `make(1)` command line.
- [x] **B1.5** Both `sys/dev/drawfs/Makefile` and
      `sys/modules/drawfs/Makefile` guard `drawfs_drm.c` behind
      `.if defined(DRAWFS_DRM_ENABLED)`.

### Acceptance criteria

- `sh configure.sh` (accept defaults) → `sh install.sh` → `kldstat -v`
  shows `drawfs.ko` with no `drm_*` symbols and no `linux_common` or
  `drm` dependency in `kldstat -v`.
- `strings /boot/modules/drawfs.ko | grep -i drm` returns nothing.
- Default build works on a FreeBSD 15 or GhostBSD host with no ports
  installed beyond the base `zig` package.
- With `DRAWFS_DRM=true`: `drawfs.ko` contains `drawfs_drm_init` and
  `drawfs_drm_fini` symbols; `sysctl hw.drawfs.backend` defaults to
  `"swap"`; setting it to `"drm"` and reloading activates the DRM path
  if drm-kmod is loaded, falls back to swap and logs a warning
  otherwise.

---

## Wave 2 — Runtime control & safety  [ALREADY IMPLEMENTED]

**Priority**: P0. Already complete in `drawfs.c` before this work began —
no change required.

- [x] **B2.1** `hw.drawfs.backend` sysctl (default `"swap"`) — already at
      `drawfs.c:1164`.
- [x] **B2.2** `drawfs_modevent(MOD_LOAD)` attempts DRM init only when
      backend is `"drm"`, falls back to swap on failure — already at
      `drawfs.c:1189`.

### Suggested follow-ups (deferred, low priority)

- [ ] **B2.3** Write a small `tests/step_XX_backend_sysctl.py` that
      confirms the sysctl exists, defaults to `"swap"`, and is
      read/write. Low effort, increases confidence that a future
      refactor doesn't regress the invariant.

---

## Wave 3 — Protocol: damage / partial updates  [DEFERRED]

**Priority**: P2. Beneficial for both backends but scoped out of the
current changeset because it is a wire-format change.

### Problem

`DRAWFS_REQ_SURFACE_PRESENT` currently implies a full-surface present.
Both backends (swap mmap, DRM dumb-buffer flip) could benefit from
explicit partial updates: the swap backend avoids unnecessary event
coalescing for small dirty regions, and the DRM backend can use
`drmModeDirtyFB` or partial page-flip on hardware that supports it.

### Plan

- [ ] **B3.1** Design. Add `DRAWFS_REQ_SURFACE_PRESENT_REGION` opcode
      to `shared/protocol_constants.json` and specify the payload
      (surface_id + list of rects, capped at N=16 per request).
- [ ] **B3.2** Regenerate C and Zig headers via `gen_constants.py`.
- [ ] **B3.3** Implement in the **swap path first**. Rect list is
      accepted, validated, coalesced, and emitted back as a
      `SURFACE_PRESENTED_REGION` event. Swap semantics are unchanged —
      this is pure metadata.
- [ ] **B3.4** Implement in the DRM path. Use `drmModeDirtyFB` if the
      kernel DRM driver supports it, fall back to full present
      otherwise.
- [ ] **B3.5** Extend `semadraw`'s drawfs backend to emit region
      presents when the compositor's damage tracker produces a bounded
      rect set.

### Non-goals for this wave

- Sub-rectangle damage at finer granularity than the compositor already
  tracks. The compositor's existing damage tracking is the upstream
  source of truth.
- Triple-buffering or front/back buffer management. Present semantics
  remain immediate.

### Acceptance criteria

- A full-surface present (the current behavior) remains the exact same
  wire bytes and event stream — zero regression for clients that don't
  use the new opcode.
- A region present with N=1 full-surface rect produces an identical
  pixel result to a full present.

---

## Wave 4 — OS detection (FreeBSD vs GhostBSD)  [DONE]

**Priority**: P1. Low-risk infrastructure.

- [x] **B4.1** `scripts/detect-os.sh` sets `UTF_OS` and
      `UTF_OS_VERSION` by probing for `ghostbsd-version(1)`.
- [x] **B4.2** `configure.sh` records `UTF_OS` in `.config` and
      tailors the drm-kmod advisory on DRM enable.
- [x] **B4.3** `build.sh` re-detects at build time and warns if
      `.config` was copied from a different OS family.
- [x] **B4.4** `install.sh` and `drawfs/build.sh` inherit `UTF_OS`
      from the parent or re-detect.

### Explicit non-goals

- Branching build behavior on `UTF_OS`. The two systems share a kernel
  family and produce identical drawfs.ko. The detection is for
  messaging and future-proofing only.
- Adding OS-specific header paths. If drm-kmod installs headers to
  different paths on the two OSes, fix it then, not speculatively.

---

## Wave 5 — Documentation  [DONE]

- [x] **B5.1** `README.md` gains a "Graphics Backends" section that
      explains the swap-default / DRM-optional story explicitly.
- [x] **B5.2** This file (`BACKLOG.md`).
- [ ] **B5.3** Add a short note to `drawfs/docs/ROADMAP.md` pointing at
      this backlog for DRM-related work (deferred, cosmetic).

---

## Invariants to preserve across all future changes

1. `sh configure.sh` with all defaults → swap-only `drawfs.ko`.
2. `drm-kmod` is never a build-time or load-time hard dependency.
3. `hw.drawfs.backend` defaults to `"swap"` at module load.
4. DRM init failure at module load falls back to swap — never panics,
   never prevents load.
5. Removing or renaming `DRAWFS_DRM_ENABLED` requires coordinating
   with every `#ifdef` in `drawfs.c`, `drawfs_drm.c`, and both
   Makefiles. Don't do it casually.
6. `UTF_OS` detection is informational only. Any future use that
   branches build behavior on it must be justified by a concrete,
   observable divergence between the two OSes, not a speculation.
