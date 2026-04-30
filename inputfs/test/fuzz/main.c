/*
 * inputfs-fuzz: HID parser fuzz harness.
 *
 * This is the AD-9.2b harness driver per
 * inputfs/docs/adr/0014-hid-fuzzing-scope.md.
 *
 * Reads a binary fuzz blob from stdin or a file argument,
 * splits it into a HID report descriptor and (optionally) a
 * single HID report, and exercises inputfs's parser surface:
 *
 *   1. inputfs_pointer_locate  (descriptor walk: pointer)
 *   2. inputfs_extract_pointer (report parse:    pointer)
 *   3. inputfs_keyboard_locate (descriptor walk: keyboard)
 *   4. inputfs_extract_keyboard(report parse:    keyboard)
 *
 * Wire format of the input blob:
 *
 *   offset 0..1    big-endian uint16: rdesc_len
 *   offset 2..    rdesc_len bytes: HID descriptor
 *   offset 2+rdesc_len..3+rdesc_len   big-endian uint16: report_len
 *   offset 4+rdesc_len..              report_len bytes: HID report
 *
 * If report_len is 0, only the locate phase runs. If the
 * input blob ends before the report-length prefix, only the
 * locate phase runs (a deliberately short input is a valid
 * fuzz pattern: "what does locate do with this descriptor
 * alone?").
 *
 * The harness exits 0 if the parsers ran without crashing.
 * AddressSanitizer (linked in via -fsanitize=address) prints
 * its own report and exits with non-zero on a detected fault
 * (out-of-bounds read, use-after-free, etc.). The fuzz oracle
 * is therefore "non-zero exit = bug; zero exit = no bug found".
 *
 * The harness deliberately does NOT validate descriptors or
 * reports for semantic correctness. We are testing crash
 * resistance, not parse correctness. Garbage in -> garbage
 * out is acceptable; garbage in -> crash is the bug we hunt.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * Parser surface declarations. The fuzz harness includes
 * inputfs_parser.h directly; the shim provides hid_size_t and
 * struct hid_location through the vendored hid.h.
 */
#include "inputfs_parser.h"

#define MAX_BLOB_BYTES (64 * 1024)

static int
read_all(FILE *fp, uint8_t *buf, size_t cap, size_t *out_len)
{
	size_t total = 0;
	while (total < cap) {
		size_t got = fread(buf + total, 1, cap - total, fp);
		if (got == 0) {
			if (feof(fp))
				break;
			return (-1);
		}
		total += got;
	}
	*out_len = total;
	return (0);
}

static uint16_t
read_be16(const uint8_t *p)
{
	return ((uint16_t)p[0] << 8) | (uint16_t)p[1];
}

int
main(int argc, char **argv)
{
	uint8_t blob[MAX_BLOB_BYTES];
	size_t blob_len = 0;
	FILE *fp = stdin;

	if (argc > 1) {
		fp = fopen(argv[1], "rb");
		if (fp == NULL) {
			perror(argv[1]);
			return (2);
		}
	}

	if (read_all(fp, blob, sizeof(blob), &blob_len) != 0) {
		perror("read");
		if (fp != stdin)
			fclose(fp);
		return (2);
	}
	if (fp != stdin)
		fclose(fp);

	/*
	 * Phase 1: parse the wire format. If the prefix is
	 * malformed (truncated, length out of bounds), we skip
	 * the corresponding phase silently. The harness should
	 * never crash on a malformed blob; that is, after all,
	 * the bug class we are testing for. Crashes from THIS
	 * code (the wire-format parser) would be harness bugs,
	 * not parser bugs.
	 */
	const uint8_t *rdesc = NULL;
	uint16_t rdesc_len = 0;
	const uint8_t *report = NULL;
	uint16_t report_len = 0;

	if (blob_len >= 2) {
		rdesc_len = read_be16(blob);
		if ((size_t)rdesc_len <= blob_len - 2) {
			rdesc = blob + 2;
			size_t after = 2 + (size_t)rdesc_len;
			if (after + 2 <= blob_len) {
				report_len = read_be16(blob + after);
				if ((size_t)report_len <= blob_len - after - 2) {
					report = blob + after + 2;
				} else {
					report_len = 0;
				}
			}
		} else {
			rdesc_len = 0;
		}
	}

	/*
	 * Phase 2: pointer locate + extract.
	 */
	struct inputfs_parser_state pstate;
	memset(&pstate, 0, sizeof(pstate));

	inputfs_pointer_locate(&pstate, rdesc, rdesc_len);

	if (report != NULL && pstate.pointer_locations_valid) {
		int32_t dx = 0, dy = 0, dw = 0;
		uint32_t buttons = 0;
		(void)inputfs_extract_pointer(&pstate, report, report_len,
		    &dx, &dy, &dw, &buttons);
	}

	/*
	 * Phase 3: keyboard locate + extract.
	 *
	 * Re-zero the parser state. Locate functions zero their
	 * own portion of the struct, but we want to test each
	 * phase in isolation rather than relying on the previous
	 * call's state.
	 */
	memset(&pstate, 0, sizeof(pstate));

	inputfs_keyboard_locate(&pstate, rdesc, rdesc_len);

	if (report != NULL && pstate.keyboard_locations_valid) {
		uint8_t modifiers = 0;
		uint8_t keys[6] = { 0 };
		(void)inputfs_extract_keyboard(&pstate, report, report_len,
		    &modifiers, keys);
	}

	return (0);
}
