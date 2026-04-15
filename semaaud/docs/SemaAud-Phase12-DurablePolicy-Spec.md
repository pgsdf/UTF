# SemaAud Phase 12 — Durable Policy Validation

Phase 12 hardens the durable policy layer: it locks in a versioned grammar,
allows comments in policy files, and exposes two additional filesystem
surfaces — `policy-valid` and `policy-errors` — so that tools watching
`/tmp/draw/audio/<target>/` can tell whether the current policy file is
well-formed without having to re-implement the parser.

## Surface layout

For each target (`default`, `alt`), the base directory
`/tmp/draw/audio/<target>/` contains:

| File            | Contents                                                    |
| --------------- | ----------------------------------------------------------- |
| `policy`        | The source of truth — a line-oriented policy configuration. |
| `policy-state`  | A derived JSON view of the last evaluation.                 |
| `policy-valid`  | `"true\n"` if the policy parses cleanly, `"false\n"` else.  |
| `policy-errors` | One error message per line. Empty when `policy-valid=true`. |

`policy-valid` and `policy-errors` are rewritten every time the policy is
(re)loaded — at daemon startup and on each inbound stream connection, before
routing/preemption decisions.

## Grammar (version 1)

The policy file is UTF-8 text, line-oriented, LF-terminated.

```
policy      := line (LF line)*
line        := WS* (comment | directive)? WS*
comment     := '#' <any characters except LF>
directive   := key '=' value
key         := 'version'
             | 'default'
             | 'deny_label'
             | 'deny_class'
             | 'allow_class'
             | 'override_class'
             | 'fallback_target'
             | 'group'
value       := <any characters except LF>
WS          := ' ' | '\t' | '\r'
```

Leading/trailing ASCII whitespace (` `, `\t`, `\r`) on a line is stripped
before parsing. A blank line is ignored. A line whose first non-whitespace
character is `#` is a comment and is ignored in full. Inline trailing
comments (e.g. `version=1 # note`) are **not** stripped — the `#` will be
treated as part of the value.

### Recognized directives

| Directive          | Value                                    | Semantics                                                                    |
| ------------------ | ---------------------------------------- | ---------------------------------------------------------------------------- |
| `version=N`        | integer                                  | Grammar version. Only `1` is supported.                                      |
| `default=allow`    | —                                        | Clients not matched by any rule are admitted (startup default).              |
| `default=deny`     | —                                        | Clients not matched by any rule are rejected.                                |
| `deny_label=L`     | arbitrary token                          | Any client whose label equals `L` is denied. May appear multiple times.      |
| `deny_class=C`     | arbitrary token                          | Any client whose class equals `C` is denied. May appear multiple times.     |
| `allow_class=C`    | arbitrary token                          | Any client whose class equals `C` is allowed. May appear multiple times.    |
| `override_class=C` | arbitrary token                          | Clients with class `C` may preempt a busy target or its group.               |
| `fallback_target=T`| `default` \| `alt`                       | On `deny`, the stream is offered to target `T` before being rejected.        |
| `group=G`          | arbitrary token                          | Targets sharing a group name are mutually exclusive (only one active stream).|

Rule precedence at evaluation time:

1. `deny_label` (exact match on the client's label) — always denies.
2. `deny_class` (exact match on the client's class) — always denies.
3. `allow_class` (exact match on the client's class) — always allows.
4. `default=allow` / `default=deny` as the fallthrough.

### Validation errors

The parser never throws on a malformed policy file — instead it collects
errors into `policy-errors`. The following diagnostics are emitted, one per
line, in the order they were encountered:

| Error text                          | Trigger                                                 |
| ----------------------------------- | ------------------------------------------------------- |
| `invalid version field`             | `version=` value is not a valid unsigned integer.       |
| `unsupported policy version`        | `version=N` with `N != 1`.                              |
| `unknown directive: <line>`         | A non-blank, non-comment line matches no known key.     |

`policy-valid` is `"true\n"` iff `policy-errors` has zero lines. Otherwise
`policy-valid` is `"false\n"` and `policy-errors` lists each diagnostic.

## Reload semantics

The policy file is re-read (and `policy-valid` / `policy-errors`
re-written) in two places:

1. During `initTarget` at daemon startup, for each target.
2. On every accepted stream connection, before the routing decision is
   made. This means an operator can edit the policy file live and the next
   incoming stream will see the updated validation surfaces.

Re-reading the policy does not restart the daemon, does not interrupt an
active stream, and never deletes other surface files.

## Acceptance criteria

A conforming Phase 12 implementation satisfies:

- A policy file containing an unknown directive results in
  `policy-valid=false\n` and a matching `unknown directive: …` line in
  `policy-errors`.
- A policy file containing `version=2` results in `policy-valid=false\n`
  and `unsupported policy version\n` in `policy-errors`.
- A policy file that parses cleanly (including one with only comments, or
  an empty file) results in `policy-valid=true\n` and an empty
  `policy-errors` file.
- Both surface files are rewritten atomically on every policy reload.

The unit tests in `src/policy_test.zig` enforce these cases — run them with
`zig build test`.
