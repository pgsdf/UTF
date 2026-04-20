# Unified Temporal Fabric

UTF is an integration repository for the PGSDF multimedia substrate. It brings
together the spatial, semantic, audio, and input layers of the system under a
single workspace and provides the cross-cutting infrastructure that makes them a
coherent fabric rather than four independent daemons.

The defining abstraction is **chronofs**: a temporal coordination layer that
aligns audio, visual, and input domains against a single monotonic clock driven
by audio hardware. All events carry an audio-sample timestamp. The frame
scheduler targets the next sample-aligned frame boundary rather than wall time,
eliminating drift between subsystems as a structural property of the
architecture.

---

## Architecture

```
                    Applications
                         │
                    libsemadraw
                    (SDCS streams)
                         │
                    semadrawd ──── semainput ──── semaaud
                    (compositor)   (input)        (audio)
                         │              \            /
                      drawfs          chronofs
                    (/dev/draw)    (temporal fabric)
                         │
                      hardware
```

| Component  | Role |
|------------|------|
| `drawfs`   | Kernel graphics transport. `/dev/draw` character device, surface lifecycle, mmap-backed pixel buffers, input event injection. |
| `semadraw` | Semantic rendering. SDCS command streams, `semadrawd` compositor, software and drawfs backends, audio-clock-driven frame scheduler. |
| `semaaud`  | Audio routing daemon. OSS output, policy-controlled stream routing, preemption, fallback, sample rate negotiation. |
| `semainput`| Input daemon. evdev device classification, pointer smoothing, gesture recognition, audio-clock timestamping. |
| `shared/`  | Protocol constants generator, unified event schema, session identity module, clock publication interface. |
| `chronofs` | Temporal coordination layer. Clock, event streams, resolver, audio-driven frame scheduler integration, `chrono_dump` diagnostic tool. |

---

## Repository Layout

```
UTF/
├── build.zig            root build (delegates to subprojects)
├── build.zig.zon        package manifest
├── build.sh             development build wrapper with logging
├── configure.sh         interactive backend selection (bsddialog)
├── install.sh           one-shot system installer
├── start.sh             start all daemons in correct order
├── drawfs/              FreeBSD kernel module (/dev/draw)
├── semadraw/            semantic rendering daemon and client library
├── semaaud/             audio routing daemon
├── semainput/           input classification and gesture daemon
├── shared/              cross-cutting schema, session, and clock modules
├── chronofs/            temporal coordination layer and chrono_dump tool
└── docs/
    ├── Thoughts.md                    chronofs design
    └── PROTOCOL_MISMATCH_FINDINGS.md  integration audit (resolved)
```

---

## Install

Requires **Zig 0.15.2** or newer. FreeBSD 15 recommended; GhostBSD supported.

### One-step install

```sh
git clone https://github.com/pgsdf/UTF
cd UTF
sh configure.sh    # select which backends to enable (interactive)
sh install.sh      # build at ReleaseSafe and install to /usr/local
```

Or with a custom prefix:

```sh
sh install.sh --prefix ~/utf-out
sh install.sh --check             # verify dependencies only
sh install.sh --uninstall         # remove installed files
```

This builds all subprojects at `ReleaseSafe`, installs the daemons to
`$PREFIX/bin/`, and writes FreeBSD `rc.d` service scripts to
`$PREFIX/etc/rc.d/`.

### Development builds

For day-to-day development, use `build.sh` rather than `install.sh`:

```sh
sh configure.sh          # select backends (writes .config)
sh build.sh              # build using .config, log to build-YYYYMMDD-HHMMSS.log
sh build.sh --build      # configure and build in one step
cat build-latest.log     # view the most recent build log
```

`build.sh` builds each subproject in-place and tees all output to a
timestamped log file in the UTF root directory, with `build-latest.log`
always pointing to the most recent run. Use this during development when
you need to capture build output for troubleshooting.

`install.sh` is for deploying UTF system-wide. `build.sh` is for building
and iterating during development. They are not interchangeable.

### Backend selection

`configure.sh` presents an interactive checklist (using `bsddialog`, which
is included in FreeBSD 15 base) to select which semadraw backends to enable.
The selection is saved to `.config` and read automatically by both
`build.sh` and `install.sh`.

```sh
sh configure.sh          # interactive selection
sh configure.sh --show   # show current configuration
sh configure.sh --build  # select and build immediately
```

