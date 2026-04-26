/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage B.5: per-device role classification.
 * Builds on B.4 (interrupt handler registration and raw report
 * logging) by formalizing the matched HID Top-Level Collection into
 * a stable role bitmask stored on the softc. The classifier reads
 * hidbus_get_usage() once at attach, applies the rule from ADR 0010
 * Decision section 2 (HUP_GENERIC_DESKTOP page guard, switch on
 * usage ID), and writes the result into sc_roles. A grep-friendly
 * "roles=<list>" line is logged at the end of attach.
 *
 * Reference drivers consulted (from ghostbsd-src):
 *   sys/dev/hid/hms.c    (HID mouse, modern)
 *   sys/dev/hid/hkbd.c   (HID keyboard, modern)
 *   sys/dev/hid/hidbus.c (HID bus driver, descriptor caching)
 *
 * System Model: inputfs is mutually exclusive with hms, hkbd, hgame,
 * hcons, hsctrl, utouch, hpen, and the hidmap framework per ADR 0007.
 * UTF Mode assumes the competing drivers are absent at boot.
 *
 * This file is part of the UTF project. See:
 *   docs/UTF_ARCHITECTURAL_DISCIPLINE.md
 *   inputfs/docs/inputfs-proposal.md
 *   inputfs/docs/foundations.md
 *   inputfs/docs/adr/0001-module-charter.md
 *   inputfs/docs/adr/0007-hidbus-attachment.md
 *   inputfs/docs/adr/0008-hid-descriptor-fetch.md
 *   inputfs/docs/adr/0009-interrupt-handler-registration.md
 *   inputfs/docs/adr/0010-role-classification.md
 *
 * Target: FreeBSD 15.0-RELEASE-p2 / GhostBSD 15.
 */

#include <sys/param.h>
#include <sys/systm.h>
#include <sys/kernel.h>
#include <sys/module.h>
#include <sys/bus.h>
#include <sys/malloc.h>
#include <sys/mutex.h>

#include <dev/hid/hid.h>
#include <dev/hid/hidbus.h>

MALLOC_DEFINE(M_INPUTFS, "inputfs", "inputfs report buffers");

/*
 * Role bitmask (Stage B.5, per ADR 0010 Decision section 1).
 * Five bits, one per role in ADR 0004's closed taxonomy. All five
 * are defined now so the encoding is stable from the outset; B.5's
 * classifier only sets POINTER and KEYBOARD, the remaining three
 * are reserved for later stages (touch/pen when the TLC match
 * table grows; lighting via the future companion spec).
 */
#define INPUTFS_ROLE_POINTER    (1u << 0)
#define INPUTFS_ROLE_KEYBOARD   (1u << 1)
#define INPUTFS_ROLE_TOUCH      (1u << 2)
#define INPUTFS_ROLE_PEN        (1u << 3)
#define INPUTFS_ROLE_LIGHTING   (1u << 4)

/*
 * Per-device softc. Stage B.4 added interrupt buffer fields;
 * Stage B.5 adds the per-device role bitmask (sc_roles).
 */
struct inputfs_softc {
	device_t	sc_dev;
	struct mtx	sc_mtx;

	/*
	 * Cached HID report descriptor, obtained from hidbus during
	 * attach. Pointer is borrowed from hidbus and must not be
	 * freed; it is valid for the lifetime of this attachment.
	 */
	const void	*sc_rdesc;
	hid_size_t	 sc_rdesc_len;

	/*
	 * Descriptor walk results, populated during attach.
	 */
	uint32_t	sc_input_items;
	uint32_t	sc_output_items;
	uint32_t	sc_feature_items;
	uint32_t	sc_collection_depth;

	/*
	 * Interrupt report buffer (Stage B.4). Allocated in attach,
	 * sized to the maximum input report for this device's
	 * descriptor. Written only from inputfs_intr. Freed in detach.
	 */
	uint8_t		*sc_ibuf;
	hid_size_t	 sc_ibuf_size;
	uint8_t		 sc_report_id;

	/*
	 * Role membership (Stage B.5). Bitmask of INPUTFS_ROLE_*.
	 * Populated once at attach by inputfs_classify_roles. A value
	 * of zero is valid (gamepad-style "attaches but produces no
	 * events" per ADR 0004 Decision item 6).
	 */
	uint8_t		 sc_roles;
};

