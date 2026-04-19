# UTF Sprint Backlog

**Sprint**: 2026-04-19 → 2026-05-03
**Window**: 2 weeks
**Status**: active

---

## Relationship to the product backlog

This is the **sprint backlog** — the subset of work actively in
progress during the current 2-week window, with ordering and
dependencies made explicit. It is derived from the product backlog at
`BACKLOG.md`, which remains the authoritative list of everything that
*could* be worked on.

Rules:

- An item may only appear here if it already exists in the product
  backlog. If something new comes up mid-sprint, add it to the product
  backlog first, then (if appropriate) pull it here.
- Items removed or skipped mid-sprint stay in the product backlog with
  their status unchanged. Only completion flows back to the product
  backlog as `[x]`.
- The sprint backlog is rewritten each sprint, not appended to.
  History lives in git, not in this file.

---

## Sprint goal

**Close out the DRM-optional theme and ship the partial-update
protocol as far as the wire contract.** Concretely: land the
ROADMAP cross-link (B5.3), commit the wire-format design for
regional presents (B3.1), and get the opcodes and struct headers in
place (B3.2) so that the kernel builds clean with the new vocabulary
and B3.3 is a pure implementation task against a stable contract.

**Scope expansion (mid-sprint, 2026-04-19).** The original goal was
met early; B3.3 (swap-path implementation) was pulled into the
current window rather than deferred to a new sprint. This is
documented here rather than retroactively rewriting the goal —
the original plan was complete at SPRINT-03; everything from
SPRINT-04 onward is expansion scope.

---

## Ordering and dependency rules

The task list below is **strictly ordered**: task N cannot start until
task N−1 is either done or explicitly marked as parallel-safe via the
`‖` marker. Dependencies are called out per task in the `Depends on:`
field; if a listed dependency is outside this sprint (an already-done
item in the product backlog or an external condition), say so.

Markers used in the list:

| Marker | Meaning                                                   |
|--------|-----------------------------------------------------------|
| `→`    | Sequential — must wait for the previous task.             |
| `‖`    | Parallel-safe with the previous task.                     |
| `⧖`    | Blocked — a dependency is not yet satisfied. Explain.     |
| `✎`    | In progress.                                              |
| `✓`    | Done. Moves back to the product backlog as `[x]`.         |

---

## Sprint tasks

### `✓` SPRINT-01 — Close B5.3: cross-link `drawfs/docs/ROADMAP.md` to root backlog

- **Product backlog**: B5.3
- **Depends on**: None
- **Effort**: trivial
- **Status**: done
- **Owner**: Vic
- **Done when**: `drawfs/docs/ROADMAP.md` carries a blockquote at the top
  pointing at the root `BACKLOG.md`; the bottom-of-file `## Backlog`
  section is removed; any surviving open items from that section are
  migrated to the root backlog (not silently dropped).

Turned out to be more than the stated "five-minute" cleanup: the
`## Backlog` section at the bottom of ROADMAP.md contained an open
item (WITNESS debug-kernel verification) that had been sitting
unacted-upon. Rather than delete it silently, it was migrated to the
root backlog as **DF-4** (now deferred pending hardware). Lesson:
consolidation tasks are rarely "just a pointer at the top" — they
require an honest pass over whatever you're pointing away from.

### `→ ✓` SPRINT-02 — B3.1: design `DRAWFS_REQ_SURFACE_PRESENT_REGION`

- **Product backlog**: B3.1
- **Depends on**: SPRINT-01 (closes out the immediate cleanup work)
- **Effort**: medium
- **Status**: done
- **Owner**: Vic
- **Done when**: a design document exists at
  `drawfs/docs/DESIGN-surface-present-region.md` specifying opcode
  assignments, wire format, semantics, error conditions, and the
  rationale for the design alternative chosen. Implementable without
  further design work.

Delivered a 407-line spec committed to the new-opcode approach
(`0x0023`/`0x8023`/`0x9003`) with `drawfs_rect` as a shared 16-byte
type and `DRAWFS_MAX_PRESENT_RECTS = 16` as a protocol-level cap.
The key design call — new opcode vs. extending `SURFACE_PRESENT` via
its reserved `flags` field — was made after reading the existing
proto header; the `__packed` fixed-size invariant of the current
struct made a new opcode the cheaper choice. Three open questions
flagged for review (cookie in event, clamp-warning events, strict
`_reserved` checking); each has a chosen default and the alternative
documented.