| Backend | Default | Requires |
|---------|---------|---------|
| Vulkan | off | `pkg install vulkan-headers vulkan-loader` |
| X11 | off | `pkg install libX11` |
| Wayland | off | `pkg install wayland` |
| bsdinput | off | `pkg install libinput libudev-devd` |

The software and drawfs backends are always included and require no
additional packages.

### Remove

```sh
sh install.sh --uninstall                     # remove from /usr/local
sh install.sh --uninstall --prefix ~/utf-out  # remove from custom prefix
```

Removes `semaaud`, `semainputd`, `semadrawd`, and `chrono_dump` from
`$PREFIX/bin/` and the `rc.d` scripts from `$PREFIX/etc/rc.d/`. Build
artifacts in the source tree are not touched; run `zig build clean` in each
subproject directory to remove those.

### Zig build

```sh
zig build                          # build all subprojects
zig build test                     # run all test suites
zig build -Doptimize=ReleaseSafe   # optimised build
zig build run-semaaud              # build and run audio daemon
zig build run-semainput            # build and run input daemon (requires root)
zig build run-semadraw             # build and run compositor
zig build chrono-dump              # build chrono_dump diagnostic tool
```

### Requirements

UTF requires **bare metal FreeBSD 15** or GhostBSD. Virtualisation is not
supported — the system depends on hardware audio clocks, DRM/KMS, evdev, and
`/dev/draw`, none of which are meaningfully available in a VM.

### Environment-specific semadraw builds

X11 and Wayland backends are **disabled by default**. Vulkan and bsdinput are
enabled by default and work on any bare metal FreeBSD or GhostBSD system.

```sh
# FreeBSD bare tty console (default — no flags needed)
cd semadraw && zig build

# GhostBSD or FreeBSD with Xorg
cd semadraw && zig build -Dx11=true

# With Wayland
cd semadraw && zig build -Dwayland=true
```

### Individual subproject builds

```sh
cd semaaud   && zig build
cd semainput && zig build
cd semadraw  && zig build
cd chronofs  && zig build
```

### drawfs kernel module

Requires FreeBSD kernel sources and root:

```sh
cd drawfs
sudo ./build.sh install   # copy sources into /usr/src
sudo ./build.sh build     # compile drawfs.ko
sudo ./build.sh deploy    # install to /boot/modules/
sudo kldload drawfs       # load immediately

# Or all at once:
sudo ./build.sh all
```

To load drawfs automatically at boot, add to `/boot/loader.conf`:

```
drawfs_load="YES"
```

---

## Quick Start

**Startup order matters.** `semaaud` must start first — it publishes the
audio hardware clock to `/var/run/sema/clock`. `semainputd` and `semadrawd`
both read this region at startup to timestamp events with `ts_audio_samples`.

### Using start.sh (recommended)

```sh
sh start.sh                        # start all daemons, drawfs backend
sh start.sh --timeline             # start all + live chrono_dump view
sh start.sh --backend software     # use software backend instead
sh start.sh --stop                 # stop all running UTF daemons
```

### Manual startup

```sh
# 1. Audio daemon first — publishes the clock
sudo semaaud &
sleep 1

# 2. Input daemon — reads clock for timestamping
sudo semainputd &
sleep 1

# 3. Compositor — reads clock for frame scheduler
sudo semadrawd -b drawfs &

# 4. Optional: unified event timeline
{ sudo semaaud; sudo semainputd; sudo semadrawd -b drawfs; } 2>/dev/null | chrono_dump
```

### Boot configuration

`install.sh` configures boot automatically. drawfs loads via `loader.conf`
and the daemons start via `rc.d` in the correct order (`semaaud` → 
`semainputd` → `semadrawd`).

To configure manually:

```sh
# /boot/loader.conf
echo 'drawfs_load="YES"' >> /boot/loader.conf

# /etc/rc.conf
sysrc semaaud_enable="YES"
sysrc semainput_enable="YES"
sysrc semadraw_enable="YES"
```

---

## Subsystems

### drawfs

A FreeBSD kernel module that exposes `/dev/draw`. Clients open the device,
negotiate a binary framed protocol, create surfaces backed by swap memory, map
them with `mmap(2)`, render into the pixel buffer, and present. The kernel is
not a compositor; policy lives in userspace.

Completed: full surface lifecycle protocol, input event injection
(`DRAWFSGIOC_INJECT_INPUT`), per-session resource limits, event queue
backpressure. Phase 2 EFI framebuffer backend (`drawfs_efifb.c`) maps the
UEFI GOP framebuffer from preload metadata and exposes `DRAWFSGIOC_BLIT_TO_EFIFB`
so semadrawd can write rendered frames directly to the physical display without
X11, Wayland, or DRM/KMS. Verified operational on bare metal FreeBSD 15 at
1024x768 under UEFI boot.

