/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage B.4: interrupt handler registration and raw report hex logging.
 * inputfs registers a report-delivery callback with hidbus via
 * hidbus_set_intr(). Each incoming HID report is copied into a
 * per-device buffer and logged as a hex dump to dmesg. No event
 * publication to userspace; that begins at Stage C.
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
 * Per-device softc. Stage B.4 adds interrupt buffer fields; Stage B.5
 * will add per-device role bitmask.
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

			/* Start interrupt delivery from the transport layer. */
			hid_intr_start(dev);
		}
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
		printf("inputfs: Stage B.4 loaded (hidbus HID driver, "
		    "descriptor fetch, interrupt handler registration, "
		    "raw report hex logging -- no userspace event delivery)\n");
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