/*
 * Match table for HID_PNP_INFO. Matches HID Top-Level Collections
 * for Generic Desktop keyboard, mouse, and pointer.
 */
static const struct hid_device_id __used inputfs_devs[] = {
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_KEYBOARD) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_MOUSE) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_POINTER) },
};

/*
 * Walk the device's report descriptor and populate softc counts.
 * Three separate passes are required because hid_start_parse accepts
 * exactly one kind bit per pass (verified in ADR 0008 errata).
 */
static void
inputfs_walk_rdesc(struct inputfs_softc *sc)
{
	struct hid_data *s;
	struct hid_item hi;
	uint32_t depth = 0, max_depth = 0;
	uint32_t input_items = 0, output_items = 0, feature_items = 0;

	/* First pass: input items and collection depth. */
	s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len, 1 << hid_input);
	if (s != NULL) {
		while (hid_get_item(s, &hi) > 0) {
			switch (hi.kind) {
			case hid_input:
				input_items++;
				break;
			case hid_collection:
				depth++;
				if (depth > max_depth)
					max_depth = depth;
				break;
			case hid_endcollection:
				if (depth > 0)
					depth--;
				break;
			default:
				break;
			}
		}
		hid_end_parse(s);
	}

	/* Second pass: output items. */
	s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len, 1 << hid_output);
	if (s != NULL) {
		while (hid_get_item(s, &hi) > 0) {
			if (hi.kind == hid_output)
				output_items++;
		}
		hid_end_parse(s);
	}

	/* Third pass: feature items. */
	s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len, 1 << hid_feature);
	if (s != NULL) {
		while (hid_get_item(s, &hi) > 0) {
			if (hi.kind == hid_feature)
				feature_items++;
		}
		hid_end_parse(s);
	}

	sc->sc_input_items    = input_items;
	sc->sc_output_items   = output_items;
	sc->sc_feature_items  = feature_items;
	sc->sc_collection_depth = max_depth;
}

/*
 * inputfs_intr -- hidbus interrupt callback (Stage B.4).
 *
 * Called from interrupt context each time the HID device delivers a
 * report. Copies the report bytes into the per-device buffer and logs
 * a single hex-dump line to dmesg.
 *
 * Constraints (ADR 0009):
 *   - Must not sleep or block.
 *   - Must not acquire sc_mtx (not yet configured for interrupt use).
 *   - device_printf is safe from interrupt context on FreeBSD.
 */
static void
inputfs_intr(void *context, void *data, hid_size_t len)
{
	struct inputfs_softc *sc = context;
	const uint8_t *bytes = data;
	hid_size_t copy_len;
	char hexbuf[256];
	int pos, i;

	if (sc->sc_ibuf == NULL || sc->sc_ibuf_size == 0)
		return;

	/* Clamp copy length to buffer size. */
	if (len > sc->sc_ibuf_size) {
		device_printf(sc->sc_dev,
		    "inputfs: report truncated (%u > %u bytes)\n",
		    (unsigned int)len, (unsigned int)sc->sc_ibuf_size);
		copy_len = sc->sc_ibuf_size;
	} else {
		copy_len = len;
	}

	memcpy(sc->sc_ibuf, data, copy_len);

	/* Build hex string for dmesg log line. */
	pos = 0;
	for (i = 0; i < (int)copy_len && pos < (int)sizeof(hexbuf) - 3; i++) {
		pos += snprintf(hexbuf + pos, sizeof(hexbuf) - pos,
		    "%02x ", bytes[i]);
	}
	if (pos > 0 && hexbuf[pos - 1] == ' ')
		hexbuf[pos - 1] = '\0';

	device_printf(sc->sc_dev,
	    "inputfs: report id=0x%02x len=%u data=%s\n",
	    (unsigned int)(copy_len > 0 ? sc->sc_ibuf[0] : 0),
	    (unsigned int)copy_len,
	    hexbuf);
}

/*
 * inputfs_classify_roles -- Stage B.5.
 *
 * Read the matched TLC from hidbus_get_usage(), apply the
 * page guard and switch from ADR 0010 Decision section 2,
 * and write the result into sc->sc_roles. Called once per
 * attach, after B.4 setup completes.
 *
 * The page guard is a no-op today (the match table only admits
 * HUP_GENERIC_DESKTOP), but it is load-bearing the moment the
 * match table grows to admit other usage pages.
 */
