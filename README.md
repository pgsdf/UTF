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
├── install.sh           one-shot installer
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
sh install.sh                     # installs to /usr/local (requires root)
sh install.sh --prefix ~/utf-out  # custom prefix, no root needed
sh install.sh --check             # verify dependencies only
sh install.sh --uninstall         # remove installed files
```

This builds all subprojects at `ReleaseSafe`, installs the daemons to
`$PREFIX/bin/`, and writes FreeBSD `rc.d` service scripts to
`$PREFIX/etc/rc.d/`.

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

### Console / bare metal without a display server

When building on a bare FreeBSD console without X11 or Wayland installed,
disable those backends to avoid missing library errors:

```sh
cd semadraw && zig build -Dconsole=true
```

This keeps Vulkan, DRM/KMS, and drawfs backends active while removing the
X11 and Wayland dependencies. Use this on bare metal GhostBSD/FreeBSD
console installs.

### VirtualBox / headless environments

When GPU libraries are entirely absent (VirtualBox, CI, headless servers):

```sh
cd semadraw && zig build -Dgpu=false
```

Individual backends can also be disabled selectively:

```sh
zig build -Dvulkan=false -Dwayland=false   # keep X11, disable others
```

The `software` and `drawfs` backends are always available and require no
external libraries. `install.sh` detects the environment automatically:
VirtualBox gets `-Dgpu=false`, bare console gets `-Dconsole=true`.

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
./build.sh install   # install kernel source tree
./build.sh build     # compile the module
./build.sh load      # kldload drawfs.ko
./build.sh test      # run Python integration tests
```

---

## Quick Start

```sh
# Start all daemons
sudo semaaud      2>/dev/null &
sudo semainputd  2>/dev/null &
semadrawd        2>/dev/null &

# Watch the unified event timeline
{ sudo semaaud; sudo semainputd; semadrawd; } 2>/dev/null | chrono_dump

# Drift analysis (requires semaaud playing audio)
{ sudo semaaud; semadrawd; } 2>/dev/null | chrono_dump --drift

# Replay a recorded session
chrono_dump --replay fabric.log --rate 48000
```

To enable daemons at boot, add to `/etc/rc.conf`:

```
semaaud_enable="YES"
semainput_enable="YES"
semadraw_enable="YES"
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
backpressure, and a DRM/KMS backend skeleton (`drawfs_drm.c`) with connector
enumeration, dumb buffer allocation, and page-flip present path gated by
`hw.drawfs.backend`.

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
| `drawfs`   | ✓ Phase 1 complete. Phase 2 DRM/KMS skeleton complete (hardware bring-up pending) |
| `semaaud`  | ✓ Complete |
| `semainput`| ✓ Complete |
| `semadraw` | ✓ Complete |
| `chronofs` | ✓ Complete |

---

## License

BSD 2-Clause. See `LICENSE`.

Copyright © 2026 Pacific Grove Software Distribution Foundation.
