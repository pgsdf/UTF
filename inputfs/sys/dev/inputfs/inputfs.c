/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage B.2: USB driver skeleton. inputfs now registers as a USB driver
 * on the uhub bus and responds to probe/attach/detach for HID boot-protocol
 * keyboards and mice. On attach, a log line is emitted identifying the
 * device by vendor and product ID. No HID report parsing, no event
 * publication, no shared-memory regions, and no ioctls. Subsequent Stage B
 * commits add those incrementally.
 *
 * Reference drivers consulted for this stage:
 *   sys/dev/usb/input/ukbd.c  (from ghostbsd-src)
 *   sys/dev/usb/input/ums.c   (from ghostbsd-src)
 *   sys/dev/usb/input/uep.c   (from ghostbsd-src)
 *
 * System Model: inputfs is mutually exclusive with ukbd and ums per ADR 0006.
 * Loading this module on a system with ukbd or ums already attached to a
 * device will not displace them; probe arbitration is a FreeBSD concern.
 * UTF Mode assumes ukbd and ums are absent at boot.
 *
 * This file is part of the UTF project. See:
 *   docs/UTF_ARCHITECTURAL_DISCIPLINE.md
 *   inputfs/docs/inputfs-proposal.md
 *   inputfs/docs/foundations.md
 *   inputfs/docs/adr/0001-module-charter.md
 *   inputfs/docs/adr/0006-usb-device-ownership.md
 *
 * Target: FreeBSD 15.
 */

#include <sys/param.h>
#include <sys/systm.h>
#include <sys/kernel.h>
#include <sys/module.h>
#include <sys/bus.h>
#include <sys/mutex.h>
#include <sys/conf.h>

#include <dev/usb/usb.h>
#include <dev/usb/usbdi.h>
#include <dev/usb/usbdi_util.h>
#include <dev/usb/usbhid.h>

/*
 * Per-device softc. Stage B.2 is state-free at the per-device level;
 * future stages add USB transfer handles, HID parse state, and role
 * classification here.
 */
struct inputfs_softc {
	device_t	sc_dev;
	struct mtx	sc_mtx;
};

/*
 * Match table for USB_PNP_HOST_INFO. Matches HID-class boot-protocol
 * keyboards and mice. Non-boot-protocol HID devices (tablets, gamepads,
 * composite devices) are deferred to later stages; Stage B.2 is
 * deliberately narrow.
 */
static const STRUCT_USB_HOST_ID __used inputfs_devs[] = {
	{USB_IFACE_CLASS(UICLASS_HID),
	 USB_IFACE_SUBCLASS(UISUBCLASS_BOOT),
	 USB_IFACE_PROTOCOL(UIPROTO_BOOT_KEYBOARD)},
	{USB_IFACE_CLASS(UICLASS_HID),
	 USB_IFACE_SUBCLASS(UISUBCLASS_BOOT),
	 USB_IFACE_PROTOCOL(UIPROTO_MOUSE)},
};

static int
inputfs_probe(device_t dev)
{
	struct usb_attach_arg *uaa = device_get_ivars(dev);

	if (uaa->usb_mode != USB_MODE_HOST)
		return (ENXIO);

	if (uaa->info.bInterfaceClass != UICLASS_HID)
		return (ENXIO);

	if (uaa->info.bInterfaceSubClass != UISUBCLASS_BOOT)
		return (ENXIO);

	if (uaa->info.bInterfaceProtocol != UIPROTO_BOOT_KEYBOARD &&
	    uaa->info.bInterfaceProtocol != UIPROTO_MOUSE)
		return (ENXIO);

	return (BUS_PROBE_DEFAULT);
}

static int
inputfs_attach(device_t dev)
{
	struct usb_attach_arg *uaa = device_get_ivars(dev);
	struct inputfs_softc *sc = device_get_softc(dev);
	const char *kind;

	sc->sc_dev = dev;
	mtx_init(&sc->sc_mtx, "inputfs softc", NULL, MTX_DEF);

	device_set_usb_desc(dev);

	switch (uaa->info.bInterfaceProtocol) {
	case UIPROTO_BOOT_KEYBOARD:
		kind = "keyboard";
		break;
	case UIPROTO_MOUSE:
		kind = "mouse";
		break;
	default:
		kind = "unknown";
		break;
	}

	device_printf(dev,
	    "inputfs: attached HID %s (vendor=0x%04x, product=0x%04x)\n",
	    kind,
	    (unsigned int)uaa->info.idVendor,
	    (unsigned int)uaa->info.idProduct);

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
		printf("inputfs: Stage B.2 loaded (USB HID driver active, "
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

static driver_t inputfs_driver = {
	.name = "inputfs",
	.methods = inputfs_methods,
	.size = sizeof(struct inputfs_softc),
};

DRIVER_MODULE(inputfs, uhub, inputfs_driver, inputfs_modevent, NULL);
MODULE_DEPEND(inputfs, usb, 1, 1, 1);
MODULE_DEPEND(inputfs, hid, 1, 1, 1);
MODULE_VERSION(inputfs, 1);
USB_PNP_HOST_INFO(inputfs_devs);
