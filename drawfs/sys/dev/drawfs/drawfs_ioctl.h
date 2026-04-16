#ifndef _DEV_DRAWFS_DRAWFS_IOCTL_H_
#ifdef _KERNEL
#include <sys/stdint.h>
#else
#include <stdint.h>
#endif
#define _DEV_DRAWFS_DRAWFS_IOCTL_H_

#include <sys/ioccom.h>
#include <sys/types.h>

struct drawfs_stats {
    uint64_t frames_received;
    uint64_t frames_processed;
    uint64_t frames_invalid;

    uint64_t messages_processed;
    uint64_t messages_unsupported;

    uint64_t events_enqueued;
    uint64_t events_dropped;

    uint64_t bytes_in;
    uint64_t bytes_out;

    uint32_t evq_depth;
    uint32_t inbuf_bytes;

    /* Observability: current resource usage */
    uint32_t evq_bytes;         /* current bytes in event queue */
    uint32_t surfaces_count;    /* current number of live surfaces */
    uint64_t surfaces_bytes;    /* total bytes allocated to surfaces */
};

#define DRAWFSGIOC_STATS _IOR('D', 0x01, struct drawfs_stats)


struct drawfs_map_surface_req {
    uint32_t surface_id;
};

struct drawfs_map_surface_rep {
    int32_t  status;
    uint32_t surface_id;
    uint32_t stride_bytes;
    uint32_t bytes_total;
};


/*
 * Step 11: select a surface for mmap on this file descriptor.
 * Caller sets surface_id. Kernel fills status, stride_bytes, bytes_total.
 */
struct drawfs_map_surface {
    int32_t  status;
    uint32_t surface_id;
    uint32_t stride_bytes;
    uint32_t bytes_total;
};

#define DRAWFSGIOC_MAP_SURFACE _IOWR('D', 0x02, struct drawfs_map_surface)

/*
 * Inject an input event into the session that owns a given surface.
 *
 * The caller (a bridge daemon or input router) fills in:
 *   surface_id  — the surface that should receive the event.
 *   event_type  — one of DRAWFS_EVT_KEY, EVT_POINTER, EVT_SCROLL, EVT_TOUCH.
 *   payload     — fixed-size union containing the event data.
 *
 * The kernel looks up the session that owns surface_id, builds a framed
 * event message, and enqueues it on that session's read queue.
 *
 * Returns:
 *   0        success
 *   ENOENT   surface_id not found in any session
 *   EINVAL   unrecognised event_type
 *   ENOSPC   target session event queue is full (backpressure)
 *   ENXIO    target session is closing
 */

/* Maximum payload bytes for any input event type. */
#define DRAWFS_INPUT_PAYLOAD_MAX  32

struct drawfs_inject_input {
    uint32_t surface_id;
    uint16_t event_type;   /* DRAWFS_EVT_KEY / _POINTER / _SCROLL / _TOUCH */
    uint16_t _pad;
    uint8_t  payload[DRAWFS_INPUT_PAYLOAD_MAX];
};

#define DRAWFSGIOC_INJECT_INPUT _IOWR('D', 0x03, struct drawfs_inject_input)

#endif