static void
inputfs_classify_roles(struct inputfs_softc *sc)
{
	uint32_t usage = hidbus_get_usage(sc->sc_dev);
	uint16_t page = HID_GET_USAGE_PAGE(usage);
	uint16_t id = HID_GET_USAGE(usage);

	sc->sc_roles = 0;

	if (page == HUP_GENERIC_DESKTOP) {
		switch (id) {
		case HUG_KEYBOARD:
			sc->sc_roles |= INPUTFS_ROLE_KEYBOARD;
			break;
		case HUG_MOUSE:
		case HUG_POINTER:
			sc->sc_roles |= INPUTFS_ROLE_POINTER;
			break;
		default:
			/* Generic Desktop usage we don't classify yet;
			 * sc_roles stays 0. */
			break;
		}
	}
	/* Non-Generic-Desktop pages: sc_roles stays 0 by design. */
}

/*
 * inputfs_format_roles -- Stage B.5.
 *
 * Format the role bitmask into a comma-separated list in fixed
 * ascending bit-position order, or the literal "<none>" if no
 * bits are set. Always writes a NUL-terminated string into buf.
 *
 * Truncation safety: each iteration computes the space needed
 * for the role name plus its leading comma plus the terminator
 * before writing anything. If it does not fit, the loop breaks
 * and the previous successful iteration's NUL terminator is
 * preserved (no trailing comma).
 */
static void
inputfs_format_roles(uint8_t roles, char *buf, size_t buflen)
{
	static const char * const names[5] = {
		"pointer", "keyboard", "touch", "pen", "lighting"
	};
	size_t pos = 0;
	int first = 1;
	int i;

	if (buflen == 0)
		return;

	if (roles == 0) {
		strlcpy(buf, "<none>", buflen);
		return;
	}

	for (i = 0; i < 5; i++) {
		size_t namelen, need;

		if ((roles & (1u << i)) == 0)
			continue;

		namelen = strlen(names[i]);
		need = namelen + (first ? 0 : 1);
		if (pos + need + 1 > buflen)
			break;

		if (!first)
			buf[pos++] = ',';
		memcpy(buf + pos, names[i], namelen);
		pos += namelen;
		first = 0;
	}
	buf[pos] = '\0';
}

static int
inputfs_probe(device_t dev)
{
	int error;

	error = HIDBUS_LOOKUP_DRIVER_INFO(dev, inputfs_devs);
	if (error != 0)
		return (error);

	hidbus_set_desc(dev, "inputfs HID device");

	return (BUS_PROBE_DEFAULT);
}

