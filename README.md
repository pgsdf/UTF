# Unified Temporal Fabric

UTF is an integration repository for the PGSDF multimedia substrate. It brings
together the spatial, semantic, audio, and input layers of the system under a
single workspace and provides the cross-cutting infrastructure — shared protocol
constants, a unified event schema, session identity, and a clock publication
interface — that makes them a coherent fabric rather than four independent
daemons.

The long-term goal is **chronofs**: a temporal coordination layer that aligns
audio, visual, and input domains against a single monotonic clock driven by
audio hardware, eliminating drift between subsystems as a structural property of
the architecture.

UTF targets PGSD, a distribution founded on FreeBSD. Earlier development used
GhostBSD as a convenient FreeBSD-derivative test host; that is no longer the
case. PGSD-on-FreeBSD is the single supported target going forward. Some
verification artefacts in the repository's history were produced on GhostBSD
VMs and bare-metal GhostBSD machines while that was the active development
venue; the substantive findings transfer to stock FreeBSD because GhostBSD
inherits FreeBSD's HID stack and kernel configuration, but the project no
longer targets GhostBSD as a deliverable platform. PGSD will ship its own
kernel configuration that omits drivers superseded by `inputfs` (currently
`hms`, `hkbd`, `hgame`, `hcons`, `hsctrl`, `utouch`).

---

## Architecture

```
                    Applications
                         |
                    libsemadraw
                    (SDCS streams)
                         |
                    semadrawd ---- semainput ---- semaaud
                    (compositor)   (input)        (audio)
                         |              \            /
                      drawfs         chronofs
                    (/dev/draw)     (temporal fabric)
                         |
                      hardware
              (EFI framebuffer / Vulkan / X11)
```

| Component | Role |
| --- | --- |
| drawfs | Kernel graphics transport. `/dev/draw` character device, surface lifecycle, mmap-backed pixel buffers, EFI framebuffer blit. |
| semadraw | Semantic rendering. SDCS command streams, `semadrawd` compositor, software and hardware backends. |
| semaaud | Audio daemon. OSS output, policy-controlled stream routing, preemption, fallback. |
| semainput | Input daemon. evdev device classification, pointer smoothing, gesture recognition. |
| shared/ | Protocol constants, event schema, session identity, clock interface. |
| chronofs | Temporal coordination layer. Audio-driven frame scheduler, ring buffers, clock publication. |

---

## Repository Layout

```
UTF/
├── drawfs/          kernel module and protocol (FreeBSD 15)
├── semadraw/        semantic rendering daemon and client library
├── semaaud/         audio routing daemon
├── semainput/       input classification and gesture daemon
├── shared/          cross-cutting constants, schema, and interfaces
├── chronofs/        temporal coordination layer
├── BACKLOG.md       consolidated project backlog (source of truth)
└── docs/
    ├── Thoughts.md                  chronofs architecture
    └── PROTOCOL_MISMATCH_FINDINGS.md  integration audit (resolved)
```

---

## Subsystems

### drawfs

A FreeBSD kernel module that exposes `/dev/draw`. Clients open the device,
negotiate via a binary framed protocol, create surfaces backed by swap memory,
map them with `mmap(2)`, render into the pixel buffer, and present. The kernel
is not a compositor; policy lives in userspace.

Phase 1 is complete: surface lifecycle, mmap, framed binary protocol, input
event injection. Phase 2 adds EFI framebuffer support: the module maps the
UEFI GOP framebuffer at load time and exposes `DRAWFSGIOC_BLIT_TO_EFIFB` and
`DRAWFSGIOC_GET_EFIFB_INFO` ioctls, allowing semadrawd to render directly to
the physical display on bare metal FreeBSD without a GPU driver. Verified on
Intel Bay Trail (1024x768) and Apple iMac (3840x2160).

DRM/KMS support is a skeleton, gated behind `DRAWFS_DRM_ENABLED` at build
time and strictly optional. The EFI framebuffer path is the default bare metal
display path and requires no DRM.

See `drawfs/docs/` for protocol specification, architecture, and build
instructions.

### semadraw

A userspace semantic graphics system. Applications link against `libsemadraw`
and produce SDCS (Semantic Draw Command Streams) — binary sequences of drawing
operations that express intent rather than GPU commands. `semadrawd` owns
surface composition and presentation. Backends include software (reference),
Vulkan, DRM/KMS, X11, Wayland, and drawfs.

