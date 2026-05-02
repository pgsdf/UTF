/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage C.3: event ring publication, layered on Stage C.2's
 * state region publication. The kernel publishes two shared-
 * memory regions under /var/run/sema/input/:
 *
 *   /var/run/sema/input/state   per shared/INPUT_STATE.md
 *   /var/run/sema/input/events  per shared/INPUT_EVENTS.md
 *
 * State is the materialised view (seqlock semantics, full-buffer
 * sync per dirty cycle). Events is an ordered delta stream
 * (per-slot seq for the lock-free reader protocol, partial
 * writes per event slot plus header).
 *
 * Architecture (Option B from BACKLOG Stage C kernel-side notes):
 *
 *   1. The module maintains an 11,328-byte live state buffer
 *      and a 65,600-byte live event ring buffer in kernel memory.
 *
 *   2. The interrupt path (inputfs_intr) updates the live state
 *      buffer in place under inputfs_state_mtx (MTX_SPIN, safe
 *      from interrupt context) and publishes corresponding events
 *      to the live ring buffer using inputfs_events_publish.
 *      State updates increment a seqlock pre/post each batch;
 *      events use the per-slot seq protocol from INPUT_EVENTS.md.
 *
 *   3. After updating, inputfs_intr sets the appropriate dirty
 *      flag (inputfs_state_dirty, inputfs_events_dirty, or both)
 *      and wakes the kthread worker. The wakeup channel is
 *      &inputfs_state_dirty (used as a unified channel for both).
 *
 *   4. The kthread worker (inputfs_state_worker) sleeps on the
 *      unified channel. When woken, it syncs whichever buffers
 *      are dirty: full-buffer write for state (~11 KB), partial
 *      write for events (one slot at 64 bytes plus a header
 *      update of 64 bytes). vn_rdwr is called from kthread
 *      context (illegal from interrupt context per FreeBSD's
 *      locking rules).
 *
 *   5. Userspace consumers mmap the file(s) shared and see updates
 *      via shared/src/input.zig's StateReader and
 *      EventRingReader. The seqlock retry loop on the state
 *      reader handles mid-write observations during the kthread's
 *      vn_rdwr; the events ring's per-slot seq protocol does the
 *      same for ring slots.
 *
 * Stage C.3 emits a small subset of the event types specified in
 * INPUT_EVENTS.md:
 *
 *   pointer.motion              from boot-protocol mouse reports
 *   pointer.button_down/_up     from button-bit transitions
 *   device_lifecycle.attach     from inputfs_attach
 *   device_lifecycle.detach     from inputfs_detach
 *
 * Keyboard, touch, and pen events are deferred to Stage C.3.x or
 * Stage D (descriptor-driven parsing). ts_sync is left zero;
 * chronofs integration is a follow-on (see ADR 0011 measurement
 * substrate).
 *
 * Lock order: sc_mtx (MTX_DEF, per-softc) before
 * inputfs_state_mtx (MTX_SPIN, module-global). Acquire in this
 * order to avoid deadlock; release in reverse.
 *
 * /var/run/sema/input/ must exist; the module attempts to
 * create it but tolerates failure (the live buffer is still
 * maintained, just not synced to disk; userspace StateReader.init
 * sees an absent file and returns the documented absent state).
 *
 * Reference drivers consulted (from FreeBSD source):
 *   sys/dev/hid/hms.c    (HID mouse, modern)
 *   sys/dev/hid/hkbd.c   (HID keyboard, modern)
 *   sys/dev/hid/hidbus.c (HID bus driver, descriptor caching)
 *   sys/kern/kern_kthread.c (kthread_add reference)
 *   sys/kern/vfs_vnops.c    (vn_open, vn_rdwr, vn_close)
 *
 * System Model: inputfs is mutually exclusive with hms, hkbd,
 * hgame, hcons, hsctrl, utouch, hpen, and the hidmap framework
 * per ADR 0007. UTF Mode assumes the competing drivers are
 * absent at boot. Additionally, /var/run is expected to be
 * tmpfs per the project README; non-tmpfs backing filesystems
 * are not supported for verification.
 *
 * This file is part of the UTF project. See:
 *   docs/UTF_ARCHITECTURAL_DISCIPLINE.md
 *   inputfs/docs/inputfs-proposal.md
 *   inputfs/docs/foundations.md
 *   inputfs/docs/adr/0001-module-charter.md
 *   inputfs/docs/adr/0002-shared-memory-regions.md
 *   inputfs/docs/adr/0007-hidbus-attachment.md
 *   inputfs/docs/adr/0008-hid-descriptor-fetch.md
 *   inputfs/docs/adr/0009-interrupt-handler-registration.md
 *   inputfs/docs/adr/0010-role-classification.md
 *   shared/INPUT_STATE.md
 *
 * Target: FreeBSD 15.0-RELEASE.
 */

#include <sys/param.h>
#include <sys/systm.h>
#include <sys/kernel.h>
#include <sys/module.h>
#include <sys/bus.h>
#include <sys/malloc.h>
#include <sys/mutex.h>
#include <sys/proc.h>
#include <sys/kthread.h>
#include <sys/namei.h>
#include <sys/vnode.h>
#include <sys/fcntl.h>
#include <sys/uio.h>
#include <sys/syscallsubr.h>
#include <sys/sysctl.h>
#include <sys/endian.h>
#include <sys/time.h>

#include <machine/atomic.h>

#include <dev/hid/hid.h>
#include <dev/hid/hidbus.h>

#include "inputfs_parser.h"

MALLOC_DEFINE(M_INPUTFS, "inputfs", "inputfs report buffers");

/*
 * Publication file ownership and mode (ADR 0013).
 *
 * Files created under /var/run/sema/input/ are stamped with
 * these attributes immediately after vn_open. Defaults are
 * root:wheel:0600, matching drawfs's existing convention for
 * its cdev. Operators on multi-user systems can relax to
 * group-readable by raising dev_mode (e.g. 0640) and setting
 * dev_gid to a deployment group (e.g. operator). Tunable from
 * /boot/loader.conf or live via sysctl(8).
 *
 * uid_t and gid_t are u32 in FreeBSD; expose as int because
 * sysctl(9) does not take an unsigned u32 macro and uid -1 has
 * no useful meaning here. mode_t is small enough that int is
 * fine for the storage.
 */
static SYSCTL_NODE(_hw, OID_AUTO, inputfs, CTLFLAG_RW | CTLFLAG_MPSAFE,
    0, "inputfs driver parameters");

static int inputfs_dev_uid = 0;
SYSCTL_INT(_hw_inputfs, OID_AUTO, dev_uid, CTLFLAG_RWTUN,
    &inputfs_dev_uid, 0,
    "Publication file owner UID (applied at module load)");

static int inputfs_dev_gid = 0;
SYSCTL_INT(_hw_inputfs, OID_AUTO, dev_gid, CTLFLAG_RWTUN,
    &inputfs_dev_gid, 0,
    "Publication file group GID (applied at module load)");

static int inputfs_dev_mode = 0600;
SYSCTL_INT(_hw_inputfs, OID_AUTO, dev_mode, CTLFLAG_RWTUN,
    &inputfs_dev_mode, 0,
    "Publication file permissions (applied at module load)");

/*
 * Publication enable/disable tunable (ADR 0012 Stage D.5).
 *
 * Default 1 (publication active). Set to 0 to gate the
 * substrate off without unloading the module: the kthread
 * stops syncing in-memory buffers to the publication files
 * and writes valid=0 to both file headers so readers detect
 * the substrate as inactive (the same code path as before
 * MOD_LOAD finished). The interrupt path keeps updating the
 * in-memory buffers, so re-enabling exports the current
 * pointer / device state immediately rather than a stale
 * snapshot from the moment of disable.
 *
 * Edge-detected by the kthread: a 1->0 transition writes
 * valid=0 once; a 0->1 transition writes valid=1 once and
 * forces a full re-sync. Steady-state values cost one int
 * read per kthread tick.
 *
 * Useful for: stopping all input event flow without
 * unloading the kernel module (debugging consumer races,
 * isolating substrate from the rest of the system, clean
 * shutdown ordering during system stop).
 */
static int inputfs_enable = 1;
SYSCTL_INT(_hw_inputfs, OID_AUTO, enable, CTLFLAG_RWTUN,
    &inputfs_enable, 0,
    "Publication enable: 1 = active (default), 0 = gated off");

/*
 * Per-report debug logging gate (AD-13.1).
 *
 * Default 0 (silent). When set to 1, inputfs_intr emits a
 * device_printf for every HID report received, formatted as:
 *
 *     inputfsN: inputfs: report id=0xRR len=L data=B0 B1 ... BN
 *
 * Useful during Stage B/C bring-up to confirm the interrupt
 * path produces the expected report shapes; harmful in
 * production because it emits to /dev/console for every
 * keystroke and pointer report. With vt(4) active the spam
 * displaces the login prompt and any UTF surface; with
 * vt(4) muted the spam is silent but the per-call CPU cost
 * (sprintf, console-lock, cnputs) still runs on the
 * interrupt path and adds latency.
 *
 * Pre-AD-13.1 the print was unconditional; AD-13.1 makes it
 * opt-in. Operators reproducing a report-decode issue can
 * still enable it at runtime:
 *
 *     sysctl hw.inputfs.debug_reports=1
 *
 * and disable it again after the diagnostic:
 *
 *     sysctl hw.inputfs.debug_reports=0
 *
 * No restart, no module reload.
 */
static int inputfs_debug_reports = 0;
SYSCTL_INT(_hw_inputfs, OID_AUTO, debug_reports, CTLFLAG_RWTUN,
    &inputfs_debug_reports, 0,
    "Per-report device_printf in interrupt handler: 0 = silent (default), 1 = verbose");


/*
 * Role bitmask (Stage B.5, per ADR 0010 Decision section 1).
 */
#define INPUTFS_ROLE_POINTER    (1u << 0)
#define INPUTFS_ROLE_KEYBOARD   (1u << 1)
#define INPUTFS_ROLE_TOUCH      (1u << 2)
#define INPUTFS_ROLE_PEN        (1u << 3)
#define INPUTFS_ROLE_LIGHTING   (1u << 4)

/*
 * State region constants (Stage C.2, per shared/INPUT_STATE.md).
 * These must match shared/src/input.zig exactly; verification is
 * by inputdump (C.4) reading the file the kernel writes here.
 */
#define INPUTFS_STATE_PATH      "/var/run/sema/input/state"
#define INPUTFS_STATE_DIR       "/var/run/sema/input"
#define INPUTFS_STATE_PARENT    "/var/run/sema"

#define INPUTFS_STATE_MAGIC     0x494E5354u  /* "INST" big-endian mnemonic */
#define INPUTFS_STATE_VERSION   1u
#define INPUTFS_STATE_SLOT_COUNT 32u

#define INPUTFS_HEADER_SIZE         64u
#define INPUTFS_DEV_SLOT_SIZE       160u
#define INPUTFS_KB_SLOT_SIZE        64u
#define INPUTFS_TOUCH_SLOT_SIZE     128u

#define INPUTFS_DEV_OFF             (INPUTFS_HEADER_SIZE)
#define INPUTFS_KB_OFF              (INPUTFS_DEV_OFF + \
    INPUTFS_STATE_SLOT_COUNT * INPUTFS_DEV_SLOT_SIZE)
#define INPUTFS_TOUCH_OFF           (INPUTFS_KB_OFF + \
    INPUTFS_STATE_SLOT_COUNT * INPUTFS_KB_SLOT_SIZE)
#define INPUTFS_STATE_SIZE          (INPUTFS_TOUCH_OFF + \
    INPUTFS_STATE_SLOT_COUNT * INPUTFS_TOUCH_SLOT_SIZE)

/* Header field offsets. */
#define OFF_MAGIC           0
#define OFF_VERSION         4
#define OFF_VALID           5
#define OFF_SLOT_COUNT      6
#define OFF_SEQLOCK         8
#define OFF_LAST_SEQ        16
#define OFF_BOOT_OFFSET     24
#define OFF_PTR_X           32
#define OFF_PTR_Y           36
#define OFF_PTR_BUTTONS     40
#define OFF_DEVICE_COUNT    44
#define OFF_TOUCH_COUNT     46
#define OFF_TRANSFORM_ACTIVE 48

/* Device slot field offsets (relative to slot start). */
#define DEV_OFF_DEVICE_ID       0
#define DEV_OFF_IDENTITY_HASH   16
#define DEV_OFF_ROLES           32
#define DEV_OFF_USB_VENDOR      36
#define DEV_OFF_USB_PRODUCT     38
#define DEV_OFF_NAME            40
#define DEV_OFF_LIGHTING_CAPS   104

/* Sentinel for "no state slot assigned" (e.g. inventory full). */
#define INPUTFS_NO_STATE_SLOT   0xFFu

/*
 * Event ring constants (Stage C.3, per shared/INPUT_EVENTS.md).
 * Single-producer multiple-consumer ring with per-slot seq for the
 * lock-free reader protocol. Writer-side serialization is via the
 * shared inputfs_state_mtx (same lock that protects state updates).
 */
#define INPUTFS_EVENTS_PATH     "/var/run/sema/input/events"

#define INPUTFS_EVENTS_MAGIC    0x494E5645u  /* "INVE" big-endian mnemonic */
#define INPUTFS_EVENTS_VERSION  1u
#define INPUTFS_EVENTS_HEADER_SIZE  64u
#define INPUTFS_EVENTS_SLOT_SIZE    64u
#define INPUTFS_EVENTS_SLOT_COUNT   1024u
#define INPUTFS_EVENTS_SIZE     (INPUTFS_EVENTS_HEADER_SIZE + \
    INPUTFS_EVENTS_SLOT_COUNT * INPUTFS_EVENTS_SLOT_SIZE)

/* Events ring header field offsets. */
#define EV_OFF_MAGIC            0
#define EV_OFF_VERSION          4
#define EV_OFF_VALID            5
#define EV_OFF_EVENT_SIZE       6
#define EV_OFF_SLOT_COUNT       8
#define EV_OFF_WRITER_SEQ       16
#define EV_OFF_EARLIEST_SEQ     24

/* Event slot field offsets (relative to slot start). */
#define EV_SLOT_OFF_SEQ         0
#define EV_SLOT_OFF_TS_ORDERING 8
#define EV_SLOT_OFF_TS_SYNC     16
#define EV_SLOT_OFF_DEVICE_SLOT 24
#define EV_SLOT_OFF_SOURCE_ROLE 26
#define EV_SLOT_OFF_EVENT_TYPE  27
#define EV_SLOT_OFF_FLAGS       28
#define EV_SLOT_OFF_PAYLOAD     32

