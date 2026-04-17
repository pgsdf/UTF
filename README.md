# UTF — Unified Temporal Fabric

UTF is a graphics, audio, and input stack for FreeBSD. It draws windows, routes
sound, and handles mice, keyboards, and touch — all coordinated against a
single audio-driven clock so audio and video stay in sync by construction
rather than by luck. Install it if you're building a FreeBSD desktop or media
application and want these three things to work together as one system.

---

## Requirements

Before you install, confirm your machine meets all of the following. UTF will
not run on Linux or macOS.

| Requirement | Minimum | Notes |
| --- | --- | --- |
| Operating system | FreeBSD 15 | Earlier versions are not supported. |
| Kernel sources | Installed | Needed to build the `drawfs` kernel module. |
| Zig | 0.15 | Used to build the three userspace daemons. |
| C toolchain | base system | Already present on FreeBSD. |
| Root access | Yes | Required to load the kernel module. |

Check your versions:

```sh
uname -r          # should report 15.x
zig version       # should report 0.15 or newer
ls /usr/src/sys   # kernel sources should be present
```

If any of these fail, stop and resolve them first. The install below assumes
all four are in place.

---

## Install

Clone the repository and run the build steps in the order below. Order
matters: `drawfs` exposes the `/dev/draw` device that `semadraw` depends on,
so it must be built and loaded first. The userspace daemons can be built in
any order after that.

```sh
# 1. Clone
git clone https://github.com/pgsdf/UTF.git
cd UTF

# 2. Build and load the kernel module (drawfs)
cd drawfs
./build.sh install
./build.sh build
sudo ./build.sh load
./build.sh test
cd ..

# 3. Build the userspace daemons
cd semadraw  && zig build && cd ..
cd semaaud   && zig build && cd ..
cd semainput && zig build && cd ..
cd chronofs  && zig build && cd ..
```

After this, the kernel module is loaded and all four daemon binaries are
built. Proceed to **Verify** to confirm the system is working.

---

## Verify

Run these checks in order. Each one confirms a layer is up.

**1. Kernel module loaded and device present:**

```sh
kldstat | grep drawfs       # should list the drawfs module
ls -l /dev/draw             # should show the character device
```

**2. Daemons start cleanly:**

Startup order matters because chronofs publishes the shared clock that the
other daemons consume. Start it first, then the rest can start in any order:

```sh
# Terminal 1 — start chronofs first (publishes the shared clock)
chronofs/zig-out/bin/chronofs

# Terminals 2, 3, 4 — the rest
semaaud/zig-out/bin/semaaud
semainput/zig-out/bin/semainput
semadraw/zig-out/bin/semadrawd
```

Each should start without error and stay running. If a daemon exits
immediately, see **Troubleshooting**.

**3. Stack is coherent:**

Run the chronofs diagnostic to confirm all subsystems are publishing events
against a common clock:

```sh
chronofs/zig-out/bin/chrono_dump
```

You should see timestamped events from `semadrawd`, `semaaud`, and
`semainput` interleaved against the shared audio-sample clock. If all three
appear and their timestamps advance monotonically, the fabric is up.

---

## Try It

See `docs/quickstart.md` for a five-minute walkthrough that renders a test
surface, routes an audio stream, and prints input events — enough to confirm
the whole fabric is working end-to-end.

For longer-form installation help, including per-step explanations and
platform-specific notes, see `docs/install.md`.

---

## Troubleshooting

**`./build.sh load` fails with "module already loaded"**
The module was loaded in a previous session. Run `sudo kldunload drawfs` and
try again, or skip the load step — it's already running.

