# Installing UTF on a fresh FreeBSD system

This document walks through installing UTF on a clean FreeBSD 15
machine. Each step has a verification check; do not proceed until
the check passes. The hazards section at the end names the things
that have actually broken installs in the past.

The high-level shape is: install FreeBSD, mount `/var/run` as
tmpfs, install build dependencies, optionally build the PGSD
kernel, build UTF userland, install UTF, load kernel modules
manually (not from loader.conf), start daemons.

## Prerequisites

- FreeBSD 15.0-RELEASE installed and bootable. ZFS or UFS root.
- Network access for `pkg install` and `git clone`.
- Root access via `sudo` or direct login.
- The `/usr/src` tree if you intend to build the PGSD kernel
  (see `pgsd-kernel/README.md`). Optional for first install;
  GENERIC works for most UTF testing.

## Step 1 — Mount `/var/run` as tmpfs

UTF publishes shared-memory regions under `/var/run/sema/`. The
default `/var/run` on FreeBSD is on the same filesystem as `/var`,
which makes shared-memory writes more expensive and leaves stale
state files across reboots. UTF assumes tmpfs.

Add to `/etc/fstab`:

```
tmpfs /var/run tmpfs rw,mode=755 0 0
```

Activate without rebooting:

```
sudo mount /var/run
```

**Verify:**

```
mount | grep /var/run
```

Expect a line `tmpfs on /var/run (tmpfs, ...)`. If absent, do not
proceed; UTF will not work correctly on a non-tmpfs `/var/run`.

## Step 2 — Install build dependencies

Zig 0.15 or newer, plus tooling needed by drawfs and the kernel
modules:

```
sudo pkg install -y zig git gmake
```

If you intend to build the PGSD kernel, also install the FreeBSD
source tree:

```
sudo pkg install -y src
```

**Verify:**

```
zig version
```

Must report `0.15.x` or newer. If it reports `0.14.x` or older,
the build will fail with errors about unrecognized syntax.

## Step 3 — Clone UTF

```
cd ~
git clone https://github.com/pgsdf/UTF.git
cd UTF
```

**Verify:**

```
ls
```

Expect to see `README.md`, `BACKLOG.md`, `install.sh`, `start.sh`,
`drawfs/`, `inputfs/`, `semadraw/`, `semaaud/`, `semainput/`,
`chronofs/`, `shared/`, `pgsd-kernel/`.

## Step 4 — Build UTF userland

The top-level `build.sh` builds every userland Zig subproject:
`semaaud`, `semainput`, `chronofs`, and `semadraw`.

```
sudo sh build.sh
```

This takes a few minutes and produces binaries under each
subproject's `zig-out/bin/`. Kernel modules are built separately
in step 5 — `build.sh` does not build kernel modules.

**Verify:**

```
ls semadraw/zig-out/bin/semadrawd
ls semaaud/zig-out/bin/semaaud
ls semainput/zig-out/bin/semainputd
ls chronofs/zig-out/bin/chrono_dump
```

All four files must exist. If any are missing, the corresponding
build step failed; re-run `build.sh` and read the error output.

## Step 5 — Build the kernel modules

drawfs and inputfs are FreeBSD kernel modules, built against
`/usr/src` via per-module helper scripts. The full build sequence
runs as part of `install.sh` in step 6, so for a normal install
you can skip this step. To build the modules without installing
the rest of UTF (for development iteration):

```
sudo sh drawfs/build.sh install
sudo sh drawfs/build.sh build
sudo sh drawfs/build.sh deploy
sudo sh inputfs/build.sh install
sudo sh inputfs/build.sh build
sudo sh inputfs/build.sh deploy
```

Each helper script copies sources into `/usr/src/sys/`, runs
`make`, and copies the resulting `.ko` to `/boot/modules/`.

**Verify:**

```
ls /boot/modules/drawfs.ko
ls /boot/modules/inputfs.ko
```

Both must exist after the deploy step.

The standalone Zig build under `inputfs/` (just `zig build` in
that directory) only builds `inputdump`, the userland diagnostic
CLI — not the kernel module. The kernel module is built by
`inputfs/build.sh` exclusively.