/*
 * Focus region constants (Stage D.1, per shared/INPUT_FOCUS.md
 * and ADR 0003).
 *
 * The compositor writes this file; inputfs reads it. The
 * publication directory is shared with the state and event
 * regions. Layout: 64-byte header + 256 surface slots * 20
 * bytes = 5184 bytes total.
 */
#define INPUTFS_FOCUS_PATH      "/var/run/sema/input/focus"

#define INPUTFS_FOCUS_MAGIC     0x4946434Fu  /* "IFCO" big-endian mnemonic */
#define INPUTFS_FOCUS_VERSION   1u
#define INPUTFS_FOCUS_HEADER_SIZE  64u
#define INPUTFS_FOCUS_SLOT_SIZE     20u
#define INPUTFS_FOCUS_SLOT_COUNT    256u
#define INPUTFS_FOCUS_SIZE      (INPUTFS_FOCUS_HEADER_SIZE + \
    INPUTFS_FOCUS_SLOT_COUNT * INPUTFS_FOCUS_SLOT_SIZE)

/* Focus header field offsets. */
#define FC_OFF_MAGIC            0
#define FC_OFF_VERSION          4
#define FC_OFF_VALID            5
#define FC_OFF_SLOT_COUNT       6
#define FC_OFF_SEQLOCK          8
#define FC_OFF_KB_FOCUS         12
#define FC_OFF_PTR_GRAB         16
#define FC_OFF_SURFACE_COUNT    20

/* Focus surface slot field offsets (relative to slot start). */
#define FC_SLOT_OFF_SESSION_ID  0
#define FC_SLOT_OFF_X           4
#define FC_SLOT_OFF_Y           8
#define FC_SLOT_OFF_WIDTH       12
#define FC_SLOT_OFF_HEIGHT      16

/*
 * Refresh period in ticks. The kthread wakes either on a sync
 * dirty signal or after this many ticks elapse, whichever comes
 * first; on each wake it does an opportunistic focus refresh.
 * 100ms is fast enough to track focus changes responsively
 * without producing observable cost. Must be set at runtime
 * since hz is not a compile-time constant; see kthread loop.
 */

/* Source role values (per INPUT_EVENTS.md). */
#define INPUTFS_SOURCE_POINTER          1u
#define INPUTFS_SOURCE_KEYBOARD         2u
#define INPUTFS_SOURCE_TOUCH            3u
#define INPUTFS_SOURCE_PEN              4u
#define INPUTFS_SOURCE_LIGHTING         5u
#define INPUTFS_SOURCE_DEVICE_LIFECYCLE 6u

/* Event type values per source. */
#define INPUTFS_POINTER_MOTION          1u
#define INPUTFS_POINTER_BUTTON_DOWN     2u
#define INPUTFS_POINTER_BUTTON_UP       3u
#define INPUTFS_POINTER_SCROLL          4u
#define INPUTFS_POINTER_ENTER           5u
#define INPUTFS_POINTER_LEAVE           6u
#define INPUTFS_KEYBOARD_KEY_DOWN       1u
#define INPUTFS_KEYBOARD_KEY_UP         2u
#define INPUTFS_LIFECYCLE_ATTACH        1u
#define INPUTFS_LIFECYCLE_DETACH        2u

/* Flag bits. */
#define INPUTFS_FLAG_SYNTHESISED        (1u << 0)
#define INPUTFS_FLAG_COALESCED          (1u << 1)

/* Synthetic device sentinel for events not associated with a device. */
#define INPUTFS_SYNTHETIC_DEVICE        0xFFFFu

/*
 * Focus snapshot types (Stage D.1).
 *
 * inputfs_focus_snapshot is the kernel-side analogue of the Zig
 * FocusSnapshot in shared/src/input.zig. Populated from the
 * cached focus buffer by inputfs_focus_snapshot(); consumed in
 * Stage D.4 by the routing path to compute session_id stamping
 * and pointer.enter / pointer.leave synthesis.
 *
 * `valid` indicates whether the cache currently holds a snapshot
 * that satisfied focus_valid == 1 at the time of the last
 * refresh. Consumers must check this before using any other
 * field; an invalid snapshot means routing should fall back to
 * "no session" (event published with session_id = 0).
 *
 * `surfaces` always contains INPUTFS_FOCUS_SLOT_COUNT entries.
 * `surface_count` is the number of populated entries; entries
 * beyond surface_count are zeroed but should not be consulted.
 */
struct inputfs_focus_surface {
	uint32_t	session_id;
	int32_t		x;
	int32_t		y;
	uint32_t	width;
	uint32_t	height;
};

struct inputfs_focus_snapshot {
	int		valid;
	uint32_t	keyboard_focus;
	uint32_t	pointer_grab;
	uint16_t	surface_count;
	struct inputfs_focus_surface surfaces[INPUTFS_FOCUS_SLOT_COUNT];
};

/*
 * struct inputfs_parser_state is declared in
 * inputfs_parser.h (included near the top of this file).
 * The four pure-parser functions
 * (inputfs_pointer_locate, inputfs_extract_pointer,
 * inputfs_keyboard_locate, inputfs_extract_keyboard) live in
 * inputfs_parser.c. Stage AD-9.2a moved them out so the
 * fuzzing harness in inputfs/test/fuzz/ can compile them
 * in isolation. inputfs_keyboard_diff_emit stays in this
 * file because it mixes parser concerns with event-emission
 * concerns (it calls inputfs_focus_keyboard_session and
 * inputfs_events_publish, and reads sc_state_slot); it is
 * out of fuzz scope per ADR 0014.
 *
 * inputfs_softc embeds the parser state as the sc_parser
 * field declared below in the softc definition.
 */

/*
 * Per-device softc. Stage B.4 added interrupt buffer fields;
 * Stage B.5 added the per-device role bitmask;
 * Stage C.2 adds the state-region slot index assigned at attach;
 * Stage D.0a adds the cached HID locations for descriptor-driven
 * pointer event extraction (now in struct inputfs_parser_state).
 */
struct inputfs_softc {
	device_t	sc_dev;
	struct mtx	sc_mtx;

	const void	*sc_rdesc;
	hid_size_t	 sc_rdesc_len;

	uint32_t	sc_input_items;
	uint32_t	sc_output_items;
	uint32_t	sc_feature_items;
	uint32_t	sc_collection_depth;

	uint8_t		*sc_ibuf;
	hid_size_t	 sc_ibuf_size;
	uint8_t		 sc_report_id;

	uint8_t		 sc_roles;

	/*
	 * State region slot index (Stage C.2). Set by
	 * inputfs_state_alloc_slot at attach, cleared by
	 * inputfs_state_release_slot at detach. Value is in
	 * [0, INPUTFS_STATE_SLOT_COUNT) when valid, or
	 * INPUTFS_NO_STATE_SLOT when the inventory was full.
	 */
	uint8_t		 sc_state_slot;

	/*
	 * Pointer-location cache, keyboard-location cache, and
	 * previous-keyboard-state buffer. Populated by
	 * inputfs_pointer_locate / inputfs_keyboard_locate at
	 * attach. Read by the extract path on every interrupt.
	 *
	 * Extracted into struct inputfs_parser_state (defined
	 * above) so the parser code can be exercised in
	 * userspace by AD-9.2's fuzzing harness without
	 * pulling in softc dependencies (mtx, sysctls, the
	 * device tree). See ADR 0014. The four pure-parser
	 * functions (inputfs_pointer_locate,
	 * inputfs_extract_pointer, inputfs_keyboard_locate,
	 * inputfs_extract_keyboard) take struct
	 * inputfs_parser_state * directly;
	 * inputfs_keyboard_diff_emit still takes struct
	 * inputfs_softc * because it mixes parser concerns
	 * with event-emission concerns and is out of fuzz
	 * scope per ADR 0014.
	 */
	struct inputfs_parser_state	 sc_parser;
};

/*
 * Module-global state region context (Stage C.2).
 *
 * inputfs_state_buf is the canonical 11,328-byte live state
 * buffer. The interrupt path updates it under inputfs_state_mtx;
 * the kthread worker copies it to the file under no lock (the
 * seqlock handles reader observability of mid-write).
 *
 * inputfs_state_slot_used tracks which device slots are
 * occupied. It is a parallel structure to the state buffer's
 * device array because reading the file's slot at offset
 * (DEV_OFF + N*DEV_SLOT_SIZE + DEV_OFF_DEVICE_ID) just to
 * check whether it is zero would mean reading from the file
 * we are also writing to; keeping a separate bitmap is simpler.
 */
static uint8_t			*inputfs_state_buf;
static struct mtx		 inputfs_state_mtx;
static uint64_t			 inputfs_state_seq;
static uint32_t			 inputfs_state_slot_used; /* bitmap, 32 bits for 32 slots */
static int			 inputfs_state_dirty;

static struct vnode		*inputfs_state_vp;

/*
 * Event ring module-global state (Stage C.3). The ring lives in
 * a separate module-global buffer; inputfs_events_writer_seq is
 * the running sequence counter (header field maintained by
 * inputfs_events_publish). inputfs_events_synced tracks the
 * highest sequence number successfully written to disk by the
 * kthread, enabling partial writes (slot + header per sync).
 */
static uint8_t			*inputfs_events_buf;
static uint64_t			 inputfs_events_writer_seq;
static uint64_t			 inputfs_events_synced;
static int			 inputfs_events_dirty;
static struct vnode		*inputfs_events_vp;

static struct proc		*inputfs_kthread_proc;
static int			 inputfs_kthread_run;
static int			 inputfs_kthread_done;

/*
 * Focus region context (Stage D.1).
 *
 * inputfs_focus_buf is a 5184-byte cached copy of the focus
 * file maintained by the kthread. The kthread re-reads the file
 * once per refresh tick (~100 ms) under inputfs_focus_mtx and
 * copies the bytes verbatim, including the seqlock counter.
 * inputfs_focus_snapshot() then performs the seqlock retry on
 * the cache: this works because the cache is a snapshot of the
 * underlying file at a moment when no kernel writer was active
 * (the only writer is the userspace compositor). The seqlock
 * still provides correctness if the file was being updated
 * during the kthread's vn_rdwr.
 *
 * inputfs_focus_vp is the open vnode for the focus file, or
 * NULL when the file is absent (compositor not running) or has
 * not yet been opened. The kthread retries the open on each
 * refresh tick until success.
 *
 * inputfs_focus_cache_valid is set when the cache holds a
 * snapshot whose magic and version checks passed and whose
 * focus_valid byte was 1. Cleared when the file is closed,
 * disappears, or fails validation.
 *
 * inputfs_focus_logged_absent suppresses repeated "file not
 * found" log lines: log once per attach cycle, not once per
 * refresh tick.
 */
static uint8_t			*inputfs_focus_buf;
static struct mtx		 inputfs_focus_mtx;
static struct vnode		*inputfs_focus_vp;
static int			 inputfs_focus_cache_valid;
static int			 inputfs_focus_logged_absent;

/*
 * Display geometry (Stage D.2).
 *
 * Read from drawfs's hw.drawfs.efifb.* sysctls at module load
 * via kernel_sysctlbyname. If the sysctls are absent (drawfs
 * not loaded, or built without EFI framebuffer support) we fall
 * back to a conservative default so inputfs remains loadable
 * standalone for development and testing. Per ADR 0012
 * §Decision 1, this avoids a hard cross-module dependency on
 * drawfs while still letting inputfs learn the actual display
 * dimensions when drawfs is present.
 *
 * inputfs_geom_known is 1 when the sysctls were read
 * successfully (regardless of whether they returned the default
 * or real geometry); 0 if the sysctl read failed entirely.
 *
 * The geometry is captured once at module load and not refreshed.
 * Display geometry does not change at runtime in the EFI
 * framebuffer model (no hotplug, no resolution change). If
 * future graphics backends require runtime geometry updates,
 * this becomes a periodic refresh in the kthread, mirroring the
 * focus cache.
 */
#define INPUTFS_GEOM_DEFAULT_WIDTH      1024u
#define INPUTFS_GEOM_DEFAULT_HEIGHT     768u
#define INPUTFS_GEOM_DEFAULT_STRIDE     (INPUTFS_GEOM_DEFAULT_WIDTH * 4u)
#define INPUTFS_GEOM_DEFAULT_BPP        32u

static u_int			 inputfs_geom_width;
static u_int			 inputfs_geom_height;
static u_int			 inputfs_geom_stride;
static u_int			 inputfs_geom_bpp;
static int			 inputfs_geom_known;

/*
 * Pointer routing state (Stage D.4).
 *
 * Tracks the session_id under the cursor across consecutive
 * pointer events so leave / enter pairs can be synthesised when
 * the cursor crosses a surface boundary. Reset to 0 (no
 * session) at module load and after the cursor leaves all
 * surfaces. Protected by inputfs_state_mtx, which is already
 * held during pointer event publication.
 */
static uint32_t			 inputfs_pointer_session_prev;

/*
 * Match table for HID_PNP_INFO. Matches HID Top-Level
 * Collections for Generic Desktop keyboard, mouse, and pointer.
 */
static const struct hid_device_id __used inputfs_devs[] = {
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_KEYBOARD) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_MOUSE) },
	{ HID_TLC(HUP_GENERIC_DESKTOP, HUG_POINTER) },
};

/*
 * Little-endian byte writers. The state region's wire format
 * is little-endian (per shared/INPUT_STATE.md and clock.zig
 * convention); these helpers serialize values into the live
 * buffer at byte-precise offsets without alignment assumptions.
 */
static inline void
inputfs_put_u8(uint8_t *buf, size_t off, uint8_t v)
{
	buf[off] = v;
}

static inline void
inputfs_put_u16le(uint8_t *buf, size_t off, uint16_t v)
{
	buf[off + 0] = (uint8_t)(v & 0xff);
	buf[off + 1] = (uint8_t)((v >> 8) & 0xff);
}

static inline void
inputfs_put_u32le(uint8_t *buf, size_t off, uint32_t v)
{
	buf[off + 0] = (uint8_t)(v & 0xff);
	buf[off + 1] = (uint8_t)((v >> 8) & 0xff);
	buf[off + 2] = (uint8_t)((v >> 16) & 0xff);
	buf[off + 3] = (uint8_t)((v >> 24) & 0xff);
}

static inline void
inputfs_put_i32le(uint8_t *buf, size_t off, int32_t v)
{
	inputfs_put_u32le(buf, off, (uint32_t)v);
}

static inline void
inputfs_put_u64le(uint8_t *buf, size_t off, uint64_t v)
{
	inputfs_put_u32le(buf, off + 0, (uint32_t)(v & 0xffffffffu));
	inputfs_put_u32le(buf, off + 4, (uint32_t)((v >> 32) & 0xffffffffu));
}

