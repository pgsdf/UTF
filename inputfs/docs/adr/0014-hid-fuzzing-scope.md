# 0014 HID descriptor and report fuzzing scope

## Status

Proposed, 2026-04-30.

## Context

`BACKLOG.md` AD-9 schedules HID descriptor and report fuzzing
for inputfs as a hardening item. That entry was drafted in
April 2026 with a description that read:

> Userspace harness feeding the kernel parser code through a
> `_KERNEL` shim ... initial corpus of malformed inputs ...
> exits non-zero if the parser asserts, segfaults, or loops.

That description assumed inputfs has its own descriptor parser
to fuzz. A closer reading of `inputfs/sys/dev/inputfs/inputfs.c`
shows this is wrong. inputfs does not walk HID descriptors
byte-by-byte; it calls FreeBSD's `hid_locate`, `hid_get_data`,
`hid_start_parse`, `hid_get_item`, and `hid_end_parse` from
`<dev/hid/hid.h>`. The descriptor walker is FreeBSD kernel
code at `/usr/src/sys/dev/hid/hid.c`, accepted as platform
transport per `docs/UTF_ARCHITECTURAL_DISCIPLINE.md`. inputfs
is the *consumer* of that walker's outputs, not the walker
itself.

This ADR re-scopes AD-9 to match what is actually fuzzable in
inputfs. It corrects the BACKLOG entry's framing, defines the
fuzz oracle precisely, and breaks the work into four
sub-stages with explicit deliverables.

The work is scheduled before AD-2 (semainputd retirement)
per the existing BACKLOG priority ordering: hardening the
parser is cheaper while semainputd still exists as a
fallback that operators can return to without losing input
entirely. Once AD-2 retires semainputd, panics in inputfs's
parser become load-bearing for the whole system. This ADR
captures the scope so it can be picked up in a future session
without re-litigating what AD-9 means.

## Decision

### What is fuzzable in inputfs

The parser-related code under inputfs's control sits in two
phases:

**Locate phase** (runs once per device at attach time):

- `inputfs_pointer_locate` (line 2094 in `inputfs.c` as of
  commit `8271a74`): given a descriptor blob, calls
  `hid_locate` for X, Y, wheel, button-1; calls
  `hid_start_parse` plus `hid_get_item` to count buttons.
  Stores the located bit-positions in the `inputfs_softc`
  fields `sc_loc_x`, `sc_loc_y`, `sc_loc_wheel`,
  `sc_loc_buttons`, plus their `_id` companions, plus
  `sc_button_count` and `sc_has_wheel`.
- `inputfs_keyboard_locate` (line 2268): analogous for
  keyboard usages. Stores `sc_loc_keys`, `sc_loc_modifiers`,
  plus their `_id` companions.

**Extract phase** (runs once per HID report at interrupt time):

- `inputfs_extract_pointer` (line 2202): given a report
  buffer, the cached locations, and the report length, calls
  `hid_get_data` to extract X delta, Y delta, wheel delta,
  and button bitmask. Writes results to a caller-provided
  output struct.
- `inputfs_keyboard_diff_emit` (line 2455): given a report
  buffer and cached locations, extracts the modifiers byte
  and walks the keys array, comparing against the previous
  state and emitting key-down / key-up events.

Bug surfaces inputfs is responsible for:

- **Trust assumptions about `hid_locate` outputs.** `hid_locate`
  may return a location for a malformed descriptor that points
  past the report length implied by the descriptor itself.
  inputfs's downstream code calls `hid_get_data` with that
  location and the report buffer length; if the location
  references bits outside the report length, behaviour
  depends on `hid_get_data`'s bounds checks plus inputfs's
  own assumptions.
- **Report-buffer bounds checks.** When an attacker-controlled
  device sends a report shorter than its descriptor implies,
  inputfs's `inputfs_extract_pointer` and
  `inputfs_keyboard_diff_emit` must not read past the report
  buffer.
- **Modifier and keys-array walking.** `inputfs_keyboard_diff_emit`
  walks bits and bytes within the report buffer to identify
  modifier transitions and pressed keys. Bit-walking on
  attacker-controlled data is a classic out-of-bounds source.
