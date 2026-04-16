#ifndef _DEV_DRAWFS_DRAWFS_PROTO_H_
#define _DEV_DRAWFS_DRAWFS_PROTO_H_

#include <sys/types.h>

#define DRAWFS_MAGIC   0x31575244u /* 'DRW1' little endian */
#define DRAWFS_VERSION 0x0100u     /* major 1 minor 0 */

#define DRAWFS_ALIGN   4u
static inline uint32_t drawfs_align4(uint32_t n) { return (n + 3u) & ~3u; }

struct drawfs_frame_hdr {
    uint32_t magic;
    uint16_t version;
    uint16_t header_bytes;
    uint32_t frame_bytes;
    uint32_t frame_id;
} __attribute__((packed));

struct drawfs_msg_hdr {
    uint16_t msg_type;
    uint16_t msg_flags;
    uint32_t msg_bytes;
    uint32_t msg_id;
    uint32_t reserved;
} __attribute__((packed));

/* BEGIN GENERATED CONSTANTS */
/* Do not edit. Generated from shared/protocol_constants.json
 * by shared/tools/gen_constants.py */

enum drawfs_msg_type {
    /* Replies (0x8xxx) */
    DRAWFS_RPL_OK                         = 0x8000,  /* Generic success */
    DRAWFS_RPL_HELLO                      = 0x8001,  /* Handshake response */
    DRAWFS_RPL_DISPLAY_LIST               = 0x8010,  /* Display list response */
    DRAWFS_RPL_DISPLAY_OPEN               = 0x8011,  /* Display open response */
    DRAWFS_RPL_SURFACE_CREATE             = 0x8020,  /* Surface created */
    DRAWFS_RPL_SURFACE_DESTROY            = 0x8021,  /* Surface destroyed */
    DRAWFS_RPL_SURFACE_PRESENT            = 0x8022,  /* Present acknowledged */
    DRAWFS_RPL_ERROR                      = 0x8FFF,  /* Error response */

    /* Requests (0x0xxx) */
    DRAWFS_REQ_HELLO                      = 0x0001,  /* Client handshake */
    DRAWFS_REQ_DISPLAY_LIST               = 0x0010,  /* Enumerate displays */
    DRAWFS_REQ_DISPLAY_OPEN               = 0x0011,  /* Open display */
    DRAWFS_REQ_SURFACE_CREATE             = 0x0020,  /* Create surface */
    DRAWFS_REQ_SURFACE_DESTROY            = 0x0021,  /* Destroy surface */
    DRAWFS_REQ_SURFACE_PRESENT            = 0x0022,  /* Present surface */
};

enum drawfs_err_code {
    DRAWFS_ERR_OK                         = 0,  /* Success */
    DRAWFS_ERR_INVALID_FRAME              = 1,  /* Malformed frame */
    DRAWFS_ERR_INVALID_MSG                = 2,  /* Malformed message */
    DRAWFS_ERR_UNSUPPORTED_VERSION        = 3,  /* Version mismatch */
    DRAWFS_ERR_UNSUPPORTED_CAP            = 4,  /* Unsupported capability */
    DRAWFS_ERR_PERMISSION                 = 5,  /* Permission denied */
    DRAWFS_ERR_NOT_FOUND                  = 6,  /* Resource not found */
    DRAWFS_ERR_BUSY                       = 7,  /* Resource busy */
    DRAWFS_ERR_NO_MEMORY                  = 8,  /* Out of memory */
    DRAWFS_ERR_INVALID_HANDLE             = 9,  /* Invalid handle */
    DRAWFS_ERR_INVALID_STATE              = 10,  /* Invalid state */
    DRAWFS_ERR_INVALID_ARG                = 11,  /* Invalid argument */
    DRAWFS_ERR_OVERFLOW                   = 12,  /* Buffer overflow */
    DRAWFS_ERR_IO                         = 13,  /* I/O error */
    DRAWFS_ERR_INTERNAL                   = 14,  /* Internal error */
};
/* END GENERATED CONSTANTS */