**`./build.sh build` fails with missing kernel headers**
Kernel sources aren't installed. Install them with `pkg install
freebsd-src-sys` or fetch them via `fetch` / `svnlite` to `/usr/src`, then
re-run.

**`zig build` fails with "unsupported Zig version" or similar**
Your Zig is older than 0.15. Check with `zig version`. Install a current Zig
from https://ziglang.org/download/ or via `pkg install zig-devel`.

**`/dev/draw` exists but `semadrawd` reports permission denied**
The device is root-owned by default. Either run `semadrawd` as root for
testing, or add a devfs rule so your user can open it. See
`drawfs/docs/permissions.md`.

**A daemon exits immediately with no error**
Run it with `-v` or `--verbose` (flag name varies by daemon) to see why. The
most common causes are a stale socket in `/var/run/` from a previous run
(delete it) or another instance already bound.

More cases in `docs/troubleshooting.md`.

---

## Uninstall

```sh
# Stop any running daemons (Ctrl-C in their terminals, or pkill)
pkill semadrawd semaaud semainput chronofs

# Unload the kernel module
sudo kldunload drawfs

# Remove build artifacts
cd UTF
rm -rf drawfs/build \
       semadraw/zig-out semaaud/zig-out \
       semainput/zig-out chronofs/zig-out

# Remove the repository
cd .. && rm -rf UTF
```

See `docs/uninstall.md` if you also want to remove installed kernel module
files or devfs rules.

---

## Architecture

UTF brings together four subsystems under a single workspace and provides the
cross-cutting infrastructure — shared protocol constants, a unified event
schema, session identity, and a clock publication interface — that makes them
a coherent fabric rather than four independent daemons.

```
                    Applications
                         │
                    libsemadraw
                    (SDCS streams)
                         │
                    semadrawd ──── semainput ──── semaaud
                    (compositor)   (input)        (audio)
                         │              \            /
                      drawfs           chronofs
                    (/dev/draw)     (temporal fabric)
                         │
                      hardware
```

**chronofs** is the temporal coordination layer that aligns audio, visual, and
input domains against a single monotonic clock driven by audio hardware. The
frame scheduler queries scene state at a target audio position rather than
wall time, eliminating drift between subsystems as a structural property of
the architecture. See `docs/architecture/chronofs.md` for the design and
`chrono_dump` for runtime diagnostics.

---

## Subsystems

| Component | Role |
| --- | --- |
| drawfs | Kernel graphics transport. `/dev/draw` character device, surface lifecycle, mmap-backed pixel buffers, DRM/KMS display. |
| semadraw | Semantic rendering. SDCS command streams, `semadrawd` compositor, software and hardware backends, remote transport. |
| semaaud | Audio daemon. OSS output, durable policy-controlled stream routing, sample rate negotiation, sample position counter. |
| semainput | Input daemon. evdev device classification, pointer smoothing, gesture recognition, audio-clock-timestamped events. |
| shared/ | Protocol constants (with code generator), unified event log schema, session identity, clock publication interface. |
| chronofs | Temporal coordination layer. Clock module, event stream ring buffers, resolver, audio-driven frame scheduler. |

Each subsystem has its own `docs/` directory with detailed protocol, build,
and API reference material.

---

## Status

All subsystems are implemented and integrated against the chronofs temporal
fabric.

| Component | Status |
| --- | --- |
| drawfs | Phase 1 and Phase 2 (DRM/KMS) complete. Kernel input event delivery integrated. |
| semadraw | Clock-source-driven frame scheduler, drawfs backend integration, remote transport hardening, DRAW_GLYPH_RUN, and unified event emission complete. |
| semaaud | Phase 12 durable policy complete. Sample position counter, sample rate negotiation, and unified schema adoption complete. |
| semainput | Pinch calibration, unified schema adoption, keyboard passthrough, and audio-clock event timestamping complete. |
| shared/ | Protocol constant generator, session identity module, unified event log schema, and clock publication shared-memory interface complete. |
| chronofs | Clock module, event stream ring buffers, resolver, and audio-driven frame scheduler integration complete. `chrono_dump` diagnostic available. |

---

## License

BSD 2-Clause. See `LICENSE`.

Copyright (c) 2026 Pacific Grove Software Distribution Foundation.
