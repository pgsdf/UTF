# UTF Sprint Backlog

**Sprint**: 2026-04-19 → 2026-05-03
**Window**: 2 weeks
**Status**: closed (2026-04-19)

Closed early: goal met and expansion scope delivered. See Sprint
Review and Retrospective at the bottom of this file.

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
| `~`    | Fix applied, awaiting verification on target.             |
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

### `✓` SPRINT-04 — B3.3 pass 1: request validator (EXPANSION SCOPE)

- **Product backlog**: B3.3 (part of B3.3–B3.5 deferred entry)
- **Depends on**: SPRINT-03 (protocol constants in place)
- **Effort**: small
- **Status**: done
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
design-doc error table pass on the Linux userspace harness. No
regression in any existing test path that touches `drawfs_frame.c`
(test_protocol, test_sdcs_integration, test_surface, test_session
all green).

### `→ ✓` SPRINT-04a — Side-fix: `drawfs/build.sh test` verb

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
honestly rather than hidden inside pass 1. The new runner was exercised
on the target with an 11-test suite run (9 green, 2 failing — which
directly led to SPRINT-04b below).

### `→ ✓` SPRINT-04b — Side-fix: DF-5 async-event drain races in tests

- **Product backlog**: DF-5 (newly opened during SPRINT-04a verification)
- **Depends on**: SPRINT-04a (the failures were invisible before)
- **Effort**: small (turned out medium after discovering the
  backpressure test's underlying design was spec-incompatible)
- **Status**: done
- **Owner**: Vic
- **Done when**: `sudo ./build.sh test` on the GhostBSD target reports
  all 11 tests green. Specifically the four failures (three in
  `test_input_injection.py`, one in `test_limits.py`) must be gone.

**Verified** on GhostBSD 15: full 11/11 test suite green.
`test_event_queue_backpressure` now hits ENOSPC after 169 presents
(≈ `max_evq_bytes=8192` ÷ 48 bytes per reply) and recovers cleanly.
`test_backpressure_enospc` drains ~200 queued `EVT_KEY` events and
closes cleanly.

Took three iterations on `test_event_queue_backpressure`. Earlier
attempts were wrong about where ENOSPC surfaces — tried to read it
as a reply status, then tried to defeat coalescing via multi-surface
round-robin, both of which fought the specification. Final version
followed the docs (PROTOCOL.md line 167, TEST_PLAN.md line 44) and
the kernel source (drawfs.c:997-999): ENOSPC arrives as an
`OSError` from `write(2)` itself, so the test simply never reads
during the accumulation phase.

Lesson: when two fixes in a row don't land, stop theorizing and read
the specification. Two of Claude's previous fixes for this test were
plausible-sounding but wrong because they never grounded in the
design documents.

Two files changed: `test_input_injection.py` (three small edits),
`test_limits.py` (one function rewritten). Zero changes to
`drawfs_test.py` or kernel code.

### `→ ✓` SPRINT-05 — B3.3 pass 2: dispatch and coalescing (EXPANSION SCOPE)

- **Product backlog**: B3.3
- **Depends on**: SPRINT-04, SPRINT-04b (clean baseline)
- **Effort**: medium
- **Status**: done
- **Owner**: Vic
- **Done when**: `drawfs.c` dispatches on
  `DRAWFS_REQ_SURFACE_PRESENT_REGION`, emits
  `EVT_SURFACE_PRESENTED_REGION`, and honors a new sysctl
  `hw.drawfs.region_coalesce_threshold` (default 75). Module builds
  clean with `DRAWFS_DRM=false` — invariant 1 preserved.

Four design calls, flagged in code comments for the reviewer:

1. **Coalescing algorithm**: sum-of-rect-areas, not a true union.
   Over-counts overlap, biased toward "coalesce earlier." Cheaper and
   correct per spec (threshold is a heuristic, not pixel-accurate
   union).
2. **Sysctl name**: `hw.drawfs.region_coalesce_threshold`, int
   0–100, default 75. Exactly as design doc.
3. **Event type**: always emit `EVT_SURFACE_PRESENTED_REGION` for
   region requests — including the collapse case, where it carries
   one full-surface rect. Matches design doc's "event reflects the
   request, not what the backend physically did."
4. **No cross-request event coalescing**: the existing
   `drawfs_try_coalesce_presented` is for `EVT_SURFACE_PRESENTED`
   only; region events don't share it. Within-request area-sum
   coalescing is in scope, across-request rect-list merging is not.

18 userspace unit tests covering clamping and area-sum arithmetic
passed on Linux before landing. **Verified on GhostBSD 15 target**:
clean compile with `-Werror`, module loads cleanly, sysctl exposed
at `hw.drawfs.region_coalesce_threshold` with default 75 and
read/write access, full 11/11 test suite still green (no regression
in existing paths).

### `→ ✓` SPRINT-06 — B3.3 pass 3: Python tests (EXPANSION SCOPE)

- **Product backlog**: B3.3
- **Depends on**: SPRINT-05
- **Effort**: small
- **Status**: done
- **Owner**: Vic
- **Done when**:
  `drawfs/tests/test_surface_present_region.py` exercises the full
  error table, the N=1-full-surface equivalence invariant, and the
  coalescing behaviour. `drawfs/build.sh test` with this file
  passes on the target host.

**Verified on GhostBSD 15**: 18 tests passed (8 error-table cases,
9 happy-path/clamping/coalescing cases, 1 equivalence invariant),
full 12-file test suite still green. First time in the B3.3 arc
that the kernel handler's behavior matched the test expectations on
first run — strong evidence the clamping, threshold collapse, and
event emission arithmetic in pass 2 is correct.

Protocol helpers are local to this file rather than added to
`drawfs_test.py`. Sysctl-mutating tests save/restore around the
body. FreeBSD errno values are hardcoded as module-level constants
rather than imported from Python's `errno` module (which resolves
to host values).