static inline uint32_t
inputfs_get_u32le(const uint8_t *buf, size_t off)
{
	return ((uint32_t)buf[off + 0]) |
	       ((uint32_t)buf[off + 1] << 8) |
	       ((uint32_t)buf[off + 2] << 16) |
	       ((uint32_t)buf[off + 3] << 24);
}

static inline int32_t
inputfs_get_i32le(const uint8_t *buf, size_t off)
{
	return (int32_t)inputfs_get_u32le(buf, off);
}

/*
 * inputfs_state_init_buf -- initialize the live state buffer
 * with the static header fields. Called once at module load,
 * before the kthread starts and before any device attaches.
 */
static void
inputfs_state_init_buf(uint8_t *buf)
{
	memset(buf, 0, INPUTFS_STATE_SIZE);
	inputfs_put_u32le(buf, OFF_MAGIC, INPUTFS_STATE_MAGIC);
	inputfs_put_u8(buf, OFF_VERSION, (uint8_t)INPUTFS_STATE_VERSION);
	inputfs_put_u8(buf, OFF_VALID, 0);
	inputfs_put_u16le(buf, OFF_SLOT_COUNT, (uint16_t)INPUTFS_STATE_SLOT_COUNT);
	inputfs_put_u32le(buf, OFF_SEQLOCK, 0);
	inputfs_put_u64le(buf, OFF_LAST_SEQ, 0);
	inputfs_put_u64le(buf, OFF_BOOT_OFFSET, 0);
}

/*
 * inputfs_state_seqlock_begin / _end -- bracket a batch update
 * to the live buffer. Must be called with inputfs_state_mtx
 * held. The seqlock counter is at OFF_SEQLOCK; it is even
 * when the buffer is consistent, odd while a write is in
 * progress.
 */
static inline void
inputfs_state_seqlock_begin(void)
{
	uint32_t cur;
	cur = inputfs_get_u32le(inputfs_state_buf, OFF_SEQLOCK);
	inputfs_put_u32le(inputfs_state_buf, OFF_SEQLOCK, cur + 1);
}

static inline void
inputfs_state_seqlock_end(void)
{
	uint32_t cur;
	cur = inputfs_get_u32le(inputfs_state_buf, OFF_SEQLOCK);
	inputfs_put_u32le(inputfs_state_buf, OFF_SEQLOCK, cur + 1);
}

/*
 * inputfs_state_mark_dirty -- request a sync to file. Sets the
 * dirty flag and wakes the kthread worker. Must be called with
 * inputfs_state_mtx held; wakeup() itself is interrupt-safe.
 */
static inline void
inputfs_state_mark_dirty(void)
{
	inputfs_state_dirty = 1;
	wakeup(&inputfs_state_dirty);
}

/*
 * inputfs_state_alloc_slot -- find a free slot in the device
 * inventory bitmap and mark it used. Returns the slot index,
 * or INPUTFS_NO_STATE_SLOT if all slots are occupied. Must be
 * called with inputfs_state_mtx held.
 */
static uint8_t
inputfs_state_alloc_slot(void)
{
	uint8_t i;
	for (i = 0; i < INPUTFS_STATE_SLOT_COUNT; i++) {
		if ((inputfs_state_slot_used & (1u << i)) == 0) {
			inputfs_state_slot_used |= (1u << i);
			return (i);
		}
	}
	return (INPUTFS_NO_STATE_SLOT);
}

static void
inputfs_state_release_slot(uint8_t slot)
{
	if (slot < INPUTFS_STATE_SLOT_COUNT)
		inputfs_state_slot_used &= ~(1u << slot);
}

/*
 * inputfs_state_count_devices -- count populated device slots.
 * Used to update OFF_DEVICE_COUNT after attach/detach. Must be
 * called with inputfs_state_mtx held.
 */
static uint16_t
inputfs_state_count_devices(void)
{
	uint16_t count = 0;
	uint32_t mask = inputfs_state_slot_used;
	while (mask) {
		count += (uint16_t)(mask & 1u);
		mask >>= 1;
	}
	return (count);
}

/*
 * inputfs_state_put_device -- write a device descriptor into
 * the live buffer at the given slot. Caller holds
 * inputfs_state_mtx. Caller is also responsible for the
 * seqlock_begin/end bracket and for marking dirty.
 *
 * device_id is derived from the device address provided by the
 * device tree; identity_hash is left zero (Stage D will
 * populate it from a stable hashing scheme).
 */
static void
inputfs_state_put_device(uint8_t slot, device_t dev, uint8_t roles)
{
	const struct hid_device_info *hw;
	size_t base;

	if (slot >= INPUTFS_STATE_SLOT_COUNT)
		return;

	base = INPUTFS_DEV_OFF + (size_t)slot * INPUTFS_DEV_SLOT_SIZE;

	/* device_id: 16 bytes derived from device unit number plus
	 * a marker. The first byte is 0x01 to distinguish from the
	 * all-zero "unused slot" sentinel. The next byte is the
	 * unit number, which is unique within this inputfs instance.
	 * The remainder is zero. Stage D may revise this to a
	 * stable hash of the underlying USB path. */
	memset(inputfs_state_buf + base + DEV_OFF_DEVICE_ID, 0, 16);
	inputfs_state_buf[base + DEV_OFF_DEVICE_ID + 0] = 0x01;
	inputfs_state_buf[base + DEV_OFF_DEVICE_ID + 1] =
	    (uint8_t)(device_get_unit(dev) & 0xff);

	/* identity_hash: zeroed for Stage C; Stage D populates. */
	memset(inputfs_state_buf + base + DEV_OFF_IDENTITY_HASH, 0, 16);

	/* roles: from softc, widened to u32 per the spec. */
	inputfs_put_u32le(inputfs_state_buf, base + DEV_OFF_ROLES,
	    (uint32_t)roles);

	/* USB vendor and product. */
	hw = hid_get_device_info(dev);
	if (hw != NULL) {
		inputfs_put_u16le(inputfs_state_buf,
		    base + DEV_OFF_USB_VENDOR, hw->idVendor);
		inputfs_put_u16le(inputfs_state_buf,
		    base + DEV_OFF_USB_PRODUCT, hw->idProduct);
	} else {
		inputfs_put_u16le(inputfs_state_buf,
		    base + DEV_OFF_USB_VENDOR, 0);
		inputfs_put_u16le(inputfs_state_buf,
		    base + DEV_OFF_USB_PRODUCT, 0);
	}

	/* name: 64-byte field, null-padded.
	 *
	 * Use device_get_desc(dev), which returns a stable, printable
	 * string maintained by FreeBSD's bus framework (the same
	 * string that appears in dmesg's `<...>` block at attach).
	 * This is more reliable than hid_get_device_info()->name,
	 * which is not consistently populated across HID device
	 * types in FreeBSD 15: for many devices it is left as
	 * uninitialized stack/heap bytes, so any non-zero first byte
	 * is misleading. */
	memset(inputfs_state_buf + base + DEV_OFF_NAME, 0, 64);
	{
		const char *desc = device_get_desc(dev);
		if (desc != NULL && desc[0] != '\0') {
			size_t desc_len = strlen(desc);
			if (desc_len > 63)
				desc_len = 63;
			memcpy(inputfs_state_buf + base + DEV_OFF_NAME,
			    desc, desc_len);
		}
	}

	/* lighting_caps: 56-byte field, zero (no lighting in Stage C). */
	memset(inputfs_state_buf + base + DEV_OFF_LIGHTING_CAPS, 0, 56);
}

static void
inputfs_state_clear_device(uint8_t slot)
{
	size_t base;
	if (slot >= INPUTFS_STATE_SLOT_COUNT)
		return;
	base = INPUTFS_DEV_OFF + (size_t)slot * INPUTFS_DEV_SLOT_SIZE;
	memset(inputfs_state_buf + base, 0, INPUTFS_DEV_SLOT_SIZE);
}

/*
 * inputfs_state_update_pointer -- accumulate a pointer delta
 * into the live buffer's global pointer position fields. Caller
 * holds inputfs_state_mtx.
 *
 * Stage C.2 published raw device-space coordinates with no
 * coordinate transform applied: each pointer report contributed
 * its dx/dy to the accumulator without bounds.
 *
 * Stage D.3 introduces the coordinate transform: when display
 * geometry is known (inputfs_geom_known == 1), the new
 * accumulated position is clamped to [0, geom_width-1] x
 * [0, geom_height-1] before being written. This places the
 * pointer in compositor pixel space, suitable for direct use
 * as surface-map coordinates. The state header byte
 * transform_active is set to 1 in inputfs_state_apply_geom to
 * advertise this. When geometry is not known (inputfs_geom_known
 * == 0; drawfs sysctls were absent at module load), the
 * accumulator runs unclamped exactly as in Stage C and
 * transform_active is left at 0.
 *
 * Note: dx/dy in event payloads remain raw deltas regardless of
 * whether clamping happens. Consumers that want raw deltas read
 * the event payload's dx/dy fields; consumers that want
 * compositor-space coordinates read pointer_x/pointer_y from the
 * state region or the x/y fields of motion events. This split
 * preserves both intentions per ADR 0012.
 */
static void
inputfs_state_update_pointer(int32_t dx, int32_t dy, uint32_t buttons)
{
	int32_t cur_x, cur_y, new_x, new_y;
	cur_x = inputfs_get_i32le(inputfs_state_buf, OFF_PTR_X);
	cur_y = inputfs_get_i32le(inputfs_state_buf, OFF_PTR_Y);
	new_x = cur_x + dx;
	new_y = cur_y + dy;

	if (inputfs_geom_known) {
		/* Clamp to [0, width-1] x [0, height-1]. */
		if (new_x < 0)
			new_x = 0;
		else if ((u_int)new_x >= inputfs_geom_width)
			new_x = (int32_t)(inputfs_geom_width - 1);
		if (new_y < 0)
			new_y = 0;
		else if ((u_int)new_y >= inputfs_geom_height)
			new_y = (int32_t)(inputfs_geom_height - 1);
	}

	inputfs_put_i32le(inputfs_state_buf, OFF_PTR_X, new_x);
	inputfs_put_i32le(inputfs_state_buf, OFF_PTR_Y, new_y);
	inputfs_put_u32le(inputfs_state_buf, OFF_PTR_BUTTONS, buttons);
}

/*
 * inputfs_state_apply_geom -- Stage D.3.
 *
 * Called from MOD_LOAD after inputfs_geom_read has populated the
 * geometry globals. Updates the state header to reflect the
 * coordinate-transform regime:
 *
 *   - If geometry is known (drawfs sysctls were readable),
 *     transform_active is set to 1 to advertise that
 *     pointer_x/pointer_y are in compositor pixel space, and
 *     the pointer is seeded at the centre of the display
 *     (geom_width/2, geom_height/2). The seeded position
 *     replaces the zero from inputfs_state_init_buf so the
 *     pointer does not start in the top-left corner.
 *
 *   - If geometry is not known, transform_active stays 0 and
 *     the pointer accumulator runs unclamped exactly as in
 *     Stage C; the pointer position remains (0, 0). This
 *     avoids advertising "compositor pixel space" when we
 *     are clamping to the wrong rectangle (the conservative
 *     fallback default of 1024x768).
 *
 * Called from MOD_LOAD context before the kthread starts; no
 * spin lock is held. The state region's seqlock is not modified
 * here because no consumer is reading at this point.
 */
static void
inputfs_state_apply_geom(void)
{
	if (inputfs_geom_known) {
		inputfs_put_u8(inputfs_state_buf, OFF_TRANSFORM_ACTIVE, 1);
		inputfs_put_i32le(inputfs_state_buf, OFF_PTR_X,
		    (int32_t)(inputfs_geom_width / 2u));
		inputfs_put_i32le(inputfs_state_buf, OFF_PTR_Y,
		    (int32_t)(inputfs_geom_height / 2u));
		printf("inputfs: D.3 transform active; pointer seeded "
		    "at (%u, %u)\n",
		    inputfs_geom_width / 2u, inputfs_geom_height / 2u);
	} else {
		inputfs_put_u8(inputfs_state_buf, OFF_TRANSFORM_ACTIVE, 0);
		printf("inputfs: D.3 transform inactive (geometry not "
		    "available); pointer reports raw accumulated deltas\n");
	}
}

/*
 * inputfs_state_advance_seq -- advance last_sequence and write
 * it into the live buffer. Caller holds inputfs_state_mtx and
 * has already opened the seqlock bracket.
 */
static void
inputfs_state_advance_seq(void)
{
	inputfs_state_seq++;
	inputfs_put_u64le(inputfs_state_buf, OFF_LAST_SEQ, inputfs_state_seq);
}

/*
 * inputfs_apply_attrs -- stamp uid/gid/mode on a freshly-opened
 * publication file vnode (ADR 0013).
 *
 * Called immediately after a successful vn_open(O_CREAT) on a
 * publication file. Applies inputfs_dev_uid, inputfs_dev_gid,
 * and inputfs_dev_mode via VOP_SETATTR while the vnode is still
 * exclusively locked from vn_open. The caller is responsible
 * for VOP_UNLOCK afterwards.
 *
 * Failures are logged but non-fatal. If VOP_SETATTR fails the
 * file remains with whatever attributes vn_open established
 * (typically root:wheel:0644 or whatever umask permits), which
 * is more permissive than intended but does not break the
 * substrate. The kthread will still sync data to it; consumers
 * that cannot read it will get EACCES at open time, which is
 * the expected failure path for a misconfigured deployment
 * rather than for a substrate fault.
 */
static void
inputfs_apply_attrs(struct vnode *vp, struct thread *td, const char *path)
{
	struct vattr vattr;
	int error;

	if (vp == NULL)
		return;

	VATTR_NULL(&vattr);
	vattr.va_uid = (uid_t)inputfs_dev_uid;
	vattr.va_gid = (gid_t)inputfs_dev_gid;
	vattr.va_mode = (mode_t)(inputfs_dev_mode & 07777);

	error = VOP_SETATTR(vp, &vattr, td->td_ucred);
	if (error != 0) {
		printf("inputfs: VOP_SETATTR(%s) failed: %d "
		    "(file remains with vn_open default attributes)\n",
		    path, error);
	}
}

/*
 * inputfs_state_open_file -- attempt to create the parent
 * directories and open the state file for writing. On success,
 * inputfs_state_vp is set to the vnode and the file is sized
 * to INPUTFS_STATE_SIZE. On failure, inputfs_state_vp is left
 * NULL and the kthread silently skips file syncs.
 */