- **State derived from the descriptor.** Fields like
  `sc_button_count` are computed from descriptor walks and
  used as bounds in subsequent extraction. A descriptor that
  reports an absurd button count (saturating to 32 by an
  inputfs check, or not) could mislead later code.

Bug surfaces inputfs is **not** responsible for and which
this fuzzing effort does **not** target:

- The HID descriptor walker itself (`hid_locate`,
  `hid_start_parse`, etc.). That is FreeBSD kernel code; per
  the discipline document, UTF accepts it as platform
  transport. If a malformed descriptor crashes
  `hid_start_parse`, that is a FreeBSD bug to file upstream,
  not an inputfs bug to fix. The harness defined here will
  surface such crashes if they exist, but the response is to
  document and file upstream, not to patch.
- USB-level input (descriptor delivery, interrupt
  scheduling, hidbus attach machinery). Those run before
  inputfs's parser code is reached.

### Fuzz oracle

A bug, for AD-9's purposes, is one of:

1. **Assert failure**, including KASSERT, INVARIANTS-mode
   assertions, or any deliberate crash macro reachable from
   the locate or extract paths.
2. **Segfault or other memory-safety violation** (out-of-
   bounds read or write, use-after-free, double-free, null
   dereference). Detected by AddressSanitizer in the
   userspace harness.
3. **Infinite loop**, defined as: a single locate or extract
   call does not return within a configurable timeout
   (default 1 second, generous for what should be a
   sub-millisecond operation).
4. **Allocation explosion**, defined as: a single call
   allocates more than a configurable threshold (default
   1 MiB) of heap memory. Detected by tracking the
   harness's malloc / free pairs.

Out of scope as bugs (not what this harness tests):

- **Incorrect-but-non-crashing parses.** A descriptor that
  declares a 16-bit X axis but inputfs reports an 8-bit
  X axis is a correctness bug, not a safety bug. It requires
  a correctness oracle (known-input/expected-output pairs),
  which is a different testing strategy. Detecting these is
  not within AD-9's remit.
- **Performance regressions.** A descriptor that takes 100ms
  to parse instead of 1ms is undesirable but not a security
  issue at attach-time rates.

### Sub-stages

Like Stage D, AD-9 breaks into smaller commits, each
independently verifiable. The sub-stage labels are AD-9.1
through AD-9.4 to match the BACKLOG numbering convention
already established for inputfs work.

#### AD-9.1: Parser surface refactor *(landed in commit `b79e8d6`)*

Extract the parser-relevant fields of `struct inputfs_softc`
into a sub-struct (`struct inputfs_parser_state`) that:

- Has no dependencies on FreeBSD kernel headers beyond
  C99 fixed-width integer types and `<dev/hid/hid.h>` for
  the `struct hid_location` type.
- Contains the 25 parser-output fields formerly named
  `sc_loc_*`, `sc_loc_*_id`, `sc_button_count`,
  `sc_has_wheel`, `sc_*_locations_valid`, `sc_prev_keys`,
  `sc_prev_modifiers` (with the `sc_` prefix dropped inside
  the substruct, since they are no longer softc fields).
- Is embedded in `inputfs_softc` as the field `sc_parser`.

The descriptor pointer/length (`sc_rdesc`, `sc_rdesc_len`)
stayed in `inputfs_softc` and became explicit parameters to
`inputfs_pointer_locate` and `inputfs_keyboard_locate`
rather than being read through softc. `sc_report_id` also
stayed in softc; it is set during attach but no parser
function uses it.

The locate and extract functions take `struct
inputfs_parser_state *` rather than `struct inputfs_softc *`.
They lose access to softc-level fields (sysctls, mtx, device
tree handles) which they were not using anyway.
`inputfs_keyboard_diff_emit` kept its softc parameter
because it mixes parser concerns with event-emission
concerns; it accesses parser fields via `sc->sc_parser.X`.