### `→ ✓` SPRINT-03 — B3.2: protocol constants and struct headers

- **Product backlog**: B3.2
- **Depends on**: SPRINT-02 (design must be committed)
- **Effort**: small
- **Status**: done
- **Owner**: Vic
- **Done when**: three entries (`REQ_SURFACE_PRESENT_REGION`,
  `RPL_SURFACE_PRESENT_REGION`, `EVT_SURFACE_PRESENTED_REGION`) are in
  `shared/protocol_constants.json`; `gen_constants.py --validate`
  reports clean; struct definitions are in `drawfs_proto.h` with
  verified sizes; `drawfs/tests/drawfs_test.py` has matching Python
  constants; a clean kernel build succeeds on the target host with
  `DRAWFS_DRM=false` (invariant 1 preserved).

Verified on GhostBSD 15 after commit: generator validation clean
across all five target entries, kernel build produces `drawfs.ko`
cleanly with the default swap-only banner. Struct sizes on the
target match the Linux compile-time check (16/24/16/16 bytes). The
pre-existing cosmetic drift on `EVT_POINTER`'s comment was fixed as
a side effect of running the generator.

### `✎` SPRINT-04 — B3.3 pass 1: request validator (EXPANSION SCOPE)

- **Product backlog**: B3.3 (part of B3.3–B3.5 deferred entry)
- **Depends on**: SPRINT-03 (protocol constants in place)
- **Effort**: small
- **Status**: in progress
- **Owner**: Vic
- **Done when**: `drawfs_frame.c` carries a validator for
  `DRAWFS_REQ_SURFACE_PRESENT_REGION` that enforces every row of the
  error table in the design doc. Validator is a pure function
  (takes bytes, returns success or a `drawfs_err_code`), unit-
  reviewable without a loaded kernel module.

Expansion scope. Split from the larger B3.3 item into three passes
so each is reviewable on its own: (1) validator, (2)
dispatch+coalescing, (3) tests.

