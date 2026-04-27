# PGSD kernel

This directory holds the FreeBSD kernel configuration for PGSD, the
distribution this project ships. The current build is minimal: it
includes FreeBSD's GENERIC kernel and removes the HID class drivers
that compete with `inputfs` for ownership of HID devices.

## Files

- `PGSD`: kernel configuration. Single file; small. Read it.

## Why this kernel exists

`inputfs` (see `inputfs/` and ADRs under `inputfs/docs/adr/`) is the
PGSDF kernel input substrate. It attaches to `hidbus` and consumes
HID reports directly. FreeBSD's stock GENERIC kernel ships drivers
that would otherwise claim the same `hidbus` children at boot:
`hms`, `hkbd`, `hgame`, `hcons`, `hsctrl`, `utouch`, `hpen`, `hmt`,
`hconf`, and the `hidmap` framework that bridges HID to `evdev`.
With those present, `inputfs` cannot bind to USB HID devices on
bare metal without a runtime workflow that turns out not to be
reliable on stock FreeBSD (see B.5 verification history in
`inputfs/docs/B5_VERIFICATION.md` and BACKLOG AD-1).

The PGSD kernel removes those drivers via `nodevice` lines.
`inputfs` is then the only candidate driver at probe time and binds
without competition. This also expresses the wider PGSDF
architectural commitment: no `evdev` anywhere in the input path.

`hidbus`, `usbhid`, and the generic `hid` layer remain. `inputfs`
needs all three.

## Build

Requires the FreeBSD source tree at `/usr/src` matching the running
release. If you do not have it, install via `git` from
`https://git.freebsd.org/src.git` or via `pkg install src`.

From the repository root:

```
sudo install -m 0644 pgsd-kernel/PGSD /usr/src/sys/amd64/conf/PGSD
cd /usr/src
sudo make buildkernel KERNCONF=PGSD
```

The build takes 30-60 minutes on modern hardware. The kernel
config does not require a full `buildworld` since the only change
is which kernel modules are compiled; the userland is unchanged.

## Install

```
cd /usr/src
sudo make installkernel KERNCONF=PGSD
```

This installs the new kernel to `/boot/kernel/` and moves the
previous kernel to `/boot/kernel.old/`. The previous kernel
remains bootable from the loader menu.

Reboot:

```
sudo shutdown -r now
```

## Verify the kernel installed correctly

After reboot, confirm the running kernel is PGSD:

```
sysctl kern.conftxt | head -3
```

The `ident` line should read `ident PGSD` (not `ident GENERIC`).

Confirm the omitted drivers are absent:

```
config -x /boot/kernel/kernel | grep -E "device.*(hms|hkbd|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)"
```

This should return no lines. If any of the removed drivers shows
up, the build did not pick up the `nodevice` directives; check
that the correct config file landed at
`/usr/src/sys/amd64/conf/PGSD`.

Confirm `hidbus` and `usbhid` are still present:

```
config -x /boot/kernel/kernel | grep -E "device.*(hidbus|usbhid|^device hid$)"
```

Should return three lines (`device hid`, `device hidbus`, `device usbhid`).

## Recovery

If the new kernel does not boot, do not panic. At the loader menu,
press a number key for "Escape to a loader prompt", then:

```
boot kernel.old
```

This boots the previous kernel. From there, investigate the build
log (`/usr/obj/...`), correct the config, and rebuild.

If the loader menu does not appear, the FreeBSD boot path
automatically falls back to `kernel.old` after a configurable
timeout. See `loader.conf(5)`.

## Run B.5 verification

With the PGSD kernel running, run the bare-metal B.5 verification
script. From the repository root:

```
cd inputfs/test/b5
sudo sh ./b5-verify-baremetal.sh
```

The script runs four signals (mouse classifies as pointer; mouse
motion produces reports; keyboard classifies as keyboard; clean
unload). Expected behavior on the PGSD kernel:

- Precondition step "Unloading drivers that compete with inputfs"
  finds none of the competing drivers loaded (because they are
  not in the kernel). The step passes immediately with
  "No competing drivers loaded."
- Signal 2.1 produces an `inputfs0: ... attached HID mouse` line
  and a `roles=pointer` line.
- Signal 2.2 produces a stream of `report id=` lines as the mouse
  is moved.
- Signal 2.3 produces an `inputfs0: ... attached HID keyboard`
  line and a `roles=keyboard` line.
- Signal 2.4 produces `inputfs0: detached` and `inputfs: unloaded`.

Logs land in `inputfs/test/b5/b5-2.{1,2,3,4}.log` and the combined
`b5-pass2-baremetal.log`. Attach the combined log to the B.5
closeout commit message.

## Future PGSD kernel work

This config is the minimal change needed for B.5 verification. As
PGSD takes shape, additional kernel deviations belong here:

- `nodevice` for legacy input drivers if they appear in some
  future GENERIC (`ukbd`, `ums`, `psm` are not currently relevant)
- `nodevice` for graphics drivers superseded by `drawfs` (AD-4)
- `nodevice` for audio drivers superseded by `semaaud` (AD-3)
- Additional `device` and `options` lines as PGSD's substrate
  matures

Each addition belongs in its own commit with reference to the
backlog item that drove it.
