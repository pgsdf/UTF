/*
 * inputfs_parser.c: HID parser surface implementation.
 *
 * Stage AD-9.2a (per inputfs/docs/adr/0014-hid-fuzzing-scope.md):
 * extracts the four pure-parser functions plus the
 * inputfs_report_id_matches helper from inputfs.c so they can
 * be compiled in isolation by AD-9.2b's userspace fuzzing
 * harness.
 *
 * This file builds in two contexts:
 *
 *   - Kernel module: included alongside inputfs.c via the
 *     SRCS list in inputfs/sys/modules/inputfs/Makefile.
 *     Pulls in <sys/param.h>, <sys/systm.h>, and FreeBSD's
 *     <dev/hid/hid.h> from the running kernel source.
 *
 *   - Fuzz harness (AD-9.2b): compiled against the kernel_shim.h
 *     and vendored hid.h under inputfs/test/fuzz/. The shim
 *     suppresses <sys/param.h> and <sys/systm.h> via include-guard
 *     pre-definition and provides minimal replacements for the
 *     symbols this file uses (memset, fixed-width types).
 *
 * Production behaviour is unchanged from before AD-9.2a: the
 * functions here are byte-identical to what they were in
 * inputfs.c, only their location in the source tree has moved.
 * inputfs_keyboard_diff_emit stays in inputfs.c per AD-9.1's
 * analysis (mixed parser + event-emission concerns, out of
 * fuzz scope per ADR 0014).
 */

#include <sys/param.h>
#include <sys/systm.h>
#include <dev/hid/hid.h>

#include "inputfs_parser.h"

/*
 * inputfs_report_id_matches -- Stage D.0a helper.
 *
 * Returns 1 if the report buffer's report ID matches the cached
 * report ID for a location. When cached_id == 0, the device does
 * not use report IDs and any non-empty buffer matches. When
 * cached_id != 0, the first byte of the buffer must equal it.
 *
 * Used by inputfs_extract_pointer to dispatch among multiple
 * report IDs on devices that multiplex (e.g. touchpads with
 * separate pointer and gesture reports).
 */
static inline int
inputfs_report_id_matches(uint8_t cached_id, const uint8_t *buf,
    hid_size_t len)
{
	if (len == 0)
		return (0);
	if (cached_id == 0)
		return (1);
	return (buf[0] == cached_id);
}

/*
 * inputfs_pointer_locate -- Stage D.0a.
 *
 * Populate the softc's HID-location cache for descriptor-driven
 * pointer event extraction. Called once at attach, after
 * inputfs_walk_rdesc and before hidbus_set_intr.
 *
 * For each pointer-relevant usage (X, Y, Wheel, and the button
 * range under HUP_BUTTON), call hid_locate against the descriptor
 * and record the resulting location and report ID. Locations
 * whose size is zero indicate the usage is not present in this
 * descriptor; the interrupt path checks size > 0 before extracting.
 *
 * Buttons are special: HID encodes per-button presence as
 * individual usages 1, 2, 3, ... under HUP_BUTTON, but in
 * practice they are emitted as a single packed bit field. We
 * locate button 1 to get the bit-field's start and use the
 * report count (number of buttons) to determine how wide the
 * field is. Up to 32 buttons are supported (one u32 in the
 * wire format); buttons beyond 32 are silently ignored.
 *
 * The location cache is unconditional regardless of role: a
 * keyboard descriptor will simply have all pointer locations
 * report size == 0, and the interrupt path will skip extraction
 * accordingly. This avoids tying cache population to a specific
 * order of role classification.
 */