static int
inputfs_attach(device_t dev)
{
	struct inputfs_softc *sc = device_get_softc(dev);
	const struct hid_device_info *hw = hid_get_device_info(dev);
	int32_t usage = hidbus_get_usage(dev);
	void *rdesc = NULL;
	hid_size_t rdesc_len = 0;
	const char *kind;
	int ibuf_size;
	int error;

	sc->sc_dev = dev;
	mtx_init(&sc->sc_mtx, "inputfs softc", NULL, MTX_DEF);

	switch (HID_GET_USAGE(usage)) {
	case HUG_KEYBOARD:
		kind = "keyboard";
		break;
	case HUG_MOUSE:
		kind = "mouse";
		break;
	case HUG_POINTER:
		kind = "pointer";
		break;
	default:
		kind = "unknown";
		break;
	}

	device_printf(dev,
	    "inputfs: attached HID %s (vendor=0x%04x, product=0x%04x)\n",
	    kind,
	    (unsigned int)hw->idVendor,
	    (unsigned int)hw->idProduct);

	/*
	 * Fetch and walk the report descriptor (Stage B.3).
	 */
	error = hid_get_report_descr(dev, &rdesc, &rdesc_len);
	if (error != 0 || rdesc == NULL) {
		device_printf(dev,
		    "inputfs: descriptor fetch failed (error=%d)\n", error);
	} else {
		sc->sc_rdesc = rdesc;
		sc->sc_rdesc_len = rdesc_len;

		if ((hid_size_t)hw->rdescsize != rdesc_len) {
			device_printf(dev,
			    "inputfs: descriptor size mismatch "
			    "(hid_device_info reports %u, fetched %u)\n",
			    (unsigned int)hw->rdescsize,
			    (unsigned int)rdesc_len);
		}

		inputfs_walk_rdesc(sc);

		device_printf(dev,
		    "inputfs: descriptor %u bytes, %u input items, "
		    "%u output, %u feature, depth=%u\n",
		    (unsigned int)sc->sc_rdesc_len,
		    (unsigned int)sc->sc_input_items,
		    (unsigned int)sc->sc_output_items,
		    (unsigned int)sc->sc_feature_items,
		    (unsigned int)sc->sc_collection_depth);

		/*
		 * Allocate interrupt buffer and register handler (Stage B.4).
		 *
		 * hid_report_size_max returns the byte count of the largest
		 * input report and populates sc_report_id with the associated
		 * report ID (0 if the device uses no report IDs).
		 */
		ibuf_size = hid_report_size_max(sc->sc_rdesc,
		    sc->sc_rdesc_len, hid_input, &sc->sc_report_id);

		if (ibuf_size <= 0) {
			device_printf(dev,
			    "inputfs: hid_report_size_max returned %d, "
			    "skipping interrupt registration\n", ibuf_size);
		} else {
			sc->sc_ibuf_size = (hid_size_t)ibuf_size;
			sc->sc_ibuf = malloc(sc->sc_ibuf_size,
			    M_INPUTFS, M_WAITOK | M_ZERO);

			device_printf(dev,
			    "inputfs: report buffer %u bytes "
			    "(report_id=0x%02x), registering interrupt\n",
			    (unsigned int)sc->sc_ibuf_size,
			    (unsigned int)sc->sc_report_id);

			hidbus_set_intr(dev, inputfs_intr, sc);

			/* Start interrupt delivery from the transport layer.
			 * Sets tlc->active=true so hidbus_intr dispatches
			 * to our callback. */
			device_printf(dev,
			    "inputfs: calling hid_intr_start\n");
			int intr_err = hid_intr_start(dev);
			device_printf(dev,
			    "inputfs: hid_intr_start returned %d\n",
			    intr_err);
		}
	}

	/*
	 * Stage B.5: classify role membership and log the result.
	 * Runs after the B.4 interrupt setup so the roles= line
	 * appears at the end of the per-device attach sequence.
	 */
	{
		char rolebuf[64];

		inputfs_classify_roles(sc);
		inputfs_format_roles(sc->sc_roles, rolebuf, sizeof(rolebuf));
		device_printf(dev, "inputfs: roles=%s\n", rolebuf);
	}

	return (0);
}

static int
inputfs_detach(device_t dev)
{
	struct inputfs_softc *sc = device_get_softc(dev);

	device_printf(dev, "inputfs: detached\n");

	/* Stop interrupt delivery before freeing the report buffer. */
	if (sc->sc_ibuf != NULL)
		hid_intr_stop(dev);

	if (sc->sc_ibuf != NULL) {
		free(sc->sc_ibuf, M_INPUTFS);
		sc->sc_ibuf = NULL;
		sc->sc_ibuf_size = 0;
	}

	sc->sc_rdesc = NULL;
	sc->sc_rdesc_len = 0;

	mtx_destroy(&sc->sc_mtx);

	return (0);
}

static int
inputfs_modevent(module_t mod, int what, void *arg)
{
	(void)mod;
	(void)arg;

	switch (what) {
	case MOD_LOAD:
		printf("inputfs: Stage B.5 loaded (hidbus HID driver, "
		    "descriptor fetch, interrupt handler registration, "
		    "raw report hex logging, role classification "
		    "-- no userspace event delivery)\n");
		return (0);
	case MOD_UNLOAD:
		printf("inputfs: unloaded\n");
		return (0);
	default:
		return (EOPNOTSUPP);
	}
}

static device_method_t inputfs_methods[] = {
	DEVMETHOD(device_probe,  inputfs_probe),
	DEVMETHOD(device_attach, inputfs_attach),
	DEVMETHOD(device_detach, inputfs_detach),

	DEVMETHOD_END
};

DEFINE_CLASS_0(inputfs, inputfs_driver, inputfs_methods,
    sizeof(struct inputfs_softc));

DRIVER_MODULE(inputfs, hidbus, inputfs_driver, inputfs_modevent, NULL);
MODULE_DEPEND(inputfs, hid, 1, 1, 1);
MODULE_DEPEND(inputfs, hidbus, 1, 1, 1);
MODULE_VERSION(inputfs, 1);
HID_PNP_INFO(inputfs_devs);
