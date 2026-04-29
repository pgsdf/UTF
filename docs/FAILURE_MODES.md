# UTF Failure Modes

Status: Stated, 2026-04-29.

This document catalogs the runtime failure modes of UTF
substrates. Each entry names a mode, describes what triggers
it, gives the log signal an operator can grep for, states
how UTF responds, and explains how to recover.

The catalog is meant for operators and contributors. It is
not exhaustive: software bugs (assertion failures, kernel
panics from broken hardware, build errors) are out of scope
here. Those are bugs to fix, not modes to document. What is
in scope is the set of runtime conditions UTF deliberately
handles, where the response is part of the design rather
than an accident.

The modes are grouped by substrate. Within each group, modes
are ordered roughly by frequency (most common first).

## chronofs

### Clock file absent at reader startup

**Trigger.** A reader (semadraw, semainput, or chronofs
diagnostic tool) opens the clock at `/var/run/sema/clock`
before semaaud has started.

**Signal.** No log line; `Clock.init(path)` returns a
`Clock` in invalid state.

**Response.** `Clock.isValid()` returns false on every
reader. All reads return 0. Consumers that derive from
`samples_written` see 0 samples elapsed, which produces
zero-length intervals and time-snapping behaviour rather
than divisions by zero.

**Recovery.** Start semaaud. The clock file appears,
`clock_valid` flips to 1, all readers see live data on
the next read. No reader-side restart is required.

### Audio xrun (sample skip)

**Trigger.** OSS reports an underrun when semaaud's stream
worker writes faster than the device can drain (or slower,
during a starvation event). The PCM sample counter advances
without a corresponding wall-clock advance, or vice versa.

**Signal.** semaaud logs the xrun event in its event
stream; an entry appears in semaaud's runtime state file
under `/tmp/draw/audio/<target>/last-event`.