static void
inputfs_pointer_locate(struct inputfs_parser_state *p,
    const void *rdesc, hid_size_t rdesc_len)
{
	uint32_t flags;
	uint8_t id;

	memset(&p->loc_x, 0, sizeof(p->loc_x));
	memset(&p->loc_y, 0, sizeof(p->loc_y));
	memset(&p->loc_wheel, 0, sizeof(p->loc_wheel));
	memset(&p->loc_buttons, 0, sizeof(p->loc_buttons));
	p->loc_x_id = 0;
	p->loc_y_id = 0;
	p->loc_wheel_id = 0;
	p->loc_buttons_id = 0;
	p->button_count = 0;
	p->has_wheel = 0;
	p->pointer_locations_valid = 0;

	if (rdesc == NULL || rdesc_len == 0)
		return;

	/* X axis. */
	if (hid_locate(rdesc, rdesc_len,
	    HID_USAGE2(HUP_GENERIC_DESKTOP, HUG_X),
	    hid_input, 0, &p->loc_x, &flags, &id) != 0) {
		p->loc_x_id = id;
	}

	/* Y axis. */
	if (hid_locate(rdesc, rdesc_len,
	    HID_USAGE2(HUP_GENERIC_DESKTOP, HUG_Y),
	    hid_input, 0, &p->loc_y, &flags, &id) != 0) {
		p->loc_y_id = id;
	}

	/* Wheel (optional). */
	if (hid_locate(rdesc, rdesc_len,
	    HID_USAGE2(HUP_GENERIC_DESKTOP, HUG_WHEEL),
	    hid_input, 0, &p->loc_wheel, &flags, &id) != 0) {
		p->loc_wheel_id = id;
		p->has_wheel = 1;
	}

	/*
	 * Buttons: locate button 1 to get the start of the button
	 * bit field. The HID spec packs buttons sequentially within
	 * a single report field; locating button 1 gives us the
	 * bit-field's location. We then walk the report descriptor
	 * to count how many button usages are present so we know the
	 * field width.
	 */
	if (hid_locate(rdesc, rdesc_len,
	    HID_USAGE2(HUP_BUTTON, 1),
	    hid_input, 0, &p->loc_buttons, &flags, &id) != 0) {
		struct hid_data *s;
		struct hid_item hi;
		uint8_t count = 0;

		p->loc_buttons_id = id;

		s = hid_start_parse(rdesc, rdesc_len,
		    1 << hid_input);
		if (s != NULL) {
			while (hid_get_item(s, &hi) > 0) {
				if (hi.kind == hid_input &&
				    HID_GET_USAGE_PAGE(hi.usage) == HUP_BUTTON) {
					if (count < 32)
						count++;
				}
			}
			hid_end_parse(s);
		}
		p->button_count = count;
	}

	if (p->loc_x.size > 0 || p->loc_y.size > 0 ||
	    p->loc_wheel.size > 0 || p->loc_buttons.size > 0) {
		p->pointer_locations_valid = 1;
	}
}

/*
 * inputfs_extract_pointer -- Stage D.0a.
 *
 * Given an interrupt report buffer of length len (including the
 * leading report ID byte if the device uses report IDs), extract
 * pointer values using the cached locations. Returns 1 if the
 * report matched at least one cached location's report ID and
 * any value was extracted; returns 0 if the report should be
 * ignored (wrong report ID, no cached locations, or empty
 * extraction).
 *
 * Output parameters are populated when their respective location
 * is present in the descriptor and matches the incoming report
 * ID. Outputs not extracted are left untouched; callers should
 * initialise to zero before calling.
 *
 * Report ID matching: hid_locate returns the report ID a usage
 * was associated with. If the device uses report IDs, the first
 * byte of the report is the ID and subsequent bytes are the
 * payload; if not, no leading byte is present and IDs are 0.
 * hid_get_data takes the buffer including any leading ID byte
 * and the field's location knows whether to skip it. The match
 * we perform here is between the first byte of the incoming
 * report and the cached id: if cached id is 0, the device does
 * not use IDs and the byte is part of the data; if cached id
 * is non-zero, the byte must match.
 */
static int
inputfs_extract_pointer(struct inputfs_parser_state *p,
    const uint8_t *buf, hid_size_t len,
    int32_t *out_dx, int32_t *out_dy, int32_t *out_dw,
    uint32_t *out_buttons)
{
	int extracted = 0;

	if (!p->pointer_locations_valid || buf == NULL || len == 0)
		return (0);

	if (p->loc_x.size > 0 &&
	    inputfs_report_id_matches(p->loc_x_id, buf, len)) {
		*out_dx = (int32_t)hid_get_data(buf, len, &p->loc_x);
		extracted = 1;
	}

	if (p->loc_y.size > 0 &&
	    inputfs_report_id_matches(p->loc_y_id, buf, len)) {
		*out_dy = (int32_t)hid_get_data(buf, len, &p->loc_y);
		extracted = 1;
	}

	if (p->loc_wheel.size > 0 &&
	    inputfs_report_id_matches(p->loc_wheel_id, buf, len)) {
		*out_dw = (int32_t)hid_get_data(buf, len, &p->loc_wheel);
		extracted = 1;
	}

	if (p->loc_buttons.size > 0 &&
	    inputfs_report_id_matches(p->loc_buttons_id, buf, len)) {
		*out_buttons = (uint32_t)hid_get_udata(buf, len,
		    &p->loc_buttons);
		extracted = 1;
	}

	return (extracted);
}

/*
 * inputfs_keyboard_locate -- Stage D.0b.
 *
 * Populate the softc's keyboard location cache. Called once at
 * attach, after inputfs_pointer_locate and before hidbus_set_intr.
 *
 * The HID boot keyboard layout has two pieces:
 *
 *  - The modifier byte: eight individual 1-bit usages
 *    (0xE0..0xE7) declared as a packed bit field. We locate
 *    usage 0xE0 (Left Ctrl), which sits at bit 0 of the byte,
 *    then synthesise an 8-bit-wide location starting at the
 *    same position. hid_get_udata against that location yields
 *    the full modifier byte in one read.
 *
 *  - The keys-held array: typically declared as a single input
 *    item with usage range and report_count > 1. hid_locate
 *    against any usage in that range returns a location whose
 *    size is the per-element bit width and count is the array
 *    length. We locate via usage 0x00 first (the conventional
 *    array-base usage), falling back to a parser walk if that
 *    does not match.
 *
 * The location cache is unconditional regardless of role; a
 * pointer-only descriptor will simply have all keyboard
 * locations report size == 0.
 */
