/*-
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * drawfs_drm.h — DRM/KMS backend interface for drawfs (DF-3)
 *
 * This header declares the interface between drawfs.c and the optional
 * DRM/KMS display backend (drawfs_drm.c).  The backend is selected at
 * runtime via the hw.drawfs.backend sysctl.  When set to "drm", display
 * open performs real mode-setting and surface present triggers a page flip.
 * When set to "swap" (the default), the existing swap-backed vm_object path
 * is used unchanged.
 *
 * Locking: all functions in this interface are called with the session lock
 * (s->lock) held by the caller unless otherwise noted.  The DRM backend is
 * responsible for its own per-display lock (drawfs_drm_display.drm_mtx).
 */

#ifndef _DEV_DRAWFS_DRAWFS_DRM_H_
#define _DEV_DRAWFS_DRAWFS_DRM_H_

#include <sys/param.h>
#include <sys/lock.h>
#include <sys/mutex.h>
#include <sys/queue.h>

#include "drawfs_internal.h"

/* -------------------------------------------------------------------------
 * Backend selector sysctl
 * -------------------------------------------------------------------------
 * Exported from drawfs.c.  Values: "swap" (default) or "drm".
 * Changes take effect for new DISPLAY_OPEN calls; open displays are
 * unaffected until they are closed.
 */
extern char drawfs_backend[16];

/* -------------------------------------------------------------------------
 * DRM display state
 * -------------------------------------------------------------------------
 * One instance per DISPLAY_OPEN when using the DRM backend.
 * Stored in drawfs_session.drm_display (pointer, NULL for swap backend).
 */
struct drawfs_drm_display {
    struct mtx      drm_mtx;        /* protects fields below */
    int             drm_fd;         /* file descriptor for /dev/dri/cardN */
    uint32_t        connector_id;   /* DRM connector selected for this display */
    uint32_t        crtc_id;        /* CRTC assigned to this connector */
    uint32_t        mode_fb_id;     /* front framebuffer object id */
    uint32_t        back_fb_id;     /* back framebuffer object id (double-buffer) */
    uint32_t        front_handle;   /* GEM handle for front buffer */
    uint32_t        back_handle;    /* GEM handle for back buffer */
    uint32_t        width_px;       /* display width in pixels */
    uint32_t        height_px;      /* display height in pixels */
    uint32_t        stride_bytes;   /* bytes per row (aligned to hardware) */
    uint8_t        *front_map;      /* kernel VA of front dumb buffer */
    uint8_t        *back_map;       /* kernel VA of back dumb buffer */
    int             flip_pending;   /* page flip queued, not yet acknowledged */
};

/* -------------------------------------------------------------------------
 * DRM backend entry points
 * Called from drawfs.c when hw.drawfs.backend == "drm".
 * -------------------------------------------------------------------------
 */

/*
 * drawfs_drm_init() — initialise the DRM subsystem.
 *
 * Called from drawfs_modevent(MOD_LOAD).  Opens /dev/dri/card0 (the first
 * DRM device), verifies capability (dumb buffers), and stores the fd for
 * later use.  Returns 0 on success, errno on failure.  Failure here causes
 * drawfs to fall back to the swap backend and log a warning; it does NOT
 * prevent module load.
 */
int  drawfs_drm_init(void);

/*
 * drawfs_drm_fini() — tear down the DRM subsystem.
 *
 * Called from drawfs_modevent(MOD_UNLOAD).  Closes the DRM fd and frees
 * any global DRM state.  Must be safe to call even if drawfs_drm_init()
 * failed.
 */
void drawfs_drm_fini(void);

/*
 * drawfs_drm_display_open() — set display mode and allocate dumb buffers.
 *
 * Called from drawfs_reply_display_open() when hw.drawfs.backend == "drm".
 * Enumerates DRM connectors, selects the first connected one, picks the
 * preferred mode, allocates two dumb buffers (front + back for
 * double-buffering), creates framebuffer objects, and performs the initial
 * mode set via drmModeSetCrtc().
 *
 * On success, allocates and returns a drawfs_drm_display struct.
 * Returns NULL on failure (caller falls back to swap backend for this
 * session).
 *
 * Called WITHOUT s->lock held.
 */
struct drawfs_drm_display *drawfs_drm_display_open(uint32_t display_id,
    uint32_t *out_width, uint32_t *out_height, uint32_t *out_stride);

/*
 * drawfs_drm_display_close() — release mode and free dumb buffers.
 *
 * Called when the session closes or the display is explicitly released.
 * Unmaps dumb buffers, destroys framebuffer objects, destroys GEM handles,
 * and frees the struct.
 *
 * Called WITHOUT s->lock held.
 */
void drawfs_drm_display_close(struct drawfs_drm_display *dd);

/*
 * drawfs_drm_surface_present() — copy surface pixels and schedule page flip.
 *
 * Called from drawfs_reply_surface_present() when hw.drawfs.backend == "drm"
 * and a DRM display is active.
 *
 * 1. Copies the surface's vm_object pixel data into the back dumb buffer,
 *    applying the optional damage rectangle list for partial updates.
 * 2. Calls drmModePageFlip() to schedule a vblank-synchronised flip.
 * 3. Swaps front/back buffer handles so the next call writes to the other
 *    buffer.
 *
 * Returns 0 on success, errno on failure.  A failure here does NOT abort
 * the SURFACE_PRESENT reply; the client still receives the acknowledgement.
 */
int  drawfs_drm_surface_present(struct drawfs_drm_display *dd,
    struct drawfs_surface *surf,
    const struct drawfs_damage_rect *damage, uint32_t damage_count);

/* -------------------------------------------------------------------------
 * Damage rectangle (for partial update optimisation)
 * -------------------------------------------------------------------------
 * Passed from the SURFACE_PRESENT payload when the client provides damage
 * information.  When damage_count == 0, the full surface is copied.
 */
struct drawfs_damage_rect {
    uint32_t x;
    uint32_t y;
    uint32_t w;
    uint32_t h;
};

#endif /* _DEV_DRAWFS_DRAWFS_DRM_H_ */
