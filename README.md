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
                      drawfs         chronofs (planned)
                    (/dev/draw)     (temporal fabric)
                         │
                      hardware
```

| Component   | Role                                                        |
|-------------|-------------------------------------------------------------|
| drawfs      | Kernel graphics transport. `/dev/draw` character device, surface lifecycle, mmap-backed pixel buffers. |
| semadraw    | Semantic rendering. SDCS command streams, `semadrawd` compositor, software and hardware backends. |
| semaaud     | Audio daemon. OSS output, policy-controlled stream routing, preemption, fallback. |
| semainput   | Input daemon. evdev device classification, pointer smoothing, gesture recognition. |
| shared/     | Protocol constants, event schema, session identity, clock interface. |
| chronofs    | Temporal coordination layer. Planned. See `docs/Thoughts.md`. |

---

## Repository Layout

```
UTF/
├── drawfs/          kernel module and protocol (FreeBSD 15)
├── semadraw/        semantic rendering daemon and client library
├── semaaud/         audio routing daemon
├── semainput/       input classification and gesture daemon
├── shared/          cross-cutting constants, schema, and interfaces
├── chronofs/        temporal coordination layer (in progress)
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

See `drawfs/docs/` for protocol specification, architecture, and build
instructions.

### semadraw

A userspace semantic graphics system. Applications link against `libsemadraw`
and produce SDCS (Semantic Draw Command Streams) — binary sequences of drawing
operations that express intent rather than GPU commands. `semadrawd` owns
surface composition and presentation. Backends include software (reference),
Vulkan, DRM/KMS, X11, Wayland, and drawfs.

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
in a single JSON source of truth. Planned: a code generator that emits C and
Zig constant definitions, a unified event schema, a session identity module,
and a clock publication interface for chronofs.

### chronofs (planned)

A temporal coordination layer that makes time a first-class addressable medium
across all four subsystems. The audio hardware clock drives a shared monotonic
counter. All events carry an audio-sample timestamp. The frame scheduler queries
scene state at a target audio position rather than wall time, producing
drift-free AV synchronization by construction.

See `docs/Thoughts.md` for the full design and `chronofs/BACKLOG.md` for the
implementation plan.

---

## Build

Each subsystem builds independently.

**drawfs** requires FreeBSD kernel sources:

```sh
cd drawfs
./build.sh install
./build.sh build
./build.sh load
./build.sh test
```

**semadraw**, **semaaud**, **semainput** require Zig 0.15 or newer:

```sh
cd semadraw && zig build
cd semaaud  && zig build
cd semainput && zig build
```

---

## Status

| Component  | Status                                      |
|------------|---------------------------------------------|
| drawfs     | Phase 1 complete. Phase 2 (DRM/KMS) planned. |
| semadraw   | Protocol fixes complete. drawfs backend integration in progress. |
| semaaud    | Phase 12 (durable policy) in progress.      |
| semainput  | Stable for pointer and touch hardware. |
| shared/    | Protocol constants defined. Generator and schema planned. |
| chronofs   | Design complete. Implementation not started. |

---

## License

BSD 2-Clause. See `LICENSE`.

Copyright (c) 2026 Pacific Grove Software Distribution Foundation.