struct drawfs_req_hello {
    uint16_t client_major;
    uint16_t client_minor;
    uint32_t client_flags;
    uint32_t max_reply_bytes;
} __attribute__((packed));

struct drawfs_rpl_hello {
    int32_t  status;
    uint16_t server_major;
    uint16_t server_minor;
    uint32_t server_flags;
    uint32_t max_reply_bytes; /* max bytes server will send in a single reply */
} __attribute__((packed));

struct drawfs_rpl_display_list {
    int32_t  status;
    uint32_t display_count;
} __attribute__((packed));

struct drawfs_rpl_error {
    uint32_t err_code;
    uint32_t err_detail;
    uint32_t err_offset;
} __attribute__((packed));


/*
 * DISPLAY_LIST reply payload (Step 8)
 *
 * Reply message payload layout:
 *   uint32_t count;
 *   struct drawfs_display_desc desc[count];
 *
 * refresh_mhz is millihertz (e.g., 60000 for 60.000 Hz).
 */
struct drawfs_display_desc {
    uint32_t display_id;
    uint32_t width_px;
    uint32_t height_px;
    uint32_t refresh_mhz;
    uint32_t flags; /* reserved */
};


/*
 * DISPLAY_OPEN request payload (Step 9)
 *   uint32_t display_id;
 */
struct drawfs_display_open_req {
    uint32_t display_id;
};

/*
 * DISPLAY_OPEN reply payload (Step 9)
 *   int32_t  status;         (0 = ok, else errno style)
 *   uint32_t display_handle; (0 on failure)
 *   uint32_t active_display_id;
 */
struct drawfs_display_open_rep {
    int32_t  status;
    uint32_t display_handle;
    uint32_t active_display_id;
};


/* Pixel formats (initial) */
enum drawfs_pixel_format {
    DRAWFS_FMT_XRGB8888 = 1,
};

/*
 * SURFACE_CREATE request payload (Step 10A)
 */
struct drawfs_surface_create_req {
    uint32_t width_px;
    uint32_t height_px;
    uint32_t format;
    uint32_t flags;
};

/*
 * SURFACE_CREATE reply payload (Step 10A)
 */
struct drawfs_surface_create_rep {
    int32_t  status;
    uint32_t surface_id;
    uint32_t stride_bytes;
    uint32_t bytes_total;
};


/*
 * SURFACE_DESTROY request payload (Step 10B)
 */
struct drawfs_surface_destroy_req {
    uint32_t surface_id;
};

/*
 * SURFACE_DESTROY reply payload (Step 10B)
 */
struct drawfs_surface_destroy_rep {
    int32_t  status;
    uint32_t surface_id;
};

/*
 * SURFACE_PRESENT (Step 12)
 *
 * Request: Client submits a surface for presentation.
 * Reply: Server acknowledges with status and echoes the cookie.
 * Event: Server notifies when surface is actually displayed.
 *
 * The cookie field is an opaque 64-bit value provided by the client
 * in the request. It is echoed back in the reply and the presented
 * event, allowing clients to correlate presentation completion with
 * the original request (e.g., for frame timing or double-buffering).
 */
/* BEGIN GENERATED CONSTANTS: events */
/* Do not edit. Generated from shared/protocol_constants.json
 * by shared/tools/gen_constants.py */

enum drawfs_event_type {
    /* Events (0x9xxx) */
    DRAWFS_EVT_SURFACE_PRESENTED          = 0x9002,  /* Surface displayed */
};
/* END GENERATED CONSTANTS: events */

struct drawfs_req_surface_present {
    uint32_t surface_id;
    uint32_t flags;      /* reserved for future (vsync, damage, etc.) */
    uint64_t cookie;     /* opaque client value, echoed in reply/event */
} __packed;

struct drawfs_rpl_surface_present {
    int32_t  status;     /* 0 = success, else error code */
    uint32_t surface_id;
    uint64_t cookie;     /* echoed from request */
} __packed;

struct drawfs_evt_surface_presented {
    uint32_t surface_id;
    uint32_t reserved;
    uint64_t cookie;     /* echoed from request */
} __packed;
#endif
