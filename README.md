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
                         |              |
                      hardware       inputfs
              (EFI framebuffer /     (HID kernel
               Vulkan / X11)          substrate)
```

| Component | Role |
| --- | --- |
| drawfs | Kernel graphics transport. `/dev/draw` character device, surface lifecycle, mmap-backed pixel buffers, EFI framebuffer blit. |
| semadraw | Semantic rendering. SDCS command streams, `semadrawd` compositor, software and hardware backends. |
| semaaud | Audio daemon. OSS output, policy-controlled stream routing, preemption, fallback. |
| semainput | Input daemon. evdev device classification, pointer smoothing, gesture recognition. To be retired by inputfs (see AD-1, AD-2 in BACKLOG). |
| inputfs | Kernel input substrate. Attaches at hidbus, parses HID reports, publishes input state and events to userspace via shared memory under `/var/run/sema/input/`. |
| shared/ | Protocol constants, event schema, session identity, clock interface. |
| chronofs | Temporal coordination layer. Audio-driven frame scheduler, ring buffers, clock publication. |

---

## Repository Layout

```
UTF/
├── drawfs/          kernel module and protocol (FreeBSD 15)
├── inputfs/         kernel input substrate (FreeBSD 15)
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

The legacy userspace input daemon. Reads evdev devices, classifies them by
capability fingerprint, aggregates physical devices into stable logical
identities, applies pointer smoothing, and emits structured JSON-lines
events for semantic input (mouse, keyboard, touch) and gestures
(two-finger scroll, pinch, three-finger swipe, drag, tap).

semainput is being retired. inputfs (below) is the kernel-side substrate
that replaces it. The substrate landed (Stages A through D); the cutover
that removes the evdev reader, the `drawfs_inject` adapter, and the
standalone `semainputd` daemon is the work tracked as AD-2a in
`BACKLOG.md`. semainput remains in the tree until that work lands so
UTF stays operational during the transition; once AD-2a completes,
the daemon binary is gone and `gesture.zig` lives on as `libsemainput`,
a userland library consumed by clients and by semadrawd.

See `semainput/docs/` for architecture and system interface documentation
of the legacy daemon.

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

### inputfs

A FreeBSD kernel module that owns the HID input path. inputfs attaches at
`hidbus`, parses HID report descriptors, registers interrupt callbacks, and
publishes input state and events to userspace via shared-memory regions
under `/var/run/sema/input/`. The state region carries the materialised
view (current pointer position, device inventory, per-device keyboard and
touch state) updated under a seqlock; the event ring carries an ordered
delta stream consumable via the `EventRingReader` from
`shared/src/input.zig`.

Stage A delivered the design (proposal, foundations, ADRs 0001 through
0011, four byte-level companion specs). Stage B delivered HID attachment,
descriptor parsing, interrupt handler registration, and per-device role
classification. Stage C delivered userspace publication of the state
region and event ring, along with the `inputdump` diagnostic CLI and a
verification protocol at `inputfs/docs/C_VERIFICATION.md` that runs 26
automated checks plus a manual mouse-and-button checklist. Stage D
(focus routing and coordinate transform) landed across eight sub-stages
(D.0a through D.6); the parser was hardened by AD-9's fuzzing work
before the cutover proceeds.

inputfs replaces `semainput` (the userspace evdev daemon) on the
PGSD target. The substrate is built; the cutover that retires the
evdev reader, the `drawfs_inject` adapter, and the `semainputd`
daemon is **Stage E, tracked as AD-2a in `BACKLOG.md` and the next
intentional act for the input stack**. Until AD-2a lands, both
paths coexist (`hw.inputfs.enable` tunable from Stage D); after
AD-2a, evdev is no longer present in any UTF code path. UTF runs
on inputfs only, with no fallback, by deliberate commitment to
the discipline at `docs/UTF_ARCHITECTURAL_DISCIPLINE.md`.

See `inputfs/docs/` for the proposal, foundations, ADRs, byte-level specs,
and verification protocols.

---

## System Requirements

UTF targets PGSD-on-FreeBSD 15.0-RELEASE. Beyond a working FreeBSD installation,
two system-level configuration items are required for the daemons and kernel
modules to operate correctly.

For an end-to-end walkthrough of installing UTF on a fresh FreeBSD system,
including hazards that have actually broken installs (in particular: do
not add `inputfs_load="YES"` to `/boot/loader.conf`), see
[`INSTALL.md`](INSTALL.md).

### `/var/run` must be tmpfs

Several UTF components publish state to userland via shared-memory regions
under `/var/run/sema/`: the audio clock at `/var/run/sema/clock` (semaaud),
the session token at `/var/run/sema/session`, and the inputfs state region
at `/var/run/sema/input/state` (Stage C onward). These files are recreated
on every daemon or module load and are meaningful only for the current boot.