## Step 6 — Install (system-wide)

```
sudo sh install.sh
```

This is the canonical install path. It:

1. Builds and deploys both kernel modules (calling `drawfs/build.sh`
   and `inputfs/build.sh` for steps 5's work, so step 5 is
   redundant if you run `install.sh`).
2. Copies userland binaries to `/usr/local/bin/`.
3. Generates rc.d service scripts for the daemons.
4. Sets `drawfs_load="YES"` in `/boot/loader.conf`.
5. Sets daemon enable flags in `/etc/rc.conf`.

**Important:** `install.sh` does **not** add `inputfs_load` to
`/boot/loader.conf`. Do not add it manually. See Hazard 1 below.

**Verify:**

```
ls /usr/local/bin/semadrawd /usr/local/bin/semaaud /usr/local/bin/semainputd /usr/local/bin/chrono_dump
ls /usr/local/etc/rc.d/semadrawd /usr/local/etc/rc.d/semaaud /usr/local/etc/rc.d/semainputd
ls /boot/modules/drawfs.ko /boot/modules/inputfs.ko
grep drawfs_load /boot/loader.conf
grep inputfs_load /boot/loader.conf  # should produce no output
```

The last command is a check, not a setup step: if it produces
output, something added `inputfs_load` and it must be removed
before the next reboot.

## Step 7 — Load kernel modules

Load drawfs first, then inputfs. Order matters because of
attachment timing.

```
sudo kldload drawfs
sudo kldload inputfs
```

**Verify:**

```
kldstat | grep -E "drawfs|inputfs"
```

Both modules must be listed. If either fails to load, run
`dmesg | tail -50` and read the error.

If `kldload inputfs` reports "module already loaded" but `kldstat`
does not list it, something attempted to load it from
`loader.conf` — see Hazard 1.

## Step 8 — Start daemons

```
sudo service semaaud start
sudo service semainputd start
sudo service semadrawd start
```

Or use the all-in-one script:

```
sudo sh start.sh
```

**Verify:**

```
service semaaud status
service semainputd status
service semadrawd status
ls /var/run/sema/clock /var/run/sema/input/state /var/run/sema/input/events
```

All daemons should report running, and the four shared-memory
regions should exist.

## Step 9 — Run something

```
sudo /usr/local/bin/semadraw-term --scale 2
```

(Or `sudo semadraw/zig-out/bin/semadraw-term --scale 2` if you
skipped the install step.)

A terminal should appear on the framebuffer. Mouse and keyboard
should respond. If they don't, see Hazard 2.

## Hazards

These are mistakes that have actually caused install-time crashes
or unrecoverable boots. Read them.

### Hazard 1 — Do NOT add `inputfs_load="YES"` to `/boot/loader.conf`

`inputfs.ko` cannot currently be loaded from `loader.conf`. Doing
so causes a kernel panic on next boot in `inputfs_state_worker`,
because the kthread starts before `/var/run` is mounted and
faults when it tries to create `/var/run/sema/input/`.

The recovery from this state requires booting from a FreeBSD
install USB and editing `/boot/loader.conf` from rescue mode —
not a quick fix.

`drawfs_load="YES"` is fine and is what `install.sh` adds. Only
inputfs has the early-boot crash.

If you want inputfs loaded automatically at boot, add to
`/etc/rc.local` instead:

```
kldload inputfs
```

`rc.local` runs late in boot, after filesystems are mounted.

A proper rc.d service for inputfs with `REQUIRE: FILESYSTEMS`
ordering is the right long-term shape but is not yet written.

### Hazard 2 — Input may not work if HID drivers compete with inputfs

FreeBSD GENERIC includes `hkbd` and `ukbd` statically. These
attach to USB keyboards before inputfs sees them, leaving
inputfs with no devices to own. Symptoms: `kldstat` shows
inputfs loaded but `ls /var/run/sema/input/` shows the state
region has no devices, and keyboard input does not reach UTF
clients.

Resolutions, in increasing order of effort:

1. **Move the competing module files out of `/boot/kernel/`
   and rebuild `linker.hints`.** Quick, reversible. See
   `BACKLOG.md` AD-8 for context.

2. **Build and install the PGSD kernel.** This is the
   supported configuration for full UTF testing. See
   `pgsd-kernel/README.md` for the build steps, including the
   pkgbase-aware install path. Plan 30-60 minutes for the
   build.

3. **Use only mice and devices not claimed by `hkbd`/`ukbd`
   for initial testing.** Pointers attach via `hms` (also
   compiled in GENERIC); if you have an `hms`-using mouse the
   same competition occurs.

The PGSD kernel exists specifically to remove this competition.

### Hazard 3 — Filesystem corruption from interrupted installs

If a previous attempt at `make installkernel` or `pkg install`
was interrupted (kernel panic, power loss, ctrl-C in the wrong
moment), `/boot/kernel/` may be in a partial state where neither
the new kernel nor `kernel.old` boots. Symptom: every boot
selection panics identically very early.

The fix is a USB-rescue boot, mount the root, and either
restore `/boot/kernel/` from `/boot/kernel.old/` or reinstall
the pkgbase kernel (`pkg -c /mnt install -f FreeBSD-kernel-generic`).

Once the system boots cleanly, **do not retry the failed install
step until you understand what caused the original interruption.**
Repeated half-completes compound the corruption.

### Hazard 4 — Zig version mismatch

Zig 0.14 and 0.15 have substantial syntax differences. UTF
targets 0.15 and the build will fail loudly on 0.14 (errors
about reserved syntax, missing imports, or wrong stdlib paths).

If `zig version` reports 0.14, install 0.15 from the official
Zig downloads or wait for `pkg install zig` to ship a 0.15
build for your FreeBSD version.

### Hazard 5 — `/var/run` not actually tmpfs

Step 1's verification is not optional. UTF's shared-memory
publication assumes tmpfs and may produce confusing failures
(stale region files from previous boots, write performance
degradation, file-mode mismatches) on a regular `/var/run`.
Always confirm `mount | grep /var/run` shows `tmpfs` before
proceeding.

## Recovery checklist

If something goes wrong during install or first run, these are
the recovery steps in order:

1. **`kldunload inputfs; kldunload drawfs`** — back out the
   kernel modules. Most issues localize here.
2. **`service semadrawd stop; service semainputd stop;
   service semaaud stop`** — back out the daemons.
3. **`rm -rf /var/run/sema/`** — clear stale state regions.
4. **Reboot** — fresh state for everything user- and
   kernel-side.
5. **If reboot panics** — boot from FreeBSD USB rescue, mount
   the root, edit `/boot/loader.conf` to remove anything UTF
   added, and reboot. See Hazard 3.

## Uninstall

```
sudo sh install.sh --uninstall
```

This removes the installed binaries, rc.d service files, the
`drawfs_load` entry from `/boot/loader.conf`, and the daemon
enable flags from `/etc/rc.conf`. It does not remove the
source tree at `~/UTF` or anything under `/var/run/sema/`
(transient; cleared on reboot).

## Next steps after a clean install

- Run the inputfs verification protocol at
  `inputfs/docs/D_VERIFICATION.md` to confirm the substrate is
  working.
- Read `BACKLOG.md` to see the open work surface.
- Read `docs/UTF_ARCHITECTURAL_DISCIPLINE.md` for the framing
  that all the work descends from.

## Why this document exists

UTF's install steps were previously distributed across several
documents (`README.md`, `pgsd-kernel/README.md`, `install.sh`
comments, the inputfs proposal). A first-install operator had
to triangulate. This document is the single end-to-end walkthrough
plus the hazard list. The hazards section in particular captures
failure modes that have actually been hit during testing,
including the `inputfs_load` early-boot crash and the universal
panic from interrupted installs.

Updates to this document should be commit-paired with the change
that necessitated them: a new hazard discovered during testing
lands here in the same commit that fixes it (or, if no fix
exists yet, lands here with a clear "no fix yet" note).