static void
inputfs_keyboard_locate(struct inputfs_parser_state *p,
    const void *rdesc, hid_size_t rdesc_len)
{
	uint32_t flags;
	uint8_t id;

	memset(&p->loc_modifiers, 0, sizeof(p->loc_modifiers));
	memset(&p->loc_keys, 0, sizeof(p->loc_keys));
	p->loc_modifiers_id = 0;
	p->loc_keys_id = 0;
	p->prev_modifiers = 0;
	memset(p->prev_keys, 0, sizeof(p->prev_keys));
	p->keyboard_locations_valid = 0;

	if (rdesc == NULL || rdesc_len == 0)
		return;

	/*
	 * Modifiers: locate usage 0xE0 (Left Ctrl) to find the bit
	 * position of bit 0 of the modifier byte. The eight modifiers
	 * are packed sequentially in this byte; we read them as one
	 * 8-bit value.
	 */
	if (hid_locate(rdesc, rdesc_len,
	    HID_USAGE2(HUP_KEYBOARD, 0xE0),
	    hid_input, 0, &p->loc_modifiers, &flags, &id) != 0) {
		p->loc_modifiers_id = id;
		/*
		 * Each modifier is declared as a 1-bit field. Extend
		 * the located size to 8 so a single hid_get_udata
		 * yields the full modifier byte. The pos field already
		 * points at bit 0 of the byte (the LeftCtrl bit).
		 */
		p->loc_modifiers.size = 8;
		p->loc_modifiers.count = 1;
	}

	/*
	 * Keys array: locate via usage 0x00 (the conventional base
	 * of the keyboard usage range used by boot keyboards). For
	 * non-boot keyboards or unusual descriptors, hid_locate may
	 * not find this; the array-walk fallback below catches those.
	 */
	if (hid_locate(rdesc, rdesc_len,
	    HID_USAGE2(HUP_KEYBOARD, 0x00),
	    hid_input, 0, &p->loc_keys, &flags, &id) != 0) {
		p->loc_keys_id = id;
	} else {
		/*
		 * Fallback: walk the descriptor and find the first
		 * input item on HUP_KEYBOARD whose report_count > 1
		 * and that is declared as an array (HIO_VARIABLE not
		 * set). That is the keys-held array.
		 */
		struct hid_data *s;
		struct hid_item hi;

		s = hid_start_parse(rdesc, rdesc_len,
		    1 << hid_input);
		if (s != NULL) {
			while (hid_get_item(s, &hi) > 0) {
				if (hi.kind == hid_input &&
				    HID_GET_USAGE_PAGE(hi.usage) == HUP_KEYBOARD &&
				    hi.loc.count > 1 &&
				    (hi.flags & HIO_VARIABLE) == 0) {
					p->loc_keys = hi.loc;
					p->loc_keys_id =
					    (uint8_t)hi.report_ID;
					break;
				}
			}
			hid_end_parse(s);
		}
	}

	if (p->loc_modifiers.size > 0 || p->loc_keys.size > 0)
		p->keyboard_locations_valid = 1;
}

/*
 * inputfs_extract_keyboard -- Stage D.0b.
 *
 * Extract the modifier byte and up to 6 keys-held entries from
 * an interrupt report. Returns 1 if extraction succeeded for at
 * least one location and the report ID matched; 0 otherwise.
 *
 * out_modifiers receives the 8-bit modifier byte. out_keys is a
 * 6-element array; entries beyond the device's actual array
 * count are zero-filled. The caller has initialised out_keys to
 * all zeros.
 *
 * Each element of the keys array is extracted by cloning the
 * cached location and advancing pos by size * index.
 */
static int
inputfs_extract_keyboard(struct inputfs_parser_state *p,
    const uint8_t *buf, hid_size_t len,
    uint8_t *out_modifiers, uint8_t out_keys[6])
{
	int extracted = 0;

	if (!p->keyboard_locations_valid || buf == NULL || len == 0)
		return (0);

	if (p->loc_modifiers.size > 0 &&
	    inputfs_report_id_matches(p->loc_modifiers_id, buf, len)) {
		*out_modifiers = (uint8_t)hid_get_udata(buf, len,
		    &p->loc_modifiers);
		extracted = 1;
	}

	if (p->loc_keys.size > 0 &&
	    inputfs_report_id_matches(p->loc_keys_id, buf, len)) {
		uint32_t i;
		uint32_t array_count = p->loc_keys.count;

		if (array_count > 6)
			array_count = 6;

		for (i = 0; i < array_count; i++) {
			struct hid_location elem = p->loc_keys;

			elem.pos = p->loc_keys.pos +
			    p->loc_keys.size * i;
			elem.count = 1;
			out_keys[i] = (uint8_t)hid_get_udata(buf, len, &elem);
		}
		extracted = 1;
	}

	return (extracted);
}