FreeBSD convention is that `/var/run` is volatile. Some installations leave
`/var/run` on the same filesystem as the rest of `/var`, which makes
shared-memory publication writes more expensive and leaves stale region
files persisting across reboots until the next module load truncates them.
The supported configuration is to mount `/var/run` as tmpfs by adding the
following line to `/etc/fstab`:

```
tmpfs /var/run tmpfs rw,mode=755 0 0
```

After editing `fstab`, either reboot or run `sudo mount /var/run` to
activate. Confirm with `mount | grep /var/run` (expect a `tmpfs on /var/run`
line). The inputfs verification protocol assumes this configuration;
running on a non-tmpfs `/var/run` is unsupported.

### PGSD kernel configuration

PGSD ships a kernel that omits drivers superseded by `inputfs`: `hms`,
`hkbd`, `hgame`, `hcons`, `hsctrl`, `utouch`, `hpen`, and the `hidmap`
framework. Stock FreeBSD compiles `hms` and `hkbd` statically into
`GENERIC` and produces `.ko` modules for the rest, which causes the
HID transport layer to attach the legacy drivers ahead of inputfs at
boot or on USB events. Running the inputfs verification protocols on
stock FreeBSD requires either booting the PGSD kernel or moving the
competing `.ko` files out of `/boot/kernel/` and regenerating
`linker.hints` (see `BACKLOG.md` AD-8 for the durable answer via
`WITHOUT_MODULES` in `/etc/src.conf`).

---

## Multi-user deployment

UTF's substrate publication files default to mode `0600` owned
by `root:wheel`, per ADR 0013
(`inputfs/docs/adr/0013-publication-permissions.md`). On a
single-user dev or bench system, no further configuration is
needed: all UTF daemons run as root by default, all consumers
run via `sudo`, and the substrate is uniformly accessible
within that root context.

On a multi-user system, operators relax the defaults via the
operating system rather than via UTF-specific configuration.
Two layers control the result:

**Kernel-side (`inputfs`).** Three sysctl tunables apply at
module load and at runtime:

```
sysctl hw.inputfs.dev_uid=0
sysctl hw.inputfs.dev_gid=$(getent group operator | cut -d: -f3)
sysctl hw.inputfs.dev_mode=0640
```

These can also live in `/boot/loader.conf` for boot-time
defaults:

```
hw.inputfs.dev_uid=0
hw.inputfs.dev_gid=920
hw.inputfs.dev_mode=0640
```

The sysctls take effect for files created after the change.
Already-open files retain the attributes they were created
with. Reload the inputfs module to refresh.

**Userspace (`semaaud`, `semadraw`, etc.).** Daemon process
group is set via `/etc/rc.conf`:

```
semaaud_user="root"
semaaud_group="operator"
chronofs_user="root"
chronofs_group="operator"
semadrawd_user="root"
semadrawd_group="operator"
```

Daemon umask is set per-script (see the existing rc.d entries
for the pattern). Setting `umask 027` together with the
explicit `0o600` UTF passes to `createFile` produces files at
mode `0600`; setting `umask 037` with explicit `0o640`
produces group-readable files. UTF cannot expose more
permissions than its explicit mode, so the umask only ever
restricts further.

Authorized consumers are added to the chosen group via
`pw groupmod operator -m <user>`. After this, the user can
run `inputdump`, `chrono_dump`, and similar diagnostic tools
without `sudo`.

drawfs's cdev follows the same convention with parallel
sysctls (`hw.drawfs.dev_uid`, `hw.drawfs.dev_gid`,
`hw.drawfs.dev_mode`).

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
| semainput | Legacy userspace daemon. Functional, retiring in AD-2a. |
| inputfs | Substrate complete (Stages A, B, C, D landed on PGSD-bare-metal; eight Stage D sub-stages D.0a through D.6; parser hardened by AD-9). Stage E cutover (AD-2a) is the next intentional act and removes evdev from the UTF tree. |
| shared/ | Protocol constants, generator, event schema, session identity, clock interface: all complete. |
| chronofs | Complete. Audio-driven frame scheduler operational. |

**The next intentional act for the input stack is Stage E.** inputfs has
owned HID at the kernel level since Stage D landed; semainput, the
userspace evdev daemon it replaces, is still in the tree because the
cutover hasn't been executed yet. AD-2a executes that cutover: switch
semadrawd's default backend to inputfs, delete the evdev adapter and
the `drawfs_inject` adapter, retire `semainputd`, promote `gesture.zig`
into a userland library `libsemainput`, and remove evdev-loading
instructions from user-facing setup docs. After AD-2a, no UTF code
path uses evdev. AD-2b (per-user pointer smoothing, design landed in
ADR 0015) is independent of AD-2a and may proceed in either order.

---

## License

BSD 2-Clause. See `LICENSE`.

Copyright (c) 2026 Pacific Grove Software Distribution Foundation.