### `⧖` SPRINT-07 — B3.4 and B3.5 (NOT in this sprint)

- **Product backlog**: B3.4, B3.5
- **Depends on**: SPRINT-06
- **Effort**: medium
- **Status**: queued for next sprint

Explicitly out of scope. B3.4 needs a DRM-enabled host with
drm-kmod installed; B3.5 needs B3.4 to test end-to-end. Both live
in the next sprint.

---

## Candidate items (for the next sprint)

With B3.3 complete, the natural next-sprint starting point is the
B3.4/B3.5 chain. Neither is blocked by anything in this codebase —
they're blocked on external conditions (DRM-enabled host, semadraw
compositor integration).

### Deferred on external conditions

- **B3.4** — DRM-path implementation of `SURFACE_PRESENT_REGION`.
  `drmModeDirtyFB` when the kernel DRM driver supports it,
  full-present fallback otherwise. Only meaningful with
  `DRAWFS_DRM_ENABLED=1` and drm-kmod installed. Pull into a sprint
  only once a DRM-enabled host is available for end-to-end testing.
- **B3.5** — semadraw emitter. Extend
  `semadraw/src/backend/drawfs.zig` to emit region presents when
  the compositor's damage tracker produces a bounded rect set.
  Requires B3.4 landed first.
- **DF-4** — WITNESS debug-kernel verification of the existing
  drawfs test suite. Blocked on access to a WITNESS-built FreeBSD 15
  kernel (none currently available). Pick up when one is.

### Nothing currently in-scope

The product backlog has no items that are both open and
implementation-ready as of sprint close. Everything tractable has
landed; what remains is hardware-blocked or waiting on downstream
work (B3.5 on B3.4).

---

## Sprint review

Closed 2026-04-19 with original goal met and expansion scope fully
delivered.

### Tasks completed

- [x] SPRINT-01 (B5.3) → cross-link landed, `ROADMAP.md` bottom-of-
      file `## Backlog` section removed, surviving WITNESS item
      migrated to DF-4 in product backlog rather than dropped.
- [x] SPRINT-02 (B3.1) → 407-line design spec
      `drawfs/docs/DESIGN-surface-present-region.md` committed; new
      opcode approach chosen over extending `SURFACE_PRESENT.flags`
      after reading the existing `drawfs_proto.h`.
- [x] SPRINT-03 (B3.2) → three JSON entries added, generator ran
      clean, struct definitions hand-added to `drawfs_proto.h`,
      sizes verified via compile (16/24/16/16 bytes). Kernel builds
      clean on target.
- [x] SPRINT-04 (B3.3 pass 1) → pure validator
      `drawfs_req_surface_present_region_validate` landed in
      `drawfs_frame.c` with 15 userspace unit tests. Clean kernel
      build and load, no regression.
- [x] SPRINT-04a (build.sh test-verb side-fix) → replaced hardcoded
      historic test-filename default with a real runner (full suite
      by default, stress mode, single-file mode). Surfaced four
      pre-existing test defects that had been hidden because the
      test runner was broken.
- [x] SPRINT-04b (DF-5 side-fix) → fixed those four test defects.
      Required three iterations on `test_event_queue_backpressure`
      before reading the specification properly and realizing the
      test shouldn't read during accumulation. Documented honestly
      in the DF-5 backlog entry and in the retrospective below.
- [x] SPRINT-05 (B3.3 pass 2) → handler
      `drawfs_reply_surface_present_region` landed in `drawfs.c`
      with clamping, area-sum threshold coalescing, new sysctl
      `hw.drawfs.region_coalesce_threshold` (default 75). Four
      design choices flagged in code. 18 userspace unit tests on
      the clamping and threshold arithmetic pass.
- [x] SPRINT-06 (B3.3 pass 3) → `test_surface_present_region.py`
      landed with 18 tests: 8 error-table rows, 9 happy-path
      scenarios, 1 equivalence invariant. All pass on target on
      first run after pass 2 landed — strong evidence for
      correctness of the clamping and threshold math.

### Items explicitly deferred

- [x] SPRINT-07 (B3.4 + B3.5) → remains queued for next sprint.
      B3.4 needs a DRM-enabled host. B3.5 needs B3.4 to test
      end-to-end.