A DRM/KMS backend skeleton (`drawfs_drm.c`) exists for future GPU-accelerated
bring-up but requires `drm-kmod` headers and is excluded from the default build.

See `drawfs/docs/` for the protocol specification and architecture.

### semadraw

A userspace semantic graphics system. Applications link against `libsemadraw`
and produce SDCS (Semantic Draw Command Streams). `semadrawd` owns surface
composition and presentation.

Completed: full SDCS command set including `DRAW_GLYPH_RUN` with CJK
double-width support; render state (`blend_mode`, `antialias`, `stroke_join`,
`stroke_cap`) in the drawfs backend; `ClockSource` vtable with
`ChronofsClockSource` adapter driving frames from the audio hardware clock;
unified event log emission with `ts_audio_samples`; remote TCP transport.

See `semadraw/docs/` for the SDCS specification.

### semaaud

An audio routing daemon. Clients connect via a Unix socket and submit PCM
streams with a JSON header. The daemon applies a policy grammar and routes
accepted streams to the OSS device.

Completed: OSS sample rate negotiation accepting any hardware-supported rate
and format (`s16le`, `s32le`); monotonic PCM sample counter published to a
shared memory clock region at `/var/run/sema/clock`; unified event log
emission with `ts_audio_samples`; Phase 12 durable policy validation.

See `semaaud/docs/` for the policy specification.

### semainput

An input classification and gesture daemon. Reads evdev devices, classifies
them by capability fingerprint, and emits structured JSON-lines events.

Completed: stable logical device identity, pointer smoothing, full gesture
recognition (scroll, pinch, swipe, drag, tap), keyboard passthrough with key
repeat suppression, audio clock timestamping, `has_keyboard` in
`identity_snapshot`.

See `semainput/docs/SystemInterface.md` for the event schema.

### shared/

Cross-cutting infrastructure used by all four daemons.

Completed: protocol constants code generator (`gen_constants.py`) producing C
and Zig definitions from `protocol_constants.json`; unified event log schema
(`EVENT_SCHEMA.md`); session identity module (`session.zig`); clock publication
interface (`clock.zig`) — 20-byte mmap region, `ClockWriter`/`ClockReader`,
`toNanoseconds()`.

### chronofs

The temporal coordination layer. Makes time a first-class addressable medium
across all four subsystems.

Completed: `Clock` and `MockClock` wrapping the shared audio clock; generic
thread-safe `EventStream(T, capacity)` ring buffer with `at(t)`, `query()`,
`latest()`; `Resolver` with `resolveVisual`, `resolveInput`, `resolveAudio`,
`resolveAll` and JSON ingestion from all three subsystems; `ChronofsClockSource`
wiring the audio clock into semadraw's `FrameScheduler`; `nextFrameTarget()`
computing the next sample-aligned frame boundary; `chrono_dump` with live,
`--drift`, and `--replay` modes.

---

## Unified Event Schema

All four daemons emit newline-delimited JSON to stdout. Every line contains:

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Event type, e.g. `stream_begin`, `frame_complete`, `mouse_move` |
| `subsystem` | string | `semaaud`, `semainput`, or `semadraw` |
| `session` | string | 16-char hex session token |
| `seq` | integer | Monotonic per-daemon sequence number |
| `ts_wall_ns` | integer | Wall-clock nanoseconds (i64) |
| `ts_audio_samples` | integer\|null | Audio sample position; null if semaaud not running |

Pipe any combination of daemons into `chrono_dump` for a merged timeline:

```sh
{ semaaud; semainputd; semadrawd; } 2>/dev/null | chrono_dump
```

---

## Implementation Waves

All seven implementation waves are complete.

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

## Status

| Component  | Status |
|------------|--------|
| `shared/`  | ✓ Complete |
| `drawfs`   | ✓ Phase 1 complete. Phase 2 EFI framebuffer backend complete. DRM/KMS skeleton complete (hardware bring-up pending) |
| `semaaud`  | ✓ Complete |
| `semainput`| ✓ Complete |
| `semadraw` | ✓ Complete |
| `chronofs` | ✓ Complete |

---

## License

BSD 2-Clause. See `LICENSE`.

Copyright © 2026 Pacific Grove Software Distribution Foundation.
