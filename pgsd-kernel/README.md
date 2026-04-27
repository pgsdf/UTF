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
HID reports directly. FreeBSD's stock GENERIC kernel statically
compiles two keyboard drivers that prevent `inputfs` from owning
USB keyboards: `hkbd` (the modern HID keyboard driver, claiming
hidbus children) and `ukbd` (the legacy USB keyboard driver,
claiming USB devices directly before `hidbus` sees them). Because
both are statically linked, runtime `kldunload` cannot displace
them. See B.5 verification history in
`inputfs/docs/B5_VERIFICATION.md` and BACKLOG AD-1.

The PGSD kernel removes both via `nodevice` lines, plus the wider
set of HID class drivers that ADR 0007 enumerates as competitors
(`hms`, `hgame`, `hcons`, `hsctrl`, `utouch`, `hpen`, `hmt`,
`hconf`, and the `hidmap` HID-to-evdev framework). Most of those
are not in stock GENERIC at the time of writing; the `nodevice`
lines are anticipatory, documenting that PGSD excludes them
regardless of whether they appear in a future GENERIC.

`hidbus`, `usbhid`, and the generic `hid` layer remain. `inputfs`
needs all three.

`evdev`, `uinput`, and `EVDEV_SUPPORT` are out of scope for this
config and remain enabled. Removing them is a separate
architectural decision with broader userland-compatibility
consequences during the PGSD transition; tracked separately, not
folded into AD-8.

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

Modern FreeBSD 15 systems are typically installed via pkgbase, which
turns the kernel into a managed package (`FreeBSD-kernel-generic`).
Plain `make installkernel` refuses to run on such a system to avoid
clobbering files owned by the pkg database. There are two install
paths depending on whether your system is pkgbase-managed.

Determine which you have:

```
pkg which /boot/kernel/kernel
```

If that returns `was installed by package FreeBSD-kernel-...`, you
are on a pkgbase system. Otherwise, the kernel was installed from
source and the classic path applies.

### pkgbase-managed system (typical for FreeBSD 15)

Unregister the pkgbase kernel so `pkg(8)` stops tracking it, then
install over the now-untracked files:

```
sudo pkg unregister FreeBSD-kernel-generic
cd /usr/src
sudo make installkernel KERNCONF=PGSD DESTDIR=/
```

`pkg unregister` removes the package's database entry without
touching the files in `/boot/kernel/`. `make installkernel
DESTDIR=/` then overwrites the kernel with the PGSD build, moving
the previous kernel to `/boot/kernel.old/`.

This sequence comes from the FreeBSD forums thread "FreeBSD 15:
now, kernel is a package" (Feb 2026). Building a custom pkgbase
kernel package (the alternative) is not yet supported in the way
that would make pkg(8) happy with it; the unregister-then-install
path is the recommended workaround.

Note for the future: a subsequent `pkg upgrade` may try to
reinstall `FreeBSD-kernel-generic` and overwrite the custom
kernel. To prevent this, `pkg-lock(8)` the kernel or arrange a
PGSD-specific pkg repository. Out of scope for B.5 verification;
relevant once PGSD has its own pkg infrastructure.

### Source-built system (classic path)

```
cd /usr/src
sudo make installkernel KERNCONF=PGSD
```

This installs the new kernel to `/boot/kernel/` and moves the
previous kernel to `/boot/kernel.old/`.

### Reboot

```
sudo shutdown -r now
```

The previous kernel remains bootable from the loader menu via
"Boot Options" -> "Boot Single User" or by explicitly selecting
`kernel.old`.

## Verify the kernel installed correctly

After reboot, confirm the running kernel is PGSD:

```
sysctl kern.conftxt | head -3
```

The `ident` line should read `ident PGSD` (not `ident GENERIC`).

Confirm the drivers we observed in stock GENERIC are now absent:

```
config -x /boot/kernel/kernel | grep -E "^device[[:space:]]+(hkbd|ukbd)"
```

This should return no lines. `hkbd` and `ukbd` were the keyboard
drivers in stock GENERIC at the time of this config; their absence
is what unblocks `inputfs` from owning USB keyboards.

Optionally, confirm the anticipatory removals are also absent. Most
of these were not in stock GENERIC, so they should already be
absent regardless:

```
config -x /boot/kernel/kernel | grep -E "^device[[:space:]]+(hms|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)"
```

Should return no lines.

Confirm `hidbus`, `usbhid`, and `hid` are still present:

```
config -x /boot/kernel/kernel | grep -E "^device[[:space:]]+(hid|hidbus|usbhid)$"
```

Should return three lines.

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