static void
inputfs_state_open_file(struct thread *td)
{
	struct nameidata nd;
	int error;

	/* Try to create parents; ignore errors (likely EEXIST). */
	(void)kern_mkdirat(td, AT_FDCWD,
	    __DECONST(char *, INPUTFS_STATE_PARENT),
	    UIO_SYSSPACE, 0755);
	(void)kern_mkdirat(td, AT_FDCWD,
	    __DECONST(char *, INPUTFS_STATE_DIR),
	    UIO_SYSSPACE, 0755);

	/* Open the state file: create if missing, truncate, write-only.
	 * vn_open takes a pointer to the flags because it may modify
	 * them in place (e.g. clearing O_CREAT after a successful
	 * create). The variable must therefore live on the stack. */
	{
		int flags = FWRITE | O_CREAT | O_TRUNC;
		NDINIT(&nd, LOOKUP, FOLLOW, UIO_SYSSPACE,
		    __DECONST(char *, INPUTFS_STATE_PATH));
		error = vn_open(&nd, &flags, inputfs_dev_mode & 07777, NULL);
	}
	if (error != 0) {
		printf("inputfs: vn_open(%s) failed: %d "
		    "(continuing without file sync)\n",
		    INPUTFS_STATE_PATH, error);
		inputfs_state_vp = NULL;
		return;
	}

	NDFREE_PNBUF(&nd);
	inputfs_state_vp = nd.ni_vp;

	/* Stamp ownership and mode per ADR 0013. The vnode is still
	 * exclusively locked from vn_open; apply attrs before unlock. */
	inputfs_apply_attrs(inputfs_state_vp, td, INPUTFS_STATE_PATH);

	VOP_UNLOCK(inputfs_state_vp);
	printf("inputfs: opened state file %s (size=%lu bytes, "
	    "uid=%d gid=%d mode=%04o)\n",
	    INPUTFS_STATE_PATH, (unsigned long)INPUTFS_STATE_SIZE,
	    inputfs_dev_uid, inputfs_dev_gid,
	    inputfs_dev_mode & 07777);
}

static void
inputfs_state_close_file(struct thread *td)
{
	if (inputfs_state_vp == NULL)
		return;
	(void)vn_close(inputfs_state_vp, FWRITE, NOCRED, td);
	inputfs_state_vp = NULL;
}

/*
 * inputfs_state_sync_to_file -- write the live buffer to the
 * state file via vn_rdwr. Called from the kthread context, not
 * from interrupt context; vnode I/O may sleep on filesystem
 * operations and is illegal from interrupt context.
 *
 * The seqlock retry loop on the userspace side handles
 * observations of mid-write states; we make no attempt to
 * snapshot the live buffer atomically before writing. This is
 * deliberate per the seqlock model.
 */
static void
inputfs_state_sync_to_file(struct thread *td)
{
	int error;

	if (inputfs_state_vp == NULL)
		return;

	/* vn_rdwr signature (FreeBSD 15):
	 *   vn_rdwr(rw, vp, base, len, offset, segflg, ioflg,
	 *           active_cred, file_cred, aresid, td)
	 * active_cred = NOCRED (use the calling thread's cred)
	 * file_cred = NULL (no separate file-level cred)
	 * aresid = NULL (we do not need the residual byte count) */
	error = vn_rdwr(UIO_WRITE, inputfs_state_vp,
	    inputfs_state_buf, (int)INPUTFS_STATE_SIZE,
	    (off_t)0, UIO_SYSSPACE,
	    IO_UNIT | IO_SYNC, NOCRED, NULL, NULL, td);
	if (error != 0) {
		printf("inputfs: vn_rdwr write failed: %d\n", error);
	}
}

/*
 * inputfs_events_init_buf -- initialize the live events ring
 * buffer with the static header fields. Called once at module
 * load. earliest_seq starts at 1 per INPUT_EVENTS.md lifecycle:
 * "writer_seq=0, earliest_seq=1" means "no events yet, the next
 * event will be seq=1".
 */
static void
inputfs_events_init_buf(uint8_t *buf)
{
	memset(buf, 0, INPUTFS_EVENTS_SIZE);
	inputfs_put_u32le(buf, EV_OFF_MAGIC, INPUTFS_EVENTS_MAGIC);
	inputfs_put_u8(buf, EV_OFF_VERSION, (uint8_t)INPUTFS_EVENTS_VERSION);
	inputfs_put_u8(buf, EV_OFF_VALID, 0);
	inputfs_put_u16le(buf, EV_OFF_EVENT_SIZE,
	    (uint16_t)INPUTFS_EVENTS_SLOT_SIZE);
	inputfs_put_u32le(buf, EV_OFF_SLOT_COUNT, INPUTFS_EVENTS_SLOT_COUNT);
	inputfs_put_u64le(buf, EV_OFF_WRITER_SEQ, 0);
	inputfs_put_u64le(buf, EV_OFF_EARLIEST_SEQ, 1);
}

/*
 * inputfs_events_publish -- publish one event to the live ring
 * buffer. Caller holds inputfs_state_mtx (the same spin mutex
 * that protects state updates; reused for writer-side
 * serialization of the ring).
 *
 * Implements the writer protocol from INPUT_EVENTS.md
 * "Concurrency model":
 *   1. Compute next slot index
 *   2. Atomic store seq=0 to invalidate the slot for any
 *      concurrent reader.
 *   3. Write all body fields except seq.
 *   4. Atomic store the new seq, publishing the event.
 *   5. Advance writer_seq (header field) atomically.
 *   6. If wrapped, advance earliest_seq.
 *
 * The kthread worker sees inputfs_events_dirty and syncs the
 * affected slots and header to disk.
 */
static void
inputfs_events_publish(uint8_t source_role, uint8_t event_type,
    uint16_t device_slot, uint32_t flags,
    const uint8_t *payload, size_t payload_len)
{
	uint64_t new_seq;
	size_t slot_idx;
	size_t slot_base;
	struct timespec ts;

	new_seq = inputfs_events_writer_seq + 1;
	slot_idx = (size_t)(new_seq & (INPUTFS_EVENTS_SLOT_COUNT - 1));
	slot_base = INPUTFS_EVENTS_HEADER_SIZE +
	    slot_idx * INPUTFS_EVENTS_SLOT_SIZE;

	/* Step 1+2: atomic-store seq=0 first. The seq field is the
	 * synchronization point for readers; setting it to 0 makes
	 * any concurrent reader's seq1==expected check fail and
	 * causes them to retry. */
	atomic_store_rel_64(
	    (volatile uint64_t *)(inputfs_events_buf + slot_base + EV_SLOT_OFF_SEQ),
	    0);

	/* Step 3: write all body fields. */
	nanouptime(&ts);
	inputfs_put_u64le(inputfs_events_buf,
	    slot_base + EV_SLOT_OFF_TS_ORDERING,
	    (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec);
	inputfs_put_u64le(inputfs_events_buf,
	    slot_base + EV_SLOT_OFF_TS_SYNC, 0); /* chronofs deferred */
	inputfs_put_u16le(inputfs_events_buf,
	    slot_base + EV_SLOT_OFF_DEVICE_SLOT, device_slot);
	inputfs_put_u8(inputfs_events_buf,
	    slot_base + EV_SLOT_OFF_SOURCE_ROLE, source_role);
	inputfs_put_u8(inputfs_events_buf,
	    slot_base + EV_SLOT_OFF_EVENT_TYPE, event_type);
	inputfs_put_u32le(inputfs_events_buf,
	    slot_base + EV_SLOT_OFF_FLAGS, flags);

	/* Payload: zero the 32-byte field, then copy what was given. */
	memset(inputfs_events_buf + slot_base + EV_SLOT_OFF_PAYLOAD, 0, 32);
	if (payload != NULL && payload_len > 0) {
		size_t copy = payload_len > 32 ? 32 : payload_len;
		memcpy(inputfs_events_buf + slot_base + EV_SLOT_OFF_PAYLOAD,
		    payload, copy);
	}

	/* Step 4: atomic store seq with the new sequence number.
	 * After this, readers see the slot as containing event new_seq. */
	atomic_store_rel_64(
	    (volatile uint64_t *)(inputfs_events_buf + slot_base + EV_SLOT_OFF_SEQ),
	    new_seq);

	/* Step 5: advance writer_seq. */
	inputfs_events_writer_seq = new_seq;
	atomic_store_rel_64(
	    (volatile uint64_t *)(inputfs_events_buf + EV_OFF_WRITER_SEQ),
	    new_seq);

	/* Step 6: if the ring has wrapped, advance earliest_seq.
	 * After EVENTS_SLOT_COUNT events, slot 0 is being overwritten;
	 * earliest visible sequence is new_seq - SLOT_COUNT + 1. */
	if (new_seq > INPUTFS_EVENTS_SLOT_COUNT) {
		uint64_t new_earliest = new_seq - INPUTFS_EVENTS_SLOT_COUNT + 1;
		atomic_store_rel_64(
		    (volatile uint64_t *)(inputfs_events_buf + EV_OFF_EARLIEST_SEQ),
		    new_earliest);
	}

	/* Mark dirty and wake the kthread. The kthread sleeps on
	 * &inputfs_state_dirty regardless of which buffer is dirty;
	 * we use that pointer as a unified wakeup channel for both
	 * state and event updates. */
	inputfs_events_dirty = 1;
	wakeup(&inputfs_state_dirty);
}

/*
 * inputfs_events_open_file -- open the events ring file for
 * writing. Same pattern as inputfs_state_open_file. The state
 * file's parent directory creation already ran by the time we
 * reach here, so we skip the kern_mkdirat calls.
 */
static void
inputfs_events_open_file(struct thread *td)
{
	struct nameidata nd;
	int error;

	{
		int flags = FWRITE | O_CREAT | O_TRUNC;
		NDINIT(&nd, LOOKUP, FOLLOW, UIO_SYSSPACE,
		    __DECONST(char *, INPUTFS_EVENTS_PATH));
		error = vn_open(&nd, &flags, inputfs_dev_mode & 07777, NULL);
	}
	if (error != 0) {
		printf("inputfs: vn_open(%s) failed: %d "
		    "(continuing without events file sync)\n",
		    INPUTFS_EVENTS_PATH, error);
		inputfs_events_vp = NULL;
		return;
	}

	NDFREE_PNBUF(&nd);
	inputfs_events_vp = nd.ni_vp;

	/* Stamp ownership and mode per ADR 0013. The vnode is still
	 * exclusively locked from vn_open; apply attrs before unlock. */
	inputfs_apply_attrs(inputfs_events_vp, td, INPUTFS_EVENTS_PATH);

	VOP_UNLOCK(inputfs_events_vp);
	printf("inputfs: opened events file %s (size=%lu bytes, "
	    "uid=%d gid=%d mode=%04o)\n",
	    INPUTFS_EVENTS_PATH, (unsigned long)INPUTFS_EVENTS_SIZE,
	    inputfs_dev_uid, inputfs_dev_gid,
	    inputfs_dev_mode & 07777);

	/* Write the entire buffer (zero-initialized slots plus the
	 * header) so the file is the correct total size from the
	 * outset. Userspace consumers expect a 65,600-byte file
	 * regardless of how many events have been published; if we
	 * only wrote the header here, the file would grow as slots
	 * were written via partial vn_rdwr calls and userspace
	 * mmaps would span only the populated prefix. The one-time
	 * 64 KB write to tmpfs is essentially free. */
	(void)vn_rdwr(UIO_WRITE, inputfs_events_vp,
	    inputfs_events_buf, (int)INPUTFS_EVENTS_SIZE,
	    (off_t)0, UIO_SYSSPACE,
	    IO_UNIT | IO_SYNC, NOCRED, NULL, NULL, td);
}

static void
inputfs_events_close_file(struct thread *td)
{
	if (inputfs_events_vp == NULL)
		return;
	(void)vn_close(inputfs_events_vp, FWRITE, NOCRED, td);
	inputfs_events_vp = NULL;
}

/*
 * inputfs_events_sync_to_file -- write newly-published events
 * to disk via partial vn_rdwr calls.
 *
 * Strategy: write the header (writer_seq, earliest_seq update)
 * and any slots between inputfs_events_synced+1 and the current
 * writer_seq. For typical 1-event-per-sync this is two short
 * writes (one slot + the header) totalling 128 bytes. For burst
 * loads with many events between syncs, it scales linearly with
 * the number of new events.
 *
 * The header MUST be written last so userspace readers do not
 * see a writer_seq advance before the corresponding slot is
 * actually populated on disk.
 */
static void
inputfs_events_sync_to_file(struct thread *td)
{
	uint64_t synced;
	uint64_t latest;
	int error;

	if (inputfs_events_vp == NULL)
		return;

	synced = inputfs_events_synced;
	latest = inputfs_events_writer_seq;

	if (synced >= latest)
		return; /* nothing new to write */

	/* Cap how many slots we write per call so a sustained burst
	 * doesn't monopolise the kthread. The cap is the full ring;
	 * if more events accumulated than the ring holds, we'll write
	 * the whole ring (one or two orbits) and the next iteration
	 * picks up any further accumulation. */
	uint64_t to_write = latest - synced;
	if (to_write > INPUTFS_EVENTS_SLOT_COUNT)
		to_write = INPUTFS_EVENTS_SLOT_COUNT;

	/* Write the affected slots one at a time. Adjacent slots
	 * could be coalesced, but the typical case is to_write=1
	 * and the simpler code wins. */
	for (uint64_t i = 0; i < to_write; i++) {
		uint64_t seq = synced + 1 + i;
		size_t slot_idx = (size_t)(seq & (INPUTFS_EVENTS_SLOT_COUNT - 1));
		off_t off = (off_t)(INPUTFS_EVENTS_HEADER_SIZE +
		    slot_idx * INPUTFS_EVENTS_SLOT_SIZE);

		error = vn_rdwr(UIO_WRITE, inputfs_events_vp,
		    inputfs_events_buf + off,
		    (int)INPUTFS_EVENTS_SLOT_SIZE,
		    off, UIO_SYSSPACE,
		    IO_UNIT | IO_SYNC, NOCRED, NULL, NULL, td);
		if (error != 0) {
			printf("inputfs: events slot vn_rdwr failed at seq=%lu: %d\n",
			    (unsigned long)seq, error);
			return;
		}
	}

	/* Header last: writer_seq and earliest_seq updates become
	 * visible on disk after the slots they advertise. */
	error = vn_rdwr(UIO_WRITE, inputfs_events_vp,
	    inputfs_events_buf, (int)INPUTFS_EVENTS_HEADER_SIZE,
	    (off_t)0, UIO_SYSSPACE,
	    IO_UNIT | IO_SYNC, NOCRED, NULL, NULL, td);
	if (error != 0) {
		printf("inputfs: events header vn_rdwr failed: %d\n", error);
		return;
	}

	inputfs_events_synced = synced + to_write;
}

/*
 * inputfs_focus_open_file -- Stage D.1.
 *
 * Attempt to open the focus file read-only. The file is
 * compositor-written; inputfs is read-only on it. The compositor
 * may not be running yet, in which case the open fails with
 * ENOENT and we leave inputfs_focus_vp == NULL. Subsequent
 * refresh ticks will retry.
 *
 * Unlike the state and events files, inputfs does not create
 * the focus file: that is the compositor's responsibility.
 * inputfs is never the writer.
 */
static void
inputfs_focus_open_file(struct thread *td)
{
	struct nameidata nd;
	int flags = FREAD;
	int error;

	if (inputfs_focus_vp != NULL)
		return;

	NDINIT(&nd, LOOKUP, FOLLOW, UIO_SYSSPACE,
	    __DECONST(char *, INPUTFS_FOCUS_PATH));
	error = vn_open(&nd, &flags, 0, NULL);
	if (error != 0) {
		if (!inputfs_focus_logged_absent) {
			printf("inputfs: focus file %s not present "
			    "(compositor not running?); will retry\n",
			    INPUTFS_FOCUS_PATH);
			inputfs_focus_logged_absent = 1;
		}
		return;
	}

	NDFREE_PNBUF(&nd);
	inputfs_focus_vp = nd.ni_vp;
	VOP_UNLOCK(inputfs_focus_vp);
	inputfs_focus_logged_absent = 0;
	printf("inputfs: opened focus file %s\n", INPUTFS_FOCUS_PATH);
}

static void
inputfs_focus_close_file(struct thread *td)
{
	if (inputfs_focus_vp == NULL)
		return;
	(void)vn_close(inputfs_focus_vp, FREAD, NOCRED, td);
	inputfs_focus_vp = NULL;
	inputfs_focus_cache_valid = 0;
}

/*
 * inputfs_focus_refresh -- Stage D.1.
 *
 * Read the entire focus file into the cached buffer. Validates
 * magic and version; on failure, marks the cache invalid but
 * leaves the file open (the compositor may be in the middle of
 * an unusual state).
 *
 * The kthread calls this once per refresh tick. The actual
 * seqlock retry is performed by inputfs_focus_snapshot when
 * consumers (Stage D.4 routing) read the cache; refresh just
 * captures whatever bytes are in the file at the moment of read.
 *
 * Called from kthread context. May sleep on filesystem I/O.
 */
static void
inputfs_focus_refresh(struct thread *td)
{
	uint8_t scratch[INPUTFS_FOCUS_SIZE];
	int error;
	uint32_t magic;

	if (inputfs_focus_vp == NULL) {
		inputfs_focus_open_file(td);
		if (inputfs_focus_vp == NULL)
			return;
	}

	error = vn_rdwr(UIO_READ, inputfs_focus_vp,
	    scratch, (int)INPUTFS_FOCUS_SIZE,
	    (off_t)0, UIO_SYSSPACE,
	    IO_UNIT, NOCRED, NULL, NULL, td);
	if (error != 0) {
		/* File may have been deleted or filesystem in trouble.
		 * Close and let the next tick retry the open. */
		printf("inputfs: focus vn_rdwr read failed: %d "
		    "(closing, will retry)\n", error);
		inputfs_focus_close_file(td);
		return;
	}

	/* Validate magic and version before populating cache. */
	magic = inputfs_get_u32le(scratch, FC_OFF_MAGIC);
	if (magic != INPUTFS_FOCUS_MAGIC) {
		mtx_lock_spin(&inputfs_focus_mtx);
		inputfs_focus_cache_valid = 0;
		mtx_unlock_spin(&inputfs_focus_mtx);
		return;
	}
	if (scratch[FC_OFF_VERSION] != INPUTFS_FOCUS_VERSION) {
		mtx_lock_spin(&inputfs_focus_mtx);
		inputfs_focus_cache_valid = 0;
		mtx_unlock_spin(&inputfs_focus_mtx);
		return;
	}

	/* Copy bytes verbatim under the spin lock so consumers see
	 * a consistent buffer state. The seqlock counter inside the
	 * buffer captures whether the compositor was mid-update at
	 * the moment of vn_rdwr; consumers re-check on snapshot. */
	mtx_lock_spin(&inputfs_focus_mtx);
	memcpy(inputfs_focus_buf, scratch, INPUTFS_FOCUS_SIZE);
	inputfs_focus_cache_valid =
	    (scratch[FC_OFF_VALID] != 0) ? 1 : 0;
	mtx_unlock_spin(&inputfs_focus_mtx);
}

/*
 * inputfs_focus_snapshot -- Stage D.1.
 *
 * Public entry point for consumers (Stage D.4 routing) to read
 * the cached focus state. Copies fields out of the cached buffer
 * into the caller's snapshot struct.
 *
 * The cached buffer is frozen under inputfs_focus_mtx for the
 * duration of this call: the kthread cannot update it
 * concurrently. The seqlock counter inside the cached buffer
 * reflects the userspace compositor's state at the time of the
 * last kthread refresh; if the compositor was mid-update during
 * that refresh, the buffer captured an inconsistent state with
 * an odd seqlock value.
 *
 * This function therefore performs a single seqlock-validity
 * check (counter must be even); no retry loop is needed because
 * the cache will not change while we hold the lock. If the
 * cached state was inconsistent at refresh time, we return with
 * out->valid = 0 and the consumer must skip routing for this
 * event. The next kthread refresh will re-read the file and may
 * capture a consistent state.
 *
 * Returns 1 if the snapshot was populated (out->valid indicates
 * whether the data is authoritative). Returns 0 only on a NULL
 * argument; the function does not fail otherwise.
 *
 * Safe to call from interrupt context: only spin-locks and
 * memory reads, no sleeping operations.
 */
static int
inputfs_focus_snapshot(struct inputfs_focus_snapshot *out)
{
	uint32_t seqlock;
	uint16_t i;

	if (out == NULL)
		return (0);

	mtx_lock_spin(&inputfs_focus_mtx);

	if (!inputfs_focus_cache_valid) {
		out->valid = 0;
		out->keyboard_focus = 0;
		out->pointer_grab = 0;
		out->surface_count = 0;
		memset(out->surfaces, 0, sizeof(out->surfaces));
		mtx_unlock_spin(&inputfs_focus_mtx);
		return (1);
	}

	seqlock = inputfs_get_u32le(inputfs_focus_buf, FC_OFF_SEQLOCK);
	if ((seqlock & 1u) != 0) {
		/* The cached buffer captured an inconsistent state
		 * (compositor was mid-update during the kthread's
		 * vn_rdwr). Fail this snapshot; the next kthread
		 * refresh will likely capture a consistent state. */
		out->valid = 0;
		out->keyboard_focus = 0;
		out->pointer_grab = 0;
		out->surface_count = 0;
		memset(out->surfaces, 0, sizeof(out->surfaces));
		mtx_unlock_spin(&inputfs_focus_mtx);
		return (1);
	}

	out->valid = 1;
	out->keyboard_focus =
	    inputfs_get_u32le(inputfs_focus_buf, FC_OFF_KB_FOCUS);
	out->pointer_grab =
	    inputfs_get_u32le(inputfs_focus_buf, FC_OFF_PTR_GRAB);
	out->surface_count = (uint16_t)(
	    inputfs_focus_buf[FC_OFF_SURFACE_COUNT] |
	    ((uint32_t)inputfs_focus_buf[FC_OFF_SURFACE_COUNT + 1] << 8));

	for (i = 0; i < INPUTFS_FOCUS_SLOT_COUNT; i++) {
		size_t off = INPUTFS_FOCUS_HEADER_SIZE +
		    i * INPUTFS_FOCUS_SLOT_SIZE;
		out->surfaces[i].session_id = inputfs_get_u32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_SESSION_ID);
		out->surfaces[i].x = inputfs_get_i32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_X);
		out->surfaces[i].y = inputfs_get_i32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_Y);
		out->surfaces[i].width = inputfs_get_u32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_WIDTH);
		out->surfaces[i].height = inputfs_get_u32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_HEIGHT);
	}

	mtx_unlock_spin(&inputfs_focus_mtx);
	return (1);
}

