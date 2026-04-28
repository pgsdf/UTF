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

MALLOC_DEFINE(M_INPUTFS, "inputfs", "inputfs report buffers");

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
 * Per-device softc. Stage B.4 added interrupt buffer fields;
 * Stage B.5 added the per-device role bitmask;
 * Stage C.2 adds the state-region slot index assigned at attach;
 * Stage D.0a adds the cached HID locations for descriptor-driven
 * pointer event extraction.
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
	 * Pointer location cache (Stage D.0a). Populated once at
	 * attach by inputfs_pointer_locate. Each location's
	 * size field is zero when the corresponding usage is not
	 * present in the descriptor; consumers must check size > 0
	 * before extracting.
	 *
	 * sc_loc_buttons covers the button usage range as a single
	 * location with one bit per button (HID button usages are
	 * 1-indexed in the HUP_BUTTON page; our wire format folds
	 * the first 32 buttons into a u32 bitmask, so we cap at 32
	 * when caching).
	 *
	 * Each location records the report ID it belongs to, since
	 * a device may multiplex multiple reports through one
	 * interrupt callback.
	 */
	uint8_t			 sc_pointer_locations_valid;
	struct hid_location	 sc_loc_x;
	struct hid_location	 sc_loc_y;
	struct hid_location	 sc_loc_wheel;
	struct hid_location	 sc_loc_buttons;
	uint8_t			 sc_loc_x_id;
	uint8_t			 sc_loc_y_id;
	uint8_t			 sc_loc_wheel_id;
	uint8_t			 sc_loc_buttons_id;
	uint8_t			 sc_button_count;
	uint8_t			 sc_has_wheel;

	/*
	 * Keyboard location cache and previous-state buffer
	 * (Stage D.0b). Populated once at attach by
	 * inputfs_keyboard_locate. The interrupt path extracts
	 * the modifier byte and the keys-held array, diffs them
	 * against sc_prev_modifiers / sc_prev_keys to compute
	 * key_down and key_up transitions, and updates the
	 * previous-state buffer for the next report.
	 *
	 * The HID boot keyboard array reports up to 6 simultaneously
	 * held keys in unspecified order; comparing as sets (not
	 * positions) is required. n-key rollover beyond 6 is
	 * reported as 0x01 in all six slots and is filtered out.
	 *
	 * sc_loc_modifiers covers the 8-bit modifier bitfield. A
	 * single hid_locate against usage 0xE0 (Left Ctrl) yields
	 * the bit position of bit 0; the eight modifier bits are
	 * read together via hid_get_udata against a location whose
	 * size is 8 (one byte) and pos points at bit 0 of the
	 * modifier byte. We synthesise this by extending the
	 * located size from 1 (per-bit declaration) to 8.
	 *
	 * sc_loc_keys covers the keys-held array as a single
	 * location whose size is the per-element bit width
	 * (typically 8) and count is the array length (typically
	 * 6). Per-element extraction adjusts a copy of the
	 * location's pos field by size * index.
	 */
	uint8_t			 sc_keyboard_locations_valid;
	struct hid_location	 sc_loc_modifiers;
	struct hid_location	 sc_loc_keys;
	uint8_t			 sc_loc_modifiers_id;
	uint8_t			 sc_loc_keys_id;
	uint8_t			 sc_prev_modifiers;
	uint8_t			 sc_prev_keys[6];
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
 * Stage C.2 publishes raw device-space coordinates with no
 * coordinate transform applied. Each pointer report contributes
 * its dx/dy to the accumulator; buttons replace the previous
 * bitmask. Stage D will introduce the transform layer.
 */
