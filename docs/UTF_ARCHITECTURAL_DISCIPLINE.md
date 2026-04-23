# UTF Architectural Discipline

Status: Stated, 2026-04-23

This document states the discipline that governs what code UTF depends on
and what code UTF writes. It is the principle behind decisions that were
previously unwritten: why drawfs exists instead of Xlib, why semaaud
exists instead of PulseAudio, why inputfs is being built instead of
continuing to use evdev.

The principle is stated once, with its rationale and its accepted
limits. Every subsystem's design document should cite this discipline
and derive specific choices from it rather than re-deriving the
underlying reasoning.

## The principle

> **UTF depends only on code written with UTF's guarantees in mind.
> Everything else is either replaced or explicitly accepted as a named
> platform-transport dependency.**

## Why

UTF's central commitments are **determinism and stability**. A recording
made today should replay identically tomorrow. A session that worked on
Monday should work on Monday-next-year without the user adjusting to
behavioural drift in something underneath them.

These are not soft goals. They shape the entire architecture: the
audio-driven clock, the kernel-authoritative surface registry, the event
schema with sequence numbers, the published state regions. Each of these
was built to hold a specific determinism or stability guarantee.

A single dependency on code that does not share those commitments can
invalidate them all. A library that fixes a "bug" in its next release
changes what UTF does. A kernel module that adds a background thread
changes UTF's timing. A userspace daemon that buffers an event changes
UTF's sequencing. None of these are malicious; they are the normal
lifecycle of code written for other purposes. But they break UTF.

The discipline says: **if we want UTF's guarantees to hold, every layer
that contributes to those guarantees must be written with them in mind.**
External code — written by people with their own goals, constraints, and
future plans — is a risk whenever it sits inside the guarantee path.

## How

Three possible postures toward any external component:

1. **Replace.** Write a UTF-owned equivalent. This is the path for
   everything inside the guarantee path. inputfs replaces evdev.
   drawfs replaces Xlib. semaaud replaces PulseAudio. The replacement
   is shaped by UTF's needs, not by the predecessor's design.

2. **Accept as platform transport.** Some dependencies cannot be
   reasonably replaced (the CPU, the USB controller, the FreeBSD
   kernel itself). These are named explicitly as accepted. They are
   treated as the boundary UTF runs on, not as components UTF's
   guarantees extend through. UTF code does not rely on undocumented
   behaviour of accepted dependencies, and when an accepted
   dependency fails or changes, UTF's response is part of the design
   rather than a surprise.

3. **Remove.** Some external dependencies exist because they were
   convenient at the time UTF started and are not required by UTF's
   goals. When the discipline is applied, these disappear. The code
   that depends on them disappears with them.

Every external component in UTF falls into one of these three.
Nothing is left in the "we'll deal with it later" category without
an explicit note saying so.

## Accepted platform-transport dependencies

This list enumerates what UTF accepts as the platform it runs on. It
is intentionally minimal. Growth requires an ADR-level decision.

**Hardware layer**
- CPU, memory, motherboard
- PCI/USB controllers and their transport-level operation
- Display hardware (through framebuffer paths today; direct GPU
  programming is an open question — see §"In scope for review")
- Audio hardware (through OSS today; also an open question)
- Input hardware (through HID transport today; everything above
  transport is being replaced by inputfs)

**FreeBSD kernel**
- Scheduler, memory manager, VM subsystem
- VFS and the filesystems that hold UTF's data
- Signal handling, process model, IPC primitives that UTF uses
  directly (shared memory, sockets, kqueue)
- USB stack above the controller (for HID transport)

**Language and toolchain**
- Zig compiler and its code generation
- Zig standard library, with the caveat that UTF code at determinism
  boundaries verifies stdlib behaviour rather than assuming it
