# SemaAud Roadmap

SemaAud is the audio daemon: OSS output on FreeBSD, two named targets
(`default` and `alt`), a policy engine with allow/deny/override/group
semantics, preemption, fallback routing, and a filesystem-backed state
layout.

## Phase history

- **Phase 11 — checkpoint**: OSS backend, two-target topology, control
  socket, policy engine with preemption and fallback, filesystem state
  surfaces, JSON event log on `/tmp/draw/audio/<target>/stream/events`.
  Preserved base in `README-PRESERVED-BASE.txt`.
- **Phase 12 — durable policy validation** *(current)*: versioned policy
  grammar, `#`-comments in policy files, and two new filesystem surfaces
  (`policy-valid`, `policy-errors`) that are rewritten on every reload so
  external watchers can detect bad policy files without re-parsing.
  Full spec: [`SemaAud-Phase12-DurablePolicy-Spec.md`](./SemaAud-Phase12-DurablePolicy-Spec.md).

## Active backlog (next)

Tracked in `semaaud-BACKLOG.md`:

- **A-2** Audio sample position counter (`shared.samples_written`) — basis
  for the chronofs monotonic clock.
- **A-3** Unified event log schema adoption on stdout, alongside the
  existing filesystem event files.
- **A-4** Sample-rate negotiation via `SNDCTL_DSP_SPEED`, replacing the
  hard-coded 48 kHz stereo s16le assumption.