`semadraw-term` is a native terminal emulator built on libsemadraw. It
supports multi-session operation (up to 8 sessions), a session status bar,
VT100/xterm-256color emulation, auto-detection of display size via
`DRAWFSGIOC_GET_EFIFB_INFO`, and font scaling for HiDPI displays. It runs
on bare-metal FreeBSD via the drawfs EFI framebuffer backend and on
FreeBSD with Xorg via the X11 backend.

See `semadraw/docs/` for the SDCS specification, architecture, and API
overview.

### semaaud

An audio routing daemon for FreeBSD. Clients connect via a Unix socket and
submit PCM streams with a JSON header. The daemon applies a policy grammar
(allow, deny, override, group exclusivity, fallback routing) and writes accepted
streams to the OSS device. Two named targets (`default` and `alt`) support
concurrent routing scenarios.

See `semaaud/docs/` for the policy specification and roadmap.

### semainput

An input classification and gesture daemon. Reads evdev devices, classifies
them by capability fingerprint, aggregates physical devices into stable logical
identities, applies pointer smoothing, and emits structured JSON-lines events
for semantic input (mouse, keyboard, touch) and gestures (two-finger scroll,
pinch, three-finger swipe, drag, tap).

See `semainput/docs/` for architecture and system interface documentation.

### shared/

Protocol constants for all three binary protocols (drawfs, semadraw IPC, SDCS)
in a single JSON source of truth. A code generator emits C headers and Zig
constant declarations. A unified event schema, session identity module, and
clock publication interface serve all four daemons.

### chronofs

A temporal coordination layer that makes time a first-class addressable medium
across all four subsystems. The audio hardware clock drives a shared monotonic
counter. All events carry an audio-sample timestamp. The frame scheduler queries
scene state at a target audio position rather than wall time, producing
drift-free AV synchronization by construction.

Implementation is complete across all dependency waves: clock publication
(`/var/run/sema/clock`), ring buffers, resolver, audio-driven frame scheduler,
and `chrono_dump` diagnostic tool.

See `docs/Thoughts.md` for the full design and `chronofs/BACKLOG.md` for the
implementation history.

---

## Build

Each subsystem builds independently. Use `start.sh` to build and run all
daemons together.

**drawfs** requires FreeBSD kernel sources:

```
cd drawfs
./build.sh install
./build.sh build
./build.sh load
./build.sh test
```

**semadraw**, **semaaud**, **semainput**, **chronofs** require Zig 0.15 or newer:

```
cd semadraw && zig build
cd semaaud  && zig build
cd semainput && zig build
cd chronofs && zig build
```

**Start all daemons and terminal** (drawfs backend, auto-detects display resolution):

```
sudo sh start.sh                  # full stack + terminal at scale 2
sudo sh start.sh --scale 4        # full stack + terminal at scale 4
sudo sh start.sh --no-term        # daemons only, no terminal
```

**Stop everything**:

```
sudo sh start.sh --stop
```

**Run the terminal emulator manually**:

```
sudo semadraw/zig-out/bin/semadraw-term            # auto-detects display size
sudo semadraw/zig-out/bin/semadraw-term --scale 2  # HiDPI
sudo semadraw/zig-out/bin/semadraw-term --scale 4  # 4K/5K
```

---

## Graphics Backends

| Backend | Use case | Requirements |
| --- | --- | --- |
| drawfs (EFI) | Bare metal FreeBSD console | UEFI firmware, drawfs.ko loaded |
| X11 | FreeBSD with Xorg | libX11 |
| Vulkan | GPU-accelerated rendering | Vulkan driver |
| software | Testing and reference | None |
| DRM/KMS | Optional GPU modesetting | drm-kmod, build with DRAWFS_DRM_ENABLED |

The EFI framebuffer path works on any UEFI machine regardless of GPU age or
driver availability, including hardware with no Vulkan support and no working
drm-kmod port.

---

## Status

| Component | Status |
| --- | --- |
| drawfs | Phase 1 complete. Phase 2 (EFI framebuffer) complete. DRM/KMS skeleton, opt-in only. |
| semadraw | drawfs backend operational. semadraw-term functional on bare metal and X11. |
| semaaud | Phase 12 (durable policy) complete. |
| semainput | Stable for pointer and touch hardware. |
| shared/ | Protocol constants, generator, event schema, session identity, clock interface: all complete. |
| chronofs | Complete. Audio-driven frame scheduler operational. |

---

## License

BSD 2-Clause. See `LICENSE`.

Copyright (c) 2026 Pacific Grove Software Distribution Foundation.