- LLVM, the linker, libc (through Zig's use of them)

**Build and runtime machinery**
- `rc.d` scripts and service supervision
- `/var/run`, `/var/log`, `/etc` conventions
- Standard Unix tooling used in build and install scripts

Everything else in UTF is either written by the project or being
actively migrated toward being written by the project.

## In scope for review

These are subsystems or dependencies where the discipline has
implications we have not yet applied. They are listed here so the
discipline is honest about its current state; they are not a
schedule of work. The BACKLOG tracks what is actually scheduled.

**Input.** evdev, bsdinput, libinput. Being replaced by inputfs.
This is the current front.

**Audio output.** semaaud uses OSS as its audio output path. OSS is
FreeBSD kernel audio infrastructure, not UTF-written. The
replacement path would be direct hardware driving, analogous to
inputfs replacing evdev. This is substantial work because
real-time audio has harder timing constraints than input.

**Graphics output.** drawfs uses efifb (or DRM/KMS on capable
hardware) for display output. The framebuffer and modesetting
paths are not UTF-written. The replacement path would be direct
GPU programming, which is the largest dependency-replacement
UTF could undertake.

**Userspace classification.** semainputd currently performs device
classification and gesture recognition. When inputfs lands, this
responsibility moves into the kernel (for classification) and
the compositor (for gestures). semainputd retires entirely.

**File persistence.** UTF uses ZFS for persistent storage of
configuration, publication artefacts, and session state. ZFS is
not UTF-written; it is accepted as platform transport. This
acceptance should be explicit rather than implicit.

## What the discipline does not mean

The discipline is not a purity test. Some edges of it require pragmatic
acceptance, and pragmatic acceptance is a valid answer.

**It does not mean rewriting everything.** Most of FreeBSD's kernel,
all of Zig's standard library, and the entire USB stack are accepted
as platform transport. The discipline is about the code *inside* the
guarantee path, not every line of code UTF touches.

**It does not mean hostility to external projects.** FreeBSD, Zig,
and the various libraries UTF does not use are fine projects pursuing
their own goals. UTF's discipline is about UTF's guarantees, not
about those projects' quality.

**It does not mean avoiding standards.** UTF uses POSIX socket APIs,
USB HID specifications, OSS audio conventions. Standards are
acceptable — they define stable interfaces. What is not acceptable
is depending on a particular implementation of a standard if that
implementation can change in ways that affect UTF's guarantees.

**It does not mean changes are free.** Each replacement is
substantial work. The discipline says UTF will do that work; it does
not say the work happens all at once. Pragmatic sequencing is part
of the discipline, not a departure from it.

**It does not mean UTF never ships.** At every moment, UTF should be
in a state where testing is possible and the current set of
replacements is working. The discipline governs direction, not
sprints.

## Operating rules

These are the rules that follow from the discipline. They apply to
ADRs, code reviews, and the BACKLOG.

1. **New features do not introduce new guarantee-path dependencies
   without an ADR.** If a feature needs capability X, and X would
   require depending on external code Y that is not already accepted
   as platform transport, the ADR for that feature must address
   whether Y is acceptable (with reasoning) or whether a UTF
   replacement for Y is in scope.

2. **Existing guarantee-path dependencies are named, not hidden.**
   Anywhere UTF currently depends on code outside this document's
   accepted list, the code's dependency should be explicit in its
   comments or commit messages. "We use evdev here" is fine as a
   temporary state; silent use of evdev is not.

3. **Replacements preserve guarantees through the transition.** No
   replacement leaves UTF non-functional for an extended period. The
   migration path for each replacement is part of the replacement's
   design, not an afterthought.

4. **Accepted dependencies can be revisited.** The accepted list in
   this document is the current snapshot. A dependency can move from
   "accepted" to "in scope for replacement" when a concrete reason
   appears — a bug that affected UTF's guarantees, a platform change
   that made replacement more tractable, a UTF feature that requires
   guarantees the dependency cannot provide.

5. **Occam's razor applies.** If a UTF component has grown complex
   because it was working around an external dependency, and the
   dependency is replaced, the component simplifies. Don't preserve
   complexity that existed only to compensate for what was wrong.

## Naming

The discipline itself does not have a catchy name in this document,
by intent. It is not a brand to promote. It is a principle the project
operates by, referenced by its commitments: determinism, stability, and
the explicit enumeration of what UTF depends on.

If a short reference is needed in commit messages or BACKLOG entries,
cite this document by path: `docs/UTF_ARCHITECTURAL_DISCIPLINE.md`.

## Related documents

- `README.md` — project overview; mentions determinism and stability
  as central goals.
- `docs/Thoughts.md` — chronofs architecture; the temporal-coherence
  discussion that established the determinism vocabulary.
- `inputfs/docs/inputfs-proposal.md` — first subsystem-level
  application of this discipline as an explicitly named design driver.
- `BACKLOG.md` — where specific replacements and acceptances are
  tracked as work items.
- `semadraw/docs/adr/0001-zig-and-sdcs.md` — the toolchain and
  canonical-representation decision that this discipline assumes.
