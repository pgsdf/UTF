# PGSD kernel

This directory holds the FreeBSD kernel configuration for PGSD, the
distribution this project ships. PGSD's kernel is a self-contained
config (a derivative of FreeBSD GENERIC at the time of PGSD's
creation, kept in sync by re-merging when tracking new FreeBSD
releases) that removes the HID class drivers competing with
`inputfs` for ownership of HID devices and suppresses their
modules from the build.

## Files

- `PGSD`: kernel configuration. Self-contained; read it.

## Why this kernel exists

`inputfs` (see `inputfs/` and ADRs under `inputfs/docs/adr/`) is the
PGSDF kernel input substrate. It attaches to `hidbus` and consumes
HID reports directly. FreeBSD's stock GENERIC kernel statically
compiles two keyboard drivers that prevent `inputfs` from owning
USB keyboards: `hkbd` (the modern HID keyboard driver, claiming
hidbus children) and `ukbd` (the legacy USB keyboard driver,
claiming USB devices directly before `hidbus` sees them). The
PGSD config simply omits these device lines.

Removing the device line from the kernel image is necessary but
not sufficient. The FreeBSD build still produces `.ko` files for
these drivers under `/boot/kernel/` from the modules tree, and
the kernel registers their PNP signatures in `linker.hints`. At
boot, when the kernel sees a USB keyboard or mouse, it
auto-loads the matching `.ko` and the system returns to the
contested state.

The closure for the modules build is `WITHOUT_MODULES=...`
passed on the **command line** to `make buildkernel` and
`make installkernel`. With that argument, nothing for those
drivers appears under `/boot/kernel/`, `linker.hints` has no
PNP entries to match, and auto-load is impossible.

A `makeoptions WITHOUT_MODULES=...` directive in the kernel
config file would seem like the right place to put this, but it
does **not** reliably suppress the modules. The kernel-config
`makeoptions` reaches the kernel-link step, but the modules
tree is invoked from `/usr/src/Makefile.inc1` via a separate
make that does not always inherit those options. We tried this
during AD-8 development and the modules built anyway. The
command-line argument is the supported and reliable path; the
PGSD config file therefore does not declare
`WITHOUT_MODULES` to avoid presenting a false sense of closure.

The `WITHOUT_MODULES` list documented in the build procedure
below covers the wider set of HID class drivers ADR 0007
enumerates as competitors (`hms`, `hgame`, `hcons`, `hsctrl`,
`utouch`, `hpen`, `hmt`, `hconf`, and the `hidmap`
HID-to-evdev framework). Most of those are not in stock
GENERIC at the time of writing; their inclusion in the list is
anticipatory, documenting that PGSD excludes them regardless of
whether they appear in a future GENERIC or arrive as a loadable
module.

`hidbus`, `usbhid`, and the generic `hid` layer remain. `inputfs`
needs all three.

`evdev`, `uinput`, and `EVDEV_SUPPORT` are out of scope for this
config and remain enabled. Removing the evdev userland contract
is a separate architectural decision with broader consequences
during the PGSD transition; tracked separately, not folded into
AD-8.

## Relationship to upstream GENERIC

PGSD copies GENERIC's body verbatim aside from the AD-8 changes
(file header, ident, and the removed `device hkbd` / `device ukbd`
lines). The file header notes this. When tracking a new FreeBSD
release, re-merge PGSD against the new GENERIC: diff the two
configs, apply non-AD-8 upstream changes to PGSD, leave the AD-8
changes in place. This is a small enough surface that the cost
of manual re-merge is acceptable; the alternative (`include
GENERIC` plus `nodevice` overrides) was insufficient because
`nodevice` does not affect the modules build.

The modules-build closure (`WITHOUT_MODULES`) lives in the build
command line rather than the config, so it does not enter into
this re-merge calculation. See "Why this kernel exists" above.

## Build

Requires the FreeBSD source tree at `/usr/src` matching the running
release. If you do not have it, install via `git` from
`https://git.freebsd.org/src.git` or via `pkg install src`.

From the repository root:

```
sudo install -m 0644 pgsd-kernel/PGSD /usr/src/sys/amd64/conf/PGSD
cd /usr/src
sudo make buildkernel KERNCONF=PGSD \
    WITHOUT_MODULES="hkbd ukbd hms hgame hcons hsctrl utouch hpen hmt hconf hidmap"
```

The `WITHOUT_MODULES` argument is the build-time mechanism that
keeps the listed `.ko` files from being produced. It must be on
the command line — see "Why this kernel exists" above for why
the corresponding `makeoptions` directive in a kernel config
does not work.

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
install over the now-untracked files. Pass `WITHOUT_MODULES` to
`make installkernel` as well as to `make buildkernel`; the install
step walks the modules tree and would otherwise re-install any
`.ko` files it could find from a prior build.