Verified on PGSD-bare-metal: kernel build clean (one
pre-existing unused-function warning unrelated to the
refactor), `kldload` succeeds, C.5 passes 26/26, D.6 passes
14/14 (D.4 routing tests deferred to manual procedure per
the existing D.6 verification protocol), and a manual
pointer smoke test exercised hundreds of `pointer.motion`,
`pointer.button_down`, and `pointer.button_up` events
through the new substruct indirection without anomaly. The
keyboard locate path was exercised at attach for three
keyboard descriptors; the keyboard extract path was not
exercised in smoke testing because PGSD-bare-metal's local
keyboard goes through atkbd rather than HID, but the
structural similarity to the pointer path (same access
pattern, same field rename, same call-site conversion)
makes a keyboard-only refactor bug vanishingly unlikely to
have survived.

This sub-stage produced no fuzzing capability on its own.
It is purely a refactor that makes AD-9.2 possible.

#### AD-9.2: Userspace shim and build *(pending)*

Build infrastructure to compile inputfs's parser code in
userspace alongside FreeBSD's `dev/hid/hid.c`. The shim
strategy was settled after a source survey of FreeBSD's
`hid.c` (1105 lines), `hid.h`, `hidquirk.c`, and `hidquirk.h`.
The earlier description of this sub-stage in this ADR (before
the source survey) is corrected here.

**Corrections from the pre-survey plan:**

- The pre-survey plan said hid.c would be compiled with
  "`_KERNEL` undefined". That was wrong: hid.h gates the
  type declarations and prototypes the harness needs behind
  `#if defined(_KERNEL) || defined(_STANDALONE)`. Defining
  `_KERNEL` in userspace pulls in too much from `<sys/*>`;
  defining `_STANDALONE` (the FreeBSD bootloader build flag)
  activates the gated declarations without the kernel-mode
  semantics in `<sys/*>`. The build uses `-D_STANDALONE`.
- The pre-survey plan listed `panic redirected to abort` as
  a shim responsibility. hid.c does not call panic. The
  shim does not need a panic stub.