/*
 * inputfs_focus_resolve_pointer -- Stage D.4.
 *
 * Narrow helper that resolves a pointer position (x, y) to the
 * session_id of the surface containing it, without copying out
 * the full focus snapshot. If pointer_grab is set in the focus
 * file, that grab session wins regardless of position. Otherwise
 * we walk the surface_map and return the first hit.
 *
 * Walks the surfaces from index 0 upward, matching the
 * compositor's z-order convention (lower index = higher z-order
 * per shared/INPUT_FOCUS.md), so the topmost surface containing
 * (x, y) is returned. If no surface contains the point, *out is
 * set to 0 (no session) and the function still returns
 * normally.
 *
 * If the focus cache is invalid (compositor not running, or
 * focus file failed validation), *out is set to 0 and the
 * function returns. Routing falls back to "no session" in that
 * case, which preserves Stage C / D.0a / D.0b semantics.
 *
 * Safe to call from interrupt context: only spin-locks and
 * memory reads.
 */
static void
inputfs_focus_resolve_pointer(int32_t x, int32_t y, uint32_t *out)
{
	uint32_t i, surface_count;
	uint32_t pointer_grab;
	uint32_t seqlock;

	if (out == NULL)
		return;
	*out = 0;

	mtx_lock_spin(&inputfs_focus_mtx);

	if (!inputfs_focus_cache_valid) {
		mtx_unlock_spin(&inputfs_focus_mtx);
		return;
	}

	seqlock = inputfs_get_u32le(inputfs_focus_buf, FC_OFF_SEQLOCK);
	if ((seqlock & 1u) != 0) {
		/* Cached buffer was captured mid-update by the
		 * userspace compositor. Treat as "no session" for
		 * this event; the next kthread refresh will likely
		 * capture a consistent state. */
		mtx_unlock_spin(&inputfs_focus_mtx);
		return;
	}

	/* pointer_grab takes precedence over surface-under-cursor:
	 * a compositor that has set a grab wants all pointer events
	 * to go to that session regardless of cursor position. */
	pointer_grab = inputfs_get_u32le(inputfs_focus_buf, FC_OFF_PTR_GRAB);
	if (pointer_grab != 0) {
		*out = pointer_grab;
		mtx_unlock_spin(&inputfs_focus_mtx);
		return;
	}

	surface_count = (uint32_t)(
	    inputfs_focus_buf[FC_OFF_SURFACE_COUNT] |
	    ((uint32_t)inputfs_focus_buf[FC_OFF_SURFACE_COUNT + 1] << 8));
	if (surface_count > INPUTFS_FOCUS_SLOT_COUNT)
		surface_count = INPUTFS_FOCUS_SLOT_COUNT;

	for (i = 0; i < surface_count; i++) {
		size_t off = INPUTFS_FOCUS_HEADER_SIZE +
		    i * INPUTFS_FOCUS_SLOT_SIZE;
		uint32_t sid = inputfs_get_u32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_SESSION_ID);
		int32_t sx = inputfs_get_i32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_X);
		int32_t sy = inputfs_get_i32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_Y);
		uint32_t sw = inputfs_get_u32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_WIDTH);
		uint32_t sh = inputfs_get_u32le(
		    inputfs_focus_buf, off + FC_SLOT_OFF_HEIGHT);

		if (sid == 0)
			continue; /* Empty slot. */
		if (x < sx || y < sy)
			continue;
		if ((uint32_t)(x - sx) >= sw)
			continue;
		if ((uint32_t)(y - sy) >= sh)
			continue;

		*out = sid;
		break;
	}

	mtx_unlock_spin(&inputfs_focus_mtx);
}

/*
 * inputfs_focus_keyboard_session -- Stage D.4.
 *
 * Narrow helper that returns the session_id of the keyboard
 * focus, without copying out the full focus snapshot.
 *
 * If the focus cache is invalid, *out is set to 0 (no session).
 *
 * Safe to call from interrupt context: only spin-locks and
 * memory reads.
 */
static void
inputfs_focus_keyboard_session(uint32_t *out)
{
	uint32_t seqlock;

	if (out == NULL)
		return;
	*out = 0;

	mtx_lock_spin(&inputfs_focus_mtx);

	if (!inputfs_focus_cache_valid) {
		mtx_unlock_spin(&inputfs_focus_mtx);
		return;
	}

	seqlock = inputfs_get_u32le(inputfs_focus_buf, FC_OFF_SEQLOCK);
	if ((seqlock & 1u) != 0) {
		mtx_unlock_spin(&inputfs_focus_mtx);
		return;
	}

	*out = inputfs_get_u32le(inputfs_focus_buf, FC_OFF_KB_FOCUS);
	mtx_unlock_spin(&inputfs_focus_mtx);
}

/*
 * inputfs_geom_read -- Stage D.2.
 *
 * Read display geometry from drawfs's hw.drawfs.efifb.* sysctls
 * via kernel_sysctlbyname. Called once at module load. On
 * success, populates inputfs_geom_{width,height,stride,bpp} and
 * sets inputfs_geom_known = 1. On failure (any sysctl absent,
 * unreadable, or returns zero), falls back to the
 * INPUTFS_GEOM_DEFAULT_* values and leaves inputfs_geom_known
 * = 0 so consumers can distinguish "fell back to defaults" from
 * "real geometry read".
 *
 * This is called from MOD_LOAD context; sleeping is permitted.
 * kernel_sysctlbyname acquires the sysctl lock and may block
 * briefly; that is acceptable in module load.
 *
 * Geometry of zero in any dimension is treated as failure
 * because drawfs returns zero when its EFI framebuffer init
 * failed (no preload metadata, no GOP, etc.). A zero-dimension
 * display is not useful for clamping pointer coordinates.
 */
