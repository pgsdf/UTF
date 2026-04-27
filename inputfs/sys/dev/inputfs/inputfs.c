/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage C.2: state region publication.
 * Builds on B.5 (per-device role classification) by publishing
 * the inputfs state region at /var/run/sema/input/state per
 * the byte layout in shared/INPUT_STATE.md and the regions
 * decision in inputfs/docs/adr/0002-shared-memory-regions.md.
 *
 * Architecture (Option B from BACKLOG Stage C kernel-side notes):
 *
 *   1. The module maintains an 11,328-byte live state buffer
 *      in kernel memory (inputfs_state_buf).
 *
 *   2. The interrupt path (inputfs_intr) updates the live
 *      buffer in place under inputfs_state_mtx (MTX_SPIN, safe
 *      from interrupt context). It increments the seqlock
 *      pre/post each batch update.
 *
 *   3. After updating, inputfs_intr sets inputfs_state_dirty
 *      and wakes the kthread worker.
 *
 *   4. The kthread worker (inputfs_state_worker) sleeps on
 *      inputfs_state_dirty becoming true. When woken, it
 *      copies the entire live buffer to /var/run/sema/input/state
 *      via vn_rdwr from kthread context (vnode I/O is illegal
 *      from interrupt context per FreeBSD's locking rules).
 *
 *   5. Userspace consumers mmap the file shared and see updates
 *      via shared/src/input.zig's StateReader. The seqlock
 *      retry loop on the reader side handles mid-write
 *      observations during the kthread's vn_rdwr.
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
#include <sys/endian.h>

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
 * Per-device softc. Stage B.4 added interrupt buffer fields;
 * Stage B.5 added the per-device role bitmask;
 * Stage C.2 adds the state-region slot index assigned at attach.
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

static struct proc		*inputfs_kthread_proc;
static int			 inputfs_kthread_run;
static int			 inputfs_kthread_done;

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
	const char *name;
	size_t base;
	size_t name_len;

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

	/* name: 64-byte field, null-padded. */
	memset(inputfs_state_buf + base + DEV_OFF_NAME, 0, 64);
	if (hw != NULL && hw->name[0] != '\0') {
		name = hw->name;
		name_len = strlen(name);
		if (name_len > 63)
			name_len = 63;
		memcpy(inputfs_state_buf + base + DEV_OFF_NAME, name, name_len);
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
 * inputfs_state_worker -- the kthread that syncs the live
 * buffer to the file. Sleeps on inputfs_state_dirty becoming
 * true; wakes up, clears the flag, performs one sync, sleeps
 * again. Exits when inputfs_kthread_run is cleared at unload.
 *
 * Sync rate cap: at most one sync per (hz / INPUTFS_SYNC_HZ)
 * ticks. With INPUTFS_SYNC_HZ = 1000 and the FreeBSD default
 * hz=1000, that is one tick (1 ms), which is the granularity
 * of pause_sbt. This caps disk write rate at ~1 kHz even under
 * a sustained input flood.
 */
#define INPUTFS_SYNC_HZ 1000

static void
inputfs_state_worker(void *arg)
{
	struct thread *td = curthread;
	int min_ticks;

	min_ticks = hz / INPUTFS_SYNC_HZ;
	if (min_ticks < 1)
		min_ticks = 1;

	(void)arg;

	inputfs_state_open_file(td);

	for (;;) {
		mtx_lock_spin(&inputfs_state_mtx);
		while (!inputfs_state_dirty && inputfs_kthread_run) {
			/* msleep_spin drops and reacquires the spin
			 * mutex, allowing other threads to update
			 * the live buffer while we sleep. */
			msleep_spin(&inputfs_state_dirty,
			    &inputfs_state_mtx,
			    "ifsstate", 0);
		}
		if (!inputfs_kthread_run) {
			mtx_unlock_spin(&inputfs_state_mtx);
			break;
		}
		inputfs_state_dirty = 0;
		mtx_unlock_spin(&inputfs_state_mtx);

		inputfs_state_sync_to_file(td);

		/* Rate cap: ensure at least min_ticks between syncs. */
		pause("ifsrate", min_ticks);
	}

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
 * inputfs_intr -- hidbus interrupt callback.
 *
 * Stage B.4: copies the report into the per-device buffer and
 * logs a hex-dump line.
 *
 * Stage C.2: for INPUTFS_ROLE_POINTER devices, parses the
 * boot-protocol mouse layout (byte 0 = buttons, byte 1 = signed
 * x delta, byte 2 = signed y delta) and accumulates into the
 * global pointer position. Other roles are not yet parsed; they
 * still produce hex-dump log lines.
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
	 * Stage C.2: pointer accumulation. Boot-protocol mouse
	 * layout assumed for INPUTFS_ROLE_POINTER devices. This is
	 * a starting point; richer descriptor-driven parsing is a
	 * follow-on within Stage C.
	 */
	if ((sc->sc_roles & INPUTFS_ROLE_POINTER) != 0 && copy_len >= 3) {
		int32_t dx = (int32_t)(int8_t)bytes[1];
		int32_t dy = (int32_t)(int8_t)bytes[2];
		uint32_t buttons = (uint32_t)bytes[0] & 0x07u; /* L,R,M */

		mtx_lock_spin(&inputfs_state_mtx);
		inputfs_state_seqlock_begin();
		inputfs_state_update_pointer(dx, dy, buttons);
		inputfs_state_advance_seq();
		inputfs_state_seqlock_end();
		inputfs_state_mark_dirty();
		mtx_unlock_spin(&inputfs_state_mtx);
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
	 */
	if (inputfs_state_buf != NULL &&
	    sc->sc_state_slot != INPUTFS_NO_STATE_SLOT) {
		uint8_t slot = sc->sc_state_slot;

		mtx_lock(&sc->sc_mtx);
		mtx_lock_spin(&inputfs_state_mtx);

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
		printf("inputfs: Stage C.2 loading "
		    "(state region publication via vnode-backed sync; "
		    "no event ring, no userspace event delivery)\n");

		/* Allocate the live buffer. */
		inputfs_state_buf = malloc(INPUTFS_STATE_SIZE,
		    M_INPUTFS, M_WAITOK | M_ZERO);
		inputfs_state_init_buf(inputfs_state_buf);
		inputfs_state_seq = 0;
		inputfs_state_slot_used = 0;
		inputfs_state_dirty = 0;

		/* Initialize the spin mutex used by the interrupt
		 * path and the kthread worker. */
		mtx_init(&inputfs_state_mtx, "inputfs state",
		    NULL, MTX_SPIN);

		/* Start the kthread worker. */
		inputfs_kthread_run = 1;
		inputfs_kthread_done = 0;
		error = kproc_create(inputfs_state_worker, NULL,
		    &inputfs_kthread_proc, 0, 0, "inputfs_state");
		if (error != 0) {
			printf("inputfs: kproc_create failed: %d\n", error);
			mtx_destroy(&inputfs_state_mtx);
			free(inputfs_state_buf, M_INPUTFS);
			inputfs_state_buf = NULL;
			return (error);
		}

		printf("inputfs: state region buffer ready (%lu bytes), "
		    "kthread started\n",
		    (unsigned long)INPUTFS_STATE_SIZE);
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
