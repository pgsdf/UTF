# PGSD Kernel Configuration

Minimal, hardened FreeBSD kernel configuration (PGSD).

**Goal**: Reduce attack surface and kernel footprint by excluding unnecessary generic USB HID/input modules.

## Excluded Modules

The following modules are **not built**:

- `hkbd` `ukbd` – USB keyboards
- `hms` `hgame` – USB mice / game devices
- `hcons` `hsctrl` – HID console / system control
- `utouch` `hpen` `hmt` `hconf` `hidmap` – Touchscreens, pens, multitouch, HID mapping

## Build Instructions

```sh
cd /usr/src

# Build kernel + modules
sudo make buildkernel KERNCONF=PGSD \
  WITHOUT_MODULES="hkbd ukbd hms hgame hcons hsctrl utouch hpen hmt hconf hidmap"

# Install kernel + modules
sudo make installkernel KERNCONF=PGSD DESTDIR=/ \
  WITHOUT_MODULES="hkbd ukbd hms hgame hcons hsctrl utouch hpen hmt hconf hidmap"

Important: Always pass WITHOUT_MODULES on the command line.
makeoptions inside the kernel config does not reliably affect modules.Cleanup (if old modules are present)sh

cd /usr/src

# Unload modules first
sudo kldunload hkbd ukbd hms hgame hcons hsctrl utouch hpen hmt hconf hidmap 2>/dev/null || true

# Remove files
sudo rm -f /boot/kernel/{hkbd,ukbd,hms,hgame,hcons,hsctrl,utouch,hpen,hmt,hconf,hidmap}.ko*
sudo rm -f /boot/kernel/{hkbd,ukbd,hms,hgame,hcons,hsctrl,utouch,hpen,hmt,hconf,hidmap}.ko.debug

# Update linker hints
sudo kldxref /boot/kernel

If removal still fails, run these extra steps:sh

sudo mount -uw /
sudo chflags -R noschg /boot/kernel 2>/dev/null || true
sudo rm -f /boot/kernel/{hkbd,ukbd,hms,hgame,hcons,hsctrl,utouch,hpen,hmt,hconf,hidmap}.ko*
sudo kldxref /boot/kernel

Then reboot and verify:sh

kldstat | grep -E '(hkbd|ukbd|hms|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)' || echo "No matching modules loaded"
ls /boot/kernel/ | grep -E '^(hkbd|ukbd|hms|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)' || echo "No matching .ko files"

Rebuild After Source UpdatesUse the same build + install commands above.Kernel Config Locationsys/amd64/conf/PGSD
Last updated: 2026-05-02