static void
inputfs_geom_read(struct thread *td)
{
	u_int width = 0, height = 0, stride = 0, bpp = 0;
	size_t sz;
	int error_w, error_h, error_s, error_b;

	sz = sizeof(width);
	error_w = kernel_sysctlbyname(td, "hw.drawfs.efifb.width",
	    &width, &sz, NULL, 0, NULL, 0);
	sz = sizeof(height);
	error_h = kernel_sysctlbyname(td, "hw.drawfs.efifb.height",
	    &height, &sz, NULL, 0, NULL, 0);
	sz = sizeof(stride);
	error_s = kernel_sysctlbyname(td, "hw.drawfs.efifb.stride",
	    &stride, &sz, NULL, 0, NULL, 0);
	sz = sizeof(bpp);
	error_b = kernel_sysctlbyname(td, "hw.drawfs.efifb.bpp",
	    &bpp, &sz, NULL, 0, NULL, 0);

	if (error_w == 0 && error_h == 0 && error_s == 0 && error_b == 0 &&
	    width > 0 && height > 0) {
		inputfs_geom_width  = width;
		inputfs_geom_height = height;
		inputfs_geom_stride = stride;
		inputfs_geom_bpp    = bpp;
		inputfs_geom_known  = 1;
		printf("inputfs: display geometry from drawfs: "
		    "%ux%u stride=%u bpp=%u\n",
		    width, height, stride, bpp);
	} else {
		inputfs_geom_width  = INPUTFS_GEOM_DEFAULT_WIDTH;
		inputfs_geom_height = INPUTFS_GEOM_DEFAULT_HEIGHT;
		inputfs_geom_stride = INPUTFS_GEOM_DEFAULT_STRIDE;
		inputfs_geom_bpp    = INPUTFS_GEOM_DEFAULT_BPP;
		inputfs_geom_known  = 0;
		printf("inputfs: hw.drawfs.efifb.* sysctls unavailable "
		    "(drawfs not loaded?); using fallback geometry "
		    "%ux%u stride=%u bpp=%u\n",
		    inputfs_geom_width, inputfs_geom_height,
		    inputfs_geom_stride, inputfs_geom_bpp);
	}
}

/*
 * inputfs_state_worker -- the kthread that syncs the live
 * buffers to disk. Sleeps until either inputfs_state_dirty or
 * inputfs_events_dirty becomes true; on wake, clears both
 * flags and performs whichever syncs are needed.
 *
 * Sync rate cap: at most one sync iteration per (hz / INPUTFS_SYNC_HZ)
 * ticks. With INPUTFS_SYNC_HZ = 1000 and the FreeBSD default
 * hz=1000, that is one tick (1 ms). Both files share the same
 * cap, so a single sync iteration may write both.
 */
#define INPUTFS_SYNC_HZ 1000

/*
 * inputfs_publish_valid -- Stage D.5.
 *
 * Write the valid byte (offset 5) of both publication files
 * directly. Used by the D.5 enable/disable transition logic to
 * make the change immediately visible to readers without waiting
 * for the next dirty-driven sync. Also updates the in-memory
 * buffers so subsequent full-buffer syncs do not undo the change.
 *
 * Called from kthread context only; vnode I/O may sleep and is
 * illegal from interrupt context. Caller must not hold
 * inputfs_state_mtx.
 *
 * Failures are logged but non-fatal: if either write fails, the
 * substrate continues to run with the old valid state in the
 * file (and the matching value in the in-memory buffer, since
 * we update the buffer *after* the file write succeeds).
 */
static void
inputfs_publish_valid(struct thread *td, uint8_t valid)
{
	uint8_t b = valid;
	int error;

	if (inputfs_state_vp != NULL) {
		error = vn_rdwr(UIO_WRITE, inputfs_state_vp,
		    &b, 1, (off_t)OFF_VALID, UIO_SYSSPACE,
		    IO_UNIT | IO_SYNC, NOCRED, NULL, NULL, td);
		if (error != 0) {
			printf("inputfs: D.5 valid-byte write to state "
			    "failed: %d\n", error);
		} else {
			inputfs_state_buf[OFF_VALID] = valid;
		}
	}

	if (inputfs_events_vp != NULL) {
		error = vn_rdwr(UIO_WRITE, inputfs_events_vp,
		    &b, 1, (off_t)EV_OFF_VALID, UIO_SYSSPACE,
		    IO_UNIT | IO_SYNC, NOCRED, NULL, NULL, td);
		if (error != 0) {
			printf("inputfs: D.5 valid-byte write to events "
			    "failed: %d\n", error);
		} else {
			inputfs_events_buf[EV_OFF_VALID] = valid;
		}
	}
}

static void
inputfs_state_worker(void *arg)
{
	struct thread *td = curthread;
	int min_ticks;
	int focus_refresh_ticks;
	int do_state, do_events;
	int prev_enable, curr_enable;

	min_ticks = hz / INPUTFS_SYNC_HZ;
	if (min_ticks < 1)
		min_ticks = 1;

	/* Stage D.1: focus refresh period. 100ms target; bounded
	 * msleep_spin will wake the kthread at this interval if no
	 * dirty signal arrives sooner, and an opportunistic refresh
	 * runs on every wake. */
	focus_refresh_ticks = hz / 10;
	if (focus_refresh_ticks < 1)
		focus_refresh_ticks = 1;

	/* Stage D.5: track enable state across iterations so we can
	 * detect transitions and write valid=0/1 to the publication
	 * files exactly once per edge. Initialise to match the default
	 * tunable value so the first iteration is a steady-state read
	 * unless an operator set hw.inputfs.enable in loader.conf. */
	prev_enable = inputfs_enable ? 1 : 0;

	(void)arg;

	inputfs_state_open_file(td);
	inputfs_events_open_file(td);
	/* Stage D.1: try the focus open at startup; if the compositor
	 * is not yet running, the open will fail silently and retry
	 * on each refresh tick. */
	inputfs_focus_open_file(td);

	for (;;) {
		mtx_lock_spin(&inputfs_state_mtx);
		if (!inputfs_state_dirty && !inputfs_events_dirty &&
		    inputfs_kthread_run) {
			/* Sleep on &inputfs_state_dirty as the unified
			 * wakeup channel: both state updates and event
			 * publications wakeup() on this same pointer.
			 * msleep_spin drops and reacquires the spin
			 * mutex, allowing the interrupt path to update
			 * the live buffers while we sleep.
			 *
			 * Stage D.1: bounded by focus_refresh_ticks so
			 * the kthread wakes periodically to refresh the
			 * focus cache even when no input is flowing. A
			 * timeout return is treated identically to a
			 * dirty wake: do the opportunistic work and
			 * loop. */
			(void)msleep_spin(&inputfs_state_dirty,
			    &inputfs_state_mtx,
			    "ifssync", focus_refresh_ticks);
		}
		if (!inputfs_kthread_run) {
			mtx_unlock_spin(&inputfs_state_mtx);
			break;
		}
		do_state = inputfs_state_dirty;
		do_events = inputfs_events_dirty;
		inputfs_state_dirty = 0;
		inputfs_events_dirty = 0;
		mtx_unlock_spin(&inputfs_state_mtx);

		/* Stage D.5: detect enable/disable transitions. The
		 * sysctl tunable hw.inputfs.enable is read without a
		 * lock; that race is benign because we only act on
		 * edges and a missed edge will be picked up on the
		 * next iteration. */
		curr_enable = inputfs_enable ? 1 : 0;
		if (curr_enable != prev_enable) {
			if (curr_enable == 0) {
				/* 1 -> 0 transition: gate publication
				 * off. Write valid=0 to both files so
				 * readers see the substrate as inactive
				 * immediately. The in-memory buffers
				 * keep updating from the interrupt path
				 * so re-enabling exports current state
				 * rather than a stale snapshot. */
				inputfs_publish_valid(td, 0);
				printf("inputfs: D.5 publication gated "
				    "off (hw.inputfs.enable=0)\n");
			} else {
				/* 0 -> 1 transition: gate back on.
				 * Write valid=1 and force a full state
				 * sync so the in-memory buffer's
				 * current contents reach the file
				 * immediately. Events sync follows
				 * naturally on the next event publish. */
				inputfs_publish_valid(td, 1);
				inputfs_state_sync_to_file(td);
				printf("inputfs: D.5 publication gated "
				    "on (hw.inputfs.enable=1)\n");
			}
			prev_enable = curr_enable;
		}

		/* Stage D.5: skip publication-file syncs when gated
		 * off. The interrupt path keeps the in-memory buffers
		 * current; only the propagation to /var/run/sema/
		 * pauses. */
		if (curr_enable) {
			if (do_state)
				inputfs_state_sync_to_file(td);
			if (do_events)
				inputfs_events_sync_to_file(td);
		}

		/* Stage D.1: opportunistic focus refresh on every wake.
		 * Cheap when the file is unchanged (vn_rdwr against
		 * tmpfs is microseconds); rate-bounded by min_ticks
		 * below. Runs regardless of enable state because the
		 * focus cache is read input, not output: gating off
		 * publication should not also gate off our consumption
		 * of the compositor's focus updates. */
		inputfs_focus_refresh(td);

		/* Rate cap: ensure at least min_ticks between iterations. */
		pause("ifsrate", min_ticks);
	}

	/* Stage D.1: focus file close before publication-side closes. */
	inputfs_focus_close_file(td);
	inputfs_events_close_file(td);
	inputfs_state_close_file(td);

	/* Signal that the kthread has finished cleanly. */
	mtx_lock_spin(&inputfs_state_mtx);
	inputfs_kthread_done = 1;
	wakeup(&inputfs_kthread_done);
	mtx_unlock_spin(&inputfs_state_mtx);

	kproc_exit(0);
}

/*
 * Walk the device's report descriptor and populate softc counts.
 * Three separate passes are required because hid_start_parse
 * accepts exactly one kind bit per pass (verified in ADR 0008
 * errata).
 */
static void
inputfs_walk_rdesc(struct inputfs_softc *sc)
{
	struct hid_data *s;
	struct hid_item hi;
	uint32_t depth = 0, max_depth = 0;
	uint32_t input_items = 0, output_items = 0, feature_items = 0;

	s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len, 1 << hid_input);
	if (s != NULL) {
		while (hid_get_item(s, &hi) > 0) {
			switch (hi.kind) {
			case hid_input:
				input_items++;
				break;
			case hid_collection:
				depth++;
				if (depth > max_depth)
					max_depth = depth;
				break;
			case hid_endcollection:
				if (depth > 0)
					depth--;
				break;
			default:
				break;
			}
		}
		hid_end_parse(s);
	}

	s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len, 1 << hid_output);
	if (s != NULL) {
		while (hid_get_item(s, &hi) > 0) {
			if (hi.kind == hid_output)
				output_items++;
		}
		hid_end_parse(s);
	}

	s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len, 1 << hid_feature);
	if (s != NULL) {
		while (hid_get_item(s, &hi) > 0) {
			if (hi.kind == hid_feature)
				feature_items++;
		}
		hid_end_parse(s);
	}

	sc->sc_input_items    = input_items;
	sc->sc_output_items   = output_items;
	sc->sc_feature_items  = feature_items;
	sc->sc_collection_depth = max_depth;
}

/*
 * The pure-parser functions and the inputfs_report_id_matches
 * helper that previously lived here moved to inputfs_parser.c
 * in Stage AD-9.2a. inputfs_keyboard_key_in_set (used only by
 * inputfs_keyboard_diff_emit, just below) stays here because
 * its sole caller mixes parser concerns with event-emission
 * concerns and is out of fuzz scope per ADR 0014.
 */


/*
 * inputfs_keyboard_key_in_set -- Stage D.0b helper.
 *
 * Returns 1 if usage is a non-zero, non-rollover-error value
 * present anywhere in the 6-slot set; 0 otherwise. Used by the
 * diff emitter to compare current and previous key arrays as
 * sets rather than positions.
 *
 * 0x00 is the empty-slot sentinel (no key in this position).
 * 0x01 (ErrorRollover), 0x02 (POSTFail), 0x03 (ErrorUndefined)
 * are status codes a keyboard may emit when more than 6 keys
 * are simultaneously held; we treat them as "no key" rather
 * than as real key presses.
 */
static inline int
inputfs_keyboard_key_in_set(uint8_t usage, const uint8_t set[6])
{
	int i;

	if (usage <= 0x03)
		return (1);  /* treat as "always present" so it never
			      * triggers a key_down or key_up */
	for (i = 0; i < 6; i++) {
		if (set[i] == usage)
			return (1);
	}
	return (0);
}

/*
 * inputfs_keyboard_diff_emit -- Stage D.0b.
 *
 * Compare the current modifier byte and keys array against the
 * previous-state buffer in the softc, and emit one
 * keyboard.key_up or keyboard.key_down event per change.
 *
 * Modifier bits use HID usages 0xE0..0xE7 (Left Ctrl through
 * Right Meta) for their hid_usage values; non-modifier keys use
 * the usage from the keys array directly.
 *
 * Order of emission per ADR 0012 §Decision 7 and the spec
 * convention: all key_up events first (modifier ups, then array
 * key ups), then all key_down events (modifier downs, then
 * array key downs). This produces a clean "everything released
 * before anything new pressed" semantic within a single report's
 * diff.
 *
 * Each event carries the new modifier byte in its modifiers
 * field, regardless of whether the change was a modifier or
 * an array key. Consumers detect modifier-state-only changes
 * by comparing the modifiers field across successive events.
 *
 * Caller must hold inputfs_state_mtx (MTX_SPIN).
 */
