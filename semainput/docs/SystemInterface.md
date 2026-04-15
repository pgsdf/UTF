# System Interface

## Output model

v28 emits newline-delimited JSON objects.

## Example semantic events

```json
{"type":"mouse_move","device":"pointer:rel-2-b2-w0-a0-t0-0","source":"/dev/input/event12","dx":1,"dy":0}
{"type":"touch_down","device":"touch:rel-0-b0-w0-a2-t3-0","source":"/dev/input/event17","contact":165,"x":514,"y":681}
{"type":"mouse_button","device":"button-source:rel-0-b1-w0-a0-t0-0","source":"/dev/input/event14","button":"right","state":"up"}
```

## Example gesture events

```json
{"type":"two_finger_scroll","device":"touch:rel-0-b0-w0-a2-t3-0","dx":1,"dy":-6}
{"type":"drag_start","device":"touch:rel-0-b0-w0-a2-t3-0","contact":166,"x":813,"y":281}
{"type":"drag_move","device":"touch:rel-0-b0-w0-a2-t3-0","contact":166,"x":852,"y":443}
{"type":"drag_end","device":"touch:rel-0-b0-w0-a2-t3-0","contact":166,"x":901,"y":561}
{"type":"tap","device":"touch:rel-0-b0-w0-a2-t3-0","contact":170,"x":733,"y":412}
```
