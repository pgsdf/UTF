/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage B.3: HID report descriptor fetch and walk. inputfs fetches
 * each device's HID report descriptor during attach, walks it to
 * count input/output/feature items and maximum collection depth,
 * and caches the descriptor pointer in the per-device softc.
 * No interrupt handler, no event publication, no shared-memory
 * regions, no ioctls. Those remain Stage B.4 onwards.
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
 *
 * Target: FreeBSD 15.0-RELEASE-p2.
 */

#include <sys/param.h>
#include <sys/systm.h>
#include <sys/kernel.h>
#include <sys/module.h>
#include <sys/bus.h>
#include <sys/mutex.h>

#include <dev/hid/hid.h>
#include <dev/hid/hidbus.h>

/*
 * Per-device softc. Stage B.3 adds descriptor metadata; Stage B.4
 * will add interrupt buffers and report parse state.
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
	hid_size_t	sc_rdesc_len;

	/*
	 * Descriptor walk results, populated during attach. These
	 * describe the shape of the report descriptor; interpretation
	 * of specific fields is deferred to Stage B.4.
	 */
	uint32_t	sc_input_items;
	uint32_t	sc_output_items;
	uint32_t	sc_feature_items;
	uint32_t	sc_collection_depth;
};

/*
 * Match table for HID_PNP_INFO. Matches HID Top-Level Collections
 * for Generic Desktop keyboard, mouse, and pointer. Additional TLCs
 * (touch, pen, gamepad, lighting) are deferred to later Stage B
 * sub-items.
 */
static const struct hid_device_id __used inputfs_devs[] = {
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_KEYBOARD) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_MOUSE) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_POINTER) },
};

/*
 * Walk the device's report descriptor and populate softc counts.
 * Called only when sc->sc_rdesc is non-NULL.
 */
static void
inputfs_walk_rdesc(struct inputfs_softc *sc)
{
	struct hid_data *s;
	struct hid_item hi;
	uint32_t depth = 0, max_depth = 0;
	uint32_t input_items = 0, output_items = 0, feature_items = 0;

	s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len,
	    (1 << hid_input) | (1 << hid_output) | (1 << hid_feature));
	if (s == NULL)
		return;

	while (hid_get_item(s, &hi) > 0) {
		switch (hi.kind) {
		case hid_input:
			input_items++;
			break;
		case hid_output:
			output_items++;
			break;
		case hid_feature:
			feature_items++;
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
		}
	}
	hid_end_parse(s);

	sc->sc_input_items = input_items;
	sc->sc_output_items = output_items;
	sc->sc_feature_items = feature_items;
	sc->sc_collection_depth = max_depth;
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
	 * Fetch and walk the report descriptor. Failure is non-fatal
	 * in Stage B.3; the device attaches and the softc descriptor
	 * fields remain zero.
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
	}

	return (0);
}

static int
inputfs_detach(device_t dev)
{
	struct inputfs_softc *sc = device_get_softc(dev);

	device_printf(dev, "inputfs: detached\n");

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
		printf("inputfs: Stage B.3 loaded (hidbus HID driver, "
		    "descriptor fetch, no event delivery yet)\n");
		return (0);
	case MOD_UNLOAD:
		printf("inputfs: unloaded\n");
		return (0);
	default:
		return (EOPNOTSUPP);
	}
}

static device_method_t inputfs_methods[] = {
	DEVMETHOD(device_probe, inputfs_probe),
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