static void
inputfs_keyboard_diff_emit(struct inputfs_softc *sc,
    uint8_t modifiers, const uint8_t keys[6])
{
	uint8_t mod_changed = sc->sc_parser.prev_modifiers ^ modifiers;
	uint16_t dev_slot;
	uint8_t payload[32];
	int i;
	uint32_t bit;
	uint32_t kbd_session = 0;

	dev_slot = (sc->sc_state_slot == INPUTFS_NO_STATE_SLOT)
	    ? INPUTFS_SYNTHETIC_DEVICE
	    : (uint16_t)sc->sc_state_slot;

	/* Stage D.4: resolve keyboard focus once at function entry.
	 * All key_up / key_down events emitted by this diff carry
	 * the same session_id (the focus snapshot at the moment of
	 * the report). If keyboard_focus is 0 (no session focused,
	 * or compositor not running), events go out unrouted. */
	inputfs_focus_keyboard_session(&kbd_session);

	/* Modifier ups: bits set in prev but not in new. */
	for (bit = 0; bit < 8; bit++) {
		uint8_t mask = (uint8_t)(1u << bit);
		if ((mod_changed & mask) == 0)
			continue;
		if ((sc->sc_parser.prev_modifiers & mask) == 0)
			continue;
		memset(payload, 0, sizeof(payload));
		inputfs_put_u32le(payload, 0, 0xE0u + bit);
		inputfs_put_u32le(payload, 4, 0xFFFFFFFFu); /* positional */
		inputfs_put_u32le(payload, 8, modifiers);
		inputfs_put_u32le(payload, 12, kbd_session);
		inputfs_events_publish(INPUTFS_SOURCE_KEYBOARD,
		    INPUTFS_KEYBOARD_KEY_UP,
		    dev_slot, 0, payload, 16);
	}

	/* Array key ups: keys in prev not in current. */
	for (i = 0; i < 6; i++) {
		uint8_t usage = sc->sc_parser.prev_keys[i];
		if (usage == 0)
			continue;
		if (usage <= 0x03)
			continue;
		if (inputfs_keyboard_key_in_set(usage, keys))
			continue;
		memset(payload, 0, sizeof(payload));
		inputfs_put_u32le(payload, 0, usage);
		inputfs_put_u32le(payload, 4, 0xFFFFFFFFu);
		inputfs_put_u32le(payload, 8, modifiers);
		inputfs_put_u32le(payload, 12, kbd_session);
		inputfs_events_publish(INPUTFS_SOURCE_KEYBOARD,
		    INPUTFS_KEYBOARD_KEY_UP,
		    dev_slot, 0, payload, 16);
	}

	/* Modifier downs: bits set in new but not in prev. */
	for (bit = 0; bit < 8; bit++) {
		uint8_t mask = (uint8_t)(1u << bit);
		if ((mod_changed & mask) == 0)
			continue;
		if ((modifiers & mask) == 0)
			continue;
		memset(payload, 0, sizeof(payload));
		inputfs_put_u32le(payload, 0, 0xE0u + bit);
		inputfs_put_u32le(payload, 4, 0xFFFFFFFFu);
		inputfs_put_u32le(payload, 8, modifiers);
		inputfs_put_u32le(payload, 12, kbd_session);
		inputfs_events_publish(INPUTFS_SOURCE_KEYBOARD,
		    INPUTFS_KEYBOARD_KEY_DOWN,
		    dev_slot, 0, payload, 16);
	}

	/* Array key downs: keys in current not in prev. */
	for (i = 0; i < 6; i++) {
		uint8_t usage = keys[i];
		if (usage == 0)
			continue;
		if (usage <= 0x03)
			continue;
		if (inputfs_keyboard_key_in_set(usage, sc->sc_parser.prev_keys))
			continue;
		memset(payload, 0, sizeof(payload));
		inputfs_put_u32le(payload, 0, usage);
		inputfs_put_u32le(payload, 4, 0xFFFFFFFFu);
		inputfs_put_u32le(payload, 8, modifiers);
		inputfs_put_u32le(payload, 12, kbd_session);
		inputfs_events_publish(INPUTFS_SOURCE_KEYBOARD,
		    INPUTFS_KEYBOARD_KEY_DOWN,
		    dev_slot, 0, payload, 16);
	}

	/* Update previous-state buffer for next report. */
	sc->sc_parser.prev_modifiers = modifiers;
	memcpy(sc->sc_parser.prev_keys, keys, sizeof(sc->sc_parser.prev_keys));
}

/*
 * inputfs_intr -- hidbus interrupt callback.
 *
 * Stage B.4: copies the report into the per-device buffer and
 * logs a hex-dump line.
 *
 * Stage C.3: for INPUTFS_ROLE_POINTER devices, parses the
 * boot-protocol mouse layout (byte 0 = buttons, byte 1 = signed
 * x delta, byte 2 = signed y delta) and emits pointer events.
 *
 * Stage D.0a: replaced boot-protocol parsing with
 * descriptor-driven extraction via the location cache populated
 * at attach by inputfs_pointer_locate. Adds report-ID dispatch
 * for devices with multiplexed reports. Adds pointer.scroll
 * event emission when HUG_WHEEL is present in the descriptor.
 *
 * Constraints (ADR 0009):
 *   - Must not sleep or block.
 *   - Must not acquire sc_mtx (not yet configured for interrupt use).
 *   - May acquire inputfs_state_mtx (MTX_SPIN, designed for
 *     interrupt context).
 *   - device_printf is safe from interrupt context on FreeBSD.
 */
static void
inputfs_intr(void *context, void *data, hid_size_t len)
{
	struct inputfs_softc *sc = context;
	const uint8_t *bytes = data;
	hid_size_t copy_len;
	char hexbuf[256];
	int pos, i;

	if (sc->sc_ibuf == NULL || sc->sc_ibuf_size == 0)
		return;

	if (len > sc->sc_ibuf_size) {
		device_printf(sc->sc_dev,
		    "inputfs: report truncated (%u > %u bytes)\n",
		    (unsigned int)len, (unsigned int)sc->sc_ibuf_size);
		copy_len = sc->sc_ibuf_size;
	} else {
		copy_len = len;
	}

	memcpy(sc->sc_ibuf, data, copy_len);

	/*
	 * AD-13.1: per-report logging gated on hw.inputfs.debug_reports.
	 * Default off; the formatting plus device_printf is skipped
	 * entirely when the sysctl is 0, removing the per-event console
	 * write and the per-call CPU cost from the interrupt path.
	 */
	if (inputfs_debug_reports) {
		pos = 0;
		for (i = 0; i < (int)copy_len && pos < (int)sizeof(hexbuf) - 3; i++) {
			pos += snprintf(hexbuf + pos, sizeof(hexbuf) - pos,
			    "%02x ", bytes[i]);
		}
		if (pos > 0 && hexbuf[pos - 1] == ' ')
			hexbuf[pos - 1] = '\0';

		device_printf(sc->sc_dev,
		    "inputfs: report id=0x%02x len=%u data=%s\n",
		    (unsigned int)(copy_len > 0 ? sc->sc_ibuf[0] : 0),
		    (unsigned int)copy_len,
		    hexbuf);
	}

	/*
	 * Stage D.0a: descriptor-driven pointer extraction.
	 *
	 * Both conditions must hold for events to fire:
	 *   - The device was classified as a pointer (sc_roles).
	 *   - The location cache is populated (sc_pointer_locations_valid).
	 *
	 * The cache may be unpopulated for pointers whose descriptor
	 * has no recognised X/Y/buttons (vanishingly rare in practice
	 * but defensible). In that case we log the hex-dump and stop.
	 */
	if ((sc->sc_roles & INPUTFS_ROLE_POINTER) != 0 &&
	    sc->sc_parser.pointer_locations_valid &&
	    copy_len > 0) {
		int32_t dx = 0, dy = 0, dw = 0;
		uint32_t buttons = 0;
		int extracted;

		extracted = inputfs_extract_pointer(&sc->sc_parser, sc->sc_ibuf,
		    copy_len, &dx, &dy, &dw, &buttons);

		if (extracted) {
			uint32_t prev_buttons;
			int32_t new_x, new_y;
			uint8_t payload[32];
			uint16_t dev_slot;

			mtx_lock_spin(&inputfs_state_mtx);
			prev_buttons = inputfs_get_u32le(inputfs_state_buf,
			    OFF_PTR_BUTTONS);
			inputfs_state_seqlock_begin();
			inputfs_state_update_pointer(dx, dy, buttons);
			inputfs_state_advance_seq();
			inputfs_state_seqlock_end();
			inputfs_state_mark_dirty();

			new_x = inputfs_get_i32le(inputfs_state_buf,
			    OFF_PTR_X);
			new_y = inputfs_get_i32le(inputfs_state_buf,
			    OFF_PTR_Y);

			dev_slot = (sc->sc_state_slot ==
			    INPUTFS_NO_STATE_SLOT)
			    ? INPUTFS_SYNTHETIC_DEVICE
			    : (uint16_t)sc->sc_state_slot;

			/*
			 * Stage D.4: resolve the session_id under the
			 * cursor at the new position. If the cursor
			 * crossed a surface boundary since the last
			 * report (curr_session != prev_session_under_cursor),
			 * synthesise pointer.leave for the old surface
			 * and pointer.enter for the new surface before
			 * emitting any other events from this report.
			 *
			 * Per shared/INPUT_EVENTS.md, enter and leave
			 * payloads are 16 bytes: x, y, surface_id,
			 * session_id. inputfs's focus model has one
			 * session per surface, so surface_id and
			 * session_id are set to the same value. Synthesised
			 * events carry flags bit 0 (synthesised) per spec.
			 */
			uint32_t curr_session = 0;
			inputfs_focus_resolve_pointer(new_x, new_y,
			    &curr_session);

			if (curr_session != inputfs_pointer_session_prev) {
				uint8_t lp[32];

				if (inputfs_pointer_session_prev != 0) {
					memset(lp, 0, sizeof(lp));
					inputfs_put_i32le(lp, 0, new_x);
					inputfs_put_i32le(lp, 4, new_y);
					inputfs_put_u32le(lp, 8,
					    inputfs_pointer_session_prev);
					inputfs_put_u32le(lp, 12,
					    inputfs_pointer_session_prev);
					inputfs_events_publish(
					    INPUTFS_SOURCE_POINTER,
					    INPUTFS_POINTER_LEAVE,
					    dev_slot, 1u, lp, 16);
				}

				if (curr_session != 0) {
					memset(lp, 0, sizeof(lp));
					inputfs_put_i32le(lp, 0, new_x);
					inputfs_put_i32le(lp, 4, new_y);
					inputfs_put_u32le(lp, 8, curr_session);
					inputfs_put_u32le(lp, 12, curr_session);
					inputfs_events_publish(
					    INPUTFS_SOURCE_POINTER,
					    INPUTFS_POINTER_ENTER,
					    dev_slot, 1u, lp, 16);
				}

				inputfs_pointer_session_prev = curr_session;
			}

			/*
			 * pointer.motion: emit if X or Y was extracted
			 * (a button-only or wheel-only report does not
			 * produce a motion event).
			 */
			if (sc->sc_parser.loc_x.size > 0 ||
			    sc->sc_parser.loc_y.size > 0) {
				memset(payload, 0, sizeof(payload));
				inputfs_put_i32le(payload, 0, new_x);
				inputfs_put_i32le(payload, 4, new_y);
				inputfs_put_i32le(payload, 8, dx);
				inputfs_put_i32le(payload, 12, dy);
				inputfs_put_u32le(payload, 16, buttons);
				inputfs_put_u32le(payload, 20, curr_session);
				inputfs_events_publish(
				    INPUTFS_SOURCE_POINTER,
				    INPUTFS_POINTER_MOTION,
				    dev_slot, 0, payload, 24);
			}

			/*
			 * Button transitions: emit one event per changed
			 * bit. The button mask width is sc_button_count;
			 * we still iterate the lower 32 bits since
			 * buttons is a u32. Buttons not present in the
			 * device contribute zero bits to both prev and
			 * curr, so changed will not flag them.
			 */
			uint32_t changed = prev_buttons ^ buttons;
			for (uint32_t bit = 0; bit < 32; bit++) {
				uint32_t mask = 1u << bit;
				if ((changed & mask) == 0)
					continue;
				memset(payload, 0, sizeof(payload));
				inputfs_put_i32le(payload, 0, new_x);
				inputfs_put_i32le(payload, 4, new_y);
				inputfs_put_u32le(payload, 8, mask);
				inputfs_put_u32le(payload, 12, buttons);
				inputfs_put_u32le(payload, 16, curr_session);
				inputfs_events_publish(
				    INPUTFS_SOURCE_POINTER,
				    (buttons & mask) != 0
				        ? INPUTFS_POINTER_BUTTON_DOWN
				        : INPUTFS_POINTER_BUTTON_UP,
				    dev_slot, 0, payload, 20);
			}

			/*
			 * Scroll: emit pointer.scroll if the wheel was
			 * extracted and is non-zero. Wheel reports
			 * scroll deltas in lines (delta_unit = 0).
			 * Pixel-precise scrolling (delta_unit = 1) is
			 * a future refinement that depends on resolution
			 * multipliers, which Stage D.0a does not parse.
			 */
			if (sc->sc_parser.has_wheel && dw != 0) {
				memset(payload, 0, sizeof(payload));
				inputfs_put_i32le(payload, 0, new_x);
				inputfs_put_i32le(payload, 4, new_y);
				inputfs_put_i32le(payload, 8, 0); /* dx */
				inputfs_put_i32le(payload, 12, dw);
				inputfs_put_u32le(payload, 16, 0); /* lines */
				inputfs_put_u32le(payload, 20, curr_session);
				inputfs_events_publish(
				    INPUTFS_SOURCE_POINTER,
				    INPUTFS_POINTER_SCROLL,
				    dev_slot, 0, payload, 24);
			}

			mtx_unlock_spin(&inputfs_state_mtx);
		}
	}

	/*
	 * Stage D.0b: descriptor-driven keyboard event emission.
	 *
	 * Both conditions must hold for events to fire:
	 *   - The device was classified as a keyboard (sc_roles).
	 *   - The keyboard location cache is populated.
	 *
	 * Extraction reads the modifier byte and up to 6 array
	 * keys; the diff emitter compares against the softc's
	 * previous-state buffer and emits one key_up or key_down
	 * event per change. The previous-state buffer is updated
	 * by the diff emitter for the next report.
	 */
	if ((sc->sc_roles & INPUTFS_ROLE_KEYBOARD) != 0 &&
	    sc->sc_parser.keyboard_locations_valid &&
	    copy_len > 0) {
		uint8_t modifiers = 0;
		uint8_t keys[6] = { 0, 0, 0, 0, 0, 0 };
		int extracted;

		extracted = inputfs_extract_keyboard(&sc->sc_parser, sc->sc_ibuf,
		    copy_len, &modifiers, keys);

		if (extracted) {
			mtx_lock_spin(&inputfs_state_mtx);
			inputfs_keyboard_diff_emit(sc, modifiers, keys);
			mtx_unlock_spin(&inputfs_state_mtx);
		}
	}
}

/*
 * inputfs_classify_roles -- Stage B.5.
 *
 * Read the matched TLC from hidbus_get_usage(), apply the page
 * guard and switch from ADR 0010 Decision section 2, and write
 * the result into sc->sc_roles.
 */
static void
inputfs_classify_roles(struct inputfs_softc *sc)
{
	uint32_t usage = hidbus_get_usage(sc->sc_dev);
	uint16_t page = HID_GET_USAGE_PAGE(usage);
	uint16_t id = HID_GET_USAGE(usage);

	sc->sc_roles = 0;

	if (page == HUP_GENERIC_DESKTOP) {
		switch (id) {
		case HUG_KEYBOARD:
			sc->sc_roles |= INPUTFS_ROLE_KEYBOARD;
			break;
		case HUG_MOUSE:
		case HUG_POINTER:
			sc->sc_roles |= INPUTFS_ROLE_POINTER;
			break;
		default:
			break;
		}
	}
}

/*
 * inputfs_format_roles -- Stage B.5.
 *
 * Format the role bitmask into a comma-separated list, or
 * "<none>" if no bits are set.
 */
