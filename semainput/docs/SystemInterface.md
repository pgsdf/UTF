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

## Keyboard event verification (I-2)

### Event schema

Keyboard events follow the unified schema with `code` carrying the evdev key
code (e.g. KEY_A = 30, KEY_ENTER = 28).

```json
{"type":"key_down","subsystem":"semainput","session":"...","seq":N,"ts_wall_ns":N,"ts_audio_samples":null,"device":"keyboard:key-0-b0-w0-a0-t0-0","source":"/dev/input/event0","code":30}
{"type":"key_up","subsystem":"semainput","session":"...","seq":N,"ts_wall_ns":N,"ts_audio_samples":null,"device":"keyboard:key-0-b0-w0-a0-t0-0","source":"/dev/input/event0","code":30}
```

### Key repeat suppression

evdev sends `value=1` (press), `value=0` (release), and `value=2` (autorepeat).
semainput emits `key_down` only on `value=1` and `key_up` only on `value=0`.
Autorepeat events (`value=2`) are silently suppressed.

### Manual test procedure

1. Run with jq filtering for key events:

```sh
sudo ./zig-out/bin/semainputd | jq 'select(.type == "key_down" or .type == "key_up")'
```

2. Press and release a key (e.g. 'A'). Verify:
   - Exactly one `key_down` line appears on press.
   - Exactly one `key_up` line appears on release.
   - No additional `key_down` lines appear while the key is held.

3. Verify keyboard devices appear in `identity_snapshot` with `has_keyboard: true`:

```sh
sudo ./zig-out/bin/semainputd | jq 'select(.type == "identity_snapshot") | .mappings[] | select(.has_keyboard == true)'
```

### Verifying key codes

evdev key codes follow the Linux input event codes standard.
Common codes: KEY_A=30, KEY_ENTER=28, KEY_ESC=1, KEY_SPACE=57, KEY_LEFT=105,
KEY_RIGHT=106, KEY_UP=103, KEY_DOWN=108.