**Pass 1 landed and verified on GhostBSD 15.** Validator compiles,
links into `drawfs.ko`, module loads cleanly. Validator is not yet
wired to any caller (that's pass 2). Fifteen unit tests against the
design-doc error table pass on the Linux userspace harness.

### `→ ✎` SPRINT-04a — Side-fix: `drawfs/build.sh test` verb

- **Product backlog**: none (small defect surfaced during pass 1 verification)
- **Depends on**: SPRINT-04 (discovered while verifying pass 1)
- **Effort**: trivial
- **Status**: done
- **Owner**: Vic
- **Done when**: `./build.sh test` with no arg runs the full
  `tests/test_*.py` suite; `test stress` runs the stress suite;
  `test tests/foo.py` runs one file. Failure of any individual test
  causes the verb to exit non-zero.

Previous default was a hardcoded filename (`tests/step11_surface_mmap_test.py`)
from a historic naming scheme that the tests directory has since moved
away from. The bare `./build.sh test` verb was effectively broken,
which would have undermined pass 3's verification story. Logged here
honestly rather than hidden inside pass 1.

### `→ ⧖` SPRINT-05 — B3.3 pass 2: dispatch and coalescing (EXPANSION SCOPE)

- **Product backlog**: B3.3
- **Depends on**: SPRINT-04
- **Effort**: medium
- **Status**: queued
- **Owner**: unassigned
- **Done when**: `drawfs.c` dispatches on
  `DRAWFS_REQ_SURFACE_PRESENT_REGION`, emits
  `EVT_SURFACE_PRESENTED_REGION`, and honors a new sysctl
  `hw.drawfs.region_coalesce_threshold` (default 75). Module builds
  clean with `DRAWFS_DRM=false` — invariant 1 preserved.

### `→ ⧖` SPRINT-06 — B3.3 pass 3: Python tests (EXPANSION SCOPE)

- **Product backlog**: B3.3
- **Depends on**: SPRINT-05
- **Effort**: small
- **Status**: queued
- **Owner**: unassigned
- **Done when**:
  `drawfs/tests/test_surface_present_region.py` exercises the full
  error table, the N=1-full-surface equivalence invariant, and the
  coalescing behaviour. `drawfs/build.sh test` with this file
  passes on the target host.

### `⧖` SPRINT-07 — B3.4 and B3.5 (NOT in this sprint)

- **Product backlog**: B3.4, B3.5
- **Depends on**: SPRINT-06
- **Effort**: medium
- **Status**: queued for next sprint

Explicitly out of scope. B3.4 needs a DRM-enabled host with
drm-kmod installed; B3.5 needs B3.4 to test end-to-end. Both live
in the next sprint.

---

## Candidate items (from product backlog)

As of end-of-sprint, these are the items eligible to enter the next
sprint. Pick from here when planning. If an item isn't on this list,
it needs to be added to the product backlog first.

### Open, implementation-ready

- **B3.3** — Swap-path implementation of `SURFACE_PRESENT_REGION`.
  All prerequisites are now in place: wire format is committed, the
  opcodes are defined in both the JSON and the C headers, and
  `drawfs_test.py` carries the Python constants. Medium effort.
  Concrete tasks:
  - Validator in `drawfs_frame.c` enforcing the design-doc error
    table (zero-count, too-many, zero-dimension rect, non-zero
    `_reserved`, non-zero `flags`).
  - Dispatch branch in `drawfs.c` on the new request opcode.
  - Coalescing logic, gated by a new sysctl
    `hw.drawfs.region_coalesce_threshold` (default 75).
  - `drawfs/tests/test_surface_present_region.py` with coverage of
    the error table, N=1-full-surface equivalence invariant, and
    coalescing behaviour.

### Open, deferred on external conditions

- **B3.4** — DRM-path implementation. Only meaningful with
  `DRAWFS_DRM_ENABLED=1` **and** drm-kmod installed. Consider pulling
  it into a sprint only on a host where both are available.
- **B3.5** — semadraw emitter. Requires B3.3 and ideally B3.4 to be
  landed first so there is a complete path to test against.
- **DF-4** — WITNESS debug-kernel verification. Blocked on access to
  a WITNESS-built FreeBSD 15 kernel (none currently available). Pick
  up when one is.

---

## Sprint review

Fill in at the end of the 2-week window.

- [x] SPRINT-01 done → B5.3 flipped to `[x]` in product backlog with
      a one-line summary of what landed. DF-4 added as a new
      deferred entry (migration from the removed ROADMAP § Backlog).
- [x] SPRINT-02 done → B3.1 flipped to `[x]`.
      `drawfs/docs/DESIGN-surface-present-region.md` exists on
      master.
- [x] SPRINT-03 done → B3.2 flipped to `[x]`. Verified on GhostBSD
      with a clean build and clean generator validation.
- [ ] SPRINT-04 explicitly deferred to next sprint. B3.3–B3.5
      remains `[ ] Deferred` in the product backlog.
- [ ] Invariants in `BACKLOG.md` § "Project-level invariants" are
      still satisfied — confirmed by a clean `sh build.sh --check`
      and a default-configure build that produced a zero-DRM
      `drawfs.ko` with the expected banner.
- [ ] Sprint goal: **met.** Wire contract for regional presents is
      committed; B3.3 is a pure implementation task against a stable
      contract.
- [ ] Commits from this sprint are on `master`.

---

## Retrospective notes

### What worked

- The B5.3 → B3.1 → B3.2 ordering was correct. Closing the
  cleanup item first gave a clean desk before starting the bigger
  design task. Doing the design before touching the JSON meant the
  protocol-constants edits were mechanical rather than exploratory.
- Running the generator as part of B3.2 caught a pre-existing
  cosmetic drift that had been silently present in `drawfs_proto.h`.
  Good argument for running `gen_constants.py --validate` in CI.
- Verifying struct sizes with a real C compiler on Linux before
  copying to the target saved a round-trip. The sizes held on
  GhostBSD exactly as predicted.

### What didn't

- Initial B5.3 scope was underestimated — framed as "add a note at
  the top" but was really "consolidate the ROADMAP's task tracking
  into the root backlog, migrate any surviving items." The correct
  framing would have caught the DF-4 migration during planning
  rather than during execution.
- `SPRINT.md` was a template for most of the sprint, not a filled
  sprint. In practice the sprint was tracked in conversation rather
  than in the file. That's workable once or twice, but the pattern
  needs attention.

### One concrete change for next sprint

Fill in `SPRINT.md` at the start of the sprint, not retroactively.
Even partially filled — a sprint goal and two task titles — is
enough scaffolding to keep the file honest. Retroactive filling
tends to smooth out the actual arc in ways that hide what really
happened.