static void
inputfs_format_roles(uint8_t roles, char *buf, size_t buflen)
{
	static const char * const names[5] = {
		"pointer", "keyboard", "touch", "pen", "lighting"
	};
	size_t pos = 0;
	int first = 1;
	int i;

	if (buflen == 0)
		return;

	if (roles == 0) {
		strlcpy(buf, "<none>", buflen);
		return;
	}

	for (i = 0; i < 5; i++) {
		size_t namelen, need;

		if ((roles & (1u << i)) == 0)
			continue;

		namelen = strlen(names[i]);
		need = namelen + (first ? 0 : 1);
		if (pos + need + 1 > buflen)
			break;

		if (!first)
			buf[pos++] = ',';
		memcpy(buf + pos, names[i], namelen);
		pos += namelen;
		first = 0;
	}
	buf[pos] = '\0';
}

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
	void *rdesc = NULL;
	hid_size_t rdesc_len = 0;
	const char *kind;
	int ibuf_size;
	int error;

	sc->sc_dev = dev;
	sc->sc_state_slot = INPUTFS_NO_STATE_SLOT;
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

	error = hid_get_report_descr(dev, &rdesc, &rdesc_len);
	if (error != 0 || rdesc == NULL) {
		device_printf(dev,
		    "inputfs: descriptor fetch failed (error=%d)\n", error);
	} else {
		sc->sc_rdesc = rdesc;
		sc->sc_rdesc_len = rdesc_len;

		if ((hid_size_t)hw->rdescsize != rdesc_len) {
			device_printf(dev,
			    "inputfs: descriptor size mismatch "
			    "(hid_device_info reports %u, fetched %u)\n",
			    (unsigned int)hw->rdescsize,
			    (unsigned int)rdesc_len);
		}

		inputfs_walk_rdesc(sc);

		device_printf(dev,
		    "inputfs: descriptor %u bytes, %u input items, "
		    "%u output, %u feature, depth=%u\n",
		    (unsigned int)sc->sc_rdesc_len,
		    (unsigned int)sc->sc_input_items,
		    (unsigned int)sc->sc_output_items,
		    (unsigned int)sc->sc_feature_items,
		    (unsigned int)sc->sc_collection_depth);

		/*
		 * Stage D.0a: populate the pointer location cache so
		 * the interrupt path can extract X/Y/wheel/buttons via
		 * hid_get_data rather than assuming boot-protocol
		 * layout. Called unconditionally; the cache is empty
		 * for non-pointer descriptors and the interrupt path
		 * checks sc_pointer_locations_valid before extracting.
		 */
		inputfs_pointer_locate(&sc->sc_parser, sc->sc_rdesc,
		    sc->sc_rdesc_len);

		if (sc->sc_parser.pointer_locations_valid) {
			device_printf(dev,
			    "inputfs: pointer locations cached "
			    "(x=%s y=%s wheel=%s buttons=%u count=%u)\n",
			    sc->sc_parser.loc_x.size > 0 ? "yes" : "no",
			    sc->sc_parser.loc_y.size > 0 ? "yes" : "no",
			    sc->sc_parser.has_wheel ? "yes" : "no",
			    (unsigned int)sc->sc_parser.loc_buttons.size,
			    (unsigned int)sc->sc_parser.button_count);
		}

		/*
		 * Stage D.0b: populate the keyboard location cache.
		 * Same pattern as the pointer cache: called
		 * unconditionally, the interrupt path checks
		 * sc_keyboard_locations_valid before extracting.
		 */
		inputfs_keyboard_locate(&sc->sc_parser, sc->sc_rdesc,
		    sc->sc_rdesc_len);

		if (sc->sc_parser.keyboard_locations_valid) {
			device_printf(dev,
			    "inputfs: keyboard locations cached "
			    "(modifiers=%s keys=%s array_count=%u)\n",
			    sc->sc_parser.loc_modifiers.size > 0 ? "yes" : "no",
			    sc->sc_parser.loc_keys.size > 0 ? "yes" : "no",
			    (unsigned int)sc->sc_parser.loc_keys.count);
		}

		ibuf_size = hid_report_size_max(sc->sc_rdesc,
		    sc->sc_rdesc_len, hid_input, &sc->sc_report_id);

		if (ibuf_size <= 0) {
			device_printf(dev,
			    "inputfs: hid_report_size_max returned %d, "
			    "skipping interrupt registration\n", ibuf_size);
		} else {
			sc->sc_ibuf_size = (hid_size_t)ibuf_size;
			sc->sc_ibuf = malloc(sc->sc_ibuf_size,
			    M_INPUTFS, M_WAITOK | M_ZERO);

			device_printf(dev,
			    "inputfs: report buffer %u bytes "
			    "(report_id=0x%02x), registering interrupt\n",
			    (unsigned int)sc->sc_ibuf_size,
			    (unsigned int)sc->sc_report_id);

			hidbus_set_intr(dev, inputfs_intr, sc);

			device_printf(dev,
			    "inputfs: calling hid_intr_start\n");
			int intr_err = hid_intr_start(dev);
			device_printf(dev,
			    "inputfs: hid_intr_start returned %d\n",
			    intr_err);
		}
	}

	{
		char rolebuf[64];

		inputfs_classify_roles(sc);
		inputfs_format_roles(sc->sc_roles, rolebuf, sizeof(rolebuf));
		device_printf(dev, "inputfs: roles=%s\n", rolebuf);
	}

	/*
	 * Stage C.2: allocate a state-region slot and publish the
	 * device descriptor. Lock order is sc_mtx, then
	 * inputfs_state_mtx; release in reverse.
	 */
	if (inputfs_state_buf != NULL) {
		uint8_t slot;

		mtx_lock(&sc->sc_mtx);
		mtx_lock_spin(&inputfs_state_mtx);

		slot = inputfs_state_alloc_slot();
		sc->sc_state_slot = slot;

		if (slot != INPUTFS_NO_STATE_SLOT) {
			uint8_t payload[32];

			inputfs_state_seqlock_begin();
			inputfs_state_put_device(slot, dev, sc->sc_roles);
			inputfs_put_u16le(inputfs_state_buf,
			    OFF_DEVICE_COUNT,
			    inputfs_state_count_devices());
			inputfs_state_advance_seq();
			inputfs_state_seqlock_end();
			/* state_valid: 0 -> 1 the first time a device
			 * publishes successfully. The valid byte is
			 * never reset, so subsequent attaches are
			 * idempotent on it. */
			inputfs_put_u8(inputfs_state_buf, OFF_VALID, 1);
			inputfs_state_mark_dirty();

			/* Stage C.3: emit device_lifecycle.device_attach
			 * event. Payload is a single u32: the roles
			 * bitmask of the new device. */
			memset(payload, 0, sizeof(payload));
			inputfs_put_u32le(payload, 0, (uint32_t)sc->sc_roles);
			inputfs_events_publish(INPUTFS_SOURCE_DEVICE_LIFECYCLE,
			    INPUTFS_LIFECYCLE_ATTACH,
			    (uint16_t)slot, 0, payload, 4);

			mtx_unlock_spin(&inputfs_state_mtx);
			mtx_unlock(&sc->sc_mtx);

			device_printf(dev,
			    "inputfs: state_slot=%u\n",
			    (unsigned int)slot);
		} else {
			mtx_unlock_spin(&inputfs_state_mtx);
			mtx_unlock(&sc->sc_mtx);

			device_printf(dev,
			    "inputfs: state inventory full, no slot\n");
		}
	}

	return (0);
}

static int
inputfs_detach(device_t dev)
{
	struct inputfs_softc *sc = device_get_softc(dev);

	device_printf(dev, "inputfs: detached\n");

	if (sc->sc_ibuf != NULL)
		hid_intr_stop(dev);

	/*
	 * Stage C.2: clear the device's state-region slot.
	 * Stage C.3: emit device_lifecycle.device_detach event
	 * before clearing the slot, so the event still references
	 * the slot index of the departing device.
	 */
	if (inputfs_state_buf != NULL &&
	    sc->sc_state_slot != INPUTFS_NO_STATE_SLOT) {
		uint8_t slot = sc->sc_state_slot;

		mtx_lock(&sc->sc_mtx);
		mtx_lock_spin(&inputfs_state_mtx);

		/* Emit detach event first; payload is empty. */
		inputfs_events_publish(INPUTFS_SOURCE_DEVICE_LIFECYCLE,
		    INPUTFS_LIFECYCLE_DETACH,
		    (uint16_t)slot, 0, NULL, 0);

		inputfs_state_seqlock_begin();
		inputfs_state_clear_device(slot);
		inputfs_state_release_slot(slot);
		inputfs_put_u16le(inputfs_state_buf,
		    OFF_DEVICE_COUNT,
		    inputfs_state_count_devices());
		inputfs_state_advance_seq();
		inputfs_state_seqlock_end();
		inputfs_state_mark_dirty();

		mtx_unlock_spin(&inputfs_state_mtx);
		mtx_unlock(&sc->sc_mtx);

		sc->sc_state_slot = INPUTFS_NO_STATE_SLOT;
	}

	if (sc->sc_ibuf != NULL) {
		free(sc->sc_ibuf, M_INPUTFS);
		sc->sc_ibuf = NULL;
		sc->sc_ibuf_size = 0;
	}

	sc->sc_rdesc = NULL;
	sc->sc_rdesc_len = 0;

	mtx_destroy(&sc->sc_mtx);

	return (0);
}

static int
inputfs_modevent(module_t mod, int what, void *arg)
{
	int error;

	(void)mod;
	(void)arg;

	switch (what) {
	case MOD_LOAD:
		printf("inputfs: Stage C.3 loading "
		    "(state region and event ring publication via "
		    "vnode-backed sync; no userspace event delivery yet)\n");

		/* Allocate the state region live buffer. */
		inputfs_state_buf = malloc(INPUTFS_STATE_SIZE,
		    M_INPUTFS, M_WAITOK | M_ZERO);
		inputfs_state_init_buf(inputfs_state_buf);
		inputfs_state_seq = 0;
		inputfs_state_slot_used = 0;
		inputfs_state_dirty = 0;

		/* Allocate the event ring live buffer. */
		inputfs_events_buf = malloc(INPUTFS_EVENTS_SIZE,
		    M_INPUTFS, M_WAITOK | M_ZERO);
		inputfs_events_init_buf(inputfs_events_buf);
		inputfs_events_writer_seq = 0;
		inputfs_events_synced = 0;
		inputfs_events_dirty = 0;

		/* Allocate the focus region cache buffer (Stage D.1).
		 * The buffer mirrors the on-disk focus file written by
		 * the userspace compositor; the kthread refreshes it
		 * once per refresh tick. */
		inputfs_focus_buf = malloc(INPUTFS_FOCUS_SIZE,
		    M_INPUTFS, M_WAITOK | M_ZERO);
		inputfs_focus_vp = NULL;
		inputfs_focus_cache_valid = 0;
		inputfs_focus_logged_absent = 0;

		/* Stage D.4: pointer routing state. Reset to 0 (no
		 * session) so the first pointer event after load
		 * never synthesises a spurious leave for a stale
		 * session_id. */
		inputfs_pointer_session_prev = 0;

		/* Initialize the spin mutex used by the interrupt
		 * path and the kthread worker. */
		mtx_init(&inputfs_state_mtx, "inputfs state",
		    NULL, MTX_SPIN);

		/* Stage D.1: spin mutex for the focus cache. Separate
		 * from inputfs_state_mtx because the focus cache is
		 * read in the interrupt path (D.4) but the kthread
		 * holds the state mutex during file I/O; sharing one
		 * mutex would unnecessarily contend the interrupt
		 * fast path against the kthread's slow path. */
		mtx_init(&inputfs_focus_mtx, "inputfs focus",
		    NULL, MTX_SPIN);

		/* Stage D.2: read display geometry from drawfs's
		 * hw.drawfs.efifb.* sysctls. Falls back to defaults
		 * if drawfs is not loaded. Called before the kthread
		 * starts because no spin lock is held and sleeping is
		 * permitted in MOD_LOAD context. */
		inputfs_geom_read(curthread);

		/* Stage D.3: apply geometry to the state header.
		 * Sets transform_active and seeds the pointer at the
		 * centre of the display when geometry is known. */
		inputfs_state_apply_geom();

		/* Start the kthread worker. */
		inputfs_kthread_run = 1;
		inputfs_kthread_done = 0;
		error = kproc_create(inputfs_state_worker, NULL,
		    &inputfs_kthread_proc, 0, 0, "inputfs_state");
		if (error != 0) {
			printf("inputfs: kproc_create failed: %d\n", error);
			mtx_destroy(&inputfs_focus_mtx);
			mtx_destroy(&inputfs_state_mtx);
			free(inputfs_focus_buf, M_INPUTFS);
			inputfs_focus_buf = NULL;
			free(inputfs_events_buf, M_INPUTFS);
			inputfs_events_buf = NULL;
			free(inputfs_state_buf, M_INPUTFS);
			inputfs_state_buf = NULL;
			return (error);
		}

		/* Mark events ring valid; the state region is marked
		 * valid by the first attach (state_valid stays at 0
		 * until then per the spec). The events ring has no
		 * such "wait for first device" condition; it goes
		 * live as soon as the file is open. */
		inputfs_put_u8(inputfs_events_buf, EV_OFF_VALID, 1);

		printf("inputfs: state region buffer ready (%lu bytes), "
		    "events ring buffer ready (%lu bytes), kthread started\n",
		    (unsigned long)INPUTFS_STATE_SIZE,
		    (unsigned long)INPUTFS_EVENTS_SIZE);
		return (0);

	case MOD_UNLOAD:
		/* Signal the kthread to exit and wait for it. */
		mtx_lock_spin(&inputfs_state_mtx);
		inputfs_kthread_run = 0;
		wakeup(&inputfs_state_dirty);
		while (!inputfs_kthread_done) {
			msleep_spin(&inputfs_kthread_done,
			    &inputfs_state_mtx,
			    "ifsexit", 0);
		}
		mtx_unlock_spin(&inputfs_state_mtx);

		mtx_destroy(&inputfs_state_mtx);
		mtx_destroy(&inputfs_focus_mtx);

		if (inputfs_focus_buf != NULL) {
			free(inputfs_focus_buf, M_INPUTFS);
			inputfs_focus_buf = NULL;
		}
		if (inputfs_events_buf != NULL) {
			free(inputfs_events_buf, M_INPUTFS);
			inputfs_events_buf = NULL;
		}
		if (inputfs_state_buf != NULL) {
			free(inputfs_state_buf, M_INPUTFS);
			inputfs_state_buf = NULL;
		}

		printf("inputfs: unloaded\n");
		return (0);

	default:
		return (EOPNOTSUPP);
	}
}

static device_method_t inputfs_methods[] = {
	DEVMETHOD(device_probe,  inputfs_probe),
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