**Response.** The clock keeps reporting `samples_written`
as the canonical position. Readers that derive a wall-clock
time from samples experience a jump (forward or backward)
proportional to the xrun. Consumers that handle this
explicitly (semadraw's frame scheduler, per Thoughts.md)
apply the three graphics strategies (frame interpolation,
frame skipping, time snapping) to absorb the discontinuity.

**Recovery.** xruns are transient. The clock continues
advancing once the audio stream recovers. No operator
action is required for occasional xruns; chronic xruns
indicate a buffer-size or scheduling configuration problem
that should be investigated separately.

### Clock writer (semaaud) exits unexpectedly

**Trigger.** The semaaud daemon crashes, is killed, or
exits cleanly without a graceful clock teardown.

**Signal.** No automatic signal at the clock-region level:
`clock_valid` remains 1 (it is never reset once set), and
`samples_written` stops advancing.

**Response.** Readers cannot distinguish "clock paused"
from "clock writer dead" by inspecting the region alone.
A consumer that needs to detect this either polls
`samples_written` for staleness (last value vs current
value over a known interval) or reads semaaud's pidfile
under `/var/run/utf/semaaud.pid` and verifies the process
is alive.

**Recovery.** Restart semaaud via `service semaaud
restart`. The clock writer reattaches to the existing
file, resets `samples_written` for a new stream, and
flips `clock_valid` back to 1 on the next stream begin.

## inputfs

### drawfs not loaded at inputfs MOD_LOAD

**Trigger.** inputfs loads before drawfs, or drawfs is
not loaded at all.

**Signal.**
```
inputfs: drawfs sysctl hw.drawfs.efifb.width unavailable; using defaults
inputfs: D.3 transform inactive (geometry not available); pointer reports raw accumulated deltas
```

**Response.** Stage D.2 geometry-read falls back to
conservative defaults (1024x768). Stage D.3 sees
`inputfs_geom_known == 0`, leaves `transform_active = 0`
in the state header, and runs the pointer accumulator
unclamped (Stage C semantics preserved). Pointer events
carry raw accumulated deltas that grow without bound.

**Recovery.** Load drawfs first
(`kldload drawfs`), then unload and reload inputfs. The
geometry read succeeds at MOD_LOAD, transform_active flips
to 1, the pointer is seeded at the display centre.

### Focus file absent (compositor not running)

**Trigger.** inputfs loads with no compositor running, so
`/var/run/sema/input/focus` does not exist.

**Signal.**
```
inputfs: focus file /var/run/sema/input/focus not present (compositor not running?); will retry
```

**Response.** The focus kthread retries periodically.
inputfs operations continue: pointer events accumulate,
publish to state and events regions normally. All events
get `session_id = 0` because the focus cache stays
invalid (D.4 routing falls through). No leave/enter
synthesised. Bit-for-bit compatible with pre-D.4 behaviour
for consumers that read events.

**Recovery.** Start the compositor (`service semadrawd
start`). The compositor creates the focus file. inputfs's
next refresh tick reads it, marks the cache valid, and
subsequent events carry derived session_ids.

### Focus file mid-update (seqlock odd)

**Trigger.** inputfs reads the focus file while the
compositor is mid-write, captured as an odd seqlock
counter.

**Signal.** No log line; the condition is observed and
handled silently.

**Response.** The narrow helpers
(`inputfs_focus_resolve_pointer`,
`inputfs_focus_keyboard_session`) return `session_id = 0`
for that report. The next kthread refresh re-reads the
file; if the writer has finished, the new read is
consistent and routing resumes.

**Recovery.** Self-healing. No operator action required.

### vn_open of state or events file fails

**Trigger.** The `/var/run/sema` tree is not writable
(e.g. tmpfs full, mount point missing, filesystem
read-only).

**Signal.**
```
inputfs: vn_open(/var/run/sema/input/state) failed: <errno> (continuing without file sync)
inputfs: vn_open(/var/run/sema/input/events) failed: <errno> (continuing without events file sync)
```

**Response.** inputfs marks the corresponding
`*_vp = NULL`, the kthread silently skips file syncs for
that region. The kernel's live in-memory buffer stays
correct and continues to receive event publications, but
no userspace consumer can read them. Module load
otherwise succeeds; HID device attachment continues
normally.

**Recovery.** Fix the underlying condition (free space on
tmpfs, mount the right filesystem, remount writable),
then unload and reload inputfs. The vn_open succeeds on
the second attempt.

### VOP_SETATTR fails after vn_open

**Trigger.** Per ADR 0013, inputfs stamps uid/gid/mode on
publication files via `VOP_SETATTR` after `vn_open`. If
the underlying filesystem rejects the operation (rare on
tmpfs, possible on exotic mounts), the call returns
non-zero.

**Signal.**
```
inputfs: VOP_SETATTR(<path>) failed: <errno> (file remains with vn_open default attributes)
```

**Response.** The file stays open and writable; the
kthread continues syncing to it. Attributes remain
whatever `vn_open` set (typically root:wheel:0600 from
the mode argument, but possibly looser if the filesystem
applied umask or other mutations). The mismatch with
intended attributes is logged; consumers that fail to
open the file get EACCES, which is the expected failure
path for misconfiguration.

**Recovery.** Diagnose the underlying filesystem
behaviour. tmpfs honours VOP_SETATTR; if the mount is on
something else, evaluate whether that filesystem is
appropriate for `/var/run/sema/`.

### HID device hotplug (unplug during active session)

**Trigger.** A user unplugs a USB keyboard or mouse
mid-session.

**Signal.** Standard FreeBSD hidbus detach lines, plus:
```
inputfs: device <slot> detached (slot zeroed)
```

**Response.** The detach handler clears the device slot
in the state region's device inventory, decrements
`device_count`. If the unplugged device was the only
keyboard or only pointer, subsequent reports of that
class stop arriving. The state region's `pointer_x` /
`pointer_y` retain their last value (the cursor does not
reset). No spurious leave/enter is synthesised.

**Recovery.** Replug or attach a different device of the
same class. The new device gets a new slot and starts
contributing reports. If the unplugged device returns,
its identity_hash matches the existing slot pattern but
the slot has been zeroed; it gets a fresh slot.

### HID device hotplug (plug during active session)

**Trigger.** A user plugs a new USB input device.

**Signal.** Standard FreeBSD hidbus attach lines, plus:
```
inputfs: device <slot> attached: vendor=0x<...> product=0x<...> roles=0x<...>
```

**Response.** The attach handler allocates a free slot
in the state region, populates the slot fields, emits a
`lifecycle.attach` event. Reports from the new device
contribute to the global cursor / keyboard accumulator
immediately.

**Recovery.** Self-handled. No operator action.

### Module unload mid-operation

**Trigger.** `kldunload inputfs` while pointer or
keyboard events are arriving.

**Signal.** Standard kldunload sequence. dmesg shows the
module unloading.

**Response.** MOD_UNLOAD detaches all hidbus children
(stopping new reports), tears down the kthread, closes
publication file vnodes, and frees module-global memory.
In-flight reports are dropped silently; the partially
written state region is left as-is on disk (publication
files persist on tmpfs).

**Recovery.** Reload inputfs (`kldload inputfs.ko`).
Module re-attaches all HID devices, recreates the
publication regions (truncating the existing files), and
resumes.

## drawfs

### EFI framebuffer init fails (no preload metadata)

**Trigger.** drawfs loads on a system that did not pass
EFI framebuffer information through to the kernel
(missing `efi_fb` preload, BIOS boot, or unusual loader
config).

**Signal.**
```
drawfs: EFI framebuffer init failed
drawfs: DRM init failed, falling back to swap
```

**Response.** drawfs loads with no display backend.
Surface composition still works in software; surfaces
are kept in vm_objects but never blitted to a physical
display. semadraw can still run and process SDCS
streams; no pixels reach a screen.

**Recovery.** Boot via the FreeBSD EFI loader with EFI
framebuffer metadata, or load a working DRM driver
before drawfs. Reload drawfs after the change.

### sysctl hw.drawfs.efifb.* unavailable

**Trigger.** Same as above (or drawfs not loaded at
all). Consumers that read these sysctls (notably inputfs
at MOD_LOAD via Stage D.2) cannot get geometry.

**Signal.** Consumer-side log lines naming the missing
sysctl.

**Response.** Each consumer falls back to its own
default. inputfs uses 1024x768 and leaves
`transform_active = 0` (see "drawfs not loaded at
inputfs MOD_LOAD" above).

**Recovery.** Same as above.

## semadraw

### Client disconnects mid-frame

**Trigger.** A SDCS client's IPC socket closes (process
exit, network drop on remote transport, explicit
`client.disconnect`).

**Signal.**
```
client <id> disconnected
client_disconnected event emitted
```

**Response.** The compositor surface registry releases
the client's surface allocations after a deferred
free (the registry borrowed slices into the client's
`sdcs_buffer`; freeing the borrow before the registry
finishes a render pass would cause use-after-free, which
the deferred-free path prevents). Compositor heartbeats
(`frame_complete`) continue across the disconnect.

**Recovery.** Self-handled. The client may reconnect
with a new session.

### Compositor cannot open `/dev/draw`

**Trigger.** drawfs kernel module is not loaded when
semadrawd starts.

**Signal.** rc.d's `semadrawd_prestart` precondition
check fires:
```
/dev/draw is not present; is the drawfs kernel module loaded?
```
and `service semadrawd start` exits non-zero before
launching the daemon.

**Response.** semadrawd does not start. The system
stays in its previous state; no half-running compositor.

**Recovery.** `kldload drawfs`, then
`service semadrawd start`.

### Surface count exceeds compositor limit

**Trigger.** A pathological client (or many cooperating
clients) creates surfaces faster than they are reaped.

**Signal.** Compositor logs a per-client surface limit
warning when the soft cap is approached, errors when
the hard cap is reached.

**Response.** New surface-create requests get rejected
with an error code; existing surfaces continue to
render. The misbehaving client is not killed, but its
new requests fail until it reaps.

**Recovery.** Reap surfaces in the offending client.
The cap is configurable via
`hw.drawfs.max_surfaces` for global limits.

## semaaud

### OSS device disappears mid-stream

**Trigger.** USB audio device unplug, ALSA kernel module
unload, or `/dev/dsp*` device removal.

**Signal.** semaaud logs the OSS error from its stream
worker; the runtime state file's `last-event` records
the failure.

**Response.** The stream worker stops. Sample counter
stops advancing. `clock_valid` remains 1
(it is never reset), but `samples_written` flatlines.
Frame schedulers in semadraw observe time as paused and
apply time-snapping per Thoughts.md drift handling.

**Recovery.** Reattach an audio device, then restart
semaaud (`service semaaud restart`). The clock resumes
on the next stream begin.

## Generic operational

### tmpfs at /var/run fills up

**Trigger.** Some other process on the system fills
`/var/run` (UTF's publication files are a few KB to
~70 KB each, well below the size that would cause this
on a typical tmpfs).

**Signal.** UTF processes that try to create or extend
files under `/var/run/sema/` log ENOSPC errors per the
inputfs vn_open mode above.

**Response.** Affected publishers fall back to in-memory
operation (kernel side: kthread skips file syncs;
userspace side: createFile returns ENOSPC and the
publisher exits with an error). Already-open files are
unaffected.

**Recovery.** Free space on `/var/run`, then reload the
affected modules and restart the affected daemons.

### Multiple inputfs instances loaded

**Trigger.** Operator loads inputfs twice, possibly
with different paths or configurations.

**Signal.** kldload reports the second load as
"module already loaded"; no second instance is created.

**Response.** Only the first-loaded inputfs is active.
The second load is a no-op.

**Recovery.** Not applicable; the situation does not
arise. inputfs is a singleton kernel module by
construction.

## Notes

This catalog grew out of an audit of actual log strings,
fallback paths, and recovery code in each substrate. It
is meant as a living document: when a new failure mode is
handled in code, it should land here in the same commit
or a follow-up. Modes that are documented but lack
handling code are acceptable as a "known issue" entry but
should be tagged as such; the catalog should not promise
behaviour the code does not deliver.

The structure deliberately avoids prescribing operator
runbooks beyond the immediate recovery step. Specific
operational procedures (escalation, alerting thresholds,
maintenance windows) belong to the operator, not to UTF.

Related documents:

- `docs/Thoughts.md`: the temporal-substrate framing,
  including drift handling and the three graphics
  strategies.
- `docs/UTF_ARCHITECTURAL_DISCIPLINE.md`: the
  replace/accept/remove discipline that informs which
  failure modes UTF chooses to handle versus delegate
  to the platform.
- `inputfs/docs/adr/0013-publication-permissions.md`:
  the threat model that informs the permission-denied
  failure mode for unauthorized consumers.
