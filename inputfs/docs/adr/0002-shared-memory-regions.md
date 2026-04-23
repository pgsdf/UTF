# 0002 Shared-memory region layout and semantics

Status: Proposed

## Context

The inputfs charter (`inputfs/docs/adr/0001-module-charter.md`)
specifies that inputfs publishes to userspace via shared-memory
regions under `/var/run/sema/input/`. The foundations document
(`inputfs/docs/foundations.md` §4) names three publication
surfaces: a current state region, an event history ring, and a
pollable fd.

UTF already has a reference pattern for shared-memory publication
in `shared/CLOCK.md` and `shared/src/clock.zig`: magic number plus
version as the first fields, little-endian layout, sequential-
consistency atomics, Writer/Reader types exposed through a shared
library, total region size stated explicitly. inputfs follows that
pattern; this ADR names the regions it publishes and their
high-level semantics.

Per-region byte-level specifications — offset tables, exact field
types, version migration rules — live in companion documents
analogous to `shared/CLOCK.md`. This ADR decides *which* regions
exist and *what* they carry; the companion specs decide *how* they
are laid out.

## Decision

1. inputfs publishes three shared-memory regions under
   `/var/run/sema/input/`:
   - `/var/run/sema/input/state` — current input state.
   - `/var/run/sema/input/events` — bounded event ring in
     sequence-number order.
   - `/var/run/sema/input/transform` — compositor-published
     coordinate transform, written by the compositor, read by
     inputfs.

2. Each region begins with a magic-plus-version header in the
   `shared/CLOCK.md` idiom. The magic identifies the region
   type; the version admits format migration. Readers verify
   both before interpreting subsequent bytes.

3. State region (`state`) carries current pointer position,
   per-device keyboard state (modifier bitmask, keys held),
   device inventory, and metadata (sequence number of the last
   event incorporated, boot-time wall-clock offset). Writes use
   seqlock versioning (foundations §4) for atomic multi-field
   reads. The inputfs kernel module is the sole writer; userspace
   consumers are read-only.

4. Event ring (`events`) is a bounded single-producer
   multiple-consumer ring. Producers write events in
   sequence-number order; consumers read by polling or waking on
   the pollable fd. Ring capacity is stated in the region's
   companion spec, not in this ADR.

5. Transform region (`transform`) is the inverse-direction surface
   — the compositor publishes the current post-transform mapping
   from device space to compositor space. inputfs reads it to
   normalise pointer coordinates. The compositor is the sole
   writer; inputfs is the sole reader.

6. A Zig library under `shared/src/input.zig` exposes
   `StateWriter`, `StateReader`, `EventRingWriter`,
   `EventRingReader`, `TransformWriter`, and `TransformReader`
   types, paralleling the `ClockWriter`/`ClockReader` pattern. C
   consumers access the regions through equivalent headers.

7. All regions are little-endian. Atomic operations use sequential
   consistency, matching the clock region's convention. Byte-level
   layouts, magic numbers, and version histories live in per-region
   specs to be written as companion documents; those specs are
   tracked in `BACKLOG.md` as sub-items of AD-1.

## Consequences

1. Every userspace consumer of input has a consistent API shape
   across the three regions, matching the clock region's shape.

2. The companion specs (for state, events, transform) become the
   authoritative references for implementation. This ADR is not
   revised when those specs land; it points at them.

3. The `transform` region establishes a convention for
   bidirectional shared-memory publication between subsystems
   (compositor writes, inputfs reads). Future subsystem pairs that
   need similar coupling can follow the same pattern.

4. inputfs depends on the compositor publishing the transform
   region before routing pointer events to compositor-space
   coordinates. Until the transform region is present and valid,
   inputfs either buffers events or publishes coordinates in a
   pre-transform fallback space. The behaviour during this window
   is specified in the state region's companion spec.

5. The event ring is bounded; slow consumers miss events. Per
   foundations §4, the recovery path is to read state (which is
   always current) and skip forward in the ring. This ADR does
   not restate that; it is a foundations-level invariant.

## Notes

Byte-level region layouts are intentionally out of scope for this
ADR. Writing them here would couple the ADR to implementation
detail that must be revisable, and would duplicate the work the
per-region specs will do properly.

The `shared/CLOCK.md` document is the pattern. Each inputfs region
gets a document of comparable depth: magic number and version,
offset table, atomic semantics, API examples, lifecycle notes.
Those companion documents are the third Stage A artifact (after
this ADR and the follow-on ADRs on focus publication and role
taxonomy), tracked under AD-1.

Region names (`state`, `events`, `transform`) are working names;
they may be revised in the companion specs if a clearer naming
convention emerges during implementation. The charter's naming
conventions (`/var/run/sema/input/`, `/dev/inputfs`,
`hw.inputfs.*`) are fixed.
