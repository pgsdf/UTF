# UTF Sprint Backlog

**Sprint**: <!-- e.g. 2026-04-19 → 2026-05-03 -->
**Window**: 2 weeks
**Status**: <!-- planning | active | review | closed -->

---

## Relationship to the product backlog

This is the **sprint backlog** — the subset of work actively in progress
during the current 2-week window, with ordering and dependencies made
explicit. It is derived from the product backlog at `BACKLOG.md`, which
remains the authoritative list of everything that *could* be worked on.

Rules:

- An item may only appear here if it already exists in the product
  backlog. If something new comes up mid-sprint, add it to the product
  backlog first, then (if appropriate) pull it here.
- Items removed or skipped mid-sprint stay in the product backlog with
  their status unchanged. Only completion flows back to the product
  backlog as `[x]`.
- The sprint backlog is rewritten each sprint, not appended to. History
  lives in git, not in this file.

---

## Sprint goal

<!--
One sentence. What single coherent outcome does this sprint produce?
Good examples:
  - "Close out the DRM-optional theme by landing B5.3 and starting B3.1."
  - "Ship the partial-update opcode in the swap path end-to-end."
Bad examples:
  - "Work on some stuff." (not coherent)
  - "Finish everything in the product backlog." (not bounded)
-->

_To be set._

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

<!--
Fill in one numbered block per task. Keep task sizes roughly comparable
— if a task is much larger than its neighbours, split it. If it's much
smaller, consider folding it into an adjacent task.

Task ID format: SPRINT-NN, where NN increases in the order of execution.
The ID is local to the sprint and resets each sprint. Cross-reference
the product backlog item(s) in the `Product backlog:` field.
-->

### `→` SPRINT-01 — <title>

- **Product backlog**: <e.g. B5.3>
- **Depends on**: <e.g. None / SPRINT-00 / external: drm-kmod 580.x installed>
- **Effort**: <trivial | small | medium | large>
- **Status**: <queued | in-progress | done>
- **Owner**: <unassigned>
- **Done when**: <observable completion criteria>

<Brief description. One paragraph at most. The product backlog holds
the detail; here we record what this sprint is specifically doing.>

---

### `→` SPRINT-02 — <title>

- **Product backlog**: <ID>
- **Depends on**: SPRINT-01
- **Effort**:
- **Status**: queued
- **Owner**:
- **Done when**:

<description>

---

<!-- Add more task blocks as needed. -->

---

## Candidate items (from product backlog)

These are the items currently eligible to enter a sprint. Pick from here
when planning. If an item isn't on this list, it needs to be added to
the product backlog first.

### Open

- **B5.3** — Cross-link from `drawfs/docs/ROADMAP.md` to root `BACKLOG.md`.
  Trivial. No dependencies. ~5 minutes.

### Deferred (need design before they can be pulled)

- **Damage / partial-update protocol** (was B3.1–B3.5). Five subtasks,
  sequential, medium-to-large total:
  1. `B3.1` Design the `DRAWFS_REQ_SURFACE_PRESENT_REGION` opcode in
     `shared/protocol_constants.json`.
  2. `B3.2` Regenerate C + Zig headers via `gen_constants.py` (S-1).
  3. `B3.3` Implement in the swap path.
  4. `B3.4` Implement in the DRM path (only meaningful with
     `DRAWFS_DRM_ENABLED`).
  5. `B3.5` Extend semadraw's drawfs backend to emit region presents.

  B3.1 is the design task — it can happen in a sprint on its own.
  B3.2 through B3.5 together are a multi-sprint body of work.

---

## Sprint review checklist

Fill in during review at the end of the 2-week window. Items that did
not complete go back to the product backlog with their status preserved.

- [ ] Every `done` task has had its product backlog entry flipped to
      `[x]` with a one-line summary of what landed.
- [ ] Every incomplete task has been explicitly returned to the product
      backlog, with a note on what remains.
- [ ] Invariants in `BACKLOG.md` § "Project-level invariants" are still
      satisfied — run `sh build.sh --check` and the relevant regression
      tests (`drawfs/tests/test_backend_sysctl.py` at minimum) to
      confirm.
- [ ] Sprint goal: met / partially met / missed — with a one-sentence
      reason.
- [ ] Commits from this sprint are on `master` (or a tagged branch, if
      long-lived work is still in flight).

---

## Retrospective notes

<!--
Brief, honest. Three prompts is enough. Don't write a novel.

  - What worked?
  - What didn't?
  - One concrete change for next sprint.
-->

_To be filled in during review._