static void
inputfs_state_update_pointer(int32_t dx, int32_t dy, uint32_t buttons)
{
	int32_t cur_x, cur_y;
	cur_x = inputfs_get_i32le(inputfs_state_buf, OFF_PTR_X);
	cur_y = inputfs_get_i32le(inputfs_state_buf, OFF_PTR_Y);
	inputfs_put_i32le(inputfs_state_buf, OFF_PTR_X, cur_x + dx);
	inputfs_put_i32le(inputfs_state_buf, OFF_PTR_Y, cur_y + dy);
	inputfs_put_u32le(inputfs_state_buf, OFF_PTR_BUTTONS, buttons);
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
		error = vn_open(&nd, &flags, 0644, NULL);
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
	VOP_UNLOCK(inputfs_state_vp);
	printf("inputfs: opened state file %s (size=%lu bytes)\n",
	    INPUTFS_STATE_PATH, (unsigned long)INPUTFS_STATE_SIZE);
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
		error = vn_open(&nd, &flags, 0644, NULL);
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
	VOP_UNLOCK(inputfs_events_vp);
	printf("inputfs: opened events file %s (size=%lu bytes)\n",
	    INPUTFS_EVENTS_PATH, (unsigned long)INPUTFS_EVENTS_SIZE);

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

static void
inputfs_state_worker(void *arg)
{
	struct thread *td = curthread;
	int min_ticks;
	int focus_refresh_ticks;
	int do_state, do_events;

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

		if (do_state)
			inputfs_state_sync_to_file(td);
		if (do_events)
			inputfs_events_sync_to_file(td);

		/* Stage D.1: opportunistic focus refresh on every wake.
		 * Cheap when the file is unchanged (vn_rdwr against
		 * tmpfs is microseconds); rate-bounded by min_ticks
		 * below. */
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
 * inputfs_report_id_matches -- Stage D.0a helper.
 *
 * Returns 1 if the report buffer's report ID matches the cached
 * report ID for a location. When cached_id == 0, the device does
 * not use report IDs and any non-empty buffer matches. When
 * cached_id != 0, the first byte of the buffer must equal it.
 *
 * Used by inputfs_extract_pointer to dispatch among multiple
 * report IDs on devices that multiplex (e.g. touchpads with
 * separate pointer and gesture reports).
 */
static inline int
inputfs_report_id_matches(uint8_t cached_id, const uint8_t *buf,
    hid_size_t len)
{
	if (len == 0)
		return (0);
	if (cached_id == 0)
		return (1);
	return (buf[0] == cached_id);
}

/*
 * inputfs_pointer_locate -- Stage D.0a.
 *
 * Populate the softc's HID-location cache for descriptor-driven
 * pointer event extraction. Called once at attach, after
 * inputfs_walk_rdesc and before hidbus_set_intr.
 *
 * For each pointer-relevant usage (X, Y, Wheel, and the button
 * range under HUP_BUTTON), call hid_locate against the descriptor
 * and record the resulting location and report ID. Locations
 * whose size is zero indicate the usage is not present in this
 * descriptor; the interrupt path checks size > 0 before extracting.
 *
 * Buttons are special: HID encodes per-button presence as
 * individual usages 1, 2, 3, ... under HUP_BUTTON, but in
 * practice they are emitted as a single packed bit field. We
 * locate button 1 to get the bit-field's start and use the
 * report count (number of buttons) to determine how wide the
 * field is. Up to 32 buttons are supported (one u32 in the
 * wire format); buttons beyond 32 are silently ignored.
 *
 * The location cache is unconditional regardless of role: a
 * keyboard descriptor will simply have all pointer locations
 * report size == 0, and the interrupt path will skip extraction
 * accordingly. This avoids tying cache population to a specific
 * order of role classification.
 */
static void
inputfs_pointer_locate(struct inputfs_softc *sc)
{
	uint32_t flags;
	uint8_t id;

	memset(&sc->sc_loc_x, 0, sizeof(sc->sc_loc_x));
	memset(&sc->sc_loc_y, 0, sizeof(sc->sc_loc_y));
	memset(&sc->sc_loc_wheel, 0, sizeof(sc->sc_loc_wheel));
	memset(&sc->sc_loc_buttons, 0, sizeof(sc->sc_loc_buttons));
	sc->sc_loc_x_id = 0;
	sc->sc_loc_y_id = 0;
	sc->sc_loc_wheel_id = 0;
	sc->sc_loc_buttons_id = 0;
	sc->sc_button_count = 0;
	sc->sc_has_wheel = 0;
	sc->sc_pointer_locations_valid = 0;

	if (sc->sc_rdesc == NULL || sc->sc_rdesc_len == 0)
		return;

	/* X axis. */
	if (hid_locate(sc->sc_rdesc, sc->sc_rdesc_len,
	    HID_USAGE2(HUP_GENERIC_DESKTOP, HUG_X),
	    hid_input, 0, &sc->sc_loc_x, &flags, &id) != 0) {
		sc->sc_loc_x_id = id;
	}

	/* Y axis. */
	if (hid_locate(sc->sc_rdesc, sc->sc_rdesc_len,
	    HID_USAGE2(HUP_GENERIC_DESKTOP, HUG_Y),
	    hid_input, 0, &sc->sc_loc_y, &flags, &id) != 0) {
		sc->sc_loc_y_id = id;
	}

	/* Wheel (optional). */
	if (hid_locate(sc->sc_rdesc, sc->sc_rdesc_len,
	    HID_USAGE2(HUP_GENERIC_DESKTOP, HUG_WHEEL),
	    hid_input, 0, &sc->sc_loc_wheel, &flags, &id) != 0) {
		sc->sc_loc_wheel_id = id;
		sc->sc_has_wheel = 1;
	}

	/*
	 * Buttons: locate button 1 to get the start of the button
	 * bit field. The HID spec packs buttons sequentially within
	 * a single report field; locating button 1 gives us the
	 * bit-field's location. We then walk the report descriptor
	 * to count how many button usages are present so we know the
	 * field width.
	 */
	if (hid_locate(sc->sc_rdesc, sc->sc_rdesc_len,
	    HID_USAGE2(HUP_BUTTON, 1),
	    hid_input, 0, &sc->sc_loc_buttons, &flags, &id) != 0) {
		struct hid_data *s;
		struct hid_item hi;
		uint8_t count = 0;

		sc->sc_loc_buttons_id = id;

		s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len,
		    1 << hid_input);
		if (s != NULL) {
			while (hid_get_item(s, &hi) > 0) {
				if (hi.kind == hid_input &&
				    HID_GET_USAGE_PAGE(hi.usage) == HUP_BUTTON) {
					if (count < 32)
						count++;
				}
			}
			hid_end_parse(s);
		}
		sc->sc_button_count = count;
	}

	if (sc->sc_loc_x.size > 0 || sc->sc_loc_y.size > 0 ||
	    sc->sc_loc_wheel.size > 0 || sc->sc_loc_buttons.size > 0) {
		sc->sc_pointer_locations_valid = 1;
	}
}

/*
 * inputfs_extract_pointer -- Stage D.0a.
 *
 * Given an interrupt report buffer of length len (including the
 * leading report ID byte if the device uses report IDs), extract
 * pointer values using the cached locations. Returns 1 if the
 * report matched at least one cached location's report ID and
 * any value was extracted; returns 0 if the report should be
 * ignored (wrong report ID, no cached locations, or empty
 * extraction).
 *
 * Output parameters are populated when their respective location
 * is present in the descriptor and matches the incoming report
 * ID. Outputs not extracted are left untouched; callers should
 * initialise to zero before calling.
 *
 * Report ID matching: hid_locate returns the report ID a usage
 * was associated with. If the device uses report IDs, the first
 * byte of the report is the ID and subsequent bytes are the
 * payload; if not, no leading byte is present and IDs are 0.
 * hid_get_data takes the buffer including any leading ID byte
 * and the field's location knows whether to skip it. The match
 * we perform here is between the first byte of the incoming
 * report and the cached id: if cached id is 0, the device does
 * not use IDs and the byte is part of the data; if cached id
 * is non-zero, the byte must match.
 */
static int
inputfs_extract_pointer(struct inputfs_softc *sc,
    const uint8_t *buf, hid_size_t len,
    int32_t *out_dx, int32_t *out_dy, int32_t *out_dw,
    uint32_t *out_buttons)
{
	int extracted = 0;

	if (!sc->sc_pointer_locations_valid || buf == NULL || len == 0)
		return (0);

	if (sc->sc_loc_x.size > 0 &&
	    inputfs_report_id_matches(sc->sc_loc_x_id, buf, len)) {
		*out_dx = (int32_t)hid_get_data(buf, len, &sc->sc_loc_x);
		extracted = 1;
	}

	if (sc->sc_loc_y.size > 0 &&
	    inputfs_report_id_matches(sc->sc_loc_y_id, buf, len)) {
		*out_dy = (int32_t)hid_get_data(buf, len, &sc->sc_loc_y);
		extracted = 1;
	}

	if (sc->sc_loc_wheel.size > 0 &&
	    inputfs_report_id_matches(sc->sc_loc_wheel_id, buf, len)) {
		*out_dw = (int32_t)hid_get_data(buf, len, &sc->sc_loc_wheel);
		extracted = 1;
	}

	if (sc->sc_loc_buttons.size > 0 &&
	    inputfs_report_id_matches(sc->sc_loc_buttons_id, buf, len)) {
		*out_buttons = (uint32_t)hid_get_udata(buf, len,
		    &sc->sc_loc_buttons);
		extracted = 1;
	}

	return (extracted);
}

/*
 * inputfs_keyboard_locate -- Stage D.0b.
 *
 * Populate the softc's keyboard location cache. Called once at
 * attach, after inputfs_pointer_locate and before hidbus_set_intr.
 *
 * The HID boot keyboard layout has two pieces:
 *
 *  - The modifier byte: eight individual 1-bit usages
 *    (0xE0..0xE7) declared as a packed bit field. We locate
 *    usage 0xE0 (Left Ctrl), which sits at bit 0 of the byte,
 *    then synthesise an 8-bit-wide location starting at the
 *    same position. hid_get_udata against that location yields
 *    the full modifier byte in one read.
 *
 *  - The keys-held array: typically declared as a single input
 *    item with usage range and report_count > 1. hid_locate
 *    against any usage in that range returns a location whose
 *    size is the per-element bit width and count is the array
 *    length. We locate via usage 0x00 first (the conventional
 *    array-base usage), falling back to a parser walk if that
 *    does not match.
 *
 * The location cache is unconditional regardless of role; a
 * pointer-only descriptor will simply have all keyboard
 * locations report size == 0.
 */
static void
inputfs_keyboard_locate(struct inputfs_softc *sc)
{
	uint32_t flags;
	uint8_t id;

	memset(&sc->sc_loc_modifiers, 0, sizeof(sc->sc_loc_modifiers));
	memset(&sc->sc_loc_keys, 0, sizeof(sc->sc_loc_keys));
	sc->sc_loc_modifiers_id = 0;
	sc->sc_loc_keys_id = 0;
	sc->sc_prev_modifiers = 0;
	memset(sc->sc_prev_keys, 0, sizeof(sc->sc_prev_keys));
	sc->sc_keyboard_locations_valid = 0;

	if (sc->sc_rdesc == NULL || sc->sc_rdesc_len == 0)
		return;

	/*
	 * Modifiers: locate usage 0xE0 (Left Ctrl) to find the bit
	 * position of bit 0 of the modifier byte. The eight modifiers
	 * are packed sequentially in this byte; we read them as one
	 * 8-bit value.
	 */
	if (hid_locate(sc->sc_rdesc, sc->sc_rdesc_len,
	    HID_USAGE2(HUP_KEYBOARD, 0xE0),
	    hid_input, 0, &sc->sc_loc_modifiers, &flags, &id) != 0) {
		sc->sc_loc_modifiers_id = id;
		/*
		 * Each modifier is declared as a 1-bit field. Extend
		 * the located size to 8 so a single hid_get_udata
		 * yields the full modifier byte. The pos field already
		 * points at bit 0 of the byte (the LeftCtrl bit).
		 */
		sc->sc_loc_modifiers.size = 8;
		sc->sc_loc_modifiers.count = 1;
	}

	/*
	 * Keys array: locate via usage 0x00 (the conventional base
	 * of the keyboard usage range used by boot keyboards). For
	 * non-boot keyboards or unusual descriptors, hid_locate may
	 * not find this; the array-walk fallback below catches those.
	 */
	if (hid_locate(sc->sc_rdesc, sc->sc_rdesc_len,
	    HID_USAGE2(HUP_KEYBOARD, 0x00),
	    hid_input, 0, &sc->sc_loc_keys, &flags, &id) != 0) {
		sc->sc_loc_keys_id = id;
	} else {
		/*
		 * Fallback: walk the descriptor and find the first
		 * input item on HUP_KEYBOARD whose report_count > 1
		 * and that is declared as an array (HIO_VARIABLE not
		 * set). That is the keys-held array.
		 */
		struct hid_data *s;
		struct hid_item hi;

		s = hid_start_parse(sc->sc_rdesc, sc->sc_rdesc_len,
		    1 << hid_input);
		if (s != NULL) {
			while (hid_get_item(s, &hi) > 0) {
				if (hi.kind == hid_input &&
				    HID_GET_USAGE_PAGE(hi.usage) == HUP_KEYBOARD &&
				    hi.loc.count > 1 &&
				    (hi.flags & HIO_VARIABLE) == 0) {
					sc->sc_loc_keys = hi.loc;
					sc->sc_loc_keys_id =
					    (uint8_t)hi.report_ID;
					break;
				}
			}
			hid_end_parse(s);
		}
	}

	if (sc->sc_loc_modifiers.size > 0 || sc->sc_loc_keys.size > 0)
		sc->sc_keyboard_locations_valid = 1;
}

/*
 * inputfs_extract_keyboard -- Stage D.0b.
 *
 * Extract the modifier byte and up to 6 keys-held entries from
 * an interrupt report. Returns 1 if extraction succeeded for at
 * least one location and the report ID matched; 0 otherwise.
 *
 * out_modifiers receives the 8-bit modifier byte. out_keys is a
 * 6-element array; entries beyond the device's actual array
 * count are zero-filled. The caller has initialised out_keys to
 * all zeros.
 *
 * Each element of the keys array is extracted by cloning the
 * cached location and advancing pos by size * index.
 */
static int
inputfs_extract_keyboard(struct inputfs_softc *sc,
    const uint8_t *buf, hid_size_t len,
    uint8_t *out_modifiers, uint8_t out_keys[6])
{
	int extracted = 0;

	if (!sc->sc_keyboard_locations_valid || buf == NULL || len == 0)
		return (0);

	if (sc->sc_loc_modifiers.size > 0 &&
	    inputfs_report_id_matches(sc->sc_loc_modifiers_id, buf, len)) {
		*out_modifiers = (uint8_t)hid_get_udata(buf, len,
		    &sc->sc_loc_modifiers);
		extracted = 1;
	}

	if (sc->sc_loc_keys.size > 0 &&
	    inputfs_report_id_matches(sc->sc_loc_keys_id, buf, len)) {
		uint32_t i;
		uint32_t array_count = sc->sc_loc_keys.count;

		if (array_count > 6)
			array_count = 6;

		for (i = 0; i < array_count; i++) {
			struct hid_location elem = sc->sc_loc_keys;

			elem.pos = sc->sc_loc_keys.pos +
			    sc->sc_loc_keys.size * i;
			elem.count = 1;
			out_keys[i] = (uint8_t)hid_get_udata(buf, len, &elem);
		}
		extracted = 1;
	}

	return (extracted);
}

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
	uint8_t mod_changed = sc->sc_prev_modifiers ^ modifiers;
	uint16_t dev_slot;
	uint8_t payload[32];
	int i;
	uint32_t bit;

	dev_slot = (sc->sc_state_slot == INPUTFS_NO_STATE_SLOT)
	    ? INPUTFS_SYNTHETIC_DEVICE
	    : (uint16_t)sc->sc_state_slot;

	/* Modifier ups: bits set in prev but not in new. */
	for (bit = 0; bit < 8; bit++) {
		uint8_t mask = (uint8_t)(1u << bit);
		if ((mod_changed & mask) == 0)
			continue;
		if ((sc->sc_prev_modifiers & mask) == 0)
			continue;
		memset(payload, 0, sizeof(payload));
		inputfs_put_u32le(payload, 0, 0xE0u + bit);
		inputfs_put_u32le(payload, 4, 0xFFFFFFFFu); /* positional */
		inputfs_put_u32le(payload, 8, modifiers);
		/* session_id at offset 12, currently 0. */
		inputfs_events_publish(INPUTFS_SOURCE_KEYBOARD,
		    INPUTFS_KEYBOARD_KEY_UP,
		    dev_slot, 0, payload, 16);
	}

	/* Array key ups: keys in prev not in current. */
	for (i = 0; i < 6; i++) {
		uint8_t usage = sc->sc_prev_keys[i];
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
		if (inputfs_keyboard_key_in_set(usage, sc->sc_prev_keys))
			continue;
		memset(payload, 0, sizeof(payload));
		inputfs_put_u32le(payload, 0, usage);
		inputfs_put_u32le(payload, 4, 0xFFFFFFFFu);
		inputfs_put_u32le(payload, 8, modifiers);
		inputfs_events_publish(INPUTFS_SOURCE_KEYBOARD,
		    INPUTFS_KEYBOARD_KEY_DOWN,
		    dev_slot, 0, payload, 16);
	}

	/* Update previous-state buffer for next report. */
	sc->sc_prev_modifiers = modifiers;
	memcpy(sc->sc_prev_keys, keys, sizeof(sc->sc_prev_keys));
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
	    sc->sc_pointer_locations_valid &&
	    copy_len > 0) {
		int32_t dx = 0, dy = 0, dw = 0;
		uint32_t buttons = 0;
		int extracted;

		extracted = inputfs_extract_pointer(sc, sc->sc_ibuf,
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
			 * pointer.motion: emit if X or Y was extracted
			 * (a button-only or wheel-only report does not
			 * produce a motion event).
			 */
			if (sc->sc_loc_x.size > 0 ||
			    sc->sc_loc_y.size > 0) {
				memset(payload, 0, sizeof(payload));
				inputfs_put_i32le(payload, 0, new_x);
				inputfs_put_i32le(payload, 4, new_y);
				inputfs_put_i32le(payload, 8, dx);
				inputfs_put_i32le(payload, 12, dy);
				inputfs_put_u32le(payload, 16, buttons);
				/* session_id at offset 20, currently 0. */
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
				/* session_id at offset 16, currently 0. */
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
			if (sc->sc_has_wheel && dw != 0) {
				memset(payload, 0, sizeof(payload));
				inputfs_put_i32le(payload, 0, new_x);
				inputfs_put_i32le(payload, 4, new_y);
				inputfs_put_i32le(payload, 8, 0); /* dx */
				inputfs_put_i32le(payload, 12, dw);
				inputfs_put_u32le(payload, 16, 0); /* lines */
				/* session_id at offset 20, currently 0. */
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
	    sc->sc_keyboard_locations_valid &&
	    copy_len > 0) {
		uint8_t modifiers = 0;
		uint8_t keys[6] = { 0, 0, 0, 0, 0, 0 };
		int extracted;

		extracted = inputfs_extract_keyboard(sc, sc->sc_ibuf,
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
		inputfs_pointer_locate(sc);

		if (sc->sc_pointer_locations_valid) {
			device_printf(dev,
			    "inputfs: pointer locations cached "
			    "(x=%s y=%s wheel=%s buttons=%u count=%u)\n",
			    sc->sc_loc_x.size > 0 ? "yes" : "no",
			    sc->sc_loc_y.size > 0 ? "yes" : "no",
			    sc->sc_has_wheel ? "yes" : "no",
			    (unsigned int)sc->sc_loc_buttons.size,
			    (unsigned int)sc->sc_button_count);
		}

		/*
		 * Stage D.0b: populate the keyboard location cache.
		 * Same pattern as the pointer cache: called
		 * unconditionally, the interrupt path checks
		 * sc_keyboard_locations_valid before extracting.
		 */
		inputfs_keyboard_locate(sc);

		if (sc->sc_keyboard_locations_valid) {
			device_printf(dev,
			    "inputfs: keyboard locations cached "
			    "(modifiers=%s keys=%s array_count=%u)\n",
			    sc->sc_loc_modifiers.size > 0 ? "yes" : "no",
			    sc->sc_loc_keys.size > 0 ? "yes" : "no",
			    (unsigned int)sc->sc_loc_keys.count);
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