```
sudo pkg unregister FreeBSD-kernel-generic
cd /usr/src
sudo make installkernel KERNCONF=PGSD DESTDIR=/ \
    WITHOUT_MODULES="hkbd ukbd hms hgame hcons hsctrl utouch hpen hmt hconf hidmap"
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
sudo make installkernel KERNCONF=PGSD \
    WITHOUT_MODULES="hkbd ukbd hms hgame hcons hsctrl utouch hpen hmt hconf hidmap"
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

Confirm the static kernel does not include the competing drivers:

```
config -x /boot/kernel/kernel | grep -E "^device[[:space:]]+(hkbd|ukbd)"
```

This should return no lines. `hkbd` and `ukbd` are the keyboard
drivers in stock GENERIC at the time of this config; their absence
from the static kernel is the first half of unblocking inputfs.

Confirm the modules also do not exist on disk (the second half;
`WITHOUT_MODULES` should have suppressed these from the build):

```
ls /boot/kernel/ | grep -E "^(hkbd|ukbd|hms|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)\.ko"
```

This should return no lines. If any of these `.ko` files exist,
`WITHOUT_MODULES` did not take effect during the kernel build
and the runtime auto-load contention path is still open.
Investigate the build log; if the build was a `make installkernel`
without a fresh `make buildkernel`, the install may have copied
old modules from a prior build. A clean `make buildkernel
KERNCONF=PGSD` followed by `make installkernel KERNCONF=PGSD`
should produce the expected result.

Cross-check that `linker.hints` does not advertise PNP signatures
for the suppressed drivers:

```
strings /boot/kernel/linker.hints | grep -E "(hkbd|ukbd|hms|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)"
```

Should return no lines. `linker.hints` is regenerated by
`kldxref` from the `.ko` files present in the directory at the
time it runs. `installkernel` runs `kldxref` automatically as
its last step, so a build that successfully suppressed the
modules produces a clean hints file in the same operation.

If the disk listing is clean but `linker.hints` still shows
entries for these drivers, the hints file is stale relative
to the directory contents — usually the result of a manual
`rm` of `.ko` files without a follow-up `kldxref`. Re-run
`sudo kldxref /boot/kernel` and re-check.

The user-visible symptom of stale hints is a stream of
"`kldload: can't load X: No such file or directory`" messages
during boot, one per autoload attempt the kernel makes against
each missing module. Functionally harmless (the load fails and
the boot continues), but indicates the cleanup is incomplete.

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

### Unwanted modules still present after install

If the verification step finds `.ko` files for any of the
suppressed drivers under `/boot/kernel/`, the most likely cause
is that `WITHOUT_MODULES` was not passed on the command line to
`make buildkernel` and `make installkernel` (or was passed to
only one of them). Recover without rebuilding the kernel:

```
for m in hkbd ukbd hms hgame hcons hsctrl utouch hpen hmt hconf hidmap; do
    sudo rm -f /boot/kernel/${m}.ko /boot/kernel/${m}.ko.debug
done
sudo kldxref /boot/kernel
```

This deletes the leaked `.ko` files and rebuilds `linker.hints`
so the kernel can no longer auto-load them on PNP match.

Verify both surfaces are clean before rebooting. The disk
listing and the hints file are independent state; one can be
clean while the other is stale.

```
ls /boot/kernel/ | grep -E "^(hkbd|ukbd|hms|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)\.ko"
strings /boot/kernel/linker.hints | grep -E "(hkbd|ukbd|hms|hgame|hcons|hsctrl|utouch|hpen|hmt|hconf|hidmap)"
```

Both should print no lines. If the `ls` is clean but the
`strings` still shows entries, run `sudo kldxref /boot/kernel`
again; the `kldxref` command writes hints based on the current
contents of the directory, so it must run *after* the rm
loop, not before. If both are clean, reboot and `kldstat`
should show none of those modules loaded.

For the next rebuild, ensure `WITHOUT_MODULES` is on the command
line for both `make buildkernel` and `make installkernel`.

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
  not in the kernel and their modules are not on disk to
  auto-load). The step passes immediately with "No competing
  drivers loaded."
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

This config is the minimal change needed for B.5 verification and
its follow-up to close the auto-load contention path. As PGSD
takes shape, additional kernel deviations belong here:

- Additional entries in `WITHOUT_MODULES` for legacy input
  drivers if they appear in some future GENERIC (`ums`, `psm` are
  not currently relevant)
- `nodevice` and `WITHOUT_MODULES` for graphics drivers
  superseded by `drawfs` (AD-4)
- `nodevice` and `WITHOUT_MODULES` for audio drivers superseded
  by `semaaud` (AD-3)
- Additional `device` and `options` lines as PGSD's substrate
  matures

Each addition belongs in its own commit with reference to the
backlog item that drove it.

When tracking new FreeBSD releases, re-merge upstream GENERIC
into PGSD: diff `/usr/src/sys/amd64/conf/GENERIC` against
`pgsd-kernel/PGSD`, port any non-AD-8 upstream additions across,
keep the AD-8 deltas (header, ident, removed device lines)
intact. The `WITHOUT_MODULES` build-command argument does not
need re-merge attention since it is not in the config file.
Commit with the FreeBSD release identifier in the message.
