/*
 * inputfs_parser.h: HID parser surface declarations.
 *
 * Stage AD-9.2a (per inputfs/docs/adr/0014-hid-fuzzing-scope.md):
 * extracts the parser-relevant declarations from inputfs.c so the
 * parser code can be compiled in isolation by AD-9.2b's userspace
 * fuzzing harness.
 *
 * In kernel mode this header is included by both inputfs.c and
 * inputfs_parser.c. In userspace (the fuzz harness) it is
 * included by main.c and inputfs_parser.c, with FreeBSD's
 * <dev/hid/hid.h> coming from the vendored copy under
 * inputfs/test/fuzz/vendored/dev/hid/.
 *
 * The parser surface deliberately depends only on
 * <dev/hid/hid.h>'s `hid_size_t` and `struct hid_location` plus
 * C99 fixed-width integer types. No softc dependencies; no
 * sysctls, mutexes, or device-tree handles. inputfs_keyboard_diff_emit
 * is NOT declared here because it mixes parser concerns with
 * event-emission concerns and stays in inputfs.c (out of fuzz
 * scope per ADR 0014).
 */

#ifndef _INPUTFS_PARSER_H_
#define _INPUTFS_PARSER_H_

#include <dev/hid/hid.h>

/*
 * Parser state: cached HID locations and previous-state buffer.
 * Embedded in struct inputfs_softc as the field sc_parser; the
 * four pure-parser functions below take a pointer to this struct
 * directly, so the harness can construct one on the stack and
 * invoke the parser with no softc machinery.
 *
 * Field-name convention drops the sc_ prefix that softc fields
 * use, since these are no longer softc fields directly. Access
 * from kernel code is sc->sc_parser.loc_x rather than
 * sc->sc_loc_x.
 *
 * Pointer location cache (Stage D.0a): each location's size
 * field is zero when the corresponding usage is not present in
 * the descriptor. Consumers check size > 0 before extracting.
 * loc_buttons covers the button usage range as a single
 * location with one bit per button; we cap at 32 buttons in
 * the wire format.
 *
 * Keyboard location cache and previous-state buffer
 * (Stage D.0b): the interrupt path extracts the modifier byte
 * and keys-held array, diffs against prev_modifiers / prev_keys,
 * and updates the previous-state buffer. n-key rollover beyond
 * 6 is reported by HID as 0x01 in all six slots and filtered
 * out. loc_modifiers covers the 8-bit modifier bitfield as a
 * single location whose size is 8. loc_keys covers the keys-held
 * array as a single location whose size is the per-element bit
 * width and count is the array length.
 */
struct inputfs_parser_state {
	uint8_t			 pointer_locations_valid;
	struct hid_location	 loc_x;
	struct hid_location	 loc_y;
	struct hid_location	 loc_wheel;
	struct hid_location	 loc_buttons;
	uint8_t			 loc_x_id;
	uint8_t			 loc_y_id;
	uint8_t			 loc_wheel_id;
	uint8_t			 loc_buttons_id;
	uint8_t			 button_count;
	uint8_t			 has_wheel;

	uint8_t			 keyboard_locations_valid;
	struct hid_location	 loc_modifiers;
	struct hid_location	 loc_keys;
	uint8_t			 loc_modifiers_id;
	uint8_t			 loc_keys_id;
	uint8_t			 prev_modifiers;
	uint8_t			 prev_keys[6];
};

/*
 * Populate the pointer location cache by walking the HID
 * descriptor for X, Y, wheel, and button-1 usages, plus a
 * descriptor walk to count buttons. Called once at attach.
 *
 * On entry, p must point to a parser_state (the contents are
 * fully overwritten). rdesc / rdesc_len describe the device's
 * HID report descriptor blob; either may be NULL/0 in which
 * case the function returns with pointer_locations_valid = 0.
 *
 * No return value: success/failure is reflected in
 * p->pointer_locations_valid (1 if any pointer usage was
 * located, 0 otherwise).
 */
void	inputfs_pointer_locate(struct inputfs_parser_state *p,
	    const void *rdesc, hid_size_t rdesc_len);

/*
 * Extract pointer-event fields (X delta, Y delta, wheel delta,
 * button bitmask) from a single HID input report. Uses the
 * cache populated by inputfs_pointer_locate.
 *
 * On entry, p must contain valid pointer locations
 * (pointer_locations_valid == 1). buf / len describe the report
 * bytes as received from the device. out_dx, out_dy, out_dw,
 * out_buttons must be non-NULL; the caller has zero-initialised
 * them.
 *
 * Returns 1 if at least one location was extracted (the report
 * ID matched and the location was non-empty), 0 otherwise.
 * Outputs are only modified for locations that were extracted;
 * outputs for absent locations remain at their caller-supplied
 * zero defaults.
 */
int	inputfs_extract_pointer(struct inputfs_parser_state *p,
	    const uint8_t *buf, hid_size_t len,
	    int32_t *out_dx, int32_t *out_dy, int32_t *out_dw,
	    uint32_t *out_buttons);

/*
 * Populate the keyboard location cache by walking the HID
 * descriptor for the modifier byte (usage 0xE0..0xE7 packed)
 * and the keys-held array (HUP_KEYBOARD usage 0x00 with array
 * declaration). Called once at attach.
 *
 * On entry, p must point to a parser_state (the keyboard
 * portion is fully overwritten; the pointer portion is left
 * unchanged so a single parser_state may host both caches).
 * rdesc / rdesc_len describe the device's HID report
 * descriptor; either may be NULL/0 in which case the function
 * returns with keyboard_locations_valid = 0.
 *
 * The previous-state buffer (prev_modifiers, prev_keys) is
 * cleared as part of locate so the first emitted diff is
 * against an empty baseline.
 */
void	inputfs_keyboard_locate(struct inputfs_parser_state *p,
	    const void *rdesc, hid_size_t rdesc_len);

/*
 * Extract keyboard-event fields (modifier byte, keys-held
 * array) from a single HID input report. Uses the cache
 * populated by inputfs_keyboard_locate.
 *
 * On entry, p must contain valid keyboard locations
 * (keyboard_locations_valid == 1). buf / len describe the
 * report bytes. out_modifiers and out_keys must be non-NULL;
 * the caller has zero-initialised them.
 *
 * Returns 1 if at least one location was extracted, 0
 * otherwise. The diff against p->prev_modifiers / p->prev_keys
 * is the responsibility of the caller (in kernel,
 * inputfs_keyboard_diff_emit; in the fuzz harness, no diff is
 * needed because we only test that extract returns without
 * crashing on malformed input).
 */
int	inputfs_extract_keyboard(struct inputfs_parser_state *p,
	    const uint8_t *buf, hid_size_t len,
	    uint8_t *out_modifiers, uint8_t out_keys[6]);

#endif /* _INPUTFS_PARSER_H_ */
