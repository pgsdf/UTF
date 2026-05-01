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

Zig 0.15 or newer, plus tooling needed by drawfs and inputfs:

```
sudo pkg install -y zig git gmake rsync
```

`rsync` is used by `drawfs/build.sh` and `inputfs/build.sh` to
copy module sources into `/usr/src/sys/`. It is not in FreeBSD
base. Without it, both kernel-module builds fail at the install
step with `rsync: not found`.

For the interactive backend selector in step 3.5 below, also
install `bsddialog`:

```
sudo pkg install -y bsddialog
```

`bsddialog` is optional — `configure.sh` falls back to a plain
text menu if it is absent — but the dialog menu is a clearer
interface and is recommended.

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

## Step 3.5 — Configure backend selection

UTF's semadraw compositor has several optional backends — Vulkan,
X11, Wayland, and bsdinput. On a fresh FreeBSD install without
the supporting ports, attempting to build any of these fails with
"unable to find dynamic system library" errors. The fix is to
record an explicit backend selection in `.config` before
building.

For a bare-metal PGSD test machine running the drawfs backend
exclusively, all four optional backends should be off:

```
sh configure.sh
```

In the dialog, leave all checkboxes unchecked and confirm.
`configure.sh` writes `.config` in the repo root with the
selections. `build.sh` and `install.sh` read `.config`
automatically.

You can also write `.config` directly without running the
interactive script:

```
cat > .config <<'EOF'
SEMADRAW_VULKAN=false
SEMADRAW_X11=false
SEMADRAW_WAYLAND=false
SEMADRAW_BSDINPUT=false
DRAWFS_DRM=false
EOF
```

To enable a backend later, install its libraries
(`vulkan-headers + vulkan-loader` for Vulkan, `libX11` for X11,
`libwayland-client` for Wayland, `libinput + libudev-devd` for
bsdinput, `drm-kmod` headers for the drawfs DRM/KMS backend),
then re-run `sh configure.sh` and toggle the relevant boxes.

**Verify:**

```
sh configure.sh --show
```

Expect to see the current configuration printed. If the file
does not exist, configure.sh tells you so; do not proceed
until `.config` is written.

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

## Step 7 — Load drawfs

drawfs loads automatically at next boot via `/boot/loader.conf`
(install.sh writes this). To load it now without rebooting:

```
sudo kldload drawfs
```

**Verify:**

```
kldstat | grep drawfs
```

If `kldload drawfs` fails, run `dmesg | tail -50` and read the
error.

inputfs is *not* loaded here. inputfs is loaded by its rc.d service,
which is started in Step 8. inputfs cannot be loaded via
`/boot/loader.conf` (see Hazard 1) and must wait until `/var/run`
is mounted.

## Step 8 — Start UTF services

```
sudo service inputfs start
sudo service semaaud start
sudo service semainput start
sudo service semadraw start
```

Or use the all-in-one script:

```
sudo sh start.sh
```

The order matters: inputfs publishes `/var/run/sema/input/{state,events}`
that semadrawd opens at startup, and semaaud publishes the audio clock
that semadrawd reads. Starting in the order above produces a
correctly-initialised stack. install.sh sets `BEFORE: semadraw semainput`
on the inputfs rc.d script and `BEFORE:` chains on the others, so
`rcorder(8)` enforces the same order at boot — the explicit ordering
above is for the manual case.

**Verify:**

```
kldstat | grep -E "drawfs|inputfs"
service semaaud status
service semainput status
service semadraw status
ls /var/run/sema/clock /var/run/sema/input/state /var/run/sema/input/events
```

Both kernel modules should be listed, all daemons should report
running, and the shared-memory regions should exist.

## Step 9 — Run something

```
sudo /usr/local/bin/semadraw-term --scale 2
```

(Or `sudo semadraw/zig-out/bin/semadraw-term --scale 2` if you
skipped the install step.)

A terminal should appear on the framebuffer. Mouse and keyboard
should respond. If they don't, see Hazard 2.

If kernel log messages flash across the screen behind the
terminal — boot output, daemon startup lines, occasional dmesg
entries — that's the FreeBSD console (vt(4)) writing to the
same framebuffer drawfs is presenting on. To silence it for
the current session:

```
sudo conscontrol mute on
```

This is a workaround, not a fix. See Hazard 7 for the longer
explanation, and BACKLOG.md AD-10 for the structural item that
will eventually make this unnecessary.

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

inputfs is loaded by its dedicated rc.d service, installed by
`install.sh` to `/usr/local/etc/rc.d/inputfs`. The script declares
`REQUIRE: FILESYSTEMS` and `BEFORE: semadraw semainput`, so
`rcorder(8)` runs `kldload inputfs` after `/var/run` is mounted
(no early-boot crash) and before the daemons that consume the
inputfs ring.

The service is enabled in `/etc/rc.conf` as `inputfs_enable="YES"`
during install. To start it without rebooting:

```
sudo service inputfs start
```

Older installs of UTF and an earlier draft of this hazard
recommended adding `kldload inputfs` to `/etc/rc.local`. That
recipe is superseded by the rc.d service. If you have an
`/etc/rc.local` line from a previous install, remove it; the
rc.d service is the supported path.

The kernel-side fix that would let inputfs load from
`loader.conf` (defer the publication kthread's first mkdir
until rootfs is mounted via `mountroothold_register`, or
refuse to load when the `cold` flag is set) is its own
backlog item, not landed.

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

### Hazard 6 — Building without `.config` on a fresh FreeBSD install

`semadraw`'s build defaults attempt to enable some optional
backends (Vulkan, X11, bsdinput) when no `.config` file is
present. On a fresh FreeBSD install without the supporting
ports, the link step then fails with errors like:

```
error: unable to find dynamic system library 'vulkan' ...
error: unable to find dynamic system library 'X11' ...
error: unable to find dynamic system library 'input' ...
error: unable to find dynamic system library 'udev' ...
```

The fix is to write `.config` before building, with all
optional backends explicitly disabled. Step 3.5 covers this.

A related symptom: missing `rsync` causes `drawfs/build.sh`
and `inputfs/build.sh` to fail at the install step with
`rsync: not found`. rsync is not in FreeBSD base; install it
explicitly per Step 2.

If you hit either failure mode mid-install, the fix is in the
build inputs (write `.config`, install `rsync`); no system
state needs to be unwound. Re-run `sudo sh install.sh`.

### Hazard 7 — Kernel console writes to the same framebuffer

When semadraw-term (or any drawfs client) draws to the EFI
framebuffer, the FreeBSD console (vt(4)) is still writing to
that same physical memory. Boot messages, daemon startup output,
and any dmesg entries written after semadrawd takes over will
flash across the screen behind the UTF surface. Typing into
semadraw-term may also produce visible artifacts as vt(4)
redraws its scrollback.

This is not a UTF bug per se — drawfs maps the framebuffer for
its own use but does not negotiate exclusive ownership with
vt(4). A real UTF session needs that handshake (see BACKLOG.md
AD-10). Until that lands, the workaround is to mute the console:

```
sudo conscontrol mute on
```

Effect is immediate; no semadraw-term restart needed. To
re-enable kernel console output later:

```
sudo conscontrol mute off
```

The mute setting does not persist across reboots. If you want
it on at every boot, add to `/etc/rc.local`:

```
conscontrol mute on
```

Note that muting the console hides legitimate kernel diagnostic
output — panics, driver warnings, etc. — so do this only on a
machine where you have SSH access to read dmesg from another
session.

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
