# UTF — Unified Temporal Fabric

UTF is a graphics, audio, and input stack for FreeBSD. It draws windows, routes
sound, and handles mice, keyboards, and touch — all coordinated against a
single audio-driven clock so audio and video stay in sync by construction
rather than by luck. Install it if you're building a FreeBSD desktop or media
application and want these three things to work together as one system.

---

## Requirements

Before you install, confirm your machine meets all of the following. UTF will
not run on Linux or macOS.

| Requirement | Minimum | Notes |
| --- | --- | --- |
| Operating system | FreeBSD 15 | Earlier versions are not supported. |
| Kernel sources | Installed | Needed to build the `drawfs` kernel module. |
| Zig | 0.15 | Used to build the userspace daemons and orchestrate the overall build. |
| C toolchain | base system | Already present on FreeBSD. |
| Root access | Yes | Required for `install`, and for loading the kernel module. |

Check your versions:

```sh
uname -r          # should report 15.x
zig version       # should report 0.15 or newer
ls /usr/src/sys   # kernel sources should be present
```

If any of these fail, stop and resolve them first.

---

## Install

```sh
git clone https://github.com/pgsdf/UTF.git
cd UTF
zig build                         # compile everything
zig build test                    # run per-subsystem and integration tests
sudo zig build install --prefix /usr/local
```

That's the whole install. `zig build` orchestrates all four userspace daemons
and the `drawfs` kernel module; `zig build install` stages binaries, the
kernel module, rc.d scripts, devfs rules, and default config into the prefix
following FreeBSD `hier(7)`:

| Artifact | Installed to |
| --- | --- |
| Daemons (`chronofs`, `semaaud`, `semainput`, `semadrawd`) | `/usr/local/sbin/` |
| `drawfs.ko` | `/boot/modules/` |
| rc.d scripts | `/usr/local/etc/rc.d/` |
| devfs rules | `/usr/local/etc/devfs.rules.d/` |
| Default config | `/usr/local/etc/utf/` |
| `utf-up` / `utf-down` wrappers | `/usr/local/sbin/` |

Without `--prefix`, everything stages under `zig-out/` so you can inspect the
tree before a system-wide install.

---

## Bring the stack up

Enable the services in `/etc/rc.conf`:

```sh
sysrc chronofs_enable=YES
sysrc semaaud_enable=YES
sysrc semainput_enable=YES
sysrc semadrawd_enable=YES
```

Then, either reboot, or bring the stack up immediately:

```sh
sudo utf-up
```

`utf-up` loads the `drawfs` kernel module and starts the daemons in dependency
order (chronofs first, semadrawd last). It delegates each start to `service(8)`
so boot-time and interactive startup share one code path.

---

## Verify

```sh
kldstat | grep drawfs     # module is loaded
service chronofs status   # daemon is running
service semaaud status
service semainput status
service semadrawd status
chrono_dump               # shows timestamped events from all three
                          # consumers against the shared audio clock
```

If `chrono_dump` shows events from `semadrawd`, `semaaud`, and `semainput`
advancing monotonically against a common timeline, the fabric is coherent and
you're done.

---

## Bring the stack down

```sh
sudo utf-down
```

This stops the daemons in reverse dependency order and unloads the kernel
module. For a clean uninstall, follow with:

```sh
cd UTF
sudo zig build uninstall --prefix /usr/local   # removes staged files
sudo sysrc -x chronofs_enable
sudo sysrc -x semaaud_enable
sudo sysrc -x semainput_enable
sudo sysrc -x semadrawd_enable
```

---

## Troubleshooting

**`zig build` fails in `drawfs` with missing kernel headers**
Kernel sources aren't installed. `pkg install freebsd-src-sys` or fetch them
to `/usr/src`, then re-run.

**`zig build` fails with "unsupported Zig version"**
Your Zig is older than 0.15. Check with `zig version`; install from
https://ziglang.org/download/ or `pkg install zig-devel`.

**`utf-up` reports `/dev/draw is not present`**
The `drawfs` kernel module failed to load. Check `dmesg` for the reason;
common causes are a kernel ABI mismatch after an update (`zig build` again
against current sources) or the module file missing from `/boot/modules/`.

**`semadrawd` starts but reports permission denied on `/dev/draw`**
The default devfs permissions are `0600 root:wheel`. Either run `semadrawd`
as root, or enable the installed devfs ruleset:
`sysrc devfs_system_ruleset=utf-drawfs && service devfs restart`, after
adding your user to the `utf` group.

**A daemon exits immediately with no error**
Stale socket or pidfile in `/var/run/utf/` from a previous unclean shutdown.
Remove the relevant file and retry, or run with `-v` for verbose diagnostics.

More cases in `docs/troubleshooting.md`.
