# Architecture

v28 introduces structured output.

## Pipeline

```text
reader threads
→ raw semantic queue
→ activity tracker
→ startup staging buffer
→ classification + aggregation + identity
→ pointer smoothing
→ structured semantic output
→ gesture recognizer
→ structured gesture output
```

## Structured output

The daemon now emits JSON lines for:
- daemon lifecycle
- classification snapshots
- identity snapshots
- semantic events
- gesture events