- The pre-survey plan said hid.c would be compiled from
  `/usr/src/sys/dev/hid/hid.c`. The harness instead vendors
  hid.c, hid.h, and hidquirk.h verbatim into
  `inputfs/test/fuzz/vendored/dev/hid/`. Reasons: (1)
  reproducibility for AD-9.4 results ("this corpus was
  tested against this exact hid.c"); (2) the harness builds
  on developer machines that may not have `/usr/src` checked
  out; (3) hid.c changes infrequently, and explicit vendor
  updates are preferable to silent upstream drift in a fuzz
  target. Each vendored file carries a top-of-file comment
  noting the FreeBSD source revision it was copied from.
- The pre-survey plan implied a single-commit deliverable.
  AD-9.2 is split into three commits below; the first
  modifies the production kernel module and is verified by
  C.5 + D.6 + smoke test before any harness code lands.

**AD-9.2a: Extract inputfs parser to its own translation unit.**

AD-9.1 grouped the parser-output fields into
`struct inputfs_parser_state`, but the four parser functions
still live inside `inputfs.c` (a 3300-line file with kernel
dependencies the harness cannot satisfy). AD-9.2a moves the
parser functions to a separate translation unit so the
harness can compile them in isolation.

Deliverables:

- `inputfs/sys/dev/inputfs/inputfs_parser.h`: declares
  `struct inputfs_parser_state` and the four parser
  function prototypes (`inputfs_pointer_locate`,
  `inputfs_extract_pointer`, `inputfs_keyboard_locate`,
  `inputfs_extract_keyboard`).
- `inputfs/sys/dev/inputfs/inputfs_parser.c`: contains the
  four function bodies plus the `inputfs_report_id_matches`
  and `inputfs_keyboard_key_in_set` static helpers they
  depend on.
- `inputfs.c` reduced by approximately 250 lines, with
  `#include "inputfs_parser.h"` for the type and prototypes.
- `inputfs_keyboard_diff_emit` stays in `inputfs.c` because
  it mixes parser concerns with event-emission (per
  AD-9.1's analysis); it accesses parser state via
  `sc->sc_parser.X` as it does today.
- The kernel module's Makefile is updated to compile both
  `inputfs.c` and `inputfs_parser.c` into the module.

Verifiable: production behaviour unchanged. Verified by
C.5 (26/26), D.6 (14/14 with D.4 deferred to manual
procedure), and a manual pointer smoke test on
PGSD-bare-metal, the same gate AD-9.1 used.

This sub-stage produces no fuzzing capability on its own.
It is the prerequisite that makes AD-9.2b possible.

**AD-9.2b: Harness build infrastructure.**

Deliverables:

- `inputfs/test/fuzz/kernel_shim.h`: force-included header
  (~150 lines) providing the kernel symbols that
  vendored hid.c references. Pre-defines kernel header
  include guards (`_SYS_PARAM_H_`, `_SYS_BUS_H_`,
  `_SYS_KDB_H_`, `_SYS_KERNEL_H_`, `_SYS_MALLOC_H_`,
  `_SYS_MODULE_H_`, `_SYS_SYSCTL_H_`) so the
  corresponding `#include` lines in hid.c become no-ops,
  then provides the symbols hid.c needs:
    - `device_t` as `void *`.
    - `M_TEMP`, `M_WAITOK`, `M_ZERO` as opaque constants;
      `malloc(size, type, flags)` macro mapping to
      `calloc`-with-zero (treats `M_ZERO` as zero-fill
      and ignores `type`). `free(ptr, type)` ignoring
      `type`.
    - `MODULE_VERSION(name, ver)` as no-op.
    - `SYSCTL_NODE`, `SYSCTL_INT`, `SYSCTL_DECL`,
      `CTLFLAG_RW`, `CTLFLAG_RWTUN`, `OID_AUTO` as
      no-ops.
    - `kdb_active` as `0`, `SCHEDULER_STOPPED()` as `0`.
    - `pause()` as no-op, `hz` as `0`.
    - `device_get_parent` returning `NULL`.
    - `bootverbose` as `0`.
    - `#define _STANDALONE` so hid.h emits its gated
      declarations.
- `inputfs/test/fuzz/shim_includes/opt_hid.h`: empty file.
  Suppresses `HID_DEBUG` definition that the FreeBSD
  kernel build would inject.
- `inputfs/test/fuzz/shim_includes/hid_if.h`: macro stubs
  for the eleven `HID_INTR_*` / `HID_GET_*` / `HID_SET_*`
  / `HID_READ` / `HID_WRITE` / `HID_IOCTL` kobj-method
  dispatch macros. Each expands to
  `((void)(parent), (void)(dev), 0)` so the device-wrapper
  functions at the bottom of hid.c (lines 1036-1102)
  compile. These functions are not called by the harness;
  the stubs exist only to satisfy the compiler.
- `inputfs/test/fuzz/vendored/dev/hid/hid.c`: verbatim copy
  of FreeBSD's `/usr/src/sys/dev/hid/hid.c`.
- `inputfs/test/fuzz/vendored/dev/hid/hid.h`: verbatim
  copy.
- `inputfs/test/fuzz/vendored/dev/hid/hidquirk.h`: verbatim
  copy. Used in its default-include form (HQ macro
  undefined), which emits the `HQ_NONE`-through-
  `HID_QUIRK_MAX` enum that hid.c needs. `hidquirk.c` is
  not vendored or compiled; hid.c's `hid_test_quirk_p`
  function pointer keeps its default initialiser
  (`&hid_test_quirk_w`, returns false), which is harmless
  for the parser path.
- `inputfs/test/fuzz/main.c`: harness driver. Reads a
  binary blob from stdin or a file, splits the blob into
  a descriptor portion and (optionally) a report portion
  by a small length-prefixed format, calls
  `inputfs_pointer_locate` followed by
  `inputfs_extract_pointer`, then
  `inputfs_keyboard_locate` followed by
  `inputfs_extract_keyboard`. Exits 0 on graceful
  handling, non-zero on bug detected.
- `inputfs/test/fuzz/Makefile`: build rules. Compiles
  vendored hid.c with `-D_STANDALONE -include kernel_shim.h
  -I shim_includes -I vendored`. Compiles
  `inputfs_parser.c` with the same flags plus
  `-I ../../sys/dev/inputfs`. Links the harness with
  AddressSanitizer enabled (`-fsanitize=address`). Honours
  CC override for cross-compiler use.
- A trivial known-good descriptor blob in
  `inputfs/test/fuzz/corpus/known-good.bin` for smoke
  testing. The full malformed-input corpus comes in
  AD-9.3.

Verifiable: `make` builds cleanly with one warning at most
(any warnings other than the `inputfs_focus_snapshot`-style
"unused function" pre-existing warning are bugs to fix
before commit). Smoke test: `./inputfs-fuzz < corpus/known-
good.bin` exits 0. Deliberately corrupting one byte of the
known-good blob and re-running should still exit 0 (the
harness's job is to detect *crashes*, not to validate
parses).

**AD-9.2c: Documentation.**

Deliverables:

- `inputfs/test/fuzz/README.md`: how to build the harness,
  how to run it against a corpus entry, how to add new
  corpus entries, what counts as a bug, how to update the
  vendored hid.c when FreeBSD upstream changes.
- This ADR's AD-9.2 section marked landed retrospectively
  with corrections (same pattern as the AD-9.1 doc-update).

**Verification gate for the whole AD-9.2:** AD-9.2a passes
C.5 + D.6 on PGSD-bare-metal. AD-9.2b's harness compiles
cleanly with AddressSanitizer and the smoke test exits 0.
AD-9.2c's README is reviewable for accuracy against what
landed.

#### AD-9.3: Initial corpus *(pending)*

Hand-rolled malformed-input corpus exercising the documented
error paths. Estimated 15-30 entries. Each entry is a binary
file at `inputfs/test/fuzz/corpus/<name>.bin` plus a
companion `<name>.txt` describing what bug the entry attempts
to provoke.

Categories:

- **Truncated descriptors.** Descriptors cut at various
  byte positions (mid-item, mid-collection-open).
- **Recursive collections.** Descriptors that open
  collections without closing, or close collections that
  weren't opened, or nest deeper than reasonable.
- **Out-of-range usages.** Descriptors with usage page IDs
  past the documented range.
- **Lying descriptors.** Descriptors that declare 1024
  buttons (where inputfs saturates at 32), or report
  lengths inconsistent with the field sums.
- **Pathological reports.** Reports shorter than the
  descriptor implies, longer than expected, with all bits
  set in fields that are signed.
- **Cross-paired blobs.** A descriptor from device A paired
  with a report from device B.

Verifiable: every corpus entry has a companion description
file. The harness runs against the entire corpus and reports
per-entry pass/fail. A `fuzz-verify.sh` script in
`inputfs/test/fuzz/` runs the harness against every corpus
entry and summarises results.

This sub-stage produces no expected bug findings. It produces
the inputs against which AD-9.4 runs.

#### AD-9.4: Run, fix, document *(pending)*

Run the AD-9.3 harness against the AD-9.3 corpus. For each
bug surfaced:

- File a tracking entry in `BACKLOG.md` if the bug requires
  more than a one-line fix.
- Write a fix commit referencing the corpus entry that
  surfaced the bug.
- Add a regression test entry to the corpus if the original
  blob was insufficient to deterministically reproduce.

It is possible AD-9.4 finds no bugs. That outcome is fine and
expected for hardening work; the harness's value is in its
existence as a regression substrate, not in producing a fix
list.

Final deliverable: a one-page summary at
`inputfs/test/fuzz/RESULTS.md` describing what was run,
what was found, and what fixes landed.

### Open questions

#### Q1: Coverage-guided extension

The harness as scoped above is corpus-driven only: it runs
each hand-rolled blob once and reports the outcome. AFL-style
coverage-guided fuzzing (where the harness mutates inputs
based on coverage feedback) is out of scope.

The reasons are: AFL instrumentation in Zig builds is
non-trivial; AFL's value is highest when the codebase has a
large unexplored input space; inputfs's parser surface is
narrow and the hand-rolled corpus is intended to cover it
exhaustively. A criterion that would reopen this question:
AD-9.4 finds zero bugs *and* a real-world exploit later
appears that the corpus did not cover. Until then, hand-
rolled is sufficient.

#### Q2: State-leak detection across calls

The harness as scoped runs each blob through a fresh parser
state. Real kernel runtime calls the locate path once per
device attach, then calls the extract path many times per
second on the same parser state. State accumulating across
extract calls (e.g. modifier-state going wrong over time) is
a different bug class than crash-on-single-call.

A future extension: a corpus entry could be a sequence of
reports rather than a single report, and the harness could
keep parser state across them. Out of scope for AD-9.1
through AD-9.4; tracked as a possible AD-9.5 if AD-9.4
finds across-call-state evidence. Default deferral: do not
implement until evidence motivates it.

#### Q3: hid.c upstream fuzzing

If the harness exposes a bug in FreeBSD's `hid.c` rather
than inputfs's consumer code, the response is documented in
the AD-9.4 results (file upstream, document the input that
triggered it, possibly add an inputfs-side workaround if the
upstream fix is delayed). It is not inputfs's job to patch
FreeBSD, but inputfs is responsible for not crashing under
the malformed inputs that exercise FreeBSD's parser.

If `hid.c` proves to have many crash bugs reachable from the
inputfs surface, the BACKLOG should grow a separate
discipline-level decision: do we accept FreeBSD's hid.c as
platform transport (current posture), do we replace it with
a UTF-owned descriptor walker (large undertaking), or do we
add inputfs-side input-validation that rejects descriptors
known to crash hid.c? This question is named here so that
AD-9.4's findings can revisit it concretely rather than
abstractly.

## Consequences

**Positive:**

- AD-9 has a precise scope. Future-us picking up the work
  knows what target the harness aims at and what counts as
  a bug.
- The misframing in the BACKLOG entry is corrected at the
  ADR layer; the BACKLOG entry can be revised to point at
  this ADR without re-explaining the scope.
- The four-sub-stage breakdown matches the patterns that
  worked for Stage D: each sub-stage is independently
  verifiable, the production code is untouched until AD-9.4,
  the refactor at AD-9.1 is tested by C.5 and D.6 before
  any harness exists.
- AD-9.1's refactor is independently valuable as a parser-
  state cleanup, even if AD-9.2 onward never lands.

**Negative:**

- The work is larger than the BACKLOG entry implied. The
  estimate "Small-Medium" should become "Medium" given the
  shim layer, the corpus construction, and the Makefile or
  build.zig integration.
- The AD-9.1 refactor touches `inputfs.c`, the production
  kernel module. Any refactor of production code carries
  some risk; mitigation is C.5 and D.6 verification before
  the commit lands.
- The harness compiles FreeBSD kernel source
  (`/usr/src/sys/dev/hid/hid.c`) in userspace. This is
  technically permissible (the file is BSD-licensed and
  available on every FreeBSD developer's system) but the
  build needs to depend on `/usr/src/sys` being present,
  which is reasonable for an inputfs developer but adds a
  dependency that didn't exist before.

**Neutral:**

- The fuzzing approach is hand-rolled corpus, not coverage-
  guided. This is a deliberate choice with a stated
  reopening criterion (Q1).
- AD-9.4 may find zero bugs. That is an acceptable outcome;
  the harness's value is in its existence as a regression
  substrate.

## Notes

The BACKLOG AD-9 entry will be updated in a separate commit
to point at this ADR and to correct the framing
("inputfs's parser" was misleading; the real fuzz target is
inputfs's parser-output consumer code). The entry's status,
size estimate, and priority position remain the same; only
the description changes.

Subsequent commits implement AD-9.1 through AD-9.4 in order.
Each is its own commit with its own verification step. The
sub-stages are not work-in-progress merge candidates; each
lands as a finished piece.

The work is scheduled before AD-2 (semainputd retirement).
This ordering is deliberate: AD-2 makes inputfs the sole
input path on UTF systems, and panics in the parser become
load-bearing once semainputd is retired. AD-9.1's refactor
and AD-9.4's fixes are cheaper to land while semainputd
still exists as a fallback that operators can return to
without losing input entirely. The two pieces of work do not
conflict in inputfs.c: AD-2 retires semainputd, which is a
different daemon entirely; AD-9.1 refactors fields within
`struct inputfs_softc`; the two changes touch disjoint code.
Reversing the order (AD-9 after AD-2) is defensible if
AD-9.1 turns out larger than estimated; the ADR's
deliverables do not depend on AD-2's state.