### Invariants

- [x] `BACKLOG.md` § "Project-level invariants" all still satisfied:
  - `sh configure.sh` defaults → swap-only `drawfs.ko` (verified:
    default banner "DRM/KMS backend: disabled (default, swap-only)").
  - `drm-kmod` remains optional (build works without it present).
  - `hw.drawfs.backend` still defaults to `"swap"` at module load
    (verified by `test_backend_sysctl.py`).
  - DRM init fallback preserved (no code paths touched this sprint).
  - `DRAWFS_DRM_ENABLED` macro name unchanged.
  - `UTF_OS` detection still informational only.

### Test-suite health

End-of-sprint state: **OK: 12 tests passed** (11 existing files + 1
new). Up from the mid-sprint state of 2-of-11 failing that surfaced
when SPRINT-04a fixed the test runner.

### Commits

All commits on `master`. No long-lived branches outstanding from
this sprint.

---

## Retrospective notes

### What worked

- **Ordering by dependency, not by size.** B5.3 → B3.1 → B3.2 → B3.3
  passes 1/2/3 was the right sequence. Each step produced a stable
  input for the next, so there was never a point where we had to
  back up and rework earlier work. Pass 3 validated pass 2 on first
  run — the clearest possible signal that the dependency order was
  sound.
- **Pure functions when possible.** Pass 1's validator was a pure
  function with no kernel-state dependencies, which meant a
  15-test userspace harness could run against exactly the same
  bytes the kernel would see. That caught every error-table case
  before it ever touched a real module load.
- **Verifying arithmetic before committing.** Pass 2's 18-test
  userspace harness for clamping and threshold math meant the
  kernel handler's behavior matched expectations on first run. The
  cost was one extra test file in `/tmp`; the benefit was avoiding
  any on-target debugging cycle for the arithmetic.
- **Running the generator as part of B3.2** caught a pre-existing
  cosmetic drift in `drawfs_proto.h`. Good argument for wiring
  `gen_constants.py --validate` into CI.
- **The new status markers `[~]` / `~`** for "fix applied, awaiting
  verification on target" filled a genuine gap. Previously Claude
  had been flipping things to `[x]` prematurely or leaving them
  `[ ]` in ways that undersold progress. The marker made the
  in-flight state visible without lying in either direction.

### What didn't

- **Scope estimation for B5.3 was wrong.** Framed as "add a note at
  the top" but was really "consolidate ROADMAP task-tracking into
  the root backlog and migrate surviving items." The right framing
  would have surfaced DF-4 during planning, not during execution.
  Pattern to watch: "just a small cleanup" in a documentation-
  consolidation task almost never is.
- **DF-5 debugging took three iterations instead of one.**
  Specifically the `test_event_queue_backpressure` sub-fix. The
  first two attempts were plausible-sounding but grounded in my
  model of the system rather than in the documentation. When the
  test failed a second time in a new shape, the right response was
  to stop theorizing and read the spec — which is what we
  eventually did, and it worked immediately. The failure mode is
  recognizable: when two fixes in a row don't land, read the docs.
- **SPRINT.md was a template for most of the sprint.** The task
  log was being maintained in conversation rather than in the
  file. The retrospective change from the mid-sprint retro
  (fill SPRINT.md at the start of the sprint, not retroactively)
  was adopted partway through — SPRINT-04, SPRINT-04a, SPRINT-04b,
  SPRINT-05, SPRINT-06 were all filled in at the time they
  started, which worked better. The early-sprint entries
  (SPRINT-01 through SPRINT-03) still read as retroactively-
  smoothed because they were.
- **The build.sh test-runner defect was hiding real test defects.**
  `./build.sh test` pointed at a non-existent historic filename,
  so the full suite hadn't run in some time. That let DF-5's four
  underlying bugs sit undetected. Fixing the runner immediately
  was the right call (SPRINT-04a) even though it pulled in
  SPRINT-04b's debugging as a consequence. The lesson: a broken
  diagnostic tool is actively harmful, not just inconvenient.

### Concrete changes for next sprint

1. **Start SPRINT.md with real content at the first task.** Goal,
   one task title, owner. Two minutes of scaffolding, and the
   sprint log doesn't rot.
2. **When two iterations of a fix fail, stop and read
   specifications before writing a third.** The DF-5 arc is the
   canonical example: two failed iterations, then a quick read of
   `PROTOCOL.md`, `TEST_PLAN.md`, and the kernel source, and the
   correct fix dropped out immediately.
3. **Consider pulling DF-4 into the next sprint if a WITNESS
   kernel becomes available.** It's a small-effort item that's
   been waiting on hardware; worth opportunistically closing when
   the blocker lifts.

### Sprint-over-sprint meta-observation

This sprint expanded from three planned items (B5.3, B3.1, B3.2)
to eight delivered items (plus two side-fixes). The expansion
happened organically: B3.3 was pulled in when B3.2 finished with
time to spare, and the two side-fixes were forced by verification
needs. Total sprint tasks completed: 8. Sprint goal: met.
Expansion goal: also met. Both honestly documented.
