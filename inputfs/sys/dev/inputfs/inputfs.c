/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage B.2 (revised): hidbus-attached driver. inputfs registers
 * on the hidbus and responds to probe/attach/detach for HID devices
 * matching Generic Desktop keyboard, mouse, or pointer top-level
 * collections. On attach, a log line is emitted identifying the
 * device by vendor and product ID. No HID report parsing, no event
 * publication, no shared-memory regions, and no ioctls. Subsequent
 * Stage B commits add those incrementally.
 *
 * Reference drivers consulted for this stage (from ghostbsd-src):
 *   sys/dev/hid/hms.c   (HID mouse, modern)
 *   sys/dev/hid/hkbd.c  (HID keyboard, modern)
 *   sys/dev/hid/hidbus.c (HID bus driver)
 *
 * System Model: inputfs is mutually exclusive with hms, hkbd, hgame,
 * hcons, hsctrl, utouch, hpen, and the hidmap framework per ADR 0007.
 * Loading inputfs on a system where those drivers are already attached
 * to HID devices results in probe-score arbitration at device level;
 * UTF Mode assumes the competing drivers are absent at boot.
 *
 * inputfs attaches on hidbus, not on uhub. This is transport-agnostic:
 * USB, Bluetooth, and I2C HID devices all reach hidbus the same way.
 * The usbhid and hidbus infrastructure is retained from FreeBSD and
 * treated as an accepted dependency per UTF's architectural discipline.
 *
 * This file is part of the UTF project. See:
 *   docs/UTF_ARCHITECTURAL_DISCIPLINE.md
 *   inputfs/docs/inputfs-proposal.md
 *   inputfs/docs/foundations.md
 *   inputfs/docs/adr/0001-module-charter.md
 *   inputfs/docs/adr/0007-hidbus-attachment.md
 *
 * Supersedes the uhub-attached design in ADR 0006 and its
 * corresponding inputfs.c code revision.
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
 * Per-device softc. Stage B.2 is state-free at the per-device level;
 * future stages add HID report parse state, interrupt buffers, and
 * role classification here.
 */
struct inputfs_softc {
	device_t	sc_dev;
	struct mtx	sc_mtx;
};

/*
 * Match table for HID_PNP_INFO. Matches HID Top-Level Collections
 * for Generic Desktop keyboard, mouse, and pointer. Additional TLCs
 * (touch, pen, lighting) are deferred to later Stage B sub-items.
 *
 * Matching on TLC is transport-independent: a USB keyboard, a
 * Bluetooth keyboard, and an I2C HID keyboard all advertise the
 * same Generic Desktop / Keyboard collection and match identically.
 */
static const struct hid_device_id __used inputfs_devs[] = {
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_KEYBOARD) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_MOUSE) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_POINTER) },
};

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
	const char *kind;

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

	return (0);
}

static int
inputfs_detach(device_t dev)
{
	struct inputfs_softc *sc = device_get_softc(dev);

	device_printf(dev, "inputfs: detached\n");

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
		printf("inputfs: Stage B.2 loaded (hidbus HID driver, "
		    "no event delivery yet)\n");
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
