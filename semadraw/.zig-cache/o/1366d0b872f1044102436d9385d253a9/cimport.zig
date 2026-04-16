pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_labs = @import("std").zig.c_builtins.__builtin_labs;
pub const __builtin_llabs = @import("std").zig.c_builtins.__builtin_llabs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub extern fn ioctl(c_int, c_ulong, ...) c_int;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_long;
pub const __uint64_t = c_ulong;
pub const __int_least8_t = __int8_t;
pub const __int_least16_t = __int16_t;
pub const __int_least32_t = __int32_t;
pub const __int_least64_t = __int64_t;
pub const __intmax_t = __int64_t;
pub const __uint_least8_t = __uint8_t;
pub const __uint_least16_t = __uint16_t;
pub const __uint_least32_t = __uint32_t;
pub const __uint_least64_t = __uint64_t;
pub const __uintmax_t = __uint64_t;
pub const __intptr_t = __int64_t;
pub const __intfptr_t = __int64_t;
pub const __uintptr_t = __uint64_t;
pub const __uintfptr_t = __uint64_t;
pub const __vm_offset_t = __uint64_t;
pub const __vm_size_t = __uint64_t;
pub const __size_t = __uint64_t;
pub const __ssize_t = __int64_t;
pub const __ptrdiff_t = __int64_t;
pub const __clock_t = __int32_t;
pub const __critical_t = __int64_t;
pub const __double_t = f64;
pub const __float_t = f32;
pub const __int_fast8_t = __int32_t;
pub const __int_fast16_t = __int32_t;
pub const __int_fast32_t = __int32_t;
pub const __int_fast64_t = __int64_t;
pub const __register_t = __int64_t;
pub const __segsz_t = __int64_t;
pub const __time_t = __int64_t;
pub const __uint_fast8_t = __uint32_t;
pub const __uint_fast16_t = __uint32_t;
pub const __uint_fast32_t = __uint32_t;
pub const __uint_fast64_t = __uint64_t;
pub const __u_register_t = __uint64_t;
pub const __vm_paddr_t = __uint64_t;
pub const ___wchar_t = c_int;
pub const __blksize_t = __int32_t;
pub const __blkcnt_t = __int64_t;
pub const __clockid_t = __int32_t;
pub const __fflags_t = __uint32_t;
pub const __fsblkcnt_t = __uint64_t;
pub const __fsfilcnt_t = __uint64_t;
pub const __gid_t = __uint32_t;
pub const __id_t = __int64_t;
pub const __ino_t = __uint64_t;
pub const __key_t = c_long;
pub const __lwpid_t = __int32_t;
pub const __mode_t = __uint16_t;
pub const __accmode_t = c_int;
pub const __nl_item = c_int;
pub const __nlink_t = __uint64_t;
pub const __off_t = __int64_t;
pub const __off64_t = __int64_t;
pub const __pid_t = __int32_t;
pub const __sbintime_t = __int64_t;
pub const __rlim_t = __int64_t;
pub const __sa_family_t = __uint8_t;
pub const __socklen_t = __uint32_t;
pub const __suseconds_t = c_long;
pub const struct___timer = opaque {};
pub const __timer_t = ?*struct___timer;
pub const struct___mq = opaque {};
pub const __mqd_t = ?*struct___mq;
pub const __uid_t = __uint32_t;
pub const __useconds_t = c_uint;
pub const __cpuwhich_t = c_int;
pub const __cpulevel_t = c_int;
pub const __cpusetid_t = c_int;
pub const __daddr_t = __int64_t;
pub const __ct_rune_t = c_int;
pub const __rune_t = __ct_rune_t;
pub const __wint_t = __ct_rune_t;
pub const __char16_t = __uint_least16_t;
pub const __char32_t = __uint_least32_t;
pub const __max_align_t = extern struct {
    __max_align1: c_longlong align(8) = @import("std").mem.zeroes(c_longlong),
    __max_align2: c_longdouble align(8) = @import("std").mem.zeroes(c_longdouble),
};
pub const __acl_tag_t = __uint32_t;
pub const __acl_perm_t = __uint32_t;
pub const __acl_entry_type_t = __uint16_t;
pub const __acl_flag_t = __uint16_t;
pub const __acl_type_t = __uint32_t;
pub const __acl_permset_t = [*c]__uint32_t;
pub const __acl_flagset_t = [*c]__uint16_t;
pub const __dev_t = __uint64_t;
pub const __fixpt_t = __uint32_t;
pub const __mbstate_t = extern union {
    __mbstate8: [128]u8,
    _mbstateL: __int64_t,
};
pub const __rman_res_t = __uintmax_t;
pub const struct___va_list_tag_1 = extern struct {
    gp_offset: c_uint = @import("std").mem.zeroes(c_uint),
    fp_offset: c_uint = @import("std").mem.zeroes(c_uint),
    overflow_arg_area: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    reg_save_area: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const __builtin_va_list = [1]struct___va_list_tag_1;
pub const __va_list = __builtin_va_list;
pub const __gnuc_va_list = __va_list;
pub const struct_fiodgname_arg = extern struct {
    len: c_int = @import("std").mem.zeroes(c_int),
    buf: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const struct_fiobmap2_arg = extern struct {
    bn: __daddr_t = @import("std").mem.zeroes(__daddr_t),
    runp: c_int = @import("std").mem.zeroes(c_int),
    runb: c_int = @import("std").mem.zeroes(c_int),
};
pub const struct_winsize = extern struct {
    ws_row: c_ushort = @import("std").mem.zeroes(c_ushort),
    ws_col: c_ushort = @import("std").mem.zeroes(c_ushort),
    ws_xpixel: c_ushort = @import("std").mem.zeroes(c_ushort),
    ws_ypixel: c_ushort = @import("std").mem.zeroes(c_ushort),
};
pub const tcflag_t = c_uint;
pub const cc_t = u8;
pub const speed_t = c_uint;
pub const struct_termios = extern struct {
    c_iflag: tcflag_t = @import("std").mem.zeroes(tcflag_t),
    c_oflag: tcflag_t = @import("std").mem.zeroes(tcflag_t),
    c_cflag: tcflag_t = @import("std").mem.zeroes(tcflag_t),
    c_lflag: tcflag_t = @import("std").mem.zeroes(tcflag_t),
    c_cc: [20]cc_t = @import("std").mem.zeroes([20]cc_t),
    c_ispeed: speed_t = @import("std").mem.zeroes(speed_t),
    c_ospeed: speed_t = @import("std").mem.zeroes(speed_t),
};
pub const pid_t = __pid_t;
pub extern fn cfgetispeed([*c]const struct_termios) speed_t;
pub extern fn cfgetospeed([*c]const struct_termios) speed_t;
pub extern fn cfsetispeed([*c]struct_termios, speed_t) c_int;
pub extern fn cfsetospeed([*c]struct_termios, speed_t) c_int;
pub extern fn tcgetattr(c_int, [*c]struct_termios) c_int;
pub extern fn tcsetattr(c_int, c_int, [*c]const struct_termios) c_int;
pub extern fn tcdrain(c_int) c_int;
pub extern fn tcflow(c_int, c_int) c_int;
pub extern fn tcflush(c_int, c_int) c_int;
pub extern fn tcsendbreak(c_int, c_int) c_int;
pub extern fn tcgetsid(c_int) pid_t;
pub extern fn tcsetsid(c_int, pid_t) c_int;
pub extern fn cfmakeraw([*c]struct_termios) void;
pub extern fn cfmakesane([*c]struct_termios) void;
pub extern fn cfsetspeed([*c]struct_termios, speed_t) c_int;
pub extern fn tcgetwinsize(c_int, [*c]struct_winsize) c_int;
pub extern fn tcsetwinsize(c_int, [*c]const struct_winsize) c_int;
pub const struct_pthread = opaque {};
pub const struct_pthread_attr = opaque {};
pub const struct_pthread_cond = opaque {};
pub const struct_pthread_cond_attr = opaque {};
pub const struct_pthread_mutex = opaque {};
pub const struct_pthread_mutex_attr = opaque {};
pub const pthread_mutex_t = ?*struct_pthread_mutex;
pub const struct_pthread_once = extern struct {
    state: c_int = @import("std").mem.zeroes(c_int),
    mutex: pthread_mutex_t = @import("std").mem.zeroes(pthread_mutex_t),
};
pub const struct_pthread_rwlock = opaque {};
pub const struct_pthread_rwlockattr = opaque {};
pub const struct_pthread_barrier = opaque {};
pub const struct_pthread_barrier_attr = opaque {};
pub const struct_pthread_spinlock = opaque {};
pub const pthread_t = ?*struct_pthread;
pub const pthread_attr_t = ?*struct_pthread_attr;
pub const pthread_mutexattr_t = ?*struct_pthread_mutex_attr;
pub const pthread_cond_t = ?*struct_pthread_cond;
pub const pthread_condattr_t = ?*struct_pthread_cond_attr;
pub const pthread_key_t = c_int;
pub const pthread_once_t = struct_pthread_once;
pub const pthread_rwlock_t = ?*struct_pthread_rwlock;
pub const pthread_rwlockattr_t = ?*struct_pthread_rwlockattr;
pub const pthread_barrier_t = ?*struct_pthread_barrier;
pub const struct_pthread_barrierattr = opaque {};
pub const pthread_barrierattr_t = ?*struct_pthread_barrierattr;
pub const pthread_spinlock_t = ?*struct_pthread_spinlock;
pub const pthread_addr_t = ?*anyopaque;
pub const pthread_startroutine_t = ?*const fn (?*anyopaque) callconv(.c) ?*anyopaque;
pub const u_char = u8;
pub const u_short = c_ushort;
pub const u_int = c_uint;
pub const u_long = c_ulong;
pub const ushort = c_ushort;
pub const uint = c_uint;
pub const intmax_t = __intmax_t;
pub const uintmax_t = __uintmax_t;
pub const u_int8_t = __uint8_t;
pub const u_int16_t = __uint16_t;
pub const u_int32_t = __uint32_t;
pub const u_int64_t = __uint64_t;
pub const u_quad_t = __uint64_t;
pub const quad_t = __int64_t;
pub const qaddr_t = [*c]quad_t;
pub const caddr_t = [*c]u8;
pub const c_caddr_t = [*c]const u8;
pub const blksize_t = __blksize_t;
pub const cpuwhich_t = __cpuwhich_t;
pub const cpulevel_t = __cpulevel_t;
pub const cpusetid_t = __cpusetid_t;
pub const blkcnt_t = __blkcnt_t;
pub const clock_t = __clock_t;
pub const clockid_t = __clockid_t;
pub const critical_t = __critical_t;
pub const daddr_t = __daddr_t;
pub const dev_t = __dev_t;
pub const fflags_t = __fflags_t;
pub const fixpt_t = __fixpt_t;
pub const fsblkcnt_t = __fsblkcnt_t;
pub const fsfilcnt_t = __fsfilcnt_t;
pub const gid_t = __gid_t;
pub const in_addr_t = __uint32_t;
pub const in_port_t = __uint16_t;
pub const id_t = __id_t;
pub const ino_t = __ino_t;
pub const key_t = __key_t;
pub const lwpid_t = __lwpid_t;
pub const mode_t = __mode_t;
pub const accmode_t = __accmode_t;
pub const nlink_t = __nlink_t;
pub const off_t = __off_t;
pub const off64_t = __off64_t;
pub const register_t = __register_t;
pub const rlim_t = __rlim_t;
pub const sbintime_t = __sbintime_t;
pub const segsz_t = __segsz_t;
pub const suseconds_t = __suseconds_t;
pub const time_t = __time_t;
pub const timer_t = __timer_t;
pub const mqd_t = __mqd_t;
pub const u_register_t = __u_register_t;
pub const uid_t = __uid_t;
pub const useconds_t = __useconds_t;
pub const cap_ioctl_t = c_ulong;
pub const struct_cap_rights = opaque {};
pub const cap_rights_t = struct_cap_rights;
pub const kpaddr_t = __uint64_t;
pub const kvaddr_t = __uint64_t;
pub const ksize_t = __uint64_t;
pub const kssize_t = __int64_t;
pub const vm_offset_t = __vm_offset_t;
pub const vm_ooffset_t = __uint64_t;
pub const vm_paddr_t = __vm_paddr_t;
pub const vm_pindex_t = __uint64_t;
pub const vm_size_t = __vm_size_t;
pub const rman_res_t = __rman_res_t;
pub const syscallarg_t = __register_t;
pub const struct___sigset = extern struct {
    __bits: [4]__uint32_t = @import("std").mem.zeroes([4]__uint32_t),
};
pub const __sigset_t = struct___sigset;
pub const struct_timeval = extern struct {
    tv_sec: time_t = @import("std").mem.zeroes(time_t),
    tv_usec: suseconds_t = @import("std").mem.zeroes(suseconds_t),
};
pub const struct_timespec = extern struct {
    tv_sec: time_t = @import("std").mem.zeroes(time_t),
    tv_nsec: c_long = @import("std").mem.zeroes(c_long),
};
pub const struct_itimerspec = extern struct {
    it_interval: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    it_value: struct_timespec = @import("std").mem.zeroes(struct_timespec),
};
pub const __fd_mask = c_ulong;
pub const fd_mask = __fd_mask;
pub const sigset_t = __sigset_t;
pub const struct_fd_set = extern struct {
    __fds_bits: [16]__fd_mask = @import("std").mem.zeroes([16]__fd_mask),
};
pub const fd_set = struct_fd_set;
pub extern fn pselect(c_int, noalias [*c]fd_set, noalias [*c]fd_set, noalias [*c]fd_set, noalias [*c]const struct_timespec, noalias [*c]const sigset_t) c_int;
pub extern fn select(c_int, [*c]fd_set, [*c]fd_set, [*c]fd_set, [*c]struct_timeval) c_int;
pub fn __major(arg__d: dev_t) callconv(.c) c_int {
    var _d = arg__d;
    _ = &_d;
    return @as(c_int, @bitCast(@as(c_uint, @truncate(((_d >> @intCast(32)) & @as(dev_t, @bitCast(@as(c_ulong, @as(c_uint, 4294967040))))) | ((_d >> @intCast(8)) & @as(dev_t, @bitCast(@as(c_long, @as(c_int, 255)))))))));
}
pub fn __minor(arg__d: dev_t) callconv(.c) c_int {
    var _d = arg__d;
    _ = &_d;
    return @as(c_int, @bitCast(@as(c_uint, @truncate(((_d >> @intCast(24)) & @as(dev_t, @bitCast(@as(c_long, @as(c_int, 65280))))) | (_d & @as(dev_t, @bitCast(@as(c_ulong, @as(c_uint, 4294902015)))))))));
}
pub fn __makedev(arg__Major: c_int, arg__Minor: c_int) callconv(.c) dev_t {
    var _Major = arg__Major;
    _ = &_Major;
    var _Minor = arg__Minor;
    _ = &_Minor;
    return (((@as(dev_t, @bitCast(@as(c_ulong, @as(c_uint, @bitCast(_Major)) & @as(c_uint, 4294967040)))) << @intCast(32)) | @as(dev_t, @bitCast(@as(c_long, (_Major & @as(c_int, 255)) << @intCast(8))))) | (@as(dev_t, @bitCast(@as(c_long, _Minor & @as(c_int, 65280)))) << @intCast(24))) | @as(dev_t, @bitCast(@as(c_ulong, @as(c_uint, @bitCast(_Minor)) & @as(c_uint, 4294902015))));
}
pub extern fn ftruncate(c_int, off_t) c_int;
pub extern fn lseek(c_int, off_t, c_int) off_t;
pub extern fn mmap(?*anyopaque, usize, c_int, c_int, c_int, off_t) ?*anyopaque;
pub extern fn truncate([*c]const u8, off_t) c_int;
pub const VFNT_MAP_NORMAL: c_int = 0;
pub const VFNT_MAP_NORMAL_RIGHT: c_int = 1;
pub const VFNT_MAP_BOLD: c_int = 2;
pub const VFNT_MAP_BOLD_RIGHT: c_int = 3;
pub const VFNT_MAPS: c_int = 4;
pub const enum_vfnt_map_type = c_uint;
pub const struct_font_info = extern struct {
    fi_checksum: i32 = @import("std").mem.zeroes(i32),
    fi_width: u32 = @import("std").mem.zeroes(u32),
    fi_height: u32 = @import("std").mem.zeroes(u32),
    fi_bitmap_size: u32 = @import("std").mem.zeroes(u32),
    fi_map_count: [4]u32 = @import("std").mem.zeroes([4]u32),
};
pub const struct_vfnt_map = extern struct {
    vfm_src: u32 align(1) = @import("std").mem.zeroes(u32),
    vfm_dst: u16 align(1) = @import("std").mem.zeroes(u16),
    vfm_len: u16 align(1) = @import("std").mem.zeroes(u16),
};
pub const vfnt_map_t = struct_vfnt_map;
pub const struct_vt_font = extern struct {
    vf_map: [4][*c]vfnt_map_t = @import("std").mem.zeroes([4][*c]vfnt_map_t),
    vf_bytes: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    vf_height: u32 = @import("std").mem.zeroes(u32),
    vf_width: u32 = @import("std").mem.zeroes(u32),
    vf_map_count: [4]u32 = @import("std").mem.zeroes([4]u32),
    vf_refcount: u32 = @import("std").mem.zeroes(u32),
};
pub const struct_vt_font_bitmap_data = extern struct {
    vfbd_width: u32 = @import("std").mem.zeroes(u32),
    vfbd_height: u32 = @import("std").mem.zeroes(u32),
    vfbd_compressed_size: u32 = @import("std").mem.zeroes(u32),
    vfbd_uncompressed_size: u32 = @import("std").mem.zeroes(u32),
    vfbd_compressed_data: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    vfbd_font: [*c]struct_vt_font = @import("std").mem.zeroes([*c]struct_vt_font),
};
pub const vt_font_bitmap_data_t = struct_vt_font_bitmap_data;
pub const FONT_AUTO: c_int = 0;
pub const FONT_MANUAL: c_int = 1;
pub const FONT_BUILTIN: c_int = 2;
pub const FONT_RELOAD: c_int = 3;
pub const FONT_FLAGS = c_uint;
const struct_unnamed_2 = extern struct {
    stqe_next: [*c]struct_fontlist = @import("std").mem.zeroes([*c]struct_fontlist),
};
pub const struct_fontlist = extern struct {
    font_name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    font_flags: FONT_FLAGS = @import("std").mem.zeroes(FONT_FLAGS),
    font_data: [*c]vt_font_bitmap_data_t = @import("std").mem.zeroes([*c]vt_font_bitmap_data_t),
    font_load: ?*const fn ([*c]u8) callconv(.c) [*c]vt_font_bitmap_data_t = @import("std").mem.zeroes(?*const fn ([*c]u8) callconv(.c) [*c]vt_font_bitmap_data_t),
    font_next: struct_unnamed_2 = @import("std").mem.zeroes(struct_unnamed_2),
};
pub const struct_font_list = extern struct {
    stqh_first: [*c]struct_fontlist = @import("std").mem.zeroes([*c]struct_fontlist),
    stqh_last: [*c][*c]struct_fontlist = @import("std").mem.zeroes([*c][*c]struct_fontlist),
};
pub const font_list_t = struct_font_list;
pub const struct_font_header = extern struct {
    fh_magic: [8]u8 align(1) = @import("std").mem.zeroes([8]u8),
    fh_width: u8 align(1) = @import("std").mem.zeroes(u8),
    fh_height: u8 align(1) = @import("std").mem.zeroes(u8),
    fh_pad: u16 align(1) = @import("std").mem.zeroes(u16),
    fh_glyph_count: u32 align(1) = @import("std").mem.zeroes(u32),
    fh_map_count: [4]u32 align(1) = @import("std").mem.zeroes([4]u32),
};
pub const struct__scr_size = extern struct {
    scr_size: [3]c_int = @import("std").mem.zeroes([3]c_int),
};
pub const scr_size_t = struct__scr_size;
pub const struct__scrmap = extern struct {
    scrmap: [256]u8 = @import("std").mem.zeroes([256]u8),
};
pub const scrmap_t = struct__scrmap;
pub const struct_ssaver = extern struct {
    name: [16]u8 = @import("std").mem.zeroes([16]u8),
    num: c_int = @import("std").mem.zeroes(c_int),
    time: c_long = @import("std").mem.zeroes(c_long),
};
pub const ssaver_t = struct_ssaver;
pub const struct_mouse_data = extern struct {
    x: c_int = @import("std").mem.zeroes(c_int),
    y: c_int = @import("std").mem.zeroes(c_int),
    z: c_int = @import("std").mem.zeroes(c_int),
    buttons: c_int = @import("std").mem.zeroes(c_int),
};
pub const mouse_data_t = struct_mouse_data;
pub const struct_mouse_mode = extern struct {
    mode: c_int = @import("std").mem.zeroes(c_int),
    signal: c_int = @import("std").mem.zeroes(c_int),
};
pub const mouse_mode_t = struct_mouse_mode;
pub const struct_mouse_event = extern struct {
    id: c_int = @import("std").mem.zeroes(c_int),
    value: c_int = @import("std").mem.zeroes(c_int),
};
pub const mouse_event_t = struct_mouse_event;
const union_unnamed_3 = extern union {
    data: mouse_data_t,
    mode: mouse_mode_t,
    event: mouse_event_t,
    mouse_char: c_int,
};
pub const struct_mouse_info = extern struct {
    operation: c_int = @import("std").mem.zeroes(c_int),
    u: union_unnamed_3 = @import("std").mem.zeroes(union_unnamed_3),
};
pub const mouse_info_t = struct_mouse_info;
pub const struct_cshape = extern struct {
    shape: [3]c_int = @import("std").mem.zeroes([3]c_int),
};
pub const struct_fnt8 = extern struct {
    fnt8x8: [2048]u8 = @import("std").mem.zeroes([2048]u8),
};
pub const fnt8_t = struct_fnt8;
pub const struct_fnt14 = extern struct {
    fnt8x14: [3584]u8 = @import("std").mem.zeroes([3584]u8),
};
pub const fnt14_t = struct_fnt14;
pub const struct_fnt16 = extern struct {
    fnt8x16: [4096]u8 = @import("std").mem.zeroes([4096]u8),
};
pub const fnt16_t = struct_fnt16;
pub const struct_vfnt = extern struct {
    map: [4][*c]vfnt_map_t = @import("std").mem.zeroes([4][*c]vfnt_map_t),
    glyphs: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    map_count: [4]c_uint = @import("std").mem.zeroes([4]c_uint),
    glyph_count: c_uint = @import("std").mem.zeroes(c_uint),
    width: c_uint = @import("std").mem.zeroes(c_uint),
    height: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const vfnt_t = struct_vfnt;
pub const struct_colors = extern struct {
    fore: u8 = @import("std").mem.zeroes(u8),
    back: u8 = @import("std").mem.zeroes(u8),
};
pub const struct_vid_info = extern struct {
    size: c_short = @import("std").mem.zeroes(c_short),
    m_num: c_short = @import("std").mem.zeroes(c_short),
    font_size: u_short = @import("std").mem.zeroes(u_short),
    mv_row: u_short = @import("std").mem.zeroes(u_short),
    mv_col: u_short = @import("std").mem.zeroes(u_short),
    mv_rsz: u_short = @import("std").mem.zeroes(u_short),
    mv_csz: u_short = @import("std").mem.zeroes(u_short),
    mv_hsz: u_short = @import("std").mem.zeroes(u_short),
    mv_norm: struct_colors = @import("std").mem.zeroes(struct_colors),
    mv_rev: struct_colors = @import("std").mem.zeroes(struct_colors),
    mv_grfc: struct_colors = @import("std").mem.zeroes(struct_colors),
    mv_ovscan: u_char = @import("std").mem.zeroes(u_char),
    mk_keylock: u_char = @import("std").mem.zeroes(u_char),
};
pub const vid_info_t = struct_vid_info;
pub const struct_scrshot = extern struct {
    x: c_int = @import("std").mem.zeroes(c_int),
    y: c_int = @import("std").mem.zeroes(c_int),
    xsize: c_int = @import("std").mem.zeroes(c_int),
    ysize: c_int = @import("std").mem.zeroes(c_int),
    buf: [*c]u_int16_t = @import("std").mem.zeroes([*c]u_int16_t),
};
pub const scrshot_t = struct_scrshot;
pub const struct_term_info = extern struct {
    ti_index: c_int = @import("std").mem.zeroes(c_int),
    ti_flags: c_int = @import("std").mem.zeroes(c_int),
    ti_name: [32]u_char = @import("std").mem.zeroes([32]u_char),
    ti_desc: [64]u_char = @import("std").mem.zeroes([64]u_char),
};
pub const term_info_t = struct_term_info;
pub const struct_vt_mode = extern struct {
    mode: u8 = @import("std").mem.zeroes(u8),
    waitv: u8 = @import("std").mem.zeroes(u8),
    relsig: c_short = @import("std").mem.zeroes(c_short),
    acqsig: c_short = @import("std").mem.zeroes(c_short),
    frsig: c_short = @import("std").mem.zeroes(c_short),
};
pub const vtmode_t = struct_vt_mode;
pub const struct_keyboard_info = extern struct {
    kb_index: c_int = @import("std").mem.zeroes(c_int),
    kb_name: [16]u8 = @import("std").mem.zeroes([16]u8),
    kb_unit: c_int = @import("std").mem.zeroes(c_int),
    kb_type: c_int = @import("std").mem.zeroes(c_int),
    kb_config: c_int = @import("std").mem.zeroes(c_int),
    kb_flags: c_int = @import("std").mem.zeroes(c_int),
};
pub const keyboard_info_t = struct_keyboard_info;
pub const kbdelays: [4]c_int = [4]c_int{
    250,
    500,
    750,
    1000,
};
pub const kbrates: [32]c_int = [32]c_int{
    34,
    38,
    42,
    46,
    50,
    55,
    59,
    63,
    68,
    76,
    84,
    92,
    100,
    110,
    118,
    126,
    136,
    152,
    168,
    184,
    200,
    220,
    236,
    252,
    272,
    304,
    336,
    368,
    400,
    440,
    472,
    504,
};
pub const struct_keyboard_repeat = extern struct {
    kb_repeat: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub const keyboard_repeat_t = struct_keyboard_repeat;
pub const struct_keyent_t = extern struct {
    map: [8]u_int = @import("std").mem.zeroes([8]u_int),
    spcl: u_char = @import("std").mem.zeroes(u_char),
    flgs: u_char = @import("std").mem.zeroes(u_char),
};
pub const struct_keymap = extern struct {
    n_keys: u_short = @import("std").mem.zeroes(u_short),
    key: [256]struct_keyent_t = @import("std").mem.zeroes([256]struct_keyent_t),
};
pub const keymap_t = struct_keymap;
pub const struct_acc_t = extern struct {
    accchar: u_int = @import("std").mem.zeroes(u_int),
    map: [52][2]u_int = @import("std").mem.zeroes([52][2]u_int),
};
pub const struct_accentmap = extern struct {
    n_accs: u_short = @import("std").mem.zeroes(u_short),
    acc: [15]struct_acc_t = @import("std").mem.zeroes([15]struct_acc_t),
};
pub const accentmap_t = struct_accentmap;
pub const struct_keyarg = extern struct {
    keynum: u_short = @import("std").mem.zeroes(u_short),
    key: struct_keyent_t = @import("std").mem.zeroes(struct_keyent_t),
};
pub const keyarg_t = struct_keyarg;
pub const struct_fkeytab = extern struct {
    str: [16]u_char = @import("std").mem.zeroes([16]u_char),
    len: u_char = @import("std").mem.zeroes(u_char),
};
pub const fkeytab_t = struct_fkeytab;
pub const struct_fkeyarg = extern struct {
    keynum: u_short = @import("std").mem.zeroes(u_short),
    keydef: [16]u8 = @import("std").mem.zeroes([16]u8),
    flen: u8 = @import("std").mem.zeroes(u8),
};
pub const fkeyarg_t = struct_fkeyarg;
pub const struct_flock = extern struct {
    l_start: off_t = @import("std").mem.zeroes(off_t),
    l_len: off_t = @import("std").mem.zeroes(off_t),
    l_pid: pid_t = @import("std").mem.zeroes(pid_t),
    l_type: c_short = @import("std").mem.zeroes(c_short),
    l_whence: c_short = @import("std").mem.zeroes(c_short),
    l_sysid: c_int = @import("std").mem.zeroes(c_int),
};
pub const struct___oflock = extern struct {
    l_start: off_t = @import("std").mem.zeroes(off_t),
    l_len: off_t = @import("std").mem.zeroes(off_t),
    l_pid: pid_t = @import("std").mem.zeroes(pid_t),
    l_type: c_short = @import("std").mem.zeroes(c_short),
    l_whence: c_short = @import("std").mem.zeroes(c_short),
};
pub const struct_spacectl_range = extern struct {
    r_offset: off_t = @import("std").mem.zeroes(off_t),
    r_len: off_t = @import("std").mem.zeroes(off_t),
};
pub extern fn open([*c]const u8, c_int, ...) c_int;
pub extern fn creat([*c]const u8, mode_t) c_int;
pub extern fn fcntl(c_int, c_int, ...) c_int;
pub extern fn flock(c_int, c_int) c_int;
pub extern fn fspacectl(c_int, c_int, [*c]const struct_spacectl_range, c_int, [*c]struct_spacectl_range) c_int;
pub extern fn openat(c_int, [*c]const u8, c_int, ...) c_int;
pub extern fn posix_fadvise(c_int, off_t, off_t, c_int) c_int;
pub extern fn posix_fallocate(c_int, off_t, off_t) c_int;
pub const struct_dirent = extern struct {
    d_fileno: ino_t = @import("std").mem.zeroes(ino_t),
    d_off: off_t = @import("std").mem.zeroes(off_t),
    d_reclen: __uint16_t = @import("std").mem.zeroes(__uint16_t),
    d_type: __uint8_t = @import("std").mem.zeroes(__uint8_t),
    d_pad0: __uint8_t = @import("std").mem.zeroes(__uint8_t),
    d_namlen: __uint16_t = @import("std").mem.zeroes(__uint16_t),
    d_pad1: __uint16_t = @import("std").mem.zeroes(__uint16_t),
    d_name: [256]u8 = @import("std").mem.zeroes([256]u8),
};
pub const struct__dirdesc = opaque {};
pub const DIR = struct__dirdesc;
pub extern fn alphasort([*c][*c]const struct_dirent, [*c][*c]const struct_dirent) c_int;
pub extern fn dirfd(?*DIR) c_int;
pub extern fn versionsort([*c][*c]const struct_dirent, [*c][*c]const struct_dirent) c_int;
pub extern fn __opendir2([*c]const u8, c_int) ?*DIR;
pub extern fn fdclosedir(?*DIR) c_int;
pub extern fn getdents(c_int, [*c]u8, usize) isize;
pub extern fn getdirentries(c_int, [*c]u8, usize, [*c]off_t) isize;
pub extern fn opendir([*c]const u8) ?*DIR;
pub extern fn fdopendir(c_int) ?*DIR;
pub extern fn readdir(?*DIR) [*c]struct_dirent;
pub extern fn readdir_r(?*DIR, [*c]struct_dirent, [*c][*c]struct_dirent) c_int;
pub extern fn rewinddir(?*DIR) void;
pub extern fn scandir([*c]const u8, [*c][*c][*c]struct_dirent, ?*const fn ([*c]const struct_dirent) callconv(.c) c_int, ?*const fn ([*c][*c]const struct_dirent, [*c][*c]const struct_dirent) callconv(.c) c_int) c_int;
pub extern fn fdscandir(c_int, [*c][*c][*c]struct_dirent, ?*const fn ([*c]const struct_dirent) callconv(.c) c_int, ?*const fn ([*c][*c]const struct_dirent, [*c][*c]const struct_dirent) callconv(.c) c_int) c_int;
pub extern fn scandirat(c_int, [*c]const u8, [*c][*c][*c]struct_dirent, ?*const fn ([*c]const struct_dirent) callconv(.c) c_int, ?*const fn ([*c][*c]const struct_dirent, [*c][*c]const struct_dirent) callconv(.c) c_int) c_int;
pub extern fn seekdir(?*DIR, c_long) void;
pub extern fn telldir(?*DIR) c_long;
pub extern fn closedir(?*DIR) c_int;
pub extern fn _exit(c_int) noreturn;
pub extern fn access([*c]const u8, c_int) c_int;
pub extern fn alarm(c_uint) c_uint;
pub extern fn chdir([*c]const u8) c_int;
pub extern fn chown([*c]const u8, uid_t, gid_t) c_int;
pub extern fn close(c_int) c_int;
pub extern fn closefrom(c_int) void;
pub extern fn dup(c_int) c_int;
pub extern fn dup2(c_int, c_int) c_int;
pub extern fn execl([*c]const u8, [*c]const u8, ...) c_int;
pub extern fn execle([*c]const u8, [*c]const u8, ...) c_int;
pub extern fn execlp([*c]const u8, [*c]const u8, ...) c_int;
pub extern fn execv([*c]const u8, [*c]const [*c]u8) c_int;
pub extern fn execve([*c]const u8, [*c]const [*c]u8, [*c]const [*c]u8) c_int;
pub extern fn execvp([*c]const u8, [*c]const [*c]u8) c_int;
pub extern fn fork() pid_t;
pub extern fn fpathconf(c_int, c_int) c_long;
pub extern fn getcwd([*c]u8, usize) [*c]u8;
pub extern fn getegid() gid_t;
pub extern fn geteuid() uid_t;
pub extern fn getgid() gid_t;
pub extern fn getgroups(c_int, [*c]gid_t) c_int;
pub extern fn getlogin() [*c]u8;
pub extern fn getpgrp() pid_t;
pub extern fn getpid() pid_t;
pub extern fn getppid() pid_t;
pub extern fn getuid() uid_t;
pub extern fn isatty(c_int) c_int;
pub extern fn link([*c]const u8, [*c]const u8) c_int;
pub extern fn pathconf([*c]const u8, c_int) c_long;
pub extern fn pause() c_int;
pub extern fn pipe([*c]c_int) c_int;
pub extern fn read(c_int, ?*anyopaque, usize) isize;
pub extern fn rmdir([*c]const u8) c_int;
pub extern fn setgid(gid_t) c_int;
pub extern fn setpgid(pid_t, pid_t) c_int;
pub extern fn setsid() pid_t;
pub extern fn setuid(uid_t) c_int;
pub extern fn sleep(c_uint) c_uint;
pub extern fn sysconf(c_int) c_long;
pub extern fn tcgetpgrp(c_int) pid_t;
pub extern fn tcsetpgrp(c_int, pid_t) c_int;
pub extern fn ttyname(c_int) [*c]u8;
pub extern fn ttyname_r(c_int, [*c]u8, usize) c_int;
pub extern fn unlink([*c]const u8) c_int;
pub extern fn write(c_int, ?*const anyopaque, usize) isize;
pub extern fn confstr(c_int, [*c]u8, usize) usize;
pub extern fn getopt(c_int, [*c]const [*c]u8, [*c]const u8) c_int;
pub extern var optarg: [*c]u8;
pub extern var optind: c_int;
pub extern var opterr: c_int;
pub extern var optopt: c_int;
pub extern fn fsync(c_int) c_int;
pub extern fn fdatasync(c_int) c_int;
pub extern fn getlogin_r([*c]u8, usize) c_int;
pub extern fn fchown(c_int, uid_t, gid_t) c_int;
pub extern fn readlink(noalias [*c]const u8, noalias [*c]u8, usize) isize;
pub extern fn gethostname([*c]u8, usize) c_int;
pub extern fn setegid(gid_t) c_int;
pub extern fn seteuid(uid_t) c_int;
pub extern fn getsid(_pid: pid_t) c_int;
pub extern fn fchdir(c_int) c_int;
pub extern fn getpgid(_pid: pid_t) c_int;
pub extern fn lchown([*c]const u8, uid_t, gid_t) c_int;
pub extern fn pread(c_int, ?*anyopaque, usize, off_t) isize;
pub extern fn pwrite(c_int, ?*const anyopaque, usize, off_t) isize;
pub extern fn faccessat(c_int, [*c]const u8, c_int, c_int) c_int;
pub extern fn fchownat(c_int, [*c]const u8, uid_t, gid_t, c_int) c_int;
pub extern fn fexecve(c_int, [*c]const [*c]u8, [*c]const [*c]u8) c_int;
pub extern fn linkat(c_int, [*c]const u8, c_int, [*c]const u8, c_int) c_int;
pub extern fn readlinkat(c_int, noalias [*c]const u8, noalias [*c]u8, usize) isize;
pub extern fn symlinkat([*c]const u8, c_int, [*c]const u8) c_int;
pub extern fn unlinkat(c_int, [*c]const u8, c_int) c_int;
pub extern fn symlink(noalias [*c]const u8, noalias [*c]const u8) c_int;
pub extern fn crypt([*c]const u8, [*c]const u8) [*c]u8;
pub extern fn gethostid() c_long;
pub extern fn lockf(c_int, c_int, off_t) c_int;
pub extern fn nice(c_int) c_int;
pub extern fn setregid(gid_t, gid_t) c_int;
pub extern fn setreuid(uid_t, uid_t) c_int;
pub extern fn swab(noalias ?*const anyopaque, noalias ?*anyopaque, isize) void;
pub extern fn sync() void;
pub extern fn brk(?*const anyopaque) c_int;
pub extern fn chroot([*c]const u8) c_int;
pub extern fn getdtablesize() c_int;
pub extern fn getpagesize() c_int;
pub extern fn getpass([*c]const u8) [*c]u8;
pub extern fn sbrk(isize) ?*anyopaque;
pub extern fn getwd([*c]u8) [*c]u8;
pub extern fn ualarm(useconds_t, useconds_t) useconds_t;
pub extern fn usleep(useconds_t) c_int;
pub extern fn vfork() c_int;
pub const struct_crypt_data = extern struct {
    initialized: c_int = @import("std").mem.zeroes(c_int),
    __buf: [256]u8 = @import("std").mem.zeroes([256]u8),
};
pub extern fn acct([*c]const u8) c_int;
pub extern fn async_daemon() c_int;
pub extern fn check_utility_compat([*c]const u8) c_int;
pub extern fn close_range(c_uint, c_uint, c_int) c_int;
pub extern fn copy_file_range(c_int, [*c]off_t, c_int, [*c]off_t, usize, c_uint) isize;
pub extern fn crypt_get_format() [*c]const u8;
pub extern fn crypt_r([*c]const u8, [*c]const u8, [*c]struct_crypt_data) [*c]u8;
pub extern fn crypt_set_format([*c]const u8) c_int;
pub extern fn dup3(c_int, c_int, c_int) c_int;
pub extern fn eaccess([*c]const u8, c_int) c_int;
pub extern fn endusershell() void;
pub extern fn exect([*c]const u8, [*c]const [*c]u8, [*c]const [*c]u8) c_int;
pub extern fn execvP([*c]const u8, [*c]const u8, [*c]const [*c]u8) c_int;
pub extern fn execvpe([*c]const u8, [*c]const [*c]u8, [*c]const [*c]u8) c_int;
pub extern fn feature_present([*c]const u8) c_int;
pub extern fn fchroot(c_int) c_int;
pub extern fn fflagstostr(u_long) [*c]u8;
pub extern fn getdomainname([*c]u8, c_int) c_int;
pub extern fn getentropy(?*anyopaque, usize) c_int;
pub extern fn getgrouplist([*c]const u8, gid_t, [*c]gid_t, [*c]c_int) c_int;
pub extern fn getloginclass([*c]u8, usize) c_int;
pub extern fn getmode(?*const anyopaque, mode_t) mode_t;
pub extern fn getosreldate() c_int;
pub extern fn getpeereid(c_int, [*c]uid_t, [*c]gid_t) c_int;
pub extern fn getresgid([*c]gid_t, [*c]gid_t, [*c]gid_t) c_int;
pub extern fn getresuid([*c]uid_t, [*c]uid_t, [*c]uid_t) c_int;
pub extern fn getusershell() [*c]u8;
pub extern fn initgroups([*c]const u8, gid_t) c_int;
pub extern fn iruserok(c_ulong, c_int, [*c]const u8, [*c]const u8) c_int;
pub extern fn iruserok_sa(?*const anyopaque, c_int, c_int, [*c]const u8, [*c]const u8) c_int;
pub extern fn issetugid() c_int;
pub extern fn __FreeBSD_libc_enter_restricted_mode() void;
pub extern fn kcmp(pid1: pid_t, pid2: pid_t, @"type": c_int, idx1: usize, idx2: usize) c_int;
pub extern fn lpathconf([*c]const u8, c_int) c_long;
pub extern fn mkdtemp([*c]u8) [*c]u8;
pub extern fn mknod([*c]const u8, mode_t, dev_t) c_int;
pub extern fn mkstemp([*c]u8) c_int;
pub extern fn mkstemps([*c]u8, c_int) c_int;
pub extern fn mktemp([*c]u8) [*c]u8;
pub extern fn nfssvc(c_int, ?*anyopaque) c_int;
pub extern fn nlm_syscall(c_int, c_int, c_int, [*c][*c]u8) c_int;
pub extern fn pipe2([*c]c_int, c_int) c_int;
pub extern fn profil([*c]u8, usize, vm_offset_t, c_int) c_int;
pub extern fn rcmd([*c][*c]u8, c_int, [*c]const u8, [*c]const u8, [*c]const u8, [*c]c_int) c_int;
pub extern fn rcmd_af([*c][*c]u8, c_int, [*c]const u8, [*c]const u8, [*c]const u8, [*c]c_int, c_int) c_int;
pub extern fn rcmdsh([*c][*c]u8, c_int, [*c]const u8, [*c]const u8, [*c]const u8, [*c]const u8) c_int;
pub extern fn re_comp([*c]const u8) [*c]u8;
pub extern fn re_exec([*c]const u8) c_int;
pub extern fn reboot(c_int) c_int;
pub extern fn revoke([*c]const u8) c_int;
pub extern fn rfork(c_int) pid_t;
pub extern fn rfork_thread(c_int, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) c_int, ?*anyopaque) pid_t;
pub extern fn rresvport([*c]c_int) c_int;
pub extern fn rresvport_af([*c]c_int, c_int) c_int;
pub extern fn ruserok([*c]const u8, c_int, [*c]const u8, [*c]const u8) c_int;
pub extern fn setdomainname([*c]const u8, c_int) c_int;
pub extern fn setgroups(c_int, [*c]const gid_t) c_int;
pub extern fn sethostid(c_long) void;
pub extern fn sethostname([*c]const u8, c_int) c_int;
pub extern fn setlogin([*c]const u8) c_int;
pub extern fn setloginclass([*c]const u8) c_int;
pub extern fn setmode([*c]const u8) ?*anyopaque;
pub extern fn setpgrp(pid_t, pid_t) c_int;
pub extern fn setproctitle(_fmt: [*c]const u8, ...) void;
pub extern fn setproctitle_fast(_fmt: [*c]const u8, ...) void;
pub extern fn setresgid(gid_t, gid_t, gid_t) c_int;
pub extern fn setresuid(uid_t, uid_t, uid_t) c_int;
pub extern fn setrgid(gid_t) c_int;
pub extern fn setruid(uid_t) c_int;
pub extern fn setusershell() void;
pub extern fn strtofflags([*c][*c]u8, [*c]u_long, [*c]u_long) c_int;
pub extern fn swapon([*c]const u8) c_int;
pub extern fn swapoff([*c]const u8, u_int) c_int;
pub extern fn syscall(c_int, ...) c_int;
pub extern fn __syscall(quad_t, ...) off_t;
pub extern fn undelete([*c]const u8) c_int;
pub extern fn unwhiteout([*c]const u8) c_int;
pub extern fn valloc(usize) ?*anyopaque;
pub extern fn funlinkat(c_int, [*c]const u8, c_int, c_int) c_int;
pub extern fn _Fork() pid_t;
pub extern var optreset: c_int;
pub const wchar_t = ___wchar_t;
pub const div_t = extern struct {
    quot: c_int = @import("std").mem.zeroes(c_int),
    rem: c_int = @import("std").mem.zeroes(c_int),
};
pub const ldiv_t = extern struct {
    quot: c_long = @import("std").mem.zeroes(c_long),
    rem: c_long = @import("std").mem.zeroes(c_long),
};
pub extern var __mb_cur_max: c_int;
pub extern fn ___mb_cur_max() c_int;
pub extern fn abort() noreturn;
pub extern fn abs(c_int) c_int;
pub extern fn atexit(?*const fn () callconv(.c) void) c_int;
pub extern fn atof([*c]const u8) f64;
pub extern fn atoi([*c]const u8) c_int;
pub extern fn atol([*c]const u8) c_long;
pub extern fn bsearch(?*const anyopaque, ?*const anyopaque, usize, usize, ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) ?*anyopaque;
pub extern fn calloc(c_ulong, c_ulong) ?*anyopaque;
pub extern fn div(c_int, c_int) div_t;
pub extern fn exit(c_int) noreturn;
pub extern fn free(?*anyopaque) void;
pub extern fn getenv([*c]const u8) [*c]u8;
pub extern fn getenv_r([*c]const u8, [*c]u8, usize) c_int;
pub extern fn labs(c_long) c_long;
pub extern fn ldiv(c_long, c_long) ldiv_t;
pub extern fn malloc(c_ulong) ?*anyopaque;
pub extern fn mblen([*c]const u8, usize) c_int;
pub extern fn mbstowcs(noalias [*c]wchar_t, noalias [*c]const u8, usize) usize;
pub extern fn mbtowc(noalias [*c]wchar_t, noalias [*c]const u8, usize) c_int;
pub extern fn qsort(?*anyopaque, usize, usize, ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;
pub extern fn rand() c_int;
pub extern fn realloc(?*anyopaque, c_ulong) ?*anyopaque;
pub extern fn srand(c_uint) void;
pub extern fn strtod([*c]const u8, [*c][*c]u8) f64;
pub extern fn strtof([*c]const u8, [*c][*c]u8) f32;
pub extern fn strtol([*c]const u8, [*c][*c]u8, c_int) c_long;
pub extern fn strtold([*c]const u8, [*c][*c]u8) c_longdouble;
pub extern fn strtoul([*c]const u8, [*c][*c]u8, c_int) c_ulong;
pub extern fn system([*c]const u8) c_int;
pub extern fn wctomb([*c]u8, wchar_t) c_int;
pub extern fn wcstombs(noalias [*c]u8, noalias [*c]const wchar_t, usize) usize;
pub const lldiv_t = extern struct {
    quot: c_longlong = @import("std").mem.zeroes(c_longlong),
    rem: c_longlong = @import("std").mem.zeroes(c_longlong),
};
pub extern fn atoll([*c]const u8) c_longlong;
pub extern fn llabs(c_longlong) c_longlong;
pub extern fn lldiv(c_longlong, c_longlong) lldiv_t;
pub extern fn strtoll([*c]const u8, [*c][*c]u8, c_int) c_longlong;
pub extern fn strtoull([*c]const u8, [*c][*c]u8, c_int) c_ulonglong;
pub extern fn _Exit(c_int) noreturn;
pub extern fn aligned_alloc(c_ulong, c_ulong) ?*anyopaque;
pub extern fn at_quick_exit(?*const fn () callconv(.c) void) c_int;
pub extern fn quick_exit(c_int) void;
pub extern fn realpath(noalias [*c]const u8, noalias [*c]u8) [*c]u8;
pub extern fn rand_r([*c]c_uint) c_int;
pub extern fn posix_memalign([*c]?*anyopaque, usize, usize) c_int;
pub extern fn setenv([*c]const u8, [*c]const u8, c_int) c_int;
pub extern fn unsetenv([*c]const u8) c_int;
pub extern fn getsubopt([*c][*c]u8, [*c]const [*c]u8, [*c][*c]u8) c_int;
pub extern fn a64l([*c]const u8) c_long;
pub extern fn drand48() f64;
pub extern fn erand48([*c]c_ushort) f64;
pub extern fn initstate(c_uint, [*c]u8, usize) [*c]u8;
pub extern fn jrand48([*c]c_ushort) c_long;
pub extern fn l64a(c_long) [*c]u8;
pub extern fn lcong48([*c]c_ushort) void;
pub extern fn lrand48() c_long;
pub extern fn mrand48() c_long;
pub extern fn nrand48([*c]c_ushort) c_long;
pub extern fn putenv([*c]u8) c_int;
pub extern fn random() c_long;
pub extern fn seed48([*c]c_ushort) [*c]c_ushort;
pub extern fn setstate([*c]u8) [*c]u8;
pub extern fn srand48(c_long) void;
pub extern fn srandom(c_uint) void;
pub extern fn grantpt(c_int) c_int;
pub extern fn posix_openpt(c_int) c_int;
pub extern fn ptsname(c_int) [*c]u8;
pub extern fn unlockpt(c_int) c_int;
pub extern fn ptsname_r(c_int, [*c]u8, usize) c_int;
pub extern var malloc_conf: [*c]const u8;
pub extern var malloc_message: ?*const fn (?*anyopaque, [*c]const u8) callconv(.c) void;
pub extern fn abort2([*c]const u8, c_int, [*c]?*anyopaque) noreturn;
pub extern fn arc4random() __uint32_t;
pub extern fn arc4random_buf(?*anyopaque, usize) void;
pub extern fn arc4random_uniform(__uint32_t) __uint32_t;
pub extern fn getbsize([*c]c_int, [*c]c_long) [*c]u8;
pub extern fn cgetcap([*c]u8, [*c]const u8, c_int) [*c]u8;
pub extern fn cgetclose() c_int;
pub extern fn cgetent([*c][*c]u8, [*c][*c]u8, [*c]const u8) c_int;
pub extern fn cgetfirst([*c][*c]u8, [*c][*c]u8) c_int;
pub extern fn cgetmatch([*c]const u8, [*c]const u8) c_int;
pub extern fn cgetnext([*c][*c]u8, [*c][*c]u8) c_int;
pub extern fn cgetnum([*c]u8, [*c]const u8, [*c]c_long) c_int;
pub extern fn cgetset([*c]const u8) c_int;
pub extern fn cgetstr([*c]u8, [*c]const u8, [*c][*c]u8) c_int;
pub extern fn cgetustr([*c]u8, [*c]const u8, [*c][*c]u8) c_int;
pub extern fn clearenv() c_int;
pub extern fn daemon(c_int, c_int) c_int;
pub extern fn daemonfd(c_int, c_int) c_int;
pub extern fn devname(__dev_t, __mode_t) [*c]u8;
pub extern fn devname_r(__dev_t, __mode_t, [*c]u8, c_int) [*c]u8;
pub extern fn fdevname(c_int) [*c]u8;
pub extern fn fdevname_r(c_int, [*c]u8, c_int) [*c]u8;
pub extern fn getloadavg([*c]f64, c_int) c_int;
pub extern fn getprogname() [*c]const u8;
pub extern fn heapsort(?*anyopaque, usize, usize, ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) c_int;
pub extern fn l64a_r(c_long, [*c]u8, c_int) c_int;
pub extern fn mergesort(?*anyopaque, usize, usize, ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) c_int;
pub extern fn mkostemp([*c]u8, c_int) c_int;
pub extern fn mkostemps([*c]u8, c_int, c_int) c_int;
pub extern fn mkostempsat(c_int, [*c]u8, c_int, c_int) c_int;
pub extern fn qsort_r(?*anyopaque, usize, usize, ?*const fn (?*const anyopaque, ?*const anyopaque, ?*anyopaque) callconv(.c) c_int, ?*anyopaque) void;
pub extern fn radixsort([*c][*c]const u8, c_int, [*c]const u8, c_uint) c_int;
pub extern fn reallocarray(?*anyopaque, usize, usize) ?*anyopaque;
pub extern fn reallocf(?*anyopaque, usize) ?*anyopaque;
pub extern fn rpmatch([*c]const u8) c_int;
pub extern fn secure_getenv([*c]const u8) [*c]u8;
pub extern fn setprogname([*c]const u8) void;
pub extern fn sradixsort([*c][*c]const u8, c_int, [*c]const u8, c_uint) c_int;
pub extern fn srandomdev() void;
pub extern fn strtonum([*c]const u8, c_longlong, c_longlong, [*c][*c]const u8) c_longlong;
pub extern fn strtoq([*c]const u8, [*c][*c]u8, c_int) __int64_t;
pub extern fn strtouq([*c]const u8, [*c][*c]u8, c_int) __uint64_t;
pub extern fn __qsort_r_compat(?*anyopaque, usize, usize, ?*anyopaque, ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;
comptime {
    asm (".symver __qsort_r_compat, qsort_r@FBSD_1.0");
}
pub extern var suboptarg: [*c]u8;
pub const rsize_t = usize;
pub const errno_t = c_int;
pub const constraint_handler_t = ?*const fn (noalias [*c]const u8, noalias ?*anyopaque, errno_t) callconv(.c) void;
pub extern fn set_constraint_handler_s(handler: constraint_handler_t) constraint_handler_t;
pub extern fn abort_handler_s(noalias [*c]const u8, noalias ?*anyopaque, errno_t) void;
pub extern fn ignore_handler_s(noalias [*c]const u8, noalias ?*anyopaque, errno_t) void;
pub extern fn qsort_s(?*anyopaque, rsize_t, rsize_t, ?*const fn (?*const anyopaque, ?*const anyopaque, ?*anyopaque) callconv(.c) c_int, ?*anyopaque) errno_t;
pub const int_least8_t = __int_least8_t;
pub const int_least16_t = __int_least16_t;
pub const int_least32_t = __int_least32_t;
pub const int_least64_t = __int_least64_t;
pub const uint_least8_t = __uint_least8_t;
pub const uint_least16_t = __uint_least16_t;
pub const uint_least32_t = __uint_least32_t;
pub const uint_least64_t = __uint_least64_t;
pub const int_fast8_t = __int_fast8_t;
pub const int_fast16_t = __int_fast16_t;
pub const int_fast32_t = __int_fast32_t;
pub const int_fast64_t = __int_fast64_t;
pub const uint_fast8_t = __uint_fast8_t;
pub const uint_fast16_t = __uint_fast16_t;
pub const uint_fast32_t = __uint_fast32_t;
pub const uint_fast64_t = __uint_fast64_t;
pub const va_list = __builtin_va_list;
pub const struct_udev = opaque {};
pub const struct_udev_list_entry = opaque {};
pub const struct_udev_device = opaque {};
pub const struct_udev_monitor = opaque {};
pub const struct_udev_enumerate = opaque {};
pub const struct_udev_queue = opaque {};
pub const struct_udev_hwdb = opaque {};
pub extern fn udev_new() ?*struct_udev;
pub extern fn udev_ref(udev: ?*struct_udev) ?*struct_udev;
pub extern fn udev_unref(udev: ?*struct_udev) void;
pub extern fn udev_get_dev_path(udev: ?*struct_udev) [*c]const u8;
pub extern fn udev_get_userdata(udev: ?*struct_udev) ?*anyopaque;
pub extern fn udev_set_userdata(udev: ?*struct_udev, userdata: ?*anyopaque) void;
pub extern fn udev_set_log_fn(udev: ?*struct_udev, log_fn: ?*const fn (?*struct_udev, c_int, [*c]const u8, c_int, [*c]const u8, [*c]const u8, [*c]struct___va_list_tag_1) callconv(.c) void) void;
pub extern fn udev_set_log_priority(udev: ?*struct_udev, priority: c_int) void;
pub extern fn udev_get_log_priority(udev: ?*struct_udev) c_int;
pub extern fn udev_device_new_from_syspath(udev: ?*struct_udev, syspath: [*c]const u8) ?*struct_udev_device;
pub extern fn udev_device_new_from_devnum(udev: ?*struct_udev, @"type": u8, devnum: dev_t) ?*struct_udev_device;
pub extern fn udev_device_new_from_subsystem_sysname(udev: ?*struct_udev, subsystem: [*c]const u8, sysname: [*c]const u8) ?*struct_udev_device;
pub extern fn udev_device_new_from_device_id(udev: ?*struct_udev, id: [*c]const u8) ?*struct_udev_device;
pub extern fn udev_device_new_from_environment(udev: ?*struct_udev) ?*struct_udev_device;
pub extern fn udev_device_ref(udev_device: ?*struct_udev_device) ?*struct_udev_device;
pub extern fn udev_device_unref(udev_device: ?*struct_udev_device) ?*struct_udev_device;
pub extern fn udev_device_get_devnode(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_devpath(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_property_value(udev_device: ?*struct_udev_device, property: [*c]const u8) [*c]const u8;
pub extern fn udev_device_get_sysattr_value(udev_device: ?*struct_udev_device, sysattr: [*c]const u8) [*c]const u8;
pub extern fn udev_device_set_sysattr_value(udev_device: ?*struct_udev_device, sysattr: [*c]const u8, value: [*c]const u8) c_int;
pub extern fn udev_device_get_properties_list_entry(udev_device: ?*struct_udev_device) ?*struct_udev_list_entry;
pub extern fn udev_device_get_sysattr_list_entry(udev_device: ?*struct_udev_device) ?*struct_udev_list_entry;
pub extern fn udev_device_get_tags_list_entry(udev_device: ?*struct_udev_device) ?*struct_udev_list_entry;
pub extern fn udev_device_has_tag(udev_device: ?*struct_udev_device, tag: [*c]const u8) c_int;
pub extern fn udev_device_get_devlinks_list_entry(udev_device: ?*struct_udev_device) ?*struct_udev_list_entry;
pub extern fn udev_device_get_udev(udev_device: ?*struct_udev_device) ?*struct_udev;
pub extern fn udev_device_get_syspath(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_sysname(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_subsystem(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_parent(udev_device: ?*struct_udev_device) ?*struct_udev_device;
pub extern fn udev_device_get_parent_with_subsystem_devtype(udev_device: ?*struct_udev_device, subsystem: [*c]const u8, devtype: [*c]const u8) ?*struct_udev_device;
pub extern fn udev_device_get_is_initialized(udev_device: ?*struct_udev_device) c_int;
pub extern fn udev_device_get_devnum(udev_device: ?*struct_udev_device) dev_t;
pub extern fn udev_device_get_devtype(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_driver(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_sysnum(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_device_get_seqnum(udev_device: ?*struct_udev_device) c_ulonglong;
pub extern fn udev_device_get_usec_since_initialized(udev_device: ?*struct_udev_device) c_ulonglong;
pub extern fn udev_enumerate_new(udev: ?*struct_udev) ?*struct_udev_enumerate;
pub extern fn udev_enumerate_ref(udev_enumerate: ?*struct_udev_enumerate) ?*struct_udev_enumerate;
pub extern fn udev_enumerate_unref(udev_enumerate: ?*struct_udev_enumerate) void;
pub extern fn udev_enumerate_add_match_subsystem(udev_enumerate: ?*struct_udev_enumerate, subsystem: [*c]const u8) c_int;
pub extern fn udev_enumerate_add_nomatch_subsystem(udev_enumerate: ?*struct_udev_enumerate, subsystem: [*c]const u8) c_int;
pub extern fn udev_enumerate_add_match_sysname(udev_enumerate: ?*struct_udev_enumerate, sysname: [*c]const u8) c_int;
pub extern fn udev_enumerate_add_match_sysattr(udev_enumerate: ?*struct_udev_enumerate, sysattr: [*c]const u8, value: [*c]const u8) c_int;
pub extern fn udev_enumerate_add_nomatch_sysattr(udev_enumerate: ?*struct_udev_enumerate, sysattr: [*c]const u8, value: [*c]const u8) c_int;
pub extern fn udev_enumerate_add_match_property(udev_enumerate: ?*struct_udev_enumerate, property: [*c]const u8, value: [*c]const u8) c_int;
pub extern fn udev_enumerate_add_match_tag(udev_enumerate: ?*struct_udev_enumerate, tag: [*c]const u8) c_int;
pub extern fn udev_enumerate_add_match_parent(udev_enumerate: ?*struct_udev_enumerate, parent: ?*struct_udev_device) c_int;
pub extern fn udev_enumerate_add_match_is_initialized(udev_enumerate: ?*struct_udev_enumerate) c_int;
pub extern fn udev_enumerate_scan_devices(udev_enumerate: ?*struct_udev_enumerate) c_int;
pub extern fn udev_enumerate_scan_subsystems(udev_enumerate: ?*struct_udev_enumerate) c_int;
pub extern fn udev_enumerate_get_list_entry(udev_enumerate: ?*struct_udev_enumerate) ?*struct_udev_list_entry;
pub extern fn udev_enumerate_add_syspath(udev_enumerate: ?*struct_udev_enumerate, syspath: [*c]const u8) c_int;
pub extern fn udev_enumerate_get_udev(udev_enumerate: ?*struct_udev_enumerate) ?*struct_udev;
pub extern fn udev_list_entry_get_next(list_entry: ?*struct_udev_list_entry) ?*struct_udev_list_entry;
pub extern fn udev_list_entry_get_name(list_entry: ?*struct_udev_list_entry) [*c]const u8;
pub extern fn udev_list_entry_get_value(list_entry: ?*struct_udev_list_entry) [*c]const u8;
pub extern fn udev_list_entry_get_by_name(list_entry: ?*struct_udev_list_entry, name: [*c]const u8) ?*struct_udev_list_entry;
pub extern fn udev_monitor_new_from_netlink(udev: ?*struct_udev, name: [*c]const u8) ?*struct_udev_monitor;
pub extern fn udev_monitor_ref(um: ?*struct_udev_monitor) ?*struct_udev_monitor;
pub extern fn udev_monitor_unref(udev_monitor: ?*struct_udev_monitor) void;
pub extern fn udev_monitor_filter_add_match_subsystem_devtype(udev_monitor: ?*struct_udev_monitor, subsystem: [*c]const u8, devtype: [*c]const u8) c_int;
pub extern fn udev_monitor_filter_add_match_tag(udev_monitor: ?*struct_udev_monitor, tag: [*c]const u8) c_int;
pub extern fn udev_monitor_enable_receiving(udev_monitor: ?*struct_udev_monitor) c_int;
pub extern fn udev_monitor_get_fd(udev_monitor: ?*struct_udev_monitor) c_int;
pub extern fn udev_monitor_receive_device(udev_monitor: ?*struct_udev_monitor) ?*struct_udev_device;
pub extern fn udev_device_get_action(udev_device: ?*struct_udev_device) [*c]const u8;
pub extern fn udev_monitor_get_udev(udev_monitor: ?*struct_udev_monitor) ?*struct_udev;
pub extern fn udev_monitor_set_receive_buffer_size(um: ?*struct_udev_monitor, size: c_int) c_int;
pub extern fn udev_monitor_filter_update(udev_monitor: ?*struct_udev_monitor) c_int;
pub extern fn udev_monitor_filter_remove(udev_monitor: ?*struct_udev_monitor) c_int;
pub extern fn udev_queue_ref(udev_queue: ?*struct_udev_queue) ?*struct_udev_queue;
pub extern fn udev_queue_unref(udev_queue: ?*struct_udev_queue) ?*struct_udev_queue;
pub extern fn udev_queue_get_udev(udev_queue: ?*struct_udev_queue) ?*struct_udev;
pub extern fn udev_queue_new(udev: ?*struct_udev) ?*struct_udev_queue;
pub extern fn udev_queue_get_kernel_seqnum(udev_queue: ?*struct_udev_queue) c_ulonglong;
pub extern fn udev_queue_get_udev_seqnum(udev_queue: ?*struct_udev_queue) c_ulonglong;
pub extern fn udev_queue_get_udev_is_active(udev_queue: ?*struct_udev_queue) c_int;
pub extern fn udev_queue_get_queue_is_empty(udev_queue: ?*struct_udev_queue) c_int;
pub extern fn udev_queue_get_seqnum_is_finished(udev_queue: ?*struct_udev_queue, seqnum: c_ulonglong) c_int;
pub extern fn udev_queue_get_seqnum_sequence_is_finished(udev_queue: ?*struct_udev_queue, start: c_ulonglong, end: c_ulonglong) c_int;
pub extern fn udev_queue_get_fd(udev_queue: ?*struct_udev_queue) c_int;
pub extern fn udev_queue_flush(udev_queue: ?*struct_udev_queue) c_int;
pub extern fn udev_queue_get_queued_list_entry(udev_queue: ?*struct_udev_queue) ?*struct_udev_list_entry;
pub extern fn udev_hwdb_new(udev: ?*struct_udev) ?*struct_udev_hwdb;
pub extern fn udev_hwdb_ref(hwdb: ?*struct_udev_hwdb) ?*struct_udev_hwdb;
pub extern fn udev_hwdb_unref(hwdb: ?*struct_udev_hwdb) ?*struct_udev_hwdb;
pub extern fn udev_hwdb_get_properties_list_entry(hwdb: ?*struct_udev_hwdb, modalias: [*c]const u8, flags: c_uint) ?*struct_udev_list_entry;
pub extern fn udev_util_encode_string(str: [*c]const u8, str_enc: [*c]u8, len: usize) c_int;
pub const struct_libinput = opaque {};
pub const struct_libinput_device = opaque {};
pub const struct_libinput_device_group = opaque {};
pub const struct_libinput_seat = opaque {};
pub const struct_libinput_tablet_tool = opaque {};
pub const struct_libinput_event = opaque {};
pub const struct_libinput_event_device_notify = opaque {};
pub const struct_libinput_event_keyboard = opaque {};
pub const struct_libinput_event_pointer = opaque {};
pub const struct_libinput_event_touch = opaque {};
pub const struct_libinput_event_tablet_tool = opaque {};
pub const struct_libinput_event_tablet_pad = opaque {};
pub const LIBINPUT_LOG_PRIORITY_DEBUG: c_int = 10;
pub const LIBINPUT_LOG_PRIORITY_INFO: c_int = 20;
pub const LIBINPUT_LOG_PRIORITY_ERROR: c_int = 30;
pub const enum_libinput_log_priority = c_uint;
pub const LIBINPUT_DEVICE_CAP_KEYBOARD: c_int = 0;
pub const LIBINPUT_DEVICE_CAP_POINTER: c_int = 1;
pub const LIBINPUT_DEVICE_CAP_TOUCH: c_int = 2;
pub const LIBINPUT_DEVICE_CAP_TABLET_TOOL: c_int = 3;
pub const LIBINPUT_DEVICE_CAP_TABLET_PAD: c_int = 4;
pub const LIBINPUT_DEVICE_CAP_GESTURE: c_int = 5;
pub const LIBINPUT_DEVICE_CAP_SWITCH: c_int = 6;
pub const enum_libinput_device_capability = c_uint;
pub const LIBINPUT_KEY_STATE_RELEASED: c_int = 0;
pub const LIBINPUT_KEY_STATE_PRESSED: c_int = 1;
pub const enum_libinput_key_state = c_uint;
pub const LIBINPUT_LED_NUM_LOCK: c_int = 1;
pub const LIBINPUT_LED_CAPS_LOCK: c_int = 2;
pub const LIBINPUT_LED_SCROLL_LOCK: c_int = 4;
pub const LIBINPUT_LED_COMPOSE: c_int = 8;
pub const LIBINPUT_LED_KANA: c_int = 16;
pub const enum_libinput_led = c_uint;
pub const LIBINPUT_BUTTON_STATE_RELEASED: c_int = 0;
pub const LIBINPUT_BUTTON_STATE_PRESSED: c_int = 1;
pub const enum_libinput_button_state = c_uint;
pub const LIBINPUT_POINTER_AXIS_SCROLL_VERTICAL: c_int = 0;
pub const LIBINPUT_POINTER_AXIS_SCROLL_HORIZONTAL: c_int = 1;
pub const enum_libinput_pointer_axis = c_uint;
pub const LIBINPUT_POINTER_AXIS_SOURCE_WHEEL: c_int = 1;
pub const LIBINPUT_POINTER_AXIS_SOURCE_FINGER: c_int = 2;
pub const LIBINPUT_POINTER_AXIS_SOURCE_CONTINUOUS: c_int = 3;
pub const LIBINPUT_POINTER_AXIS_SOURCE_WHEEL_TILT: c_int = 4;
pub const enum_libinput_pointer_axis_source = c_uint;
pub const LIBINPUT_TABLET_PAD_RING_SOURCE_UNKNOWN: c_int = 1;
pub const LIBINPUT_TABLET_PAD_RING_SOURCE_FINGER: c_int = 2;
pub const enum_libinput_tablet_pad_ring_axis_source = c_uint;
pub const LIBINPUT_TABLET_PAD_STRIP_SOURCE_UNKNOWN: c_int = 1;
pub const LIBINPUT_TABLET_PAD_STRIP_SOURCE_FINGER: c_int = 2;
pub const enum_libinput_tablet_pad_strip_axis_source = c_uint;
pub const LIBINPUT_TABLET_TOOL_TYPE_PEN: c_int = 1;
pub const LIBINPUT_TABLET_TOOL_TYPE_ERASER: c_int = 2;
pub const LIBINPUT_TABLET_TOOL_TYPE_BRUSH: c_int = 3;
pub const LIBINPUT_TABLET_TOOL_TYPE_PENCIL: c_int = 4;
pub const LIBINPUT_TABLET_TOOL_TYPE_AIRBRUSH: c_int = 5;
pub const LIBINPUT_TABLET_TOOL_TYPE_MOUSE: c_int = 6;
pub const LIBINPUT_TABLET_TOOL_TYPE_LENS: c_int = 7;
pub const LIBINPUT_TABLET_TOOL_TYPE_TOTEM: c_int = 8;
pub const enum_libinput_tablet_tool_type = c_uint;
pub const LIBINPUT_TABLET_TOOL_PROXIMITY_STATE_OUT: c_int = 0;
pub const LIBINPUT_TABLET_TOOL_PROXIMITY_STATE_IN: c_int = 1;
pub const enum_libinput_tablet_tool_proximity_state = c_uint;
pub const LIBINPUT_TABLET_TOOL_TIP_UP: c_int = 0;
pub const LIBINPUT_TABLET_TOOL_TIP_DOWN: c_int = 1;
pub const enum_libinput_tablet_tool_tip_state = c_uint;
pub const struct_libinput_tablet_pad_mode_group = opaque {};
pub extern fn libinput_device_tablet_pad_get_num_mode_groups(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_tablet_pad_get_mode_group(device: ?*struct_libinput_device, index: c_uint) ?*struct_libinput_tablet_pad_mode_group;
pub extern fn libinput_tablet_pad_mode_group_get_index(group: ?*struct_libinput_tablet_pad_mode_group) c_uint;
pub extern fn libinput_tablet_pad_mode_group_get_num_modes(group: ?*struct_libinput_tablet_pad_mode_group) c_uint;
pub extern fn libinput_tablet_pad_mode_group_get_mode(group: ?*struct_libinput_tablet_pad_mode_group) c_uint;
pub extern fn libinput_tablet_pad_mode_group_has_button(group: ?*struct_libinput_tablet_pad_mode_group, button: c_uint) c_int;
pub extern fn libinput_tablet_pad_mode_group_has_dial(group: ?*struct_libinput_tablet_pad_mode_group, dial: c_uint) c_int;
pub extern fn libinput_tablet_pad_mode_group_has_ring(group: ?*struct_libinput_tablet_pad_mode_group, ring: c_uint) c_int;
pub extern fn libinput_tablet_pad_mode_group_has_strip(group: ?*struct_libinput_tablet_pad_mode_group, strip: c_uint) c_int;
pub extern fn libinput_tablet_pad_mode_group_button_is_toggle(group: ?*struct_libinput_tablet_pad_mode_group, button: c_uint) c_int;
pub extern fn libinput_tablet_pad_mode_group_ref(group: ?*struct_libinput_tablet_pad_mode_group) ?*struct_libinput_tablet_pad_mode_group;
pub extern fn libinput_tablet_pad_mode_group_unref(group: ?*struct_libinput_tablet_pad_mode_group) ?*struct_libinput_tablet_pad_mode_group;
pub extern fn libinput_tablet_pad_mode_group_set_user_data(group: ?*struct_libinput_tablet_pad_mode_group, user_data: ?*anyopaque) void;
pub extern fn libinput_tablet_pad_mode_group_get_user_data(group: ?*struct_libinput_tablet_pad_mode_group) ?*anyopaque;
pub const LIBINPUT_SWITCH_STATE_OFF: c_int = 0;
pub const LIBINPUT_SWITCH_STATE_ON: c_int = 1;
pub const enum_libinput_switch_state = c_uint;
pub const LIBINPUT_SWITCH_LID: c_int = 1;
pub const LIBINPUT_SWITCH_TABLET_MODE: c_int = 2;
pub const enum_libinput_switch = c_uint;
pub const struct_libinput_event_switch = opaque {};
pub const LIBINPUT_EVENT_NONE: c_int = 0;
pub const LIBINPUT_EVENT_DEVICE_ADDED: c_int = 1;
pub const LIBINPUT_EVENT_DEVICE_REMOVED: c_int = 2;
pub const LIBINPUT_EVENT_KEYBOARD_KEY: c_int = 300;
pub const LIBINPUT_EVENT_POINTER_MOTION: c_int = 400;
pub const LIBINPUT_EVENT_POINTER_MOTION_ABSOLUTE: c_int = 401;
pub const LIBINPUT_EVENT_POINTER_BUTTON: c_int = 402;
pub const LIBINPUT_EVENT_POINTER_AXIS: c_int = 403;
pub const LIBINPUT_EVENT_POINTER_SCROLL_WHEEL: c_int = 404;
pub const LIBINPUT_EVENT_POINTER_SCROLL_FINGER: c_int = 405;
pub const LIBINPUT_EVENT_POINTER_SCROLL_CONTINUOUS: c_int = 406;
pub const LIBINPUT_EVENT_TOUCH_DOWN: c_int = 500;
pub const LIBINPUT_EVENT_TOUCH_UP: c_int = 501;
pub const LIBINPUT_EVENT_TOUCH_MOTION: c_int = 502;
pub const LIBINPUT_EVENT_TOUCH_CANCEL: c_int = 503;
pub const LIBINPUT_EVENT_TOUCH_FRAME: c_int = 504;
pub const LIBINPUT_EVENT_TABLET_TOOL_AXIS: c_int = 600;
pub const LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY: c_int = 601;
pub const LIBINPUT_EVENT_TABLET_TOOL_TIP: c_int = 602;
pub const LIBINPUT_EVENT_TABLET_TOOL_BUTTON: c_int = 603;
pub const LIBINPUT_EVENT_TABLET_PAD_BUTTON: c_int = 700;
pub const LIBINPUT_EVENT_TABLET_PAD_RING: c_int = 701;
pub const LIBINPUT_EVENT_TABLET_PAD_STRIP: c_int = 702;
pub const LIBINPUT_EVENT_TABLET_PAD_KEY: c_int = 703;
pub const LIBINPUT_EVENT_TABLET_PAD_DIAL: c_int = 704;
pub const LIBINPUT_EVENT_GESTURE_SWIPE_BEGIN: c_int = 800;
pub const LIBINPUT_EVENT_GESTURE_SWIPE_UPDATE: c_int = 801;
pub const LIBINPUT_EVENT_GESTURE_SWIPE_END: c_int = 802;
pub const LIBINPUT_EVENT_GESTURE_PINCH_BEGIN: c_int = 803;
pub const LIBINPUT_EVENT_GESTURE_PINCH_UPDATE: c_int = 804;
pub const LIBINPUT_EVENT_GESTURE_PINCH_END: c_int = 805;
pub const LIBINPUT_EVENT_GESTURE_HOLD_BEGIN: c_int = 806;
pub const LIBINPUT_EVENT_GESTURE_HOLD_END: c_int = 807;
pub const LIBINPUT_EVENT_SWITCH_TOGGLE: c_int = 900;
pub const enum_libinput_event_type = c_uint;
pub extern fn libinput_event_destroy(event: ?*struct_libinput_event) void;
pub extern fn libinput_event_get_type(event: ?*struct_libinput_event) enum_libinput_event_type;
pub extern fn libinput_event_get_context(event: ?*struct_libinput_event) ?*struct_libinput;
pub extern fn libinput_event_get_device(event: ?*struct_libinput_event) ?*struct_libinput_device;
pub extern fn libinput_event_get_pointer_event(event: ?*struct_libinput_event) ?*struct_libinput_event_pointer;
pub extern fn libinput_event_get_keyboard_event(event: ?*struct_libinput_event) ?*struct_libinput_event_keyboard;
pub extern fn libinput_event_get_touch_event(event: ?*struct_libinput_event) ?*struct_libinput_event_touch;
pub const struct_libinput_event_gesture = opaque {};
pub extern fn libinput_event_get_gesture_event(event: ?*struct_libinput_event) ?*struct_libinput_event_gesture;
pub extern fn libinput_event_get_tablet_tool_event(event: ?*struct_libinput_event) ?*struct_libinput_event_tablet_tool;
pub extern fn libinput_event_get_tablet_pad_event(event: ?*struct_libinput_event) ?*struct_libinput_event_tablet_pad;
pub extern fn libinput_event_get_switch_event(event: ?*struct_libinput_event) ?*struct_libinput_event_switch;
pub extern fn libinput_event_get_device_notify_event(event: ?*struct_libinput_event) ?*struct_libinput_event_device_notify;
pub extern fn libinput_event_device_notify_get_base_event(event: ?*struct_libinput_event_device_notify) ?*struct_libinput_event;
pub extern fn libinput_event_keyboard_get_time(event: ?*struct_libinput_event_keyboard) u32;
pub extern fn libinput_event_keyboard_get_time_usec(event: ?*struct_libinput_event_keyboard) u64;
pub extern fn libinput_event_keyboard_get_key(event: ?*struct_libinput_event_keyboard) u32;
pub extern fn libinput_event_keyboard_get_key_state(event: ?*struct_libinput_event_keyboard) enum_libinput_key_state;
pub extern fn libinput_event_keyboard_get_base_event(event: ?*struct_libinput_event_keyboard) ?*struct_libinput_event;
pub extern fn libinput_event_keyboard_get_seat_key_count(event: ?*struct_libinput_event_keyboard) u32;
pub extern fn libinput_event_pointer_get_time(event: ?*struct_libinput_event_pointer) u32;
pub extern fn libinput_event_pointer_get_time_usec(event: ?*struct_libinput_event_pointer) u64;
pub extern fn libinput_event_pointer_get_dx(event: ?*struct_libinput_event_pointer) f64;
pub extern fn libinput_event_pointer_get_dy(event: ?*struct_libinput_event_pointer) f64;
pub extern fn libinput_event_pointer_get_dx_unaccelerated(event: ?*struct_libinput_event_pointer) f64;
pub extern fn libinput_event_pointer_get_dy_unaccelerated(event: ?*struct_libinput_event_pointer) f64;
pub extern fn libinput_event_pointer_get_absolute_x(event: ?*struct_libinput_event_pointer) f64;
pub extern fn libinput_event_pointer_get_absolute_y(event: ?*struct_libinput_event_pointer) f64;
pub extern fn libinput_event_pointer_get_absolute_x_transformed(event: ?*struct_libinput_event_pointer, width: u32) f64;
pub extern fn libinput_event_pointer_get_absolute_y_transformed(event: ?*struct_libinput_event_pointer, height: u32) f64;
pub extern fn libinput_event_pointer_get_button(event: ?*struct_libinput_event_pointer) u32;
pub extern fn libinput_event_pointer_get_button_state(event: ?*struct_libinput_event_pointer) enum_libinput_button_state;
pub extern fn libinput_event_pointer_get_seat_button_count(event: ?*struct_libinput_event_pointer) u32;
pub extern fn libinput_event_pointer_has_axis(event: ?*struct_libinput_event_pointer, axis: enum_libinput_pointer_axis) c_int;
pub extern fn libinput_event_pointer_get_axis_value(event: ?*struct_libinput_event_pointer, axis: enum_libinput_pointer_axis) f64;
pub extern fn libinput_event_pointer_get_axis_source(event: ?*struct_libinput_event_pointer) enum_libinput_pointer_axis_source;
pub extern fn libinput_event_pointer_get_axis_value_discrete(event: ?*struct_libinput_event_pointer, axis: enum_libinput_pointer_axis) f64;
pub extern fn libinput_event_pointer_get_scroll_value(event: ?*struct_libinput_event_pointer, axis: enum_libinput_pointer_axis) f64;
pub extern fn libinput_event_pointer_get_scroll_value_v120(event: ?*struct_libinput_event_pointer, axis: enum_libinput_pointer_axis) f64;
pub extern fn libinput_event_pointer_get_base_event(event: ?*struct_libinput_event_pointer) ?*struct_libinput_event;
pub extern fn libinput_event_touch_get_time(event: ?*struct_libinput_event_touch) u32;
pub extern fn libinput_event_touch_get_time_usec(event: ?*struct_libinput_event_touch) u64;
pub extern fn libinput_event_touch_get_slot(event: ?*struct_libinput_event_touch) i32;
pub extern fn libinput_event_touch_get_seat_slot(event: ?*struct_libinput_event_touch) i32;
pub extern fn libinput_event_touch_get_x(event: ?*struct_libinput_event_touch) f64;
pub extern fn libinput_event_touch_get_y(event: ?*struct_libinput_event_touch) f64;
pub extern fn libinput_event_touch_get_x_transformed(event: ?*struct_libinput_event_touch, width: u32) f64;
pub extern fn libinput_event_touch_get_y_transformed(event: ?*struct_libinput_event_touch, height: u32) f64;
pub extern fn libinput_event_touch_get_base_event(event: ?*struct_libinput_event_touch) ?*struct_libinput_event;
pub extern fn libinput_event_gesture_get_time(event: ?*struct_libinput_event_gesture) u32;
pub extern fn libinput_event_gesture_get_time_usec(event: ?*struct_libinput_event_gesture) u64;
pub extern fn libinput_event_gesture_get_base_event(event: ?*struct_libinput_event_gesture) ?*struct_libinput_event;
pub extern fn libinput_event_gesture_get_finger_count(event: ?*struct_libinput_event_gesture) c_int;
pub extern fn libinput_event_gesture_get_cancelled(event: ?*struct_libinput_event_gesture) c_int;
pub extern fn libinput_event_gesture_get_dx(event: ?*struct_libinput_event_gesture) f64;
pub extern fn libinput_event_gesture_get_dy(event: ?*struct_libinput_event_gesture) f64;
pub extern fn libinput_event_gesture_get_dx_unaccelerated(event: ?*struct_libinput_event_gesture) f64;
pub extern fn libinput_event_gesture_get_dy_unaccelerated(event: ?*struct_libinput_event_gesture) f64;
pub extern fn libinput_event_gesture_get_scale(event: ?*struct_libinput_event_gesture) f64;
pub extern fn libinput_event_gesture_get_angle_delta(event: ?*struct_libinput_event_gesture) f64;
pub extern fn libinput_event_tablet_tool_get_base_event(event: ?*struct_libinput_event_tablet_tool) ?*struct_libinput_event;
pub extern fn libinput_event_tablet_tool_x_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_y_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_pressure_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_distance_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_tilt_x_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_tilt_y_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_rotation_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_slider_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_size_major_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_size_minor_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_wheel_has_changed(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_get_x(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_y(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_dx(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_dy(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_pressure(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_distance(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_tilt_x(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_tilt_y(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_rotation(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_slider_position(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_size_major(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_size_minor(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_wheel_delta(event: ?*struct_libinput_event_tablet_tool) f64;
pub extern fn libinput_event_tablet_tool_get_wheel_delta_discrete(event: ?*struct_libinput_event_tablet_tool) c_int;
pub extern fn libinput_event_tablet_tool_get_x_transformed(event: ?*struct_libinput_event_tablet_tool, width: u32) f64;
pub extern fn libinput_event_tablet_tool_get_y_transformed(event: ?*struct_libinput_event_tablet_tool, height: u32) f64;
pub extern fn libinput_event_tablet_tool_get_tool(event: ?*struct_libinput_event_tablet_tool) ?*struct_libinput_tablet_tool;
pub extern fn libinput_event_tablet_tool_get_proximity_state(event: ?*struct_libinput_event_tablet_tool) enum_libinput_tablet_tool_proximity_state;
pub extern fn libinput_event_tablet_tool_get_tip_state(event: ?*struct_libinput_event_tablet_tool) enum_libinput_tablet_tool_tip_state;
pub extern fn libinput_event_tablet_tool_get_button(event: ?*struct_libinput_event_tablet_tool) u32;
pub extern fn libinput_event_tablet_tool_get_button_state(event: ?*struct_libinput_event_tablet_tool) enum_libinput_button_state;
pub extern fn libinput_event_tablet_tool_get_seat_button_count(event: ?*struct_libinput_event_tablet_tool) u32;
pub extern fn libinput_event_tablet_tool_get_time(event: ?*struct_libinput_event_tablet_tool) u32;
pub extern fn libinput_event_tablet_tool_get_time_usec(event: ?*struct_libinput_event_tablet_tool) u64;
pub extern fn libinput_tablet_tool_get_type(tool: ?*struct_libinput_tablet_tool) enum_libinput_tablet_tool_type;
pub extern fn libinput_tablet_tool_get_tool_id(tool: ?*struct_libinput_tablet_tool) u64;
pub extern fn libinput_tablet_tool_ref(tool: ?*struct_libinput_tablet_tool) ?*struct_libinput_tablet_tool;
pub extern fn libinput_tablet_tool_unref(tool: ?*struct_libinput_tablet_tool) ?*struct_libinput_tablet_tool;
pub extern fn libinput_tablet_tool_has_pressure(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_has_distance(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_has_tilt(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_has_rotation(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_has_slider(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_has_size(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_has_wheel(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_has_button(tool: ?*struct_libinput_tablet_tool, code: u32) c_int;
pub extern fn libinput_tablet_tool_is_unique(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_get_serial(tool: ?*struct_libinput_tablet_tool) u64;
pub extern fn libinput_tablet_tool_get_user_data(tool: ?*struct_libinput_tablet_tool) ?*anyopaque;
pub extern fn libinput_tablet_tool_set_user_data(tool: ?*struct_libinput_tablet_tool, user_data: ?*anyopaque) void;
pub extern fn libinput_event_tablet_pad_get_base_event(event: ?*struct_libinput_event_tablet_pad) ?*struct_libinput_event;
pub extern fn libinput_event_tablet_pad_get_ring_position(event: ?*struct_libinput_event_tablet_pad) f64;
pub extern fn libinput_event_tablet_pad_get_ring_number(event: ?*struct_libinput_event_tablet_pad) c_uint;
pub extern fn libinput_event_tablet_pad_get_ring_source(event: ?*struct_libinput_event_tablet_pad) enum_libinput_tablet_pad_ring_axis_source;
pub extern fn libinput_event_tablet_pad_get_strip_position(event: ?*struct_libinput_event_tablet_pad) f64;
pub extern fn libinput_event_tablet_pad_get_strip_number(event: ?*struct_libinput_event_tablet_pad) c_uint;
pub extern fn libinput_event_tablet_pad_get_strip_source(event: ?*struct_libinput_event_tablet_pad) enum_libinput_tablet_pad_strip_axis_source;
pub extern fn libinput_event_tablet_pad_get_button_number(event: ?*struct_libinput_event_tablet_pad) u32;
pub extern fn libinput_event_tablet_pad_get_button_state(event: ?*struct_libinput_event_tablet_pad) enum_libinput_button_state;
pub extern fn libinput_event_tablet_pad_get_key(event: ?*struct_libinput_event_tablet_pad) u32;
pub extern fn libinput_event_tablet_pad_get_key_state(event: ?*struct_libinput_event_tablet_pad) enum_libinput_key_state;
pub extern fn libinput_event_tablet_pad_get_dial_delta_v120(event: ?*struct_libinput_event_tablet_pad) f64;
pub extern fn libinput_event_tablet_pad_get_dial_number(event: ?*struct_libinput_event_tablet_pad) c_uint;
pub extern fn libinput_event_tablet_pad_get_mode(event: ?*struct_libinput_event_tablet_pad) c_uint;
pub extern fn libinput_event_tablet_pad_get_mode_group(event: ?*struct_libinput_event_tablet_pad) ?*struct_libinput_tablet_pad_mode_group;
pub extern fn libinput_event_tablet_pad_get_time(event: ?*struct_libinput_event_tablet_pad) u32;
pub extern fn libinput_event_tablet_pad_get_time_usec(event: ?*struct_libinput_event_tablet_pad) u64;
pub extern fn libinput_event_switch_get_switch(event: ?*struct_libinput_event_switch) enum_libinput_switch;
pub extern fn libinput_event_switch_get_switch_state(event: ?*struct_libinput_event_switch) enum_libinput_switch_state;
pub extern fn libinput_event_switch_get_base_event(event: ?*struct_libinput_event_switch) ?*struct_libinput_event;
pub extern fn libinput_event_switch_get_time(event: ?*struct_libinput_event_switch) u32;
pub extern fn libinput_event_switch_get_time_usec(event: ?*struct_libinput_event_switch) u64;
pub const struct_libinput_interface = extern struct {
    open_restricted: ?*const fn ([*c]const u8, c_int, ?*anyopaque) callconv(.c) c_int = @import("std").mem.zeroes(?*const fn ([*c]const u8, c_int, ?*anyopaque) callconv(.c) c_int),
    close_restricted: ?*const fn (c_int, ?*anyopaque) callconv(.c) void = @import("std").mem.zeroes(?*const fn (c_int, ?*anyopaque) callconv(.c) void),
};
pub extern fn libinput_udev_create_context(interface: [*c]const struct_libinput_interface, user_data: ?*anyopaque, udev: ?*struct_udev) ?*struct_libinput;
pub extern fn libinput_udev_assign_seat(libinput: ?*struct_libinput, seat_id: [*c]const u8) c_int;
pub extern fn libinput_path_create_context(interface: [*c]const struct_libinput_interface, user_data: ?*anyopaque) ?*struct_libinput;
pub extern fn libinput_path_add_device(libinput: ?*struct_libinput, path: [*c]const u8) ?*struct_libinput_device;
pub extern fn libinput_path_remove_device(device: ?*struct_libinput_device) void;
pub extern fn libinput_get_fd(libinput: ?*struct_libinput) c_int;
pub extern fn libinput_dispatch(libinput: ?*struct_libinput) c_int;
pub extern fn libinput_get_event(libinput: ?*struct_libinput) ?*struct_libinput_event;
pub extern fn libinput_next_event_type(libinput: ?*struct_libinput) enum_libinput_event_type;
pub extern fn libinput_set_user_data(libinput: ?*struct_libinput, user_data: ?*anyopaque) void;
pub extern fn libinput_get_user_data(libinput: ?*struct_libinput) ?*anyopaque;
pub extern fn libinput_resume(libinput: ?*struct_libinput) c_int;
pub extern fn libinput_suspend(libinput: ?*struct_libinput) void;
pub extern fn libinput_ref(libinput: ?*struct_libinput) ?*struct_libinput;
pub extern fn libinput_unref(libinput: ?*struct_libinput) ?*struct_libinput;
pub extern fn libinput_log_set_priority(libinput: ?*struct_libinput, priority: enum_libinput_log_priority) void;
pub extern fn libinput_log_get_priority(libinput: ?*const struct_libinput) enum_libinput_log_priority;
pub const libinput_log_handler = ?*const fn (?*struct_libinput, enum_libinput_log_priority, [*c]const u8, [*c]struct___va_list_tag_1) callconv(.c) void;
pub extern fn libinput_log_set_handler(libinput: ?*struct_libinput, log_handler: libinput_log_handler) void;
pub extern fn libinput_seat_ref(seat: ?*struct_libinput_seat) ?*struct_libinput_seat;
pub extern fn libinput_seat_unref(seat: ?*struct_libinput_seat) ?*struct_libinput_seat;
pub extern fn libinput_seat_set_user_data(seat: ?*struct_libinput_seat, user_data: ?*anyopaque) void;
pub extern fn libinput_seat_get_user_data(seat: ?*struct_libinput_seat) ?*anyopaque;
pub extern fn libinput_seat_get_context(seat: ?*struct_libinput_seat) ?*struct_libinput;
pub extern fn libinput_seat_get_physical_name(seat: ?*struct_libinput_seat) [*c]const u8;
pub extern fn libinput_seat_get_logical_name(seat: ?*struct_libinput_seat) [*c]const u8;
pub extern fn libinput_device_ref(device: ?*struct_libinput_device) ?*struct_libinput_device;
pub extern fn libinput_device_unref(device: ?*struct_libinput_device) ?*struct_libinput_device;
pub extern fn libinput_device_set_user_data(device: ?*struct_libinput_device, user_data: ?*anyopaque) void;
pub extern fn libinput_device_get_user_data(device: ?*struct_libinput_device) ?*anyopaque;
pub extern fn libinput_device_get_context(device: ?*struct_libinput_device) ?*struct_libinput;
pub extern fn libinput_device_get_device_group(device: ?*struct_libinput_device) ?*struct_libinput_device_group;
pub extern fn libinput_device_get_sysname(device: ?*struct_libinput_device) [*c]const u8;
pub extern fn libinput_device_get_name(device: ?*struct_libinput_device) [*c]const u8;
pub extern fn libinput_device_get_id_bustype(device: ?*struct_libinput_device) c_uint;
pub extern fn libinput_device_get_id_product(device: ?*struct_libinput_device) c_uint;
pub extern fn libinput_device_get_id_vendor(device: ?*struct_libinput_device) c_uint;
pub extern fn libinput_device_get_output_name(device: ?*struct_libinput_device) [*c]const u8;
pub extern fn libinput_device_get_seat(device: ?*struct_libinput_device) ?*struct_libinput_seat;
pub extern fn libinput_device_set_seat_logical_name(device: ?*struct_libinput_device, name: [*c]const u8) c_int;
pub extern fn libinput_device_get_udev_device(device: ?*struct_libinput_device) ?*struct_udev_device;
pub extern fn libinput_device_led_update(device: ?*struct_libinput_device, leds: enum_libinput_led) void;
pub extern fn libinput_device_has_capability(device: ?*struct_libinput_device, capability: enum_libinput_device_capability) c_int;
pub extern fn libinput_device_get_size(device: ?*struct_libinput_device, width: [*c]f64, height: [*c]f64) c_int;
pub extern fn libinput_device_pointer_has_button(device: ?*struct_libinput_device, code: u32) c_int;
pub extern fn libinput_device_keyboard_has_key(device: ?*struct_libinput_device, code: u32) c_int;
pub extern fn libinput_device_touch_get_touch_count(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_switch_has_switch(device: ?*struct_libinput_device, sw: enum_libinput_switch) c_int;
pub extern fn libinput_device_tablet_pad_get_num_buttons(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_tablet_pad_get_num_dials(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_tablet_pad_get_num_rings(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_tablet_pad_get_num_strips(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_tablet_pad_has_key(device: ?*struct_libinput_device, code: u32) c_int;
pub extern fn libinput_device_group_ref(group: ?*struct_libinput_device_group) ?*struct_libinput_device_group;
pub extern fn libinput_device_group_unref(group: ?*struct_libinput_device_group) ?*struct_libinput_device_group;
pub extern fn libinput_device_group_set_user_data(group: ?*struct_libinput_device_group, user_data: ?*anyopaque) void;
pub extern fn libinput_device_group_get_user_data(group: ?*struct_libinput_device_group) ?*anyopaque;
pub const LIBINPUT_CONFIG_STATUS_SUCCESS: c_int = 0;
pub const LIBINPUT_CONFIG_STATUS_UNSUPPORTED: c_int = 1;
pub const LIBINPUT_CONFIG_STATUS_INVALID: c_int = 2;
pub const enum_libinput_config_status = c_uint;
pub extern fn libinput_config_status_to_str(status: enum_libinput_config_status) [*c]const u8;
pub const LIBINPUT_CONFIG_TAP_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_TAP_ENABLED: c_int = 1;
pub const enum_libinput_config_tap_state = c_uint;
pub extern fn libinput_device_config_tap_get_finger_count(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_tap_set_enabled(device: ?*struct_libinput_device, enable: enum_libinput_config_tap_state) enum_libinput_config_status;
pub extern fn libinput_device_config_tap_get_enabled(device: ?*struct_libinput_device) enum_libinput_config_tap_state;
pub extern fn libinput_device_config_tap_get_default_enabled(device: ?*struct_libinput_device) enum_libinput_config_tap_state;
pub const LIBINPUT_CONFIG_TAP_MAP_LRM: c_int = 0;
pub const LIBINPUT_CONFIG_TAP_MAP_LMR: c_int = 1;
pub const enum_libinput_config_tap_button_map = c_uint;
pub const LIBINPUT_CONFIG_CLICKFINGER_MAP_LRM: c_int = 0;
pub const LIBINPUT_CONFIG_CLICKFINGER_MAP_LMR: c_int = 1;
pub const enum_libinput_config_clickfinger_button_map = c_uint;
pub extern fn libinput_device_config_tap_set_button_map(device: ?*struct_libinput_device, map: enum_libinput_config_tap_button_map) enum_libinput_config_status;
pub extern fn libinput_device_config_tap_get_button_map(device: ?*struct_libinput_device) enum_libinput_config_tap_button_map;
pub extern fn libinput_device_config_tap_get_default_button_map(device: ?*struct_libinput_device) enum_libinput_config_tap_button_map;
pub const LIBINPUT_CONFIG_DRAG_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_DRAG_ENABLED: c_int = 1;
pub const enum_libinput_config_drag_state = c_uint;
pub extern fn libinput_device_config_tap_set_drag_enabled(device: ?*struct_libinput_device, enable: enum_libinput_config_drag_state) enum_libinput_config_status;
pub extern fn libinput_device_config_tap_get_drag_enabled(device: ?*struct_libinput_device) enum_libinput_config_drag_state;
pub extern fn libinput_device_config_tap_get_default_drag_enabled(device: ?*struct_libinput_device) enum_libinput_config_drag_state;
pub const LIBINPUT_CONFIG_DRAG_LOCK_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_DRAG_LOCK_ENABLED_TIMEOUT: c_int = 1;
pub const LIBINPUT_CONFIG_DRAG_LOCK_ENABLED: c_int = 1;
pub const LIBINPUT_CONFIG_DRAG_LOCK_ENABLED_STICKY: c_int = 2;
pub const enum_libinput_config_drag_lock_state = c_uint;
pub extern fn libinput_device_config_tap_set_drag_lock_enabled(device: ?*struct_libinput_device, enable: enum_libinput_config_drag_lock_state) enum_libinput_config_status;
pub extern fn libinput_device_config_tap_get_drag_lock_enabled(device: ?*struct_libinput_device) enum_libinput_config_drag_lock_state;
pub extern fn libinput_device_config_tap_get_default_drag_lock_enabled(device: ?*struct_libinput_device) enum_libinput_config_drag_lock_state;
pub const LIBINPUT_CONFIG_3FG_DRAG_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_3FG_DRAG_ENABLED_3FG: c_int = 1;
pub const LIBINPUT_CONFIG_3FG_DRAG_ENABLED_4FG: c_int = 2;
pub const enum_libinput_config_3fg_drag_state = c_uint;
pub extern fn libinput_device_config_3fg_drag_get_finger_count(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_3fg_drag_set_enabled(device: ?*struct_libinput_device, enable: enum_libinput_config_3fg_drag_state) enum_libinput_config_status;
pub extern fn libinput_device_config_3fg_drag_get_enabled(device: ?*struct_libinput_device) enum_libinput_config_3fg_drag_state;
pub extern fn libinput_device_config_3fg_drag_get_default_enabled(device: ?*struct_libinput_device) enum_libinput_config_3fg_drag_state;
pub extern fn libinput_device_config_calibration_has_matrix(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_calibration_set_matrix(device: ?*struct_libinput_device, matrix: [*c]const f32) enum_libinput_config_status;
pub extern fn libinput_device_config_calibration_get_matrix(device: ?*struct_libinput_device, matrix: [*c]f32) c_int;
pub extern fn libinput_device_config_calibration_get_default_matrix(device: ?*struct_libinput_device, matrix: [*c]f32) c_int;
pub const struct_libinput_config_area_rectangle = extern struct {
    x1: f64 = @import("std").mem.zeroes(f64),
    y1: f64 = @import("std").mem.zeroes(f64),
    x2: f64 = @import("std").mem.zeroes(f64),
    y2: f64 = @import("std").mem.zeroes(f64),
};
pub extern fn libinput_device_config_area_has_rectangle(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_area_set_rectangle(device: ?*struct_libinput_device, rect: [*c]const struct_libinput_config_area_rectangle) enum_libinput_config_status;
pub extern fn libinput_device_config_area_get_rectangle(device: ?*struct_libinput_device) struct_libinput_config_area_rectangle;
pub extern fn libinput_device_config_area_get_default_rectangle(device: ?*struct_libinput_device) struct_libinput_config_area_rectangle;
pub const LIBINPUT_CONFIG_SEND_EVENTS_ENABLED: c_int = 0;
pub const LIBINPUT_CONFIG_SEND_EVENTS_DISABLED: c_int = 1;
pub const LIBINPUT_CONFIG_SEND_EVENTS_DISABLED_ON_EXTERNAL_MOUSE: c_int = 2;
pub const enum_libinput_config_send_events_mode = c_uint;
pub extern fn libinput_device_config_send_events_get_modes(device: ?*struct_libinput_device) u32;
pub extern fn libinput_device_config_send_events_set_mode(device: ?*struct_libinput_device, mode: u32) enum_libinput_config_status;
pub extern fn libinput_device_config_send_events_get_mode(device: ?*struct_libinput_device) u32;
pub extern fn libinput_device_config_send_events_get_default_mode(device: ?*struct_libinput_device) u32;
pub extern fn libinput_device_config_accel_is_available(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_accel_set_speed(device: ?*struct_libinput_device, speed: f64) enum_libinput_config_status;
pub extern fn libinput_device_config_accel_get_speed(device: ?*struct_libinput_device) f64;
pub extern fn libinput_device_config_accel_get_default_speed(device: ?*struct_libinput_device) f64;
pub const LIBINPUT_CONFIG_ACCEL_PROFILE_NONE: c_int = 0;
pub const LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT: c_int = 1;
pub const LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE: c_int = 2;
pub const LIBINPUT_CONFIG_ACCEL_PROFILE_CUSTOM: c_int = 4;
pub const enum_libinput_config_accel_profile = c_uint;
pub const struct_libinput_config_accel = opaque {};
pub extern fn libinput_config_accel_create(profile: enum_libinput_config_accel_profile) ?*struct_libinput_config_accel;
pub extern fn libinput_config_accel_destroy(accel_config: ?*struct_libinput_config_accel) void;
pub extern fn libinput_device_config_accel_apply(device: ?*struct_libinput_device, accel_config: ?*struct_libinput_config_accel) enum_libinput_config_status;
pub const LIBINPUT_ACCEL_TYPE_FALLBACK: c_int = 0;
pub const LIBINPUT_ACCEL_TYPE_MOTION: c_int = 1;
pub const LIBINPUT_ACCEL_TYPE_SCROLL: c_int = 2;
pub const enum_libinput_config_accel_type = c_uint;
pub extern fn libinput_config_accel_set_points(accel_config: ?*struct_libinput_config_accel, accel_type: enum_libinput_config_accel_type, step: f64, npoints: usize, points: [*c]f64) enum_libinput_config_status;
pub extern fn libinput_device_config_accel_get_profiles(device: ?*struct_libinput_device) u32;
pub extern fn libinput_device_config_accel_set_profile(device: ?*struct_libinput_device, profile: enum_libinput_config_accel_profile) enum_libinput_config_status;
pub extern fn libinput_device_config_accel_get_profile(device: ?*struct_libinput_device) enum_libinput_config_accel_profile;
pub extern fn libinput_device_config_accel_get_default_profile(device: ?*struct_libinput_device) enum_libinput_config_accel_profile;
pub extern fn libinput_device_config_scroll_has_natural_scroll(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_scroll_set_natural_scroll_enabled(device: ?*struct_libinput_device, enable: c_int) enum_libinput_config_status;
pub extern fn libinput_device_config_scroll_get_natural_scroll_enabled(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_scroll_get_default_natural_scroll_enabled(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_left_handed_is_available(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_left_handed_set(device: ?*struct_libinput_device, left_handed: c_int) enum_libinput_config_status;
pub extern fn libinput_device_config_left_handed_get(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_left_handed_get_default(device: ?*struct_libinput_device) c_int;
pub const LIBINPUT_CONFIG_CLICK_METHOD_NONE: c_int = 0;
pub const LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS: c_int = 1;
pub const LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER: c_int = 2;
pub const enum_libinput_config_click_method = c_uint;
pub extern fn libinput_device_config_click_get_methods(device: ?*struct_libinput_device) u32;
pub extern fn libinput_device_config_click_set_method(device: ?*struct_libinput_device, method: enum_libinput_config_click_method) enum_libinput_config_status;
pub extern fn libinput_device_config_click_get_method(device: ?*struct_libinput_device) enum_libinput_config_click_method;
pub extern fn libinput_device_config_click_get_default_method(device: ?*struct_libinput_device) enum_libinput_config_click_method;
pub extern fn libinput_device_config_click_set_clickfinger_button_map(device: ?*struct_libinput_device, map: enum_libinput_config_clickfinger_button_map) enum_libinput_config_status;
pub extern fn libinput_device_config_click_get_clickfinger_button_map(device: ?*struct_libinput_device) enum_libinput_config_clickfinger_button_map;
pub extern fn libinput_device_config_click_get_default_clickfinger_button_map(device: ?*struct_libinput_device) enum_libinput_config_clickfinger_button_map;
pub const LIBINPUT_CONFIG_MIDDLE_EMULATION_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_MIDDLE_EMULATION_ENABLED: c_int = 1;
pub const enum_libinput_config_middle_emulation_state = c_uint;
pub extern fn libinput_device_config_middle_emulation_is_available(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_middle_emulation_set_enabled(device: ?*struct_libinput_device, enable: enum_libinput_config_middle_emulation_state) enum_libinput_config_status;
pub extern fn libinput_device_config_middle_emulation_get_enabled(device: ?*struct_libinput_device) enum_libinput_config_middle_emulation_state;
pub extern fn libinput_device_config_middle_emulation_get_default_enabled(device: ?*struct_libinput_device) enum_libinput_config_middle_emulation_state;
pub const LIBINPUT_CONFIG_SCROLL_NO_SCROLL: c_int = 0;
pub const LIBINPUT_CONFIG_SCROLL_2FG: c_int = 1;
pub const LIBINPUT_CONFIG_SCROLL_EDGE: c_int = 2;
pub const LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN: c_int = 4;
pub const enum_libinput_config_scroll_method = c_uint;
pub extern fn libinput_device_config_scroll_get_methods(device: ?*struct_libinput_device) u32;
pub extern fn libinput_device_config_scroll_set_method(device: ?*struct_libinput_device, method: enum_libinput_config_scroll_method) enum_libinput_config_status;
pub extern fn libinput_device_config_scroll_get_method(device: ?*struct_libinput_device) enum_libinput_config_scroll_method;
pub extern fn libinput_device_config_scroll_get_default_method(device: ?*struct_libinput_device) enum_libinput_config_scroll_method;
pub extern fn libinput_device_config_scroll_set_button(device: ?*struct_libinput_device, button: u32) enum_libinput_config_status;
pub extern fn libinput_device_config_scroll_get_button(device: ?*struct_libinput_device) u32;
pub extern fn libinput_device_config_scroll_get_default_button(device: ?*struct_libinput_device) u32;
pub const LIBINPUT_CONFIG_SCROLL_BUTTON_LOCK_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_SCROLL_BUTTON_LOCK_ENABLED: c_int = 1;
pub const enum_libinput_config_scroll_button_lock_state = c_uint;
pub extern fn libinput_device_config_scroll_set_button_lock(device: ?*struct_libinput_device, state: enum_libinput_config_scroll_button_lock_state) enum_libinput_config_status;
pub extern fn libinput_device_config_scroll_get_button_lock(device: ?*struct_libinput_device) enum_libinput_config_scroll_button_lock_state;
pub extern fn libinput_device_config_scroll_get_default_button_lock(device: ?*struct_libinput_device) enum_libinput_config_scroll_button_lock_state;
pub const LIBINPUT_CONFIG_DWT_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_DWT_ENABLED: c_int = 1;
pub const enum_libinput_config_dwt_state = c_uint;
pub extern fn libinput_device_config_dwt_is_available(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_dwt_set_enabled(device: ?*struct_libinput_device, enable: enum_libinput_config_dwt_state) enum_libinput_config_status;
pub extern fn libinput_device_config_dwt_get_enabled(device: ?*struct_libinput_device) enum_libinput_config_dwt_state;
pub extern fn libinput_device_config_dwt_get_default_enabled(device: ?*struct_libinput_device) enum_libinput_config_dwt_state;
pub const LIBINPUT_CONFIG_DWTP_DISABLED: c_int = 0;
pub const LIBINPUT_CONFIG_DWTP_ENABLED: c_int = 1;
pub const enum_libinput_config_dwtp_state = c_uint;
pub extern fn libinput_device_config_dwtp_is_available(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_dwtp_set_enabled(device: ?*struct_libinput_device, enable: enum_libinput_config_dwtp_state) enum_libinput_config_status;
pub extern fn libinput_device_config_dwtp_get_enabled(device: ?*struct_libinput_device) enum_libinput_config_dwtp_state;
pub extern fn libinput_device_config_dwtp_get_default_enabled(device: ?*struct_libinput_device) enum_libinput_config_dwtp_state;
pub extern fn libinput_device_config_rotation_is_available(device: ?*struct_libinput_device) c_int;
pub extern fn libinput_device_config_rotation_set_angle(device: ?*struct_libinput_device, degrees_cw: c_uint) enum_libinput_config_status;
pub extern fn libinput_device_config_rotation_get_angle(device: ?*struct_libinput_device) c_uint;
pub extern fn libinput_device_config_rotation_get_default_angle(device: ?*struct_libinput_device) c_uint;
pub extern fn libinput_tablet_tool_config_pressure_range_is_available(tool: ?*struct_libinput_tablet_tool) c_int;
pub extern fn libinput_tablet_tool_config_pressure_range_set(tool: ?*struct_libinput_tablet_tool, minimum: f64, maximum: f64) enum_libinput_config_status;
pub extern fn libinput_tablet_tool_config_pressure_range_get_minimum(tool: ?*struct_libinput_tablet_tool) f64;
pub extern fn libinput_tablet_tool_config_pressure_range_get_maximum(tool: ?*struct_libinput_tablet_tool) f64;
pub extern fn libinput_tablet_tool_config_pressure_range_get_default_minimum(tool: ?*struct_libinput_tablet_tool) f64;
pub extern fn libinput_tablet_tool_config_pressure_range_get_default_maximum(tool: ?*struct_libinput_tablet_tool) f64;
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 20);
pub const __clang_minor__ = @as(c_int, 1);
pub const __clang_patchlevel__ = @as(c_int, 8);
pub const __clang_version__ = "20.1.8 ";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __MEMORY_SCOPE_SYSTEM = @as(c_int, 0);
pub const __MEMORY_SCOPE_DEVICE = @as(c_int, 1);
pub const __MEMORY_SCOPE_WRKGRP = @as(c_int, 2);
pub const __MEMORY_SCOPE_WVFRNT = @as(c_int, 3);
pub const __MEMORY_SCOPE_SINGLE = @as(c_int, 4);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __FPCLASS_SNAN = @as(c_int, 0x0001);
pub const __FPCLASS_QNAN = @as(c_int, 0x0002);
pub const __FPCLASS_NEGINF = @as(c_int, 0x0004);
pub const __FPCLASS_NEGNORMAL = @as(c_int, 0x0008);
pub const __FPCLASS_NEGSUBNORMAL = @as(c_int, 0x0010);
pub const __FPCLASS_NEGZERO = @as(c_int, 0x0020);
pub const __FPCLASS_POSZERO = @as(c_int, 0x0040);
pub const __FPCLASS_POSSUBNORMAL = @as(c_int, 0x0080);
pub const __FPCLASS_POSNORMAL = @as(c_int, 0x0100);
pub const __FPCLASS_POSINF = @as(c_int, 0x0200);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 20.1.8";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-32";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 1);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 8388608, .decimal);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_FMTd__ = "ld";
pub const __INTMAX_FMTi__ = "li";
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// (no file):95:9
pub const __INTMAX_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):102:9
pub const __UINTMAX_C = @import("std").zig.c_translation.Macros.UL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_long;
pub const __PTRDIFF_FMTd__ = "ld";
pub const __PTRDIFF_FMTi__ = "li";
pub const __INTPTR_TYPE__ = c_long;
pub const __INTPTR_FMTd__ = "ld";
pub const __INTPTR_FMTi__ = "li";
pub const __SIZE_TYPE__ = c_ulong;
pub const __SIZE_FMTo__ = "lo";
pub const __SIZE_FMTu__ = "lu";
pub const __SIZE_FMTx__ = "lx";
pub const __SIZE_FMTX__ = "lX";
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_int;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __UINTPTR_FMTo__ = "lo";
pub const __UINTPTR_FMTu__ = "lu";
pub const __UINTPTR_FMTx__ = "lx";
pub const __UINTPTR_FMTX__ = "lX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_NORM_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_NORM_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_NORM_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_NORM_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// (no file):206:9
pub const __INT64_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// (no file):231:9
pub const __UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):240:9
pub const __UINT64_C = @import("std").zig.c_translation.Macros.UL_SUFFIX;
pub const __UINT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "ld";
pub const __INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_LEAST64_FMTo__ = "lo";
pub const __UINT_LEAST64_FMTu__ = "lu";
pub const __UINT_LEAST64_FMTx__ = "lx";
pub const __UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "ld";
pub const __INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_FAST64_FMTo__ = "lo";
pub const __UINT_FAST64_FMTu__ = "lu";
pub const __UINT_FAST64_FMTx__ = "lx";
pub const __UINT_FAST64_FMTX__ = "lX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __NO_MATH_ERRNO__ = @as(c_int, 1);
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __GCC_DESTRUCTIVE_SIZE = @as(c_int, 64);
pub const __GCC_CONSTRUCTIVE_SIZE = @as(c_int, 64);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
pub const __ELF__ = @as(c_int, 1);
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):376:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):377:9
pub const __corei7 = @as(c_int, 1);
pub const __corei7__ = @as(c_int, 1);
pub const __tune_corei7__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __SGX__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const __FreeBSD__ = @as(c_int, 15);
pub const __FreeBSD_cc_version = @import("std").zig.c_translation.promoteIntLiteral(c_int, 1500001, .decimal);
pub const __KPRINTF_ATTRIBUTE__ = @as(c_int, 1);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __STDC_MB_MIGHT_NEQ_WC__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __FreeBSD_version = @import("std").zig.c_translation.promoteIntLiteral(c_int, 1500500, .decimal);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const _SYS_IOCTL_H_ = "";
pub const _SYS_IOCCOM_H_ = "";
pub const IOCPARM_SHIFT = @as(c_int, 13);
pub const IOCPARM_MASK = (@as(c_int, 1) << IOCPARM_SHIFT) - @as(c_int, 1);
pub inline fn IOCPARM_LEN(x: anytype) @TypeOf((x >> @as(c_int, 16)) & IOCPARM_MASK) {
    _ = &x;
    return (x >> @as(c_int, 16)) & IOCPARM_MASK;
}
pub inline fn IOCBASECMD(x: anytype) @TypeOf(x & ~(IOCPARM_MASK << @as(c_int, 16))) {
    _ = &x;
    return x & ~(IOCPARM_MASK << @as(c_int, 16));
}
pub inline fn IOCGROUP(x: anytype) @TypeOf((x >> @as(c_int, 8)) & @as(c_int, 0xff)) {
    _ = &x;
    return (x >> @as(c_int, 8)) & @as(c_int, 0xff);
}
pub const IOCPARM_MAX = @as(c_int, 1) << IOCPARM_SHIFT;
pub const IOC_VOID = @as(c_ulong, 0x20000000);
pub const IOC_OUT = @as(c_ulong, 0x40000000);
pub const IOC_IN = @as(c_ulong, 0x80000000);
pub const IOC_INOUT = IOC_IN | IOC_OUT;
pub const IOC_DIRMASK = (IOC_VOID | IOC_OUT) | IOC_IN;
pub inline fn _IOC(inout: anytype, group: anytype, num: anytype, len: anytype) c_ulong {
    _ = &inout;
    _ = &group;
    _ = &num;
    _ = &len;
    return @import("std").zig.c_translation.cast(c_ulong, ((inout | ((len & IOCPARM_MASK) << @as(c_int, 16))) | (group << @as(c_int, 8))) | num);
}
pub inline fn _IO(g: anytype, n: anytype) @TypeOf(_IOC(IOC_VOID, g, n, @as(c_int, 0))) {
    _ = &g;
    _ = &n;
    return _IOC(IOC_VOID, g, n, @as(c_int, 0));
}
pub inline fn _IOWINT(g: anytype, n: anytype) @TypeOf(_IOC(IOC_VOID, g, n, @import("std").zig.c_translation.sizeof(c_int))) {
    _ = &g;
    _ = &n;
    return _IOC(IOC_VOID, g, n, @import("std").zig.c_translation.sizeof(c_int));
}
pub inline fn _IOR(g: anytype, n: anytype, t: anytype) @TypeOf(_IOC(IOC_OUT, g, n, @import("std").zig.c_translation.sizeof(t))) {
    _ = &g;
    _ = &n;
    _ = &t;
    return _IOC(IOC_OUT, g, n, @import("std").zig.c_translation.sizeof(t));
}
pub inline fn _IOW(g: anytype, n: anytype, t: anytype) @TypeOf(_IOC(IOC_IN, g, n, @import("std").zig.c_translation.sizeof(t))) {
    _ = &g;
    _ = &n;
    _ = &t;
    return _IOC(IOC_IN, g, n, @import("std").zig.c_translation.sizeof(t));
}
pub inline fn _IOWR(g: anytype, n: anytype, t: anytype) @TypeOf(_IOC(IOC_INOUT, g, n, @import("std").zig.c_translation.sizeof(t))) {
    _ = &g;
    _ = &n;
    _ = &t;
    return _IOC(IOC_INOUT, g, n, @import("std").zig.c_translation.sizeof(t));
}
pub inline fn _IOC_NEWLEN(ioc: anytype, len: anytype) @TypeOf((~(IOCPARM_MASK << @as(c_int, 16)) & ioc) | ((len & IOCPARM_MASK) << @as(c_int, 16))) {
    _ = &ioc;
    _ = &len;
    return (~(IOCPARM_MASK << @as(c_int, 16)) & ioc) | ((len & IOCPARM_MASK) << @as(c_int, 16));
}
pub inline fn _IOC_NEWTYPE(ioc: anytype, @"type": anytype) @TypeOf(_IOC_NEWLEN(ioc, @import("std").zig.c_translation.sizeof(@"type"))) {
    _ = &ioc;
    _ = &@"type";
    return _IOC_NEWLEN(ioc, @import("std").zig.c_translation.sizeof(@"type"));
}
pub const _SYS_CDEFS_H_ = "";
pub const __BEGIN_DECLS = "";
pub const __END_DECLS = "";
pub inline fn __GNUC_PREREQ__(ma: anytype, mi: anytype) @TypeOf((__GNUC__ > ma) or ((__GNUC__ == ma) and (__GNUC_MINOR__ >= mi))) {
    _ = &ma;
    _ = &mi;
    return (__GNUC__ > ma) or ((__GNUC__ == ma) and (__GNUC_MINOR__ >= mi));
}
pub const __compiler_membar = @compileError("unable to translate C expr: unexpected token '__asm'");
// /usr/include/sys/cdefs.h:93:9
pub const __CC_SUPPORTS___INLINE = @as(c_int, 1);
pub const __CC_SUPPORTS_SYMVER = @as(c_int, 1);
pub inline fn __P(protos: anytype) @TypeOf(protos) {
    _ = &protos;
    return protos;
}
pub const __CONCAT1 = @compileError("unable to translate C expr: unexpected token '##'");
// /usr/include/sys/cdefs.h:122:9
pub inline fn __CONCAT(x: anytype, y: anytype) @TypeOf(__CONCAT1(x, y)) {
    _ = &x;
    _ = &y;
    return __CONCAT1(x, y);
}
pub const __STRING = @compileError("unable to translate C expr: unexpected token '#'");
// /usr/include/sys/cdefs.h:124:9
pub inline fn __XSTRING(x: anytype) @TypeOf(__STRING(x)) {
    _ = &x;
    return __STRING(x);
}
pub const __volatile = @compileError("unable to translate C expr: unexpected token 'volatile'");
// /usr/include/sys/cdefs.h:127:9
pub const __weak_symbol = @compileError("unable to translate macro: undefined identifier `__weak__`");
// /usr/include/sys/cdefs.h:152:9
pub const __dead2 = @compileError("unable to translate macro: undefined identifier `__noreturn__`");
// /usr/include/sys/cdefs.h:153:9
pub const __pure2 = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// /usr/include/sys/cdefs.h:154:9
pub const __unused = @compileError("unable to translate macro: undefined identifier `__unused__`");
// /usr/include/sys/cdefs.h:155:9
pub const __used = @compileError("unable to translate macro: undefined identifier `__used__`");
// /usr/include/sys/cdefs.h:156:9
pub const __deprecated = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// /usr/include/sys/cdefs.h:157:9
pub const __deprecated1 = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// /usr/include/sys/cdefs.h:158:9
pub const __packed = @compileError("unable to translate macro: undefined identifier `__packed__`");
// /usr/include/sys/cdefs.h:159:9
pub const __aligned = @compileError("unable to translate macro: undefined identifier `__aligned__`");
// /usr/include/sys/cdefs.h:160:9
pub const __section = @compileError("unable to translate macro: undefined identifier `__section__`");
// /usr/include/sys/cdefs.h:161:9
pub const __writeonly = __unused;
pub const __alloc_size = @compileError("unable to translate macro: undefined identifier `__alloc_size__`");
// /usr/include/sys/cdefs.h:163:9
pub const __alloc_size2 = @compileError("unable to translate macro: undefined identifier `__alloc_size__`");
// /usr/include/sys/cdefs.h:164:9
pub const __alloc_align = @compileError("unable to translate macro: undefined identifier `__alloc_align__`");
// /usr/include/sys/cdefs.h:165:9
pub const __generic = @compileError("unable to translate C expr: unexpected token '_Generic'");
// /usr/include/sys/cdefs.h:227:9
pub const __min_size = @compileError("unable to translate C expr: unexpected token 'static'");
// /usr/include/sys/cdefs.h:244:9
pub const __malloc_like = @compileError("unable to translate macro: undefined identifier `__malloc__`");
// /usr/include/sys/cdefs.h:249:9
pub const __pure = @compileError("unable to translate macro: undefined identifier `__pure__`");
// /usr/include/sys/cdefs.h:250:9
pub const __always_inline = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// /usr/include/sys/cdefs.h:252:9
pub const __noinline = @compileError("unable to translate macro: undefined identifier `__noinline__`");
// /usr/include/sys/cdefs.h:253:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`");
// /usr/include/sys/cdefs.h:254:9
pub const __result_use_check = @compileError("unable to translate macro: undefined identifier `__warn_unused_result__`");
// /usr/include/sys/cdefs.h:255:9
pub const __returns_twice = @compileError("unable to translate macro: undefined identifier `__returns_twice__`");
// /usr/include/sys/cdefs.h:256:9
pub inline fn __unreachable() @TypeOf(__builtin_unreachable()) {
    return __builtin_unreachable();
}
pub const __LONG_LONG_SUPPORTED = "";
pub const __noexcept = "";
pub const __noexcept_if = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/sys/cdefs.h:283:9
pub const __nodiscard = @compileError("unable to translate macro: undefined identifier `__nodiscard__`");
// /usr/include/sys/cdefs.h:307:9
pub const __restrict = @compileError("unable to translate C expr: unexpected token 'restrict'");
// /usr/include/sys/cdefs.h:331:9
pub inline fn __predict_true(exp: anytype) @TypeOf(__builtin_expect(exp, @as(c_int, 1))) {
    _ = &exp;
    return __builtin_expect(exp, @as(c_int, 1));
}
pub inline fn __predict_false(exp: anytype) @TypeOf(__builtin_expect(exp, @as(c_int, 0))) {
    _ = &exp;
    return __builtin_expect(exp, @as(c_int, 0));
}
pub const __null_sentinel = @compileError("unable to translate macro: undefined identifier `__sentinel__`");
// /usr/include/sys/cdefs.h:344:9
pub const __exported = @compileError("unable to translate macro: undefined identifier `__visibility__`");
// /usr/include/sys/cdefs.h:345:9
pub const __hidden = @compileError("unable to translate macro: undefined identifier `__visibility__`");
// /usr/include/sys/cdefs.h:346:9
pub const __offsetof = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// /usr/include/sys/cdefs.h:352:9
pub inline fn __rangeof(@"type": anytype, start: anytype, end: anytype) @TypeOf(__offsetof(@"type", end) - __offsetof(@"type", start)) {
    _ = &@"type";
    _ = &start;
    _ = &end;
    return __offsetof(@"type", end) - __offsetof(@"type", start);
}
pub const __containerof = @compileError("unable to translate macro: undefined identifier `__x`");
// /usr/include/sys/cdefs.h:362:9
pub const __printflike = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/include/sys/cdefs.h:371:9
pub const __scanflike = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/include/sys/cdefs.h:373:9
pub const __format_arg = @compileError("unable to translate macro: undefined identifier `__format_arg__`");
// /usr/include/sys/cdefs.h:375:9
pub const __strfmonlike = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/include/sys/cdefs.h:376:9
pub const __strftimelike = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/include/sys/cdefs.h:378:9
pub const __printf0like = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/include/sys/cdefs.h:391:9
pub const __strong_reference = @compileError("unable to translate macro: undefined identifier `__alias__`");
// /usr/include/sys/cdefs.h:397:9
pub const __weak_reference = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/sys/cdefs.h:400:9
pub const __warn_references = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/sys/cdefs.h:403:9
pub const __sym_compat = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/sys/cdefs.h:408:9
pub const __sym_default = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/sys/cdefs.h:410:9
pub const __GLOBL = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/sys/cdefs.h:429:9
pub const __WEAK = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/sys/cdefs.h:430:9
pub const __IDSTRING = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/sys/cdefs.h:432:9
pub const __FBSDID = @compileError("unable to translate macro: undefined identifier `__rcsid_`");
// /usr/include/sys/cdefs.h:441:9
pub const __RCSID = @compileError("unable to translate macro: undefined identifier `__rcsid_`");
// /usr/include/sys/cdefs.h:449:9
pub const __RCSID_SOURCE = @compileError("unable to translate macro: undefined identifier `__rcsid_source_`");
// /usr/include/sys/cdefs.h:457:9
pub const __SCCSID = @compileError("unable to translate macro: undefined identifier `__sccsid_`");
// /usr/include/sys/cdefs.h:465:9
pub const __COPYRIGHT = @compileError("unable to translate macro: undefined identifier `__copyright_`");
// /usr/include/sys/cdefs.h:473:9
pub const __DECONST = @compileError("unable to translate C expr: unexpected token 'const'");
// /usr/include/sys/cdefs.h:480:9
pub const __DEVOLATILE = @compileError("unable to translate C expr: unexpected token 'volatile'");
// /usr/include/sys/cdefs.h:484:9
pub const __DEQUALIFY = @compileError("unable to translate C expr: unexpected token 'const'");
// /usr/include/sys/cdefs.h:488:9
pub const __RENAME = @compileError("unable to translate C expr: unexpected token '__asm'");
// /usr/include/sys/cdefs.h:492:9
pub const _SYS__VISIBLE_H_ = "";
pub const __POSIX_VISIBLE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 202405, .decimal);
pub const __XSI_VISIBLE = @as(c_int, 800);
pub const __BSD_VISIBLE = @as(c_int, 1);
pub const __ISO_C_VISIBLE = @as(c_int, 2023);
pub const __EXT1_VISIBLE = @as(c_int, 1);
pub const __NULLABILITY_PRAGMA_PUSH = @compileError("unable to translate macro: undefined identifier `_Pragma`");
// /usr/include/sys/cdefs.h:509:9
pub const __NULLABILITY_PRAGMA_POP = @compileError("unable to translate macro: undefined identifier `_Pragma`");
// /usr/include/sys/cdefs.h:511:9
pub const __arg_type_tag = @compileError("unable to translate macro: undefined identifier `__argument_with_type_tag__`");
// /usr/include/sys/cdefs.h:523:9
pub const __datatype_type_tag = @compileError("unable to translate macro: undefined identifier `__type_tag_for_datatype__`");
// /usr/include/sys/cdefs.h:525:9
pub const __lock_annotate = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// /usr/include/sys/cdefs.h:545:9
pub const __lockable = @compileError("unable to translate macro: undefined identifier `lockable`");
// /usr/include/sys/cdefs.h:551:9
pub const __locks_exclusive = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:554:9
pub const __locks_shared = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:556:9
pub const __trylocks_exclusive = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:560:9
pub const __trylocks_shared = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:562:9
pub const __unlocks = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:566:9
pub const __asserts_exclusive = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:569:9
pub const __asserts_shared = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:571:9
pub const __requires_exclusive = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:575:9
pub const __requires_shared = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:577:9
pub const __requires_unlocked = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/cdefs.h:579:9
pub const __no_lock_analysis = @compileError("unable to translate macro: undefined identifier `no_thread_safety_analysis`");
// /usr/include/sys/cdefs.h:583:9
pub const __nosanitizeaddress = "";
pub const __nosanitizecoverage = "";
pub const __nosanitizememory = "";
pub const __nosanitizethread = "";
pub const __nostackprotector = @compileError("unable to translate macro: undefined identifier `no_stack_protector`");
// /usr/include/sys/cdefs.h:623:9
pub const __guarded_by = @compileError("unable to translate macro: undefined identifier `guarded_by`");
// /usr/include/sys/cdefs.h:630:9
pub const __pt_guarded_by = @compileError("unable to translate macro: undefined identifier `pt_guarded_by`");
// /usr/include/sys/cdefs.h:631:9
pub const __align_up = @compileError("unable to translate macro: undefined identifier `__builtin_align_up`");
// /usr/include/sys/cdefs.h:648:9
pub const __align_down = @compileError("unable to translate macro: undefined identifier `__builtin_align_down`");
// /usr/include/sys/cdefs.h:649:9
pub const __is_aligned = @compileError("unable to translate macro: undefined identifier `__builtin_is_aligned`");
// /usr/include/sys/cdefs.h:650:9
pub const _SYS_FILIO_H_ = "";
pub const _SYS__TYPES_H_ = "";
pub const _MACHINE__TYPES_H_ = "";
pub const _MACHINE__LIMITS_H_ = "";
pub const __CHAR_BIT = @as(c_int, 8);
pub const __SCHAR_MAX = @as(c_int, 0x7f);
pub const __SCHAR_MIN = -@as(c_int, 0x7f) - @as(c_int, 1);
pub const __UCHAR_MAX = @as(c_int, 0xff);
pub const __USHRT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffff, .hex);
pub const __SHRT_MAX = @as(c_int, 0x7fff);
pub const __SHRT_MIN = -@as(c_int, 0x7fff) - @as(c_int, 1);
pub const __UINT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffff, .hex);
pub const __INT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hex);
pub const __INT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hex) - @as(c_int, 1);
pub const __ULONG_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffffffffffff, .hex);
pub const __LONG_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffffffffffff, .hex);
pub const __LONG_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffffffffffff, .hex) - @as(c_int, 1);
pub const __ULLONG_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const __LLONG_MAX = @as(c_longlong, 0x7fffffffffffffff);
pub const __LLONG_MIN = -@as(c_longlong, 0x7fffffffffffffff) - @as(c_int, 1);
pub const __SSIZE_MAX = __LONG_MAX;
pub const __SIZE_T_MAX = __ULONG_MAX;
pub const __OFF_MAX = __LONG_MAX;
pub const __OFF_MIN = __LONG_MIN;
pub const __UQUAD_MAX = __ULONG_MAX;
pub const __QUAD_MAX = __LONG_MAX;
pub const __QUAD_MIN = __LONG_MIN;
pub const __LONG_BIT = @as(c_int, 64);
pub const __WORD_BIT = @as(c_int, 32);
pub const __MINSIGSTKSZ = @as(c_int, 512) * @as(c_int, 4);
pub const __NO_STRICT_ALIGNMENT = "";
pub const __WCHAR_MIN = __INT_MIN;
pub const __WCHAR_MAX = __INT_MAX;
pub const __GNUC_VA_LIST = "";
pub const __INO64 = "";
pub const FIOCLEX = _IO('f', @as(c_int, 1));
pub const FIONCLEX = _IO('f', @as(c_int, 2));
pub const FIONREAD = _IOR('f', @as(c_int, 127), c_int);
pub const FIONBIO = _IOW('f', @as(c_int, 126), c_int);
pub const FIOASYNC = _IOW('f', @as(c_int, 125), c_int);
pub const FIOSETOWN = _IOW('f', @as(c_int, 124), c_int);
pub const FIOGETOWN = _IOR('f', @as(c_int, 123), c_int);
pub const FIODTYPE = _IOR('f', @as(c_int, 122), c_int);
pub const FIOGETLBA = _IOR('f', @as(c_int, 121), c_int);
pub const FIODGNAME = _IOW('f', @as(c_int, 120), struct_fiodgname_arg);
pub const FIONWRITE = _IOR('f', @as(c_int, 119), c_int);
pub const FIONSPACE = _IOR('f', @as(c_int, 118), c_int);
pub const FIOSEEKDATA = _IOWR('f', @as(c_int, 97), off_t);
pub const FIOSEEKHOLE = _IOWR('f', @as(c_int, 98), off_t);
pub const FIOBMAP2 = _IOWR('f', @as(c_int, 99), struct_fiobmap2_arg);
pub const FIOSSHMLPGCNF = @compileError("unable to translate macro: undefined identifier `shm_largepage_conf`");
// /usr/include/sys/filio.h:71:9
pub const FIOGSHMLPGCNF = @compileError("unable to translate macro: undefined identifier `shm_largepage_conf`");
// /usr/include/sys/filio.h:72:9
pub const _SYS_SOCKIO_H_ = "";
pub const SIOCSHIWAT = _IOW('s', @as(c_int, 0), c_int);
pub const SIOCGHIWAT = _IOR('s', @as(c_int, 1), c_int);
pub const SIOCSLOWAT = _IOW('s', @as(c_int, 2), c_int);
pub const SIOCGLOWAT = _IOR('s', @as(c_int, 3), c_int);
pub const SIOCATMARK = _IOR('s', @as(c_int, 7), c_int);
pub const SIOCSPGRP = _IOW('s', @as(c_int, 8), c_int);
pub const SIOCGPGRP = _IOR('s', @as(c_int, 9), c_int);
pub const SIOCGETVIFCNT = @compileError("unable to translate macro: undefined identifier `sioc_vif_req`");
// /usr/include/sys/sockio.h:48:9
pub const SIOCGETSGCNT = @compileError("unable to translate macro: undefined identifier `sioc_sg_req`");
// /usr/include/sys/sockio.h:49:9
pub const SIOCSIFADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:51:9
pub const SIOCGIFADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:53:9
pub const SIOCSIFDSTADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:54:9
pub const SIOCGIFDSTADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:56:9
pub const SIOCSIFFLAGS = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:57:9
pub const SIOCGIFFLAGS = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:58:9
pub const SIOCGIFBRDADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:60:9
pub const SIOCSIFBRDADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:61:9
pub const SIOCGIFCONF = @compileError("unable to translate macro: undefined identifier `ifconf`");
// /usr/include/sys/sockio.h:63:9
pub const SIOCGIFNETMASK = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:65:9
pub const SIOCSIFNETMASK = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:66:9
pub const SIOCGIFMETRIC = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:67:9
pub const SIOCSIFMETRIC = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:68:9
pub const SIOCDIFADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:69:9
pub const OSIOCAIFADDR = @compileError("unable to translate macro: undefined identifier `oifaliasreq`");
// /usr/include/sys/sockio.h:70:9
pub const SIOCSIFCAP = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:74:9
pub const SIOCGIFCAP = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:75:9
pub const SIOCGIFINDEX = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:76:9
pub const SIOCGIFMAC = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:77:9
pub const SIOCSIFMAC = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:78:9
pub const SIOCSIFNAME = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:79:9
pub const SIOCSIFDESCR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:80:9
pub const SIOCGIFDESCR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:81:9
pub const SIOCAIFADDR = @compileError("unable to translate macro: undefined identifier `ifaliasreq`");
// /usr/include/sys/sockio.h:82:9
pub const SIOCGIFDATA = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:83:9
pub const SIOCGIFALIAS = @compileError("unable to translate macro: undefined identifier `ifaliasreq`");
// /usr/include/sys/sockio.h:84:9
pub const SIOCADDMULTI = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:86:9
pub const SIOCDELMULTI = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:87:9
pub const SIOCGIFMTU = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:88:9
pub const SIOCSIFMTU = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:89:9
pub const SIOCGIFPHYS = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:90:9
pub const SIOCSIFPHYS = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:91:9
pub const SIOCSIFMEDIA = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:92:9
pub const SIOCGIFMEDIA = @compileError("unable to translate macro: undefined identifier `ifmediareq`");
// /usr/include/sys/sockio.h:93:9
pub const SIOCSIFGENERIC = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:95:9
pub const SIOCGIFGENERIC = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:96:9
pub const SIOCGIFSTATUS = @compileError("unable to translate macro: undefined identifier `ifstat`");
// /usr/include/sys/sockio.h:98:9
pub const SIOCSIFLLADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:99:9
pub const SIOCGI2C = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:100:9
pub const SIOCGHWADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:101:9
pub const SIOCSIFPHYADDR = @compileError("unable to translate macro: undefined identifier `ifaliasreq`");
// /usr/include/sys/sockio.h:103:9
pub const SIOCGIFPSRCADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:104:9
pub const SIOCGIFPDSTADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:105:9
pub const SIOCDIFPHYADDR = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:106:9
pub const SIOCGPRIVATE_0 = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:110:9
pub const SIOCGPRIVATE_1 = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:111:9
pub const SIOCSIFVNET = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:113:9
pub const SIOCSIFRVNET = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:114:9
pub const SIOCGIFFIB = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:116:9
pub const SIOCSIFFIB = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:117:9
pub const SIOCGTUNFIB = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:119:9
pub const SIOCSTUNFIB = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:120:9
pub const SIOCSDRVSPEC = @compileError("unable to translate macro: undefined identifier `ifdrv`");
// /usr/include/sys/sockio.h:122:9
pub const SIOCGDRVSPEC = @compileError("unable to translate macro: undefined identifier `ifdrv`");
// /usr/include/sys/sockio.h:124:9
pub const SIOCIFCREATE = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:127:9
pub const SIOCIFCREATE2 = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:128:9
pub const SIOCIFDESTROY = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:129:9
pub const SIOCIFGCLONERS = @compileError("unable to translate macro: undefined identifier `if_clonereq`");
// /usr/include/sys/sockio.h:130:9
pub const SIOCAIFGROUP = @compileError("unable to translate macro: undefined identifier `ifgroupreq`");
// /usr/include/sys/sockio.h:132:9
pub const SIOCGIFGROUP = @compileError("unable to translate macro: undefined identifier `ifgroupreq`");
// /usr/include/sys/sockio.h:133:9
pub const SIOCDIFGROUP = @compileError("unable to translate macro: undefined identifier `ifgroupreq`");
// /usr/include/sys/sockio.h:134:9
pub const SIOCGIFGMEMB = @compileError("unable to translate macro: undefined identifier `ifgroupreq`");
// /usr/include/sys/sockio.h:135:9
pub const SIOCGIFXMEDIA = @compileError("unable to translate macro: undefined identifier `ifmediareq`");
// /usr/include/sys/sockio.h:136:9
pub const SIOCGIFRSSKEY = @compileError("unable to translate macro: undefined identifier `ifrsskey`");
// /usr/include/sys/sockio.h:138:9
pub const SIOCGIFRSSHASH = @compileError("unable to translate macro: undefined identifier `ifrsshash`");
// /usr/include/sys/sockio.h:139:9
pub const SIOCGLANPCP = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:142:9
pub const SIOCSLANPCP = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:143:9
pub const SIOCGIFDOWNREASON = @compileError("unable to translate macro: undefined identifier `ifdownreason`");
// /usr/include/sys/sockio.h:145:9
pub const SIOCSIFCAPNV = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:147:9
pub const SIOCGIFCAPNV = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:148:9
pub const SIOCGUMBINFO = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:150:9
pub const SIOCSUMBPARAM = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:151:9
pub const SIOCGUMBPARAM = @compileError("unable to translate macro: undefined identifier `ifreq`");
// /usr/include/sys/sockio.h:152:9
pub const _SYS_TTYCOM_H_ = "";
pub const _SYS__WINSIZE_H_ = "";
pub const TIOCEXCL = _IO('t', @as(c_int, 13));
pub const TIOCNXCL = _IO('t', @as(c_int, 14));
pub const TIOCGPTN = _IOR('t', @as(c_int, 15), c_int);
pub const TIOCFLUSH = _IOW('t', @as(c_int, 16), c_int);
pub const TIOCGETA = _IOR('t', @as(c_int, 19), struct_termios);
pub const TIOCSETA = _IOW('t', @as(c_int, 20), struct_termios);
pub const TIOCSETAW = _IOW('t', @as(c_int, 21), struct_termios);
pub const TIOCSETAF = _IOW('t', @as(c_int, 22), struct_termios);
pub const TIOCGETD = _IOR('t', @as(c_int, 26), c_int);
pub const TIOCSETD = _IOW('t', @as(c_int, 27), c_int);
pub const TIOCPTMASTER = _IO('t', @as(c_int, 28));
pub const TIOCGDRAINWAIT = _IOR('t', @as(c_int, 86), c_int);
pub const TIOCSDRAINWAIT = _IOW('t', @as(c_int, 87), c_int);
pub const TIOCTIMESTAMP = _IOR('t', @as(c_int, 89), struct_timeval);
pub const TIOCDRAIN = _IO('t', @as(c_int, 94));
pub const TIOCSIG = _IOWINT('t', @as(c_int, 95));
pub const TIOCEXT = _IOW('t', @as(c_int, 96), c_int);
pub const TIOCSCTTY = _IO('t', @as(c_int, 97));
pub const TIOCCONS = _IOW('t', @as(c_int, 98), c_int);
pub const TIOCGSID = _IOR('t', @as(c_int, 99), c_int);
pub const TIOCSTAT = _IO('t', @as(c_int, 101));
pub const TIOCUCNTL = _IOW('t', @as(c_int, 102), c_int);
pub inline fn UIOCCMD(n: anytype) @TypeOf(_IO('u', n)) {
    _ = &n;
    return _IO('u', n);
}
pub const TIOCSWINSZ = _IOW('t', @as(c_int, 103), struct_winsize);
pub const TIOCGWINSZ = _IOR('t', @as(c_int, 104), struct_winsize);
pub const TIOCMGET = _IOR('t', @as(c_int, 106), c_int);
pub const TIOCM_LE = @as(c_int, 0o001);
pub const TIOCM_DTR = @as(c_int, 0o002);
pub const TIOCM_RTS = @as(c_int, 0o004);
pub const TIOCM_ST = @as(c_int, 0o010);
pub const TIOCM_SR = @as(c_int, 0o020);
pub const TIOCM_CTS = @as(c_int, 0o040);
pub const TIOCM_DCD = @as(c_int, 0o100);
pub const TIOCM_RI = @as(c_int, 0o200);
pub const TIOCM_DSR = @as(c_int, 0o400);
pub const TIOCM_CD = TIOCM_DCD;
pub const TIOCM_CAR = TIOCM_DCD;
pub const TIOCM_RNG = TIOCM_RI;
pub const TIOCMBIC = _IOW('t', @as(c_int, 107), c_int);
pub const TIOCMBIS = _IOW('t', @as(c_int, 108), c_int);
pub const TIOCMSET = _IOW('t', @as(c_int, 109), c_int);
pub const TIOCSTART = _IO('t', @as(c_int, 110));
pub const TIOCSTOP = _IO('t', @as(c_int, 111));
pub const TIOCPKT = _IOW('t', @as(c_int, 112), c_int);
pub const TIOCPKT_DATA = @as(c_int, 0x00);
pub const TIOCPKT_FLUSHREAD = @as(c_int, 0x01);
pub const TIOCPKT_FLUSHWRITE = @as(c_int, 0x02);
pub const TIOCPKT_STOP = @as(c_int, 0x04);
pub const TIOCPKT_START = @as(c_int, 0x08);
pub const TIOCPKT_NOSTOP = @as(c_int, 0x10);
pub const TIOCPKT_DOSTOP = @as(c_int, 0x20);
pub const TIOCPKT_IOCTL = @as(c_int, 0x40);
pub const TIOCNOTTY = _IO('t', @as(c_int, 113));
pub const TIOCSTI = _IOW('t', @as(c_int, 114), u8);
pub const TIOCOUTQ = _IOR('t', @as(c_int, 115), c_int);
pub const TIOCSPGRP = _IOW('t', @as(c_int, 118), c_int);
pub const TIOCGPGRP = _IOR('t', @as(c_int, 119), c_int);
pub const TIOCCDTR = _IO('t', @as(c_int, 120));
pub const TIOCSDTR = _IO('t', @as(c_int, 121));
pub const TIOCCBRK = _IO('t', @as(c_int, 122));
pub const TIOCSBRK = _IO('t', @as(c_int, 123));
pub const TTYDISC = @as(c_int, 0);
pub const SLIPDISC = @as(c_int, 4);
pub const PPPDISC = @as(c_int, 5);
pub const NETGRAPHDISC = @as(c_int, 6);
pub const H4DISC = @as(c_int, 7);
pub const _TERMIOS_H_ = "";
pub const _SYS__TERMIOS_H_ = "";
pub const VEOF = @as(c_int, 0);
pub const VEOL = @as(c_int, 1);
pub const VEOL2 = @as(c_int, 2);
pub const VERASE = @as(c_int, 3);
pub const VWERASE = @as(c_int, 4);
pub const VKILL = @as(c_int, 5);
pub const VREPRINT = @as(c_int, 6);
pub const VERASE2 = @as(c_int, 7);
pub const VINTR = @as(c_int, 8);
pub const VQUIT = @as(c_int, 9);
pub const VSUSP = @as(c_int, 10);
pub const VDSUSP = @as(c_int, 11);
pub const VSTART = @as(c_int, 12);
pub const VSTOP = @as(c_int, 13);
pub const VLNEXT = @as(c_int, 14);
pub const VDISCARD = @as(c_int, 15);
pub const VMIN = @as(c_int, 16);
pub const VTIME = @as(c_int, 17);
pub const VSTATUS = @as(c_int, 18);
pub const NCCS = @as(c_int, 20);
pub const _POSIX_VDISABLE = @as(c_int, 0xff);
pub const IGNBRK = @as(c_int, 0x00000001);
pub const BRKINT = @as(c_int, 0x00000002);
pub const IGNPAR = @as(c_int, 0x00000004);
pub const PARMRK = @as(c_int, 0x00000008);
pub const INPCK = @as(c_int, 0x00000010);
pub const ISTRIP = @as(c_int, 0x00000020);
pub const INLCR = @as(c_int, 0x00000040);
pub const IGNCR = @as(c_int, 0x00000080);
pub const ICRNL = @as(c_int, 0x00000100);
pub const IXON = @as(c_int, 0x00000200);
pub const IXOFF = @as(c_int, 0x00000400);
pub const IXANY = @as(c_int, 0x00000800);
pub const IMAXBEL = @as(c_int, 0x00002000);
pub const IUTF8 = @as(c_int, 0x00004000);
pub const OPOST = @as(c_int, 0x00000001);
pub const ONLCR = @as(c_int, 0x00000002);
pub const TABDLY = @as(c_int, 0x00000004);
pub const TAB0 = @as(c_int, 0x00000000);
pub const TAB3 = @as(c_int, 0x00000004);
pub const ONOEOT = @as(c_int, 0x00000008);
pub const OCRNL = @as(c_int, 0x00000010);
pub const ONOCR = @as(c_int, 0x00000020);
pub const ONLRET = @as(c_int, 0x00000040);
pub const CIGNORE = @as(c_int, 0x00000001);
pub const CSIZE = @as(c_int, 0x00000300);
pub const CS5 = @as(c_int, 0x00000000);
pub const CS6 = @as(c_int, 0x00000100);
pub const CS7 = @as(c_int, 0x00000200);
pub const CS8 = @as(c_int, 0x00000300);
pub const CSTOPB = @as(c_int, 0x00000400);
pub const CREAD = @as(c_int, 0x00000800);
pub const PARENB = @as(c_int, 0x00001000);
pub const PARODD = @as(c_int, 0x00002000);
pub const HUPCL = @as(c_int, 0x00004000);
pub const CLOCAL = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00008000, .hex);
pub const CCTS_OFLOW = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00010000, .hex);
pub const CRTSCTS = CCTS_OFLOW | CRTS_IFLOW;
pub const CRTS_IFLOW = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00020000, .hex);
pub const CDTR_IFLOW = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00040000, .hex);
pub const CDSR_OFLOW = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hex);
pub const CCAR_OFLOW = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00100000, .hex);
pub const CNO_RTSDTR = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00200000, .hex);
pub const ECHOKE = @as(c_int, 0x00000001);
pub const ECHOE = @as(c_int, 0x00000002);
pub const ECHOK = @as(c_int, 0x00000004);
pub const ECHO = @as(c_int, 0x00000008);
pub const ECHONL = @as(c_int, 0x00000010);
pub const ECHOPRT = @as(c_int, 0x00000020);
pub const ECHOCTL = @as(c_int, 0x00000040);
pub const ISIG = @as(c_int, 0x00000080);
pub const ICANON = @as(c_int, 0x00000100);
pub const ALTWERASE = @as(c_int, 0x00000200);
pub const IEXTEN = @as(c_int, 0x00000400);
pub const EXTPROC = @as(c_int, 0x00000800);
pub const TOSTOP = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00400000, .hex);
pub const FLUSHO = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00800000, .hex);
pub const NOKERNINFO = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x02000000, .hex);
pub const PENDIN = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x20000000, .hex);
pub const NOFLSH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hex);
pub const B0 = @as(c_int, 0);
pub const B50 = @as(c_int, 50);
pub const B75 = @as(c_int, 75);
pub const B110 = @as(c_int, 110);
pub const B134 = @as(c_int, 134);
pub const B150 = @as(c_int, 150);
pub const B200 = @as(c_int, 200);
pub const B300 = @as(c_int, 300);
pub const B600 = @as(c_int, 600);
pub const B1200 = @as(c_int, 1200);
pub const B1800 = @as(c_int, 1800);
pub const B2400 = @as(c_int, 2400);
pub const B4800 = @as(c_int, 4800);
pub const B9600 = @as(c_int, 9600);
pub const B19200 = @as(c_int, 19200);
pub const B38400 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 38400, .decimal);
pub const B7200 = @as(c_int, 7200);
pub const B14400 = @as(c_int, 14400);
pub const B28800 = @as(c_int, 28800);
pub const B57600 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 57600, .decimal);
pub const B76800 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 76800, .decimal);
pub const B115200 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 115200, .decimal);
pub const B230400 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 230400, .decimal);
pub const B460800 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 460800, .decimal);
pub const B500000 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 500000, .decimal);
pub const B921600 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 921600, .decimal);
pub const B1000000 = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 1000000, .decimal);
pub const B1500000 = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 1500000, .decimal);
pub const B2000000 = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 2000000, .decimal);
pub const B2500000 = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 2500000, .decimal);
pub const B3000000 = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 3000000, .decimal);
pub const B3500000 = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 3500000, .decimal);
pub const B4000000 = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4000000, .decimal);
pub const EXTA = @as(c_int, 19200);
pub const EXTB = @import("std").zig.c_translation.promoteIntLiteral(c_int, 38400, .decimal);
pub const _PID_T_DECLARED = "";
pub const OXTABS = TAB3;
pub const MDMBUF = CCAR_OFLOW;
pub inline fn CCEQ(val: anytype, c: anytype) @TypeOf((c == val) and (val != _POSIX_VDISABLE)) {
    _ = &val;
    _ = &c;
    return (c == val) and (val != _POSIX_VDISABLE);
}
pub const TCSANOW = @as(c_int, 0);
pub const TCSADRAIN = @as(c_int, 1);
pub const TCSAFLUSH = @as(c_int, 2);
pub const TCSASOFT = @as(c_int, 0x10);
pub const TCIFLUSH = @as(c_int, 1);
pub const TCOFLUSH = @as(c_int, 2);
pub const TCIOFLUSH = @as(c_int, 3);
pub const TCOOFF = @as(c_int, 1);
pub const TCOON = @as(c_int, 2);
pub const TCIOFF = @as(c_int, 3);
pub const TCION = @as(c_int, 4);
pub const _SYS_TTYDEFAULTS_H_ = "";
pub const TTYDEF_IFLAG = ((((BRKINT | ICRNL) | IMAXBEL) | IXON) | IXANY) | IUTF8;
pub const TTYDEF_OFLAG = OPOST | ONLCR;
pub const TTYDEF_LFLAG_NOECHO = (ICANON | ISIG) | IEXTEN;
pub const TTYDEF_LFLAG_ECHO = (((TTYDEF_LFLAG_NOECHO | ECHO) | ECHOE) | ECHOKE) | ECHOCTL;
pub const TTYDEF_LFLAG = TTYDEF_LFLAG_ECHO;
pub const TTYDEF_CFLAG = (CREAD | CS8) | HUPCL;
pub const TTYDEF_SPEED = B9600;
pub inline fn CTRL(x: anytype) @TypeOf(if ((x >= 'a') and (x <= 'z')) (x - 'a') + @as(c_int, 1) else ((x - 'A') + @as(c_int, 1)) & @as(c_int, 0x7f)) {
    _ = &x;
    return if ((x >= 'a') and (x <= 'z')) (x - 'a') + @as(c_int, 1) else ((x - 'A') + @as(c_int, 1)) & @as(c_int, 0x7f);
}
pub const CEOF = CTRL('D');
pub const CEOL = @as(c_int, 0xff);
pub const CERASE = CTRL('?');
pub const CERASE2 = CTRL('H');
pub const CINTR = CTRL('C');
pub const CSTATUS = CTRL('T');
pub const CKILL = CTRL('U');
pub const CMIN = @as(c_int, 1);
pub const CQUIT = CTRL('\\');
pub const CSUSP = CTRL('Z');
pub const CTIME = @as(c_int, 0);
pub const CDSUSP = CTRL('Y');
pub const CSTART = CTRL('Q');
pub const CSTOP = CTRL('S');
pub const CLNEXT = CTRL('V');
pub const CDISCARD = CTRL('O');
pub const CWERASE = CTRL('W');
pub const CREPRINT = CTRL('R');
pub const CEOT = CEOF;
pub const CBRK = CEOL;
pub const CRPRNT = CREPRINT;
pub const CFLUSH = CDISCARD;
pub const _SYS_CONSIO_H_ = "";
pub const _SYS_TYPES_H_ = "";
pub const _MACHINE_ENDIAN_H_ = "";
pub const _SYS__ENDIAN_H_ = "";
pub const _BYTE_ORDER = __BYTE_ORDER__;
pub const _LITTLE_ENDIAN = __ORDER_LITTLE_ENDIAN__;
pub const _BIG_ENDIAN = __ORDER_BIG_ENDIAN__;
pub const _PDP_ENDIAN = __ORDER_PDP_ENDIAN__;
pub const _QUAD_HIGHWORD = @as(c_int, 1);
pub const _QUAD_LOWWORD = @as(c_int, 0);
pub const LITTLE_ENDIAN = _LITTLE_ENDIAN;
pub const BIG_ENDIAN = _BIG_ENDIAN;
pub const PDP_ENDIAN = _PDP_ENDIAN;
pub const BYTE_ORDER = _BYTE_ORDER;
pub inline fn __bswap16(x: anytype) @TypeOf(__builtin_bswap16(x)) {
    _ = &x;
    return __builtin_bswap16(x);
}
pub inline fn __bswap32(x: anytype) @TypeOf(__builtin_bswap32(x)) {
    _ = &x;
    return __builtin_bswap32(x);
}
pub inline fn __bswap64(x: anytype) @TypeOf(__builtin_bswap64(x)) {
    _ = &x;
    return __builtin_bswap64(x);
}
pub inline fn __ntohl(x: anytype) @TypeOf(__bswap32(x)) {
    _ = &x;
    return __bswap32(x);
}
pub inline fn __ntohs(x: anytype) @TypeOf(__bswap16(x)) {
    _ = &x;
    return __bswap16(x);
}
pub inline fn __htonl(x: anytype) @TypeOf(__bswap32(x)) {
    _ = &x;
    return __bswap32(x);
}
pub inline fn __htons(x: anytype) @TypeOf(__bswap16(x)) {
    _ = &x;
    return __bswap16(x);
}
pub inline fn htobe16(x: anytype) @TypeOf(__bswap16(x)) {
    _ = &x;
    return __bswap16(x);
}
pub inline fn htobe32(x: anytype) @TypeOf(__bswap32(x)) {
    _ = &x;
    return __bswap32(x);
}
pub inline fn htobe64(x: anytype) @TypeOf(__bswap64(x)) {
    _ = &x;
    return __bswap64(x);
}
pub inline fn htole16(x: anytype) u16 {
    _ = &x;
    return @import("std").zig.c_translation.cast(u16, x);
}
pub inline fn htole32(x: anytype) u32 {
    _ = &x;
    return @import("std").zig.c_translation.cast(u32, x);
}
pub inline fn htole64(x: anytype) u64 {
    _ = &x;
    return @import("std").zig.c_translation.cast(u64, x);
}
pub inline fn be16toh(x: anytype) @TypeOf(__bswap16(x)) {
    _ = &x;
    return __bswap16(x);
}
pub inline fn be32toh(x: anytype) @TypeOf(__bswap32(x)) {
    _ = &x;
    return __bswap32(x);
}
pub inline fn be64toh(x: anytype) @TypeOf(__bswap64(x)) {
    _ = &x;
    return __bswap64(x);
}
pub inline fn le16toh(x: anytype) u16 {
    _ = &x;
    return @import("std").zig.c_translation.cast(u16, x);
}
pub inline fn le32toh(x: anytype) u32 {
    _ = &x;
    return @import("std").zig.c_translation.cast(u32, x);
}
pub inline fn le64toh(x: anytype) u64 {
    _ = &x;
    return @import("std").zig.c_translation.cast(u64, x);
}
pub const _SYS__PTHREADTYPES_H_ = "";
pub const _PTHREAD_T_DECLARED = "";
pub const _SYS__STDINT_H_ = "";
pub const _INT8_T_DECLARED = "";
pub const _INT16_T_DECLARED = "";
pub const _INT32_T_DECLARED = "";
pub const _INT64_T_DECLARED = "";
pub const _UINT8_T_DECLARED = "";
pub const _UINT16_T_DECLARED = "";
pub const _UINT32_T_DECLARED = "";
pub const _UINT64_T_DECLARED = "";
pub const _INTPTR_T_DECLARED = "";
pub const _UINTPTR_T_DECLARED = "";
pub const _INTMAX_T_DECLARED = "";
pub const _UINTMAX_T_DECLARED = "";
pub const _BLKSIZE_T_DECLARED = "";
pub const _BLKCNT_T_DECLARED = "";
pub const _CLOCK_T_DECLARED = "";
pub const _CLOCKID_T_DECLARED = "";
pub const _DEV_T_DECLARED = "";
pub const _FFLAGS_T_DECLARED = "";
pub const _FSBLKCNT_T_DECLARED = "";
pub const _GID_T_DECLARED = "";
pub const _IN_ADDR_T_DECLARED = "";
pub const _IN_PORT_T_DECLARED = "";
pub const _ID_T_DECLARED = "";
pub const _INO_T_DECLARED = "";
pub const _KEY_T_DECLARED = "";
pub const _LWPID_T_DECLARED = "";
pub const _MODE_T_DECLARED = "";
pub const _ACCMODE_T_DECLARED = "";
pub const _NLINK_T_DECLARED = "";
pub const _OFF_T_DECLARED = "";
pub const _OFF64_T_DECLARED = "";
pub const _RLIM_T_DECLARED = "";
pub const _SIZE_T_DECLARED = "";
pub const _SSIZE_T_DECLARED = "";
pub const _SUSECONDS_T_DECLARED = "";
pub const _TIME_T_DECLARED = "";
pub const _TIMER_T_DECLARED = "";
pub const _MQD_T_DECLARED = "";
pub const _UID_T_DECLARED = "";
pub const _USECONDS_T_DECLARED = "";
pub const _CAP_IOCTL_T_DECLARED = "";
pub const _CAP_RIGHTS_T_DECLARED = "";
pub const _SYS_BITCOUNT_H_ = "";
pub const __bitcount64 = @compileError("unable to translate macro: undefined identifier `__builtin_popcountll`");
// /usr/include/sys/bitcount.h:43:9
pub inline fn __bitcount32(x: anytype) @TypeOf(__builtin_popcount(@import("std").zig.c_translation.cast(__uint32_t, x))) {
    _ = &x;
    return __builtin_popcount(@import("std").zig.c_translation.cast(__uint32_t, x));
}
pub inline fn __bitcount16(x: anytype) @TypeOf(__builtin_popcount(@import("std").zig.c_translation.cast(__uint16_t, x))) {
    _ = &x;
    return __builtin_popcount(@import("std").zig.c_translation.cast(__uint16_t, x));
}
pub const __bitcountl = @compileError("unable to translate macro: undefined identifier `__builtin_popcountl`");
// /usr/include/sys/bitcount.h:46:9
pub inline fn __bitcount(x: anytype) @TypeOf(__builtin_popcount(@import("std").zig.c_translation.cast(c_uint, x))) {
    _ = &x;
    return __builtin_popcount(@import("std").zig.c_translation.cast(c_uint, x));
}
pub const _SYS_SELECT_H_ = "";
pub const _SYS__SIGSET_H_ = "";
pub const _SIG_WORDS = @as(c_int, 4);
pub const _SIG_MAXSIG = @as(c_int, 128);
pub inline fn _SIG_IDX(sig: anytype) @TypeOf(sig - @as(c_int, 1)) {
    _ = &sig;
    return sig - @as(c_int, 1);
}
pub inline fn _SIG_WORD(sig: anytype) @TypeOf(_SIG_IDX(sig) >> @as(c_int, 5)) {
    _ = &sig;
    return _SIG_IDX(sig) >> @as(c_int, 5);
}
pub inline fn _SIG_BIT(sig: anytype) @TypeOf(@as(c_uint, 1) << (_SIG_IDX(sig) & @as(c_int, 31))) {
    _ = &sig;
    return @as(c_uint, 1) << (_SIG_IDX(sig) & @as(c_int, 31));
}
pub inline fn _SIG_VALID(sig: anytype) @TypeOf((sig <= _SIG_MAXSIG) and (sig > @as(c_int, 0))) {
    _ = &sig;
    return (sig <= _SIG_MAXSIG) and (sig > @as(c_int, 0));
}
pub const _SYS__TIMEVAL_H_ = "";
pub const _SYS_TIMESPEC_H_ = "";
pub const _SYS__TIMESPEC_H_ = "";
pub const TIMEVAL_TO_TIMESPEC = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/timespec.h:39:9
pub const TIMESPEC_TO_TIMEVAL = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/timespec.h:44:9
pub const _SIGSET_T_DECLARED = "";
pub const __SSP_FORTIFY_LEVEL = @as(c_int, 0);
pub const FD_SETSIZE = @as(c_int, 1024);
pub const _NFDBITS = @import("std").zig.c_translation.sizeof(__fd_mask) * @as(c_int, 8);
pub const NFDBITS = _NFDBITS;
pub inline fn _howmany(x: anytype, y: anytype) @TypeOf(@import("std").zig.c_translation.MacroArithmetic.div(x + (y - @as(c_int, 1)), y)) {
    _ = &x;
    _ = &y;
    return @import("std").zig.c_translation.MacroArithmetic.div(x + (y - @as(c_int, 1)), y);
}
pub const fds_bits = @compileError("unable to translate macro: undefined identifier `__fds_bits`");
// /usr/include/sys/select.h:81:9
pub inline fn __fdset_idx_(p: anytype, n: anytype) @TypeOf(@import("std").zig.c_translation.MacroArithmetic.div(n, _NFDBITS)) {
    _ = &p;
    _ = &n;
    return @import("std").zig.c_translation.MacroArithmetic.div(n, _NFDBITS);
}
pub inline fn __fdset_idx(p: anytype, n: anytype) @TypeOf(__fdset_idx_(p, n)) {
    _ = &p;
    _ = &n;
    return __fdset_idx_(p, n);
}
pub inline fn __fdset_mask(n: anytype) @TypeOf(@import("std").zig.c_translation.cast(__fd_mask, @as(c_int, 1)) << @import("std").zig.c_translation.MacroArithmetic.rem(n, _NFDBITS)) {
    _ = &n;
    return @import("std").zig.c_translation.cast(__fd_mask, @as(c_int, 1)) << @import("std").zig.c_translation.MacroArithmetic.rem(n, _NFDBITS);
}
pub const FD_CLR = @compileError("unable to translate C expr: expected ')' instead got '&='");
// /usr/include/sys/select.h:104:9
pub const FD_COPY = @compileError("unable to translate C expr: expected ')' instead got '='");
// /usr/include/sys/select.h:106:9
pub inline fn FD_ISSET(n: anytype, p: anytype) @TypeOf((p.*.__fds_bits[@as(usize, @intCast(__fdset_idx(p, n)))] & __fdset_mask(n)) != @as(c_int, 0)) {
    _ = &n;
    _ = &p;
    return (p.*.__fds_bits[@as(usize, @intCast(__fdset_idx(p, n)))] & __fdset_mask(n)) != @as(c_int, 0);
}
pub const FD_SET = @compileError("unable to translate C expr: expected ')' instead got '|='");
// /usr/include/sys/select.h:110:9
pub const FD_ZERO = @compileError("unable to translate macro: undefined identifier `_p`");
// /usr/include/sys/select.h:111:9
pub const _SELECT_DECLARED = "";
pub inline fn major(d: anytype) @TypeOf(__major(d)) {
    _ = &d;
    return __major(d);
}
pub inline fn minor(d: anytype) @TypeOf(__minor(d)) {
    _ = &d;
    return __minor(d);
}
pub inline fn makedev(M: anytype, m: anytype) @TypeOf(__makedev(M, m)) {
    _ = &M;
    _ = &m;
    return __makedev(M, m);
}
pub const __enum_uint8_decl = @compileError("unable to translate macro: undefined identifier `_uint8`");
// /usr/include/sys/types.h:352:9
pub const __enum_uint8 = @compileError("unable to translate macro: undefined identifier `_uint8`");
// /usr/include/sys/types.h:353:9
pub const _FTRUNCATE_DECLARED = "";
pub const _LSEEK_DECLARED = "";
pub const _MMAP_DECLARED = "";
pub const _TRUNCATE_DECLARED = "";
pub const _SYS_FONT_H_ = "";
pub const _SYS_QUEUE_H_ = "";
pub const QMD_TRACE_ELEM = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/sys/queue.h:150:9
pub const QMD_TRACE_HEAD = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/sys/queue.h:151:9
pub const TRACEBUF = "";
pub const TRACEBUF_INITIALIZER = "";
pub const QMD_SAVELINK = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/sys/queue.h:161:9
pub const TRASHIT = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/sys/queue.h:162:9
pub inline fn QMD_IS_TRASHED(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub const QMD_ASSERT = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /usr/include/sys/queue.h:218:9
pub const QUEUE_TYPEOF = @compileError("unable to translate macro: untranslatable usage of arg `type`");
// /usr/include/sys/queue.h:228:9
pub const SLIST_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:235:9
pub const SLIST_CLASS_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:240:9
pub const SLIST_HEAD_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/sys/queue.h:245:9
pub const SLIST_ENTRY = @compileError("unable to translate macro: untranslatable usage of arg `type`");
// /usr/include/sys/queue.h:248:9
pub const SLIST_CLASS_ENTRY = @compileError("unable to translate macro: undefined identifier `class`");
// /usr/include/sys/queue.h:253:9
pub inline fn QMD_SLIST_CHECK_PREVPTR(prevp: anytype, elm: anytype) @TypeOf(QMD_ASSERT(prevp.* == elm, "Bad prevptr *(%p) == %p != %p", prevp, prevp.*, elm)) {
    _ = &prevp;
    _ = &elm;
    return QMD_ASSERT(prevp.* == elm, "Bad prevptr *(%p) == %p != %p", prevp, prevp.*, elm);
}
pub inline fn SLIST_ASSERT_EMPTY(head: anytype) @TypeOf(QMD_ASSERT(SLIST_EMPTY(head), "slist %p is not empty", head)) {
    _ = &head;
    return QMD_ASSERT(SLIST_EMPTY(head), "slist %p is not empty", head);
}
pub inline fn SLIST_ASSERT_NONEMPTY(head: anytype) @TypeOf(QMD_ASSERT(!(SLIST_EMPTY(head) != 0), "slist %p is empty", head)) {
    _ = &head;
    return QMD_ASSERT(!(SLIST_EMPTY(head) != 0), "slist %p is empty", head);
}
pub const SLIST_CONCAT = @compileError("unable to translate macro: undefined identifier `_Curelm`");
// /usr/include/sys/queue.h:275:9
pub inline fn SLIST_EMPTY(head: anytype) @TypeOf(head.*.slh_first == NULL) {
    _ = &head;
    return head.*.slh_first == NULL;
}
pub const SLIST_EMPTY_ATOMIC = @compileError("unable to translate macro: undefined identifier `atomic_load_ptr`");
// /usr/include/sys/queue.h:290:9
pub inline fn SLIST_FIRST(head: anytype) @TypeOf(head.*.slh_first) {
    _ = &head;
    return head.*.slh_first;
}
pub const SLIST_FOREACH = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:295:9
pub const SLIST_FOREACH_FROM = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:300:9
pub const SLIST_FOREACH_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:305:9
pub const SLIST_FOREACH_FROM_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:310:9
pub const SLIST_FOREACH_PREVPTR = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:315:9
pub const SLIST_INIT = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:320:9
pub const SLIST_INSERT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:324:9
pub const SLIST_INSERT_HEAD = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:329:9
pub inline fn SLIST_NEXT(elm: anytype, field: anytype) @TypeOf(elm.*.field.sle_next) {
    _ = &elm;
    _ = &field;
    return elm.*.field.sle_next;
}
pub const SLIST_REMOVE = @compileError("unable to translate macro: undefined identifier `_Curelm`");
// /usr/include/sys/queue.h:336:9
pub const SLIST_REMOVE_AFTER = @compileError("unable to translate macro: undefined identifier `_Oldnext`");
// /usr/include/sys/queue.h:348:9
pub const SLIST_REMOVE_HEAD = @compileError("unable to translate macro: undefined identifier `_Oldnext`");
// /usr/include/sys/queue.h:355:9
pub const SLIST_REMOVE_PREVPTR = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:361:9
pub const SLIST_SPLIT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:367:9
pub const SLIST_SWAP = @compileError("unable to translate macro: undefined identifier `_Swap_first`");
// /usr/include/sys/queue.h:373:9
pub inline fn SLIST_END(head: anytype) @TypeOf(NULL) {
    _ = &head;
    return NULL;
}
pub const STAILQ_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:385:9
pub const STAILQ_CLASS_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:391:9
pub const STAILQ_HEAD_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/sys/queue.h:397:9
pub const STAILQ_ENTRY = @compileError("unable to translate macro: untranslatable usage of arg `type`");
// /usr/include/sys/queue.h:400:9
pub const STAILQ_CLASS_ENTRY = @compileError("unable to translate macro: undefined identifier `class`");
// /usr/include/sys/queue.h:405:9
pub inline fn QMD_STAILQ_CHECK_EMPTY(head: anytype) @TypeOf(QMD_ASSERT(head.*.stqh_last == (&head.*.stqh_first), "Empty stailq %p->stqh_last is %p, " ++ "not head's first field address", head, head.*.stqh_last)) {
    _ = &head;
    return QMD_ASSERT(head.*.stqh_last == (&head.*.stqh_first), "Empty stailq %p->stqh_last is %p, " ++ "not head's first field address", head, head.*.stqh_last);
}
pub inline fn QMD_STAILQ_CHECK_TAIL(head: anytype) @TypeOf(QMD_ASSERT(head.*.stqh_last.* == NULL, "Stailq %p last element's next pointer is " ++ "%p, not NULL", head, head.*.stqh_last.*)) {
    _ = &head;
    return QMD_ASSERT(head.*.stqh_last.* == NULL, "Stailq %p last element's next pointer is " ++ "%p, not NULL", head, head.*.stqh_last.*);
}
pub inline fn STAILQ_ASSERT_EMPTY(head: anytype) @TypeOf(QMD_ASSERT(STAILQ_EMPTY(head), "stailq %p is not empty", head)) {
    _ = &head;
    return QMD_ASSERT(STAILQ_EMPTY(head), "stailq %p is not empty", head);
}
pub inline fn STAILQ_ASSERT_NONEMPTY(head: anytype) @TypeOf(QMD_ASSERT(!(STAILQ_EMPTY(head) != 0), "stailq %p is empty", head)) {
    _ = &head;
    return QMD_ASSERT(!(STAILQ_EMPTY(head) != 0), "stailq %p is empty", head);
}
pub const STAILQ_CONCAT = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:444:9
pub const STAILQ_EMPTY = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/sys/queue.h:452:9
pub const STAILQ_EMPTY_ATOMIC = @compileError("unable to translate macro: undefined identifier `atomic_load_ptr`");
// /usr/include/sys/queue.h:458:9
pub inline fn STAILQ_FIRST(head: anytype) @TypeOf(head.*.stqh_first) {
    _ = &head;
    return head.*.stqh_first;
}
pub const STAILQ_FOREACH = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:463:9
pub const STAILQ_FOREACH_FROM = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:468:9
pub const STAILQ_FOREACH_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:473:9
pub const STAILQ_FOREACH_FROM_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:478:9
pub const STAILQ_INIT = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:483:9
pub const STAILQ_INSERT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:488:9
pub const STAILQ_INSERT_HEAD = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:494:9
pub const STAILQ_INSERT_TAIL = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:500:9
pub inline fn STAILQ_LAST(head: anytype, @"type": anytype, field: anytype) @TypeOf(if (STAILQ_EMPTY(head) != 0) NULL else __containerof(head.*.stqh_last, QUEUE_TYPEOF(@"type"), field.stqe_next)) {
    _ = &head;
    _ = &@"type";
    _ = &field;
    return if (STAILQ_EMPTY(head) != 0) NULL else __containerof(head.*.stqh_last, QUEUE_TYPEOF(@"type"), field.stqe_next);
}
pub inline fn STAILQ_NEXT(elm: anytype, field: anytype) @TypeOf(elm.*.field.stqe_next) {
    _ = &elm;
    _ = &field;
    return elm.*.field.stqe_next;
}
pub const STAILQ_REMOVE = @compileError("unable to translate macro: undefined identifier `_Oldnext`");
// /usr/include/sys/queue.h:514:9
pub const STAILQ_REMOVE_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:528:9
pub const STAILQ_REMOVE_HEAD = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:534:9
pub const STAILQ_SPLIT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:540:9
pub const STAILQ_SWAP = @compileError("unable to translate macro: undefined identifier `_Swap_first`");
// /usr/include/sys/queue.h:554:9
pub const STAILQ_REVERSE = @compileError("unable to translate macro: undefined identifier `_Var`");
// /usr/include/sys/queue.h:567:9
pub inline fn STAILQ_END(head: anytype) @TypeOf(NULL) {
    _ = &head;
    return NULL;
}
pub const LIST_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:589:9
pub const LIST_CLASS_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:594:9
pub const LIST_HEAD_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/sys/queue.h:599:9
pub const LIST_ENTRY = @compileError("unable to translate macro: untranslatable usage of arg `type`");
// /usr/include/sys/queue.h:602:9
pub const LIST_CLASS_ENTRY = @compileError("unable to translate macro: undefined identifier `class`");
// /usr/include/sys/queue.h:608:9
pub inline fn QMD_LIST_CHECK_HEAD(head: anytype, field: anytype) @TypeOf(QMD_ASSERT((LIST_FIRST(head) == NULL) or (LIST_FIRST(head).*.field.le_prev == (&LIST_FIRST(head))), "Bad list head %p first->prev != head", head)) {
    _ = &head;
    _ = &field;
    return QMD_ASSERT((LIST_FIRST(head) == NULL) or (LIST_FIRST(head).*.field.le_prev == (&LIST_FIRST(head))), "Bad list head %p first->prev != head", head);
}
pub inline fn QMD_LIST_CHECK_NEXT(elm: anytype, field: anytype) @TypeOf(QMD_ASSERT((LIST_NEXT(elm, field) == NULL) or (LIST_NEXT(elm, field).*.field.le_prev == (&elm.*.field.le_next)), "Bad link elm %p next->prev != elm", elm)) {
    _ = &elm;
    _ = &field;
    return QMD_ASSERT((LIST_NEXT(elm, field) == NULL) or (LIST_NEXT(elm, field).*.field.le_prev == (&elm.*.field.le_next)), "Bad link elm %p next->prev != elm", elm);
}
pub inline fn QMD_LIST_CHECK_PREV(elm: anytype, field: anytype) @TypeOf(QMD_ASSERT(elm.*.field.le_prev.* == elm, "Bad link elm %p prev->next != elm", elm)) {
    _ = &elm;
    _ = &field;
    return QMD_ASSERT(elm.*.field.le_prev.* == elm, "Bad link elm %p prev->next != elm", elm);
}
pub inline fn LIST_ASSERT_EMPTY(head: anytype) @TypeOf(QMD_ASSERT(LIST_EMPTY(head), "list %p is not empty", head)) {
    _ = &head;
    return QMD_ASSERT(LIST_EMPTY(head), "list %p is not empty", head);
}
pub inline fn LIST_ASSERT_NONEMPTY(head: anytype) @TypeOf(QMD_ASSERT(!(LIST_EMPTY(head) != 0), "list %p is empty", head)) {
    _ = &head;
    return QMD_ASSERT(!(LIST_EMPTY(head) != 0), "list %p is empty", head);
}
pub const LIST_CONCAT = @compileError("unable to translate macro: undefined identifier `_Curelm`");
// /usr/include/sys/queue.h:660:9
pub inline fn LIST_EMPTY(head: anytype) @TypeOf(head.*.lh_first == NULL) {
    _ = &head;
    return head.*.lh_first == NULL;
}
pub const LIST_EMPTY_ATOMIC = @compileError("unable to translate macro: undefined identifier `atomic_load_ptr`");
// /usr/include/sys/queue.h:679:9
pub inline fn LIST_FIRST(head: anytype) @TypeOf(head.*.lh_first) {
    _ = &head;
    return head.*.lh_first;
}
pub const LIST_FOREACH = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:684:9
pub const LIST_FOREACH_FROM = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:689:9
pub const LIST_FOREACH_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:694:9
pub const LIST_FOREACH_FROM_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:699:9
pub const LIST_INIT = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:704:9
pub const LIST_INSERT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:708:9
pub const LIST_INSERT_BEFORE = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:717:9
pub const LIST_INSERT_HEAD = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:725:9
pub inline fn LIST_NEXT(elm: anytype, field: anytype) @TypeOf(elm.*.field.le_next) {
    _ = &elm;
    _ = &field;
    return elm.*.field.le_next;
}
pub inline fn LIST_PREV(elm: anytype, head: anytype, @"type": anytype, field: anytype) @TypeOf(if (elm.*.field.le_prev == (&LIST_FIRST(head))) NULL else __containerof(elm.*.field.le_prev, QUEUE_TYPEOF(@"type"), field.le_next)) {
    _ = &elm;
    _ = &head;
    _ = &@"type";
    _ = &field;
    return if (elm.*.field.le_prev == (&LIST_FIRST(head))) NULL else __containerof(elm.*.field.le_prev, QUEUE_TYPEOF(@"type"), field.le_next);
}
pub inline fn LIST_REMOVE_HEAD(head: anytype, field: anytype) @TypeOf(LIST_REMOVE(LIST_FIRST(head), field)) {
    _ = &head;
    _ = &field;
    return LIST_REMOVE(LIST_FIRST(head), field);
}
pub const LIST_REMOVE = @compileError("unable to translate macro: undefined identifier `_Oldnext`");
// /usr/include/sys/queue.h:743:9
pub const LIST_REPLACE = @compileError("unable to translate macro: undefined identifier `_Oldnext`");
// /usr/include/sys/queue.h:756:9
pub const LIST_SPLIT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:771:9
pub const LIST_SWAP = @compileError("unable to translate macro: undefined identifier `swap_tmp`");
// /usr/include/sys/queue.h:784:9
pub inline fn LIST_END(head: anytype) @TypeOf(NULL) {
    _ = &head;
    return NULL;
}
pub const TAILQ_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:800:9
pub const TAILQ_CLASS_HEAD = @compileError("unable to translate macro: untranslatable usage of arg `name`");
// /usr/include/sys/queue.h:807:9
pub const TAILQ_HEAD_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/sys/queue.h:814:9
pub const TAILQ_ENTRY = @compileError("unable to translate macro: untranslatable usage of arg `type`");
// /usr/include/sys/queue.h:817:9
pub const TAILQ_CLASS_ENTRY = @compileError("unable to translate macro: undefined identifier `class`");
// /usr/include/sys/queue.h:824:9
pub inline fn QMD_TAILQ_CHECK_HEAD(head: anytype, field: anytype) @TypeOf(QMD_ASSERT((TAILQ_EMPTY(head) != 0) or (TAILQ_FIRST(head).*.field.tqe_prev == (&TAILQ_FIRST(head))), "Bad tailq head %p first->prev != head", head)) {
    _ = &head;
    _ = &field;
    return QMD_ASSERT((TAILQ_EMPTY(head) != 0) or (TAILQ_FIRST(head).*.field.tqe_prev == (&TAILQ_FIRST(head))), "Bad tailq head %p first->prev != head", head);
}
pub inline fn QMD_TAILQ_CHECK_TAIL(head: anytype, field: anytype) @TypeOf(QMD_ASSERT(head.*.tqh_last.* == NULL, "Bad tailq NEXT(%p->tqh_last) != NULL", head)) {
    _ = &head;
    _ = &field;
    return QMD_ASSERT(head.*.tqh_last.* == NULL, "Bad tailq NEXT(%p->tqh_last) != NULL", head);
}
pub inline fn QMD_TAILQ_CHECK_NEXT(elm: anytype, field: anytype) @TypeOf(QMD_ASSERT((TAILQ_NEXT(elm, field) == NULL) or (TAILQ_NEXT(elm, field).*.field.tqe_prev == (&elm.*.field.tqe_next)), "Bad link elm %p next->prev != elm", elm)) {
    _ = &elm;
    _ = &field;
    return QMD_ASSERT((TAILQ_NEXT(elm, field) == NULL) or (TAILQ_NEXT(elm, field).*.field.tqe_prev == (&elm.*.field.tqe_next)), "Bad link elm %p next->prev != elm", elm);
}
pub inline fn QMD_TAILQ_CHECK_PREV(elm: anytype, field: anytype) @TypeOf(QMD_ASSERT(elm.*.field.tqe_prev.* == elm, "Bad link elm %p prev->next != elm", elm)) {
    _ = &elm;
    _ = &field;
    return QMD_ASSERT(elm.*.field.tqe_prev.* == elm, "Bad link elm %p prev->next != elm", elm);
}
pub inline fn TAILQ_ASSERT_EMPTY(head: anytype) @TypeOf(QMD_ASSERT(TAILQ_EMPTY(head), "tailq %p is not empty", head)) {
    _ = &head;
    return QMD_ASSERT(TAILQ_EMPTY(head), "tailq %p is not empty", head);
}
pub inline fn TAILQ_ASSERT_NONEMPTY(head: anytype) @TypeOf(QMD_ASSERT(!(TAILQ_EMPTY(head) != 0), "tailq %p is empty", head)) {
    _ = &head;
    return QMD_ASSERT(!(TAILQ_EMPTY(head) != 0), "tailq %p is empty", head);
}
pub const TAILQ_CONCAT = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:887:9
pub inline fn TAILQ_EMPTY(head: anytype) @TypeOf(head.*.tqh_first == NULL) {
    _ = &head;
    return head.*.tqh_first == NULL;
}
pub const TAILQ_EMPTY_ATOMIC = @compileError("unable to translate macro: undefined identifier `atomic_load_ptr`");
// /usr/include/sys/queue.h:900:9
pub inline fn TAILQ_FIRST(head: anytype) @TypeOf(head.*.tqh_first) {
    _ = &head;
    return head.*.tqh_first;
}
pub const TAILQ_FOREACH = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:905:9
pub const TAILQ_FOREACH_FROM = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:910:9
pub const TAILQ_FOREACH_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:915:9
pub const TAILQ_FOREACH_FROM_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:920:9
pub const TAILQ_FOREACH_REVERSE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:925:9
pub const TAILQ_FOREACH_REVERSE_FROM = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:930:9
pub const TAILQ_FOREACH_REVERSE_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:935:9
pub const TAILQ_FOREACH_REVERSE_FROM_SAFE = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/include/sys/queue.h:940:9
pub const TAILQ_INIT = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:945:9
pub const TAILQ_INSERT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:951:9
pub const TAILQ_INSERT_BEFORE = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:966:9
pub const TAILQ_INSERT_HEAD = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:976:9
pub const TAILQ_INSERT_TAIL = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:989:9
pub const TAILQ_LAST = @compileError("unable to translate macro: untranslatable usage of arg `headname`");
// /usr/include/sys/queue.h:999:9
pub inline fn TAILQ_LAST_FAST(head: anytype, @"type": anytype, field: anytype) @TypeOf(if (TAILQ_EMPTY(head) != 0) NULL else __containerof(head.*.tqh_last, QUEUE_TYPEOF(@"type"), field.tqe_next)) {
    _ = &head;
    _ = &@"type";
    _ = &field;
    return if (TAILQ_EMPTY(head) != 0) NULL else __containerof(head.*.tqh_last, QUEUE_TYPEOF(@"type"), field.tqe_next);
}
pub inline fn TAILQ_NEXT(elm: anytype, field: anytype) @TypeOf(elm.*.field.tqe_next) {
    _ = &elm;
    _ = &field;
    return elm.*.field.tqe_next;
}
pub const TAILQ_PREV = @compileError("unable to translate macro: untranslatable usage of arg `headname`");
// /usr/include/sys/queue.h:1014:9
pub inline fn TAILQ_PREV_FAST(elm: anytype, head: anytype, @"type": anytype, field: anytype) @TypeOf(if (elm.*.field.tqe_prev == (&head.*.tqh_first)) NULL else __containerof(elm.*.field.tqe_prev, QUEUE_TYPEOF(@"type"), field.tqe_next)) {
    _ = &elm;
    _ = &head;
    _ = &@"type";
    _ = &field;
    return if (elm.*.field.tqe_prev == (&head.*.tqh_first)) NULL else __containerof(elm.*.field.tqe_prev, QUEUE_TYPEOF(@"type"), field.tqe_next);
}
pub inline fn TAILQ_REMOVE_HEAD(head: anytype, field: anytype) @TypeOf(TAILQ_REMOVE(head, TAILQ_FIRST(head), field)) {
    _ = &head;
    _ = &field;
    return TAILQ_REMOVE(head, TAILQ_FIRST(head), field);
}
pub const TAILQ_REMOVE = @compileError("unable to translate macro: undefined identifier `_Oldnext`");
// /usr/include/sys/queue.h:1024:9
pub const TAILQ_REPLACE = @compileError("unable to translate macro: undefined identifier `_Oldnext`");
// /usr/include/sys/queue.h:1042:9
pub const TAILQ_SPLIT_AFTER = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/sys/queue.h:1060:9
pub const TAILQ_SWAP = @compileError("unable to translate macro: undefined identifier `swap_first`");
// /usr/include/sys/queue.h:1077:9
pub inline fn TAILQ_END(head: anytype) @TypeOf(NULL) {
    _ = &head;
    return NULL;
}
pub const FONT_HEADER_MAGIC = "VFNT0002";
pub const KD_TEXT = @as(c_int, 0);
pub const KD_TEXT0 = @as(c_int, 0);
pub const KD_GRAPHICS = @as(c_int, 1);
pub const KD_TEXT1 = @as(c_int, 2);
pub const KD_PIXEL = @as(c_int, 3);
pub const KDGETMODE = _IOR('K', @as(c_int, 9), c_int);
pub const KDSETMODE = _IOWINT('K', @as(c_int, 10));
pub const KDSBORDER = _IOWINT('K', @as(c_int, 13));
pub const KDRASTER = _IOW('K', @as(c_int, 100), scr_size_t);
pub const GIO_SCRNMAP = _IOR('k', @as(c_int, 2), scrmap_t);
pub const PIO_SCRNMAP = _IOW('k', @as(c_int, 3), scrmap_t);
pub const GIO_ATTR = _IOR('a', @as(c_int, 0), c_int);
pub const GIO_COLOR = _IOR('c', @as(c_int, 0), c_int);
pub const CONS_CURRENT = _IOR('c', @as(c_int, 1), c_int);
pub const CONS_GET = _IOR('c', @as(c_int, 2), c_int);
pub const CONS_IO = _IO('c', @as(c_int, 3));
pub const CONS_BLANKTIME = _IOW('c', @as(c_int, 4), c_int);
pub const MAXSSAVER = @as(c_int, 16);
pub const CONS_SSAVER = _IOW('c', @as(c_int, 5), ssaver_t);
pub const CONS_GSAVER = _IOWR('c', @as(c_int, 6), ssaver_t);
pub const CONS_CURSORTYPE = _IOW('c', @as(c_int, 7), c_int);
pub const CONS_VISUAL_BELL = @as(c_int, 1) << @as(c_int, 0);
pub const CONS_QUIET_BELL = @as(c_int, 1) << @as(c_int, 1);
pub const CONS_BELLTYPE = _IOW('c', @as(c_int, 8), c_int);
pub const CONS_HISTORY = _IOW('c', @as(c_int, 9), c_int);
pub const CONS_CLRHIST = _IO('c', @as(c_int, 10));
pub const MOUSE_SHOW = @as(c_int, 0x01);
pub const MOUSE_HIDE = @as(c_int, 0x02);
pub const MOUSE_MOVEABS = @as(c_int, 0x03);
pub const MOUSE_MOVEREL = @as(c_int, 0x04);
pub const MOUSE_GETINFO = @as(c_int, 0x05);
pub const MOUSE_MODE = @as(c_int, 0x06);
pub const MOUSE_ACTION = @as(c_int, 0x07);
pub const MOUSE_MOTION_EVENT = @as(c_int, 0x08);
pub const MOUSE_BUTTON_EVENT = @as(c_int, 0x09);
pub const MOUSE_MOUSECHAR = @as(c_int, 0x0a);
pub const CONS_MOUSECTL = _IOWR('c', @as(c_int, 10), mouse_info_t);
pub const CONS_IDLE = _IOR('c', @as(c_int, 11), c_int);
pub const CONS_NO_SAVER = -@as(c_int, 1);
pub const CONS_LKM_SAVER = @as(c_int, 0);
pub const CONS_USR_SAVER = @as(c_int, 1);
pub const CONS_SAVERMODE = _IOW('c', @as(c_int, 12), c_int);
pub const CONS_SAVERSTART = _IOW('c', @as(c_int, 13), c_int);
pub const CONS_BLINK_CURSOR = @as(c_int, 1) << @as(c_int, 0);
pub const CONS_CHAR_CURSOR = @as(c_int, 1) << @as(c_int, 1);
pub const CONS_HIDDEN_CURSOR = @as(c_int, 1) << @as(c_int, 2);
pub const CONS_CURSOR_ATTRS = (CONS_BLINK_CURSOR | CONS_CHAR_CURSOR) | CONS_HIDDEN_CURSOR;
pub const CONS_CHARCURSOR_COLORS = @as(c_int, 1) << @as(c_int, 26);
pub const CONS_MOUSECURSOR_COLORS = @as(c_int, 1) << @as(c_int, 27);
pub const CONS_DEFAULT_CURSOR = @as(c_int, 1) << @as(c_int, 28);
pub const CONS_SHAPEONLY_CURSOR = @as(c_int, 1) << @as(c_int, 29);
pub const CONS_RESET_CURSOR = @as(c_int, 1) << @as(c_int, 30);
pub const CONS_LOCAL_CURSOR = @as(c_uint, 1) << @as(c_int, 31);
pub const CONS_GETCURSORSHAPE = _IOWR('c', @as(c_int, 14), struct_cshape);
pub const CONS_SETCURSORSHAPE = _IOW('c', @as(c_int, 15), struct_cshape);
pub const PIO_FONT8x8 = _IOW('c', @as(c_int, 64), fnt8_t);
pub const GIO_FONT8x8 = _IOR('c', @as(c_int, 65), fnt8_t);
pub const PIO_FONT8x14 = _IOW('c', @as(c_int, 66), fnt14_t);
pub const GIO_FONT8x14 = _IOR('c', @as(c_int, 67), fnt14_t);
pub const PIO_FONT8x16 = _IOW('c', @as(c_int, 68), fnt16_t);
pub const GIO_FONT8x16 = _IOR('c', @as(c_int, 69), fnt16_t);
pub const PIO_VFONT = _IOW('c', @as(c_int, 70), vfnt_t);
pub const GIO_VFONT = _IOR('c', @as(c_int, 71), vfnt_t);
pub const PIO_VFONT_DEFAULT = _IO('c', @as(c_int, 72));
pub const CONS_GETINFO = _IOWR('c', @as(c_int, 73), vid_info_t);
pub const CONS_GETVERS = _IOR('c', @as(c_int, 74), c_int);
pub const CONS_CURRENTADP = _IOR('c', @as(c_int, 100), c_int);
pub const CONS_ADPINFO = @compileError("unable to translate macro: undefined identifier `video_adapter_info_t`");
// /usr/include/sys/consio.h:270:9
pub const CONS_MODEINFO = @compileError("unable to translate macro: undefined identifier `video_info_t`");
// /usr/include/sys/consio.h:273:9
pub const CONS_FINDMODE = @compileError("unable to translate macro: undefined identifier `video_info_t`");
// /usr/include/sys/consio.h:276:9
pub const CONS_SETWINORG = _IOWINT('c', @as(c_int, 104));
pub const CONS_SETKBD = _IOWINT('c', @as(c_int, 110));
pub const CONS_RELKBD = _IO('c', @as(c_int, 111));
pub const CONS_SCRSHOT = _IOWR('c', @as(c_int, 105), scrshot_t);
pub const TI_NAME_LEN = @as(c_int, 32);
pub const TI_DESC_LEN = @as(c_int, 64);
pub const CONS_GETTERM = _IOWR('c', @as(c_int, 112), term_info_t);
pub const CONS_SETTERM = _IOW('c', @as(c_int, 113), term_info_t);
pub const VT_OPENQRY = _IOR('v', @as(c_int, 1), c_int);
pub const _VT_MODE_DECLARED = "";
pub const VT_AUTO = @as(c_int, 0);
pub const VT_PROCESS = @as(c_int, 1);
pub const VT_KERNEL = @as(c_int, 255);
pub const VT_SETMODE = _IOW('v', @as(c_int, 2), vtmode_t);
pub const VT_GETMODE = _IOR('v', @as(c_int, 3), vtmode_t);
pub const VT_FALSE = @as(c_int, 0);
pub const VT_TRUE = @as(c_int, 1);
pub const VT_ACKACQ = @as(c_int, 2);
pub const VT_RELDISP = _IOWINT('v', @as(c_int, 4));
pub const VT_ACTIVATE = _IOWINT('v', @as(c_int, 5));
pub const VT_WAITACTIVE = _IOWINT('v', @as(c_int, 6));
pub const VT_GETACTIVE = _IOR('v', @as(c_int, 7), c_int);
pub const VT_GETINDEX = _IOR('v', @as(c_int, 8), c_int);
pub const VT_LOCKSWITCH = _IOW('v', @as(c_int, 9), c_int);
pub const SW_B40x25 = @compileError("unable to translate macro: undefined identifier `M_B40x25`");
// /usr/include/sys/consio.h:365:9
pub const SW_C40x25 = @compileError("unable to translate macro: undefined identifier `M_C40x25`");
// /usr/include/sys/consio.h:366:9
pub const SW_B80x25 = @compileError("unable to translate macro: undefined identifier `M_B80x25`");
// /usr/include/sys/consio.h:367:9
pub const SW_C80x25 = @compileError("unable to translate macro: undefined identifier `M_C80x25`");
// /usr/include/sys/consio.h:368:9
pub const SW_BG320 = @compileError("unable to translate macro: undefined identifier `M_BG320`");
// /usr/include/sys/consio.h:369:9
pub const SW_CG320 = @compileError("unable to translate macro: undefined identifier `M_CG320`");
// /usr/include/sys/consio.h:370:9
pub const SW_BG640 = @compileError("unable to translate macro: undefined identifier `M_BG640`");
// /usr/include/sys/consio.h:371:9
pub const SW_EGAMONO80x25 = @compileError("unable to translate macro: undefined identifier `M_EGAMONO80x25`");
// /usr/include/sys/consio.h:372:9
pub const SW_CG320_D = @compileError("unable to translate macro: undefined identifier `M_CG320_D`");
// /usr/include/sys/consio.h:373:9
pub const SW_CG640_E = @compileError("unable to translate macro: undefined identifier `M_CG640_E`");
// /usr/include/sys/consio.h:374:9
pub const SW_EGAMONOAPA = @compileError("unable to translate macro: undefined identifier `M_EGAMONOAPA`");
// /usr/include/sys/consio.h:375:9
pub const SW_CG640x350 = @compileError("unable to translate macro: undefined identifier `M_CG640x350`");
// /usr/include/sys/consio.h:376:9
pub const SW_ENH_MONOAPA2 = @compileError("unable to translate macro: undefined identifier `M_ENHMONOAPA2`");
// /usr/include/sys/consio.h:377:9
pub const SW_ENH_CG640 = @compileError("unable to translate macro: undefined identifier `M_ENH_CG640`");
// /usr/include/sys/consio.h:378:9
pub const SW_ENH_B40x25 = @compileError("unable to translate macro: undefined identifier `M_ENH_B40x25`");
// /usr/include/sys/consio.h:379:9
pub const SW_ENH_C40x25 = @compileError("unable to translate macro: undefined identifier `M_ENH_C40x25`");
// /usr/include/sys/consio.h:380:9
pub const SW_ENH_B80x25 = @compileError("unable to translate macro: undefined identifier `M_ENH_B80x25`");
// /usr/include/sys/consio.h:381:9
pub const SW_ENH_C80x25 = @compileError("unable to translate macro: undefined identifier `M_ENH_C80x25`");
// /usr/include/sys/consio.h:382:9
pub const SW_ENH_B80x43 = @compileError("unable to translate macro: undefined identifier `M_ENH_B80x43`");
// /usr/include/sys/consio.h:383:9
pub const SW_ENH_C80x43 = @compileError("unable to translate macro: undefined identifier `M_ENH_C80x43`");
// /usr/include/sys/consio.h:384:9
pub const SW_MCAMODE = @compileError("unable to translate macro: undefined identifier `M_MCA_MODE`");
// /usr/include/sys/consio.h:385:9
pub const SW_VGA_C40x25 = @compileError("unable to translate macro: undefined identifier `M_VGA_C40x25`");
// /usr/include/sys/consio.h:386:9
pub const SW_VGA_C80x25 = @compileError("unable to translate macro: undefined identifier `M_VGA_C80x25`");
// /usr/include/sys/consio.h:387:9
pub const SW_VGA_C80x30 = @compileError("unable to translate macro: undefined identifier `M_VGA_C80x30`");
// /usr/include/sys/consio.h:388:9
pub const SW_VGA_C80x50 = @compileError("unable to translate macro: undefined identifier `M_VGA_C80x50`");
// /usr/include/sys/consio.h:389:9
pub const SW_VGA_C80x60 = @compileError("unable to translate macro: undefined identifier `M_VGA_C80x60`");
// /usr/include/sys/consio.h:390:9
pub const SW_VGA_M80x25 = @compileError("unable to translate macro: undefined identifier `M_VGA_M80x25`");
// /usr/include/sys/consio.h:391:9
pub const SW_VGA_M80x30 = @compileError("unable to translate macro: undefined identifier `M_VGA_M80x30`");
// /usr/include/sys/consio.h:392:9
pub const SW_VGA_M80x50 = @compileError("unable to translate macro: undefined identifier `M_VGA_M80x50`");
// /usr/include/sys/consio.h:393:9
pub const SW_VGA_M80x60 = @compileError("unable to translate macro: undefined identifier `M_VGA_M80x60`");
// /usr/include/sys/consio.h:394:9
pub const SW_VGA11 = @compileError("unable to translate macro: undefined identifier `M_VGA11`");
// /usr/include/sys/consio.h:395:9
pub const SW_BG640x480 = @compileError("unable to translate macro: undefined identifier `M_VGA11`");
// /usr/include/sys/consio.h:396:9
pub const SW_VGA12 = @compileError("unable to translate macro: undefined identifier `M_VGA12`");
// /usr/include/sys/consio.h:397:9
pub const SW_CG640x480 = @compileError("unable to translate macro: undefined identifier `M_VGA12`");
// /usr/include/sys/consio.h:398:9
pub const SW_VGA13 = @compileError("unable to translate macro: undefined identifier `M_VGA13`");
// /usr/include/sys/consio.h:399:9
pub const SW_VGA_CG320 = @compileError("unable to translate macro: undefined identifier `M_VGA13`");
// /usr/include/sys/consio.h:400:9
pub const SW_VGA_CG640 = @compileError("unable to translate macro: undefined identifier `M_VGA_CG640`");
// /usr/include/sys/consio.h:401:9
pub const SW_VGA_MODEX = @compileError("unable to translate macro: undefined identifier `M_VGA_MODEX`");
// /usr/include/sys/consio.h:402:9
pub const SW_VGA_C90x25 = @compileError("unable to translate macro: undefined identifier `M_VGA_C90x25`");
// /usr/include/sys/consio.h:404:9
pub const SW_VGA_M90x25 = @compileError("unable to translate macro: undefined identifier `M_VGA_M90x25`");
// /usr/include/sys/consio.h:405:9
pub const SW_VGA_C90x30 = @compileError("unable to translate macro: undefined identifier `M_VGA_C90x30`");
// /usr/include/sys/consio.h:406:9
pub const SW_VGA_M90x30 = @compileError("unable to translate macro: undefined identifier `M_VGA_M90x30`");
// /usr/include/sys/consio.h:407:9
pub const SW_VGA_C90x43 = @compileError("unable to translate macro: undefined identifier `M_VGA_C90x43`");
// /usr/include/sys/consio.h:408:9
pub const SW_VGA_M90x43 = @compileError("unable to translate macro: undefined identifier `M_VGA_M90x43`");
// /usr/include/sys/consio.h:409:9
pub const SW_VGA_C90x50 = @compileError("unable to translate macro: undefined identifier `M_VGA_C90x50`");
// /usr/include/sys/consio.h:410:9
pub const SW_VGA_M90x50 = @compileError("unable to translate macro: undefined identifier `M_VGA_M90x50`");
// /usr/include/sys/consio.h:411:9
pub const SW_VGA_C90x60 = @compileError("unable to translate macro: undefined identifier `M_VGA_C90x60`");
// /usr/include/sys/consio.h:412:9
pub const SW_VGA_M90x60 = @compileError("unable to translate macro: undefined identifier `M_VGA_M90x60`");
// /usr/include/sys/consio.h:413:9
pub const SW_TEXT_80x25 = @compileError("unable to translate macro: undefined identifier `M_TEXT_80x25`");
// /usr/include/sys/consio.h:415:9
pub const SW_TEXT_80x30 = @compileError("unable to translate macro: undefined identifier `M_TEXT_80x30`");
// /usr/include/sys/consio.h:416:9
pub const SW_TEXT_80x43 = @compileError("unable to translate macro: undefined identifier `M_TEXT_80x43`");
// /usr/include/sys/consio.h:417:9
pub const SW_TEXT_80x50 = @compileError("unable to translate macro: undefined identifier `M_TEXT_80x50`");
// /usr/include/sys/consio.h:418:9
pub const SW_TEXT_80x60 = @compileError("unable to translate macro: undefined identifier `M_TEXT_80x60`");
// /usr/include/sys/consio.h:419:9
pub const SW_TEXT_132x25 = @compileError("unable to translate macro: undefined identifier `M_TEXT_132x25`");
// /usr/include/sys/consio.h:420:9
pub const SW_TEXT_132x30 = @compileError("unable to translate macro: undefined identifier `M_TEXT_132x30`");
// /usr/include/sys/consio.h:421:9
pub const SW_TEXT_132x43 = @compileError("unable to translate macro: undefined identifier `M_TEXT_132x43`");
// /usr/include/sys/consio.h:422:9
pub const SW_TEXT_132x50 = @compileError("unable to translate macro: undefined identifier `M_TEXT_132x50`");
// /usr/include/sys/consio.h:423:9
pub const SW_TEXT_132x60 = @compileError("unable to translate macro: undefined identifier `M_TEXT_132x60`");
// /usr/include/sys/consio.h:424:9
pub const SW_VESA_CG640x400 = @compileError("unable to translate macro: undefined identifier `M_VESA_CG640x400`");
// /usr/include/sys/consio.h:426:9
pub const SW_VESA_CG640x480 = @compileError("unable to translate macro: undefined identifier `M_VESA_CG640x480`");
// /usr/include/sys/consio.h:427:9
pub const SW_VESA_800x600 = @compileError("unable to translate macro: undefined identifier `M_VESA_800x600`");
// /usr/include/sys/consio.h:428:9
pub const SW_VESA_CG800x600 = @compileError("unable to translate macro: undefined identifier `M_VESA_CG800x600`");
// /usr/include/sys/consio.h:429:9
pub const SW_VESA_1024x768 = @compileError("unable to translate macro: undefined identifier `M_VESA_1024x768`");
// /usr/include/sys/consio.h:430:9
pub const SW_VESA_CG1024x768 = @compileError("unable to translate macro: undefined identifier `M_VESA_CG1024x768`");
// /usr/include/sys/consio.h:431:9
pub const SW_VESA_1280x1024 = @compileError("unable to translate macro: undefined identifier `M_VESA_1280x1024`");
// /usr/include/sys/consio.h:432:9
pub const SW_VESA_CG1280x1024 = @compileError("unable to translate macro: undefined identifier `M_VESA_CG1280x1024`");
// /usr/include/sys/consio.h:433:9
pub const SW_VESA_C80x60 = @compileError("unable to translate macro: undefined identifier `M_VESA_C80x60`");
// /usr/include/sys/consio.h:434:9
pub const SW_VESA_C132x25 = @compileError("unable to translate macro: undefined identifier `M_VESA_C132x25`");
// /usr/include/sys/consio.h:435:9
pub const SW_VESA_C132x43 = @compileError("unable to translate macro: undefined identifier `M_VESA_C132x43`");
// /usr/include/sys/consio.h:436:9
pub const SW_VESA_C132x50 = @compileError("unable to translate macro: undefined identifier `M_VESA_C132x50`");
// /usr/include/sys/consio.h:437:9
pub const SW_VESA_C132x60 = @compileError("unable to translate macro: undefined identifier `M_VESA_C132x60`");
// /usr/include/sys/consio.h:438:9
pub const SW_VESA_32K_320 = @compileError("unable to translate macro: undefined identifier `M_VESA_32K_320`");
// /usr/include/sys/consio.h:439:9
pub const SW_VESA_64K_320 = @compileError("unable to translate macro: undefined identifier `M_VESA_64K_320`");
// /usr/include/sys/consio.h:440:9
pub const SW_VESA_FULL_320 = @compileError("unable to translate macro: undefined identifier `M_VESA_FULL_320`");
// /usr/include/sys/consio.h:441:9
pub const SW_VESA_32K_640 = @compileError("unable to translate macro: undefined identifier `M_VESA_32K_640`");
// /usr/include/sys/consio.h:442:9
pub const SW_VESA_64K_640 = @compileError("unable to translate macro: undefined identifier `M_VESA_64K_640`");
// /usr/include/sys/consio.h:443:9
pub const SW_VESA_FULL_640 = @compileError("unable to translate macro: undefined identifier `M_VESA_FULL_640`");
// /usr/include/sys/consio.h:444:9
pub const SW_VESA_32K_800 = @compileError("unable to translate macro: undefined identifier `M_VESA_32K_800`");
// /usr/include/sys/consio.h:445:9
pub const SW_VESA_64K_800 = @compileError("unable to translate macro: undefined identifier `M_VESA_64K_800`");
// /usr/include/sys/consio.h:446:9
pub const SW_VESA_FULL_800 = @compileError("unable to translate macro: undefined identifier `M_VESA_FULL_800`");
// /usr/include/sys/consio.h:447:9
pub const SW_VESA_32K_1024 = @compileError("unable to translate macro: undefined identifier `M_VESA_32K_1024`");
// /usr/include/sys/consio.h:448:9
pub const SW_VESA_64K_1024 = @compileError("unable to translate macro: undefined identifier `M_VESA_64K_1024`");
// /usr/include/sys/consio.h:449:9
pub const SW_VESA_FULL_1024 = @compileError("unable to translate macro: undefined identifier `M_VESA_FULL_1024`");
// /usr/include/sys/consio.h:450:9
pub const SW_VESA_32K_1280 = @compileError("unable to translate macro: undefined identifier `M_VESA_32K_1280`");
// /usr/include/sys/consio.h:451:9
pub const SW_VESA_64K_1280 = @compileError("unable to translate macro: undefined identifier `M_VESA_64K_1280`");
// /usr/include/sys/consio.h:452:9
pub const SW_VESA_FULL_1280 = @compileError("unable to translate macro: undefined identifier `M_VESA_FULL_1280`");
// /usr/include/sys/consio.h:453:9
pub const _SYS_KBIO_H_ = "";
pub const K_RAW = @as(c_int, 0);
pub const K_XLATE = @as(c_int, 1);
pub const K_CODE = @as(c_int, 2);
pub const KDGKBMODE = _IOR('K', @as(c_int, 6), c_int);
pub const KDSKBMODE = _IOWINT('K', @as(c_int, 7));
pub const KDMKTONE = _IOWINT('K', @as(c_int, 8));
pub const CLKED = @as(c_int, 1);
pub const NLKED = @as(c_int, 2);
pub const SLKED = @as(c_int, 4);
pub const ALKED = @as(c_int, 8);
pub const LOCK_MASK = ((CLKED | NLKED) | SLKED) | ALKED;
pub const KDGKBSTATE = _IOR('K', @as(c_int, 19), c_int);
pub const KDSKBSTATE = _IOWINT('K', @as(c_int, 20));
pub const KDENABIO = _IO('K', @as(c_int, 60));
pub const KDDISABIO = _IO('K', @as(c_int, 61));
pub const KIOCSOUND = _IOWINT('K', @as(c_int, 63));
pub const KB_OTHER = @as(c_int, 0);
pub const KB_84 = @as(c_int, 1);
pub const KB_101 = @as(c_int, 2);
pub const KDGKBTYPE = _IOR('K', @as(c_int, 64), c_int);
pub const LED_CAP = @as(c_int, 1);
pub const LED_NUM = @as(c_int, 2);
pub const LED_SCR = @as(c_int, 4);
pub const LED_MASK = (LED_CAP | LED_NUM) | LED_SCR;
pub const KDGETLED = _IOR('K', @as(c_int, 65), c_int);
pub const KDSETLED = _IOWINT('K', @as(c_int, 66));
pub const KDSETRAD = _IOWINT('K', @as(c_int, 67));
pub const KBADDKBD = _IOW('K', @as(c_int, 68), keyboard_info_t);
pub const KBRELKBD = _IOW('K', @as(c_int, 69), keyboard_info_t);
pub const KDGKBINFO = _IOR('K', @as(c_int, 101), keyboard_info_t);
pub const KDSETREPEAT = _IOW('K', @as(c_int, 102), keyboard_repeat_t);
pub const KDGETREPEAT = _IOR('K', @as(c_int, 103), keyboard_repeat_t);
pub const NUM_KEYS = @as(c_int, 256);
pub const NUM_STATES = @as(c_int, 8);
pub const ALTGR_OFFSET = @as(c_int, 128);
pub const NUM_DEADKEYS = @as(c_int, 15);
pub const NUM_ACCENTCHARS = @as(c_int, 52);
pub const NUM_FKEYS = @as(c_int, 96);
pub const MAXFK = @as(c_int, 16);
pub const _KEYMAP_DECLARED = "";
pub const FLAG_LOCK_O = @as(c_int, 0);
pub const FLAG_LOCK_C = @as(c_int, 1);
pub const FLAG_LOCK_N = @as(c_int, 2);
pub const NOP = @as(c_int, 0x00);
pub const LSH = @as(c_int, 0x02);
pub const RSH = @as(c_int, 0x03);
pub const CLK = @as(c_int, 0x04);
pub const NLK = @as(c_int, 0x05);
pub const SLK = @as(c_int, 0x06);
pub const LALT = @as(c_int, 0x07);
pub const BTAB = @as(c_int, 0x08);
pub const LCTR = @as(c_int, 0x09);
pub const NEXT = @as(c_int, 0x0a);
pub const F_SCR = @as(c_int, 0x0b);
pub const L_SCR = @as(c_int, 0x1a);
pub const F_FN = @as(c_int, 0x1b);
pub const L_FN = @as(c_int, 0x7a);
pub const RCTR = @as(c_int, 0x80);
pub const RALT = @as(c_int, 0x81);
pub const ALK = @as(c_int, 0x82);
pub const ASH = @as(c_int, 0x83);
pub const META = @as(c_int, 0x84);
pub const RBT = @as(c_int, 0x85);
pub const DBG = @as(c_int, 0x86);
pub const SUSP = @as(c_int, 0x87);
pub const SPSC = @as(c_int, 0x88);
pub const F_ACC = DGRA;
pub const DGRA = @as(c_int, 0x89);
pub const DACU = @as(c_int, 0x8a);
pub const DCIR = @as(c_int, 0x8b);
pub const DTIL = @as(c_int, 0x8c);
pub const DMAC = @as(c_int, 0x8d);
pub const DBRE = @as(c_int, 0x8e);
pub const DDOT = @as(c_int, 0x8f);
pub const DUML = @as(c_int, 0x90);
pub const DDIA = @as(c_int, 0x90);
pub const DSLA = @as(c_int, 0x91);
pub const DRIN = @as(c_int, 0x92);
pub const DCED = @as(c_int, 0x93);
pub const DAPO = @as(c_int, 0x94);
pub const DDAC = @as(c_int, 0x95);
pub const DOGO = @as(c_int, 0x96);
pub const DCAR = @as(c_int, 0x97);
pub const L_ACC = DCAR;
pub const STBY = @as(c_int, 0x98);
pub const PREV = @as(c_int, 0x99);
pub const PNC = @as(c_int, 0x9a);
pub const LSHA = @as(c_int, 0x9b);
pub const RSHA = @as(c_int, 0x9c);
pub const LCTRA = @as(c_int, 0x9d);
pub const RCTRA = @as(c_int, 0x9e);
pub const LALTA = @as(c_int, 0x9f);
pub const RALTA = @as(c_int, 0xa0);
pub const HALT = @as(c_int, 0xa1);
pub const PDWN = @as(c_int, 0xa2);
pub const PASTE = @as(c_int, 0xa3);
pub inline fn F(x: anytype) @TypeOf((x + F_FN) - @as(c_int, 1)) {
    _ = &x;
    return (x + F_FN) - @as(c_int, 1);
}
pub inline fn S(x: anytype) @TypeOf((x + F_SCR) - @as(c_int, 1)) {
    _ = &x;
    return (x + F_SCR) - @as(c_int, 1);
}
pub inline fn ACC(x: anytype) @TypeOf(x + F_ACC) {
    _ = &x;
    return x + F_ACC;
}
pub const GETFKEY = _IOWR('k', @as(c_int, 0), fkeyarg_t);
pub const SETFKEY = _IOWR('k', @as(c_int, 1), fkeyarg_t);
pub const GIO_KEYMAP = _IO('k', @as(c_int, 6));
pub const PIO_KEYMAP = _IO('k', @as(c_int, 7));
pub const GIO_DEADKEYMAP = _IO('k', @as(c_int, 8));
pub const PIO_DEADKEYMAP = _IO('k', @as(c_int, 9));
pub const GIO_KEYMAPENT = _IOWR('k', @as(c_int, 10), keyarg_t);
pub const PIO_KEYMAPENT = _IOW('k', @as(c_int, 11), keyarg_t);
pub const NOKEY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x01000000, .hex);
pub const FKEY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x02000000, .hex);
pub const MKEY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x04000000, .hex);
pub const BKEY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x08000000, .hex);
pub const SPCLKEY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hex);
pub const RELKEY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x40000000, .hex);
pub const ERRKEY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x20000000, .hex);
pub inline fn KEYCHAR(c: anytype) @TypeOf(c & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00ffffff, .hex)) {
    _ = &c;
    return c & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00ffffff, .hex);
}
pub inline fn KEYFLAGS(c: anytype) @TypeOf(c & ~@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00ffffff, .hex)) {
    _ = &c;
    return c & ~@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00ffffff, .hex);
}
pub const _SYS_FCNTL_H_ = "";
pub const O_RDONLY = @as(c_int, 0x0000);
pub const O_WRONLY = @as(c_int, 0x0001);
pub const O_RDWR = @as(c_int, 0x0002);
pub const O_ACCMODE = @as(c_int, 0x0003);
pub const FREAD = @as(c_int, 0x0001);
pub const FWRITE = @as(c_int, 0x0002);
pub const O_NONBLOCK = @as(c_int, 0x0004);
pub const O_APPEND = @as(c_int, 0x0008);
pub const O_SHLOCK = @as(c_int, 0x0010);
pub const O_EXLOCK = @as(c_int, 0x0020);
pub const O_ASYNC = @as(c_int, 0x0040);
pub const O_FSYNC = @as(c_int, 0x0080);
pub const O_SYNC = @as(c_int, 0x0080);
pub const O_NOFOLLOW = @as(c_int, 0x0100);
pub const O_CREAT = @as(c_int, 0x0200);
pub const O_TRUNC = @as(c_int, 0x0400);
pub const O_EXCL = @as(c_int, 0x0800);
pub const O_NOCTTY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hex);
pub const O_DIRECT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00010000, .hex);
pub const O_DIRECTORY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00020000, .hex);
pub const O_EXEC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00040000, .hex);
pub const O_SEARCH = O_EXEC;
pub const O_TTY_INIT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hex);
pub const O_CLOEXEC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00100000, .hex);
pub const O_VERIFY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00200000, .hex);
pub const O_PATH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00400000, .hex);
pub const O_RESOLVE_BENEATH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00800000, .hex);
pub const O_DSYNC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x01000000, .hex);
pub const O_EMPTY_PATH = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x02000000, .hex);
pub const O_NAMEDATTR = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x04000000, .hex);
pub const O_XATTR = O_NAMEDATTR;
pub const O_CLOFORK = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x08000000, .hex);
pub const FAPPEND = O_APPEND;
pub const FASYNC = O_ASYNC;
pub const FFSYNC = O_FSYNC;
pub const FDSYNC = O_DSYNC;
pub const FNONBLOCK = O_NONBLOCK;
pub const FNDELAY = O_NONBLOCK;
pub const O_NDELAY = O_NONBLOCK;
pub const FRDAHEAD = O_CREAT;
pub const AT_FDCWD = -@as(c_int, 100);
pub const AT_EACCESS = @as(c_int, 0x0100);
pub const AT_SYMLINK_NOFOLLOW = @as(c_int, 0x0200);
pub const AT_SYMLINK_FOLLOW = @as(c_int, 0x0400);
pub const AT_REMOVEDIR = @as(c_int, 0x0800);
pub const AT_RESOLVE_BENEATH = @as(c_int, 0x2000);
pub const AT_EMPTY_PATH = @as(c_int, 0x4000);
pub const F_DUPFD = @as(c_int, 0);
pub const F_GETFD = @as(c_int, 1);
pub const F_SETFD = @as(c_int, 2);
pub const F_GETFL = @as(c_int, 3);
pub const F_SETFL = @as(c_int, 4);
pub const F_GETOWN = @as(c_int, 5);
pub const F_SETOWN = @as(c_int, 6);
pub const F_OGETLK = @as(c_int, 7);
pub const F_OSETLK = @as(c_int, 8);
pub const F_OSETLKW = @as(c_int, 9);
pub const F_DUP2FD = @as(c_int, 10);
pub const F_GETLK = @as(c_int, 11);
pub const F_SETLK = @as(c_int, 12);
pub const F_SETLKW = @as(c_int, 13);
pub const F_SETLK_REMOTE = @as(c_int, 14);
pub const F_READAHEAD = @as(c_int, 15);
pub const F_RDAHEAD = @as(c_int, 16);
pub const F_DUPFD_CLOEXEC = @as(c_int, 17);
pub const F_DUP2FD_CLOEXEC = @as(c_int, 18);
pub const F_ADD_SEALS = @as(c_int, 19);
pub const F_GET_SEALS = @as(c_int, 20);
pub const F_ISUNIONSTACK = @as(c_int, 21);
pub const F_KINFO = @as(c_int, 22);
pub const F_DUPFD_CLOFORK = @as(c_int, 23);
pub const F_DUP3FD = @as(c_int, 24);
pub const F_DUP3FD_SHIFT = @as(c_int, 16);
pub const F_SEAL_SEAL = @as(c_int, 0x0001);
pub const F_SEAL_SHRINK = @as(c_int, 0x0002);
pub const F_SEAL_GROW = @as(c_int, 0x0004);
pub const F_SEAL_WRITE = @as(c_int, 0x0008);
pub const FD_CLOEXEC = @as(c_int, 1);
pub const FD_RESOLVE_BENEATH = @as(c_int, 2);
pub const FD_CLOFORK = @as(c_int, 4);
pub const F_RDLCK = @as(c_int, 1);
pub const F_UNLCK = @as(c_int, 2);
pub const F_WRLCK = @as(c_int, 3);
pub const F_UNLCKSYS = @as(c_int, 4);
pub const F_CANCEL = @as(c_int, 5);
pub const LOCK_SH = @as(c_int, 0x01);
pub const LOCK_EX = @as(c_int, 0x02);
pub const LOCK_NB = @as(c_int, 0x04);
pub const LOCK_UN = @as(c_int, 0x08);
pub const POSIX_FADV_NORMAL = @as(c_int, 0);
pub const POSIX_FADV_RANDOM = @as(c_int, 1);
pub const POSIX_FADV_SEQUENTIAL = @as(c_int, 2);
pub const POSIX_FADV_WILLNEED = @as(c_int, 3);
pub const POSIX_FADV_DONTNEED = @as(c_int, 4);
pub const POSIX_FADV_NOREUSE = @as(c_int, 5);
pub const FD_NONE = -@as(c_int, 200);
pub const SPACECTL_DEALLOC = @as(c_int, 1);
pub const SPACECTL_F_SUPPORTED = @as(c_int, 0);
pub const _DIRENT_H_ = "";
pub const _SYS_DIRENT_H_ = "";
pub const MAXNAMLEN = @as(c_int, 255);
pub const DT_UNKNOWN = @as(c_int, 0);
pub const DT_FIFO = @as(c_int, 1);
pub const DT_CHR = @as(c_int, 2);
pub const DT_DIR = @as(c_int, 4);
pub const DT_BLK = @as(c_int, 6);
pub const DT_REG = @as(c_int, 8);
pub const DT_LNK = @as(c_int, 10);
pub const DT_SOCK = @as(c_int, 12);
pub const DT_WHT = @as(c_int, 14);
pub inline fn IFTODT(mode: anytype) @TypeOf((mode & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0o170000, .octal)) >> @as(c_int, 12)) {
    _ = &mode;
    return (mode & @import("std").zig.c_translation.promoteIntLiteral(c_int, 0o170000, .octal)) >> @as(c_int, 12);
}
pub inline fn DTTOIF(dirtype: anytype) @TypeOf(dirtype << @as(c_int, 12)) {
    _ = &dirtype;
    return dirtype << @as(c_int, 12);
}
pub const _GENERIC_DIRLEN = @compileError("unable to translate macro: undefined identifier `d_name`");
// /usr/include/sys/dirent.h:119:9
pub inline fn _GENERIC_DIRSIZ(dp: anytype) @TypeOf(_GENERIC_DIRLEN(dp.*.d_namlen)) {
    _ = &dp;
    return _GENERIC_DIRLEN(dp.*.d_namlen);
}
pub const _GENERIC_MINDIRSIZ = _GENERIC_DIRLEN(@as(c_int, 1));
pub const _GENERIC_MAXDIRSIZ = _GENERIC_DIRLEN(MAXNAMLEN);
pub const d_ino = @compileError("unable to translate macro: undefined identifier `d_fileno`");
// /usr/include/dirent.h:73:9
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const DIRBLKSIZ = @as(c_int, 1024);
pub const DTF_HIDEW = @as(c_int, 0x0001);
pub const DTF_NODUP = @as(c_int, 0x0002);
pub const DTF_REWIND = @as(c_int, 0x0004);
pub const __DTF_READALL = @as(c_int, 0x0008);
pub const __DTF_SKIPREAD = @as(c_int, 0x0010);
pub const _UNISTD_H_ = "";
pub const _SYS_UNISTD_H_ = "";
pub const _POSIX_ADVISORY_INFO = @as(c_long, 200112);
pub const _POSIX_ASYNCHRONOUS_IO = @as(c_long, 200112);
pub const _POSIX_CHOWN_RESTRICTED = @as(c_int, 1);
pub const _POSIX_CLOCK_SELECTION = -@as(c_int, 1);
pub const _POSIX_CPUTIME = @as(c_long, 200112);
pub const _POSIX_FSYNC = @as(c_long, 200112);
pub const _POSIX_IPV6 = @as(c_int, 0);
pub const _POSIX_JOB_CONTROL = @as(c_int, 1);
pub const _POSIX_MAPPED_FILES = @as(c_long, 200112);
pub const _POSIX_MEMLOCK = -@as(c_int, 1);
pub const _POSIX_MEMLOCK_RANGE = @as(c_long, 200112);
pub const _POSIX_MEMORY_PROTECTION = @as(c_long, 200112);
pub const _POSIX_MESSAGE_PASSING = @as(c_long, 200112);
pub const _POSIX_MONOTONIC_CLOCK = @as(c_long, 200112);
pub const _POSIX_NO_TRUNC = @as(c_int, 1);
pub const _POSIX_PRIORITIZED_IO = -@as(c_int, 1);
pub const _POSIX_PRIORITY_SCHEDULING = @as(c_int, 0);
pub const _POSIX_RAW_SOCKETS = @as(c_long, 200112);
pub const _POSIX_REALTIME_SIGNALS = @as(c_long, 200112);
pub const _POSIX_SEMAPHORES = @as(c_long, 200112);
pub const _POSIX_SHARED_MEMORY_OBJECTS = @as(c_long, 200112);
pub const _POSIX_SPORADIC_SERVER = -@as(c_int, 1);
pub const _POSIX_SYNCHRONIZED_IO = -@as(c_int, 1);
pub const _POSIX_TIMEOUTS = @as(c_long, 200112);
pub const _POSIX_TIMERS = @as(c_long, 200112);
pub const _POSIX_TYPED_MEMORY_OBJECTS = -@as(c_int, 1);
pub const _XOPEN_SHM = @as(c_int, 1);
pub const _XOPEN_STREAMS = -@as(c_int, 1);
pub const _POSIX_VERSION = @as(c_long, 200809);
pub const F_OK = @as(c_int, 0);
pub const X_OK = @as(c_int, 0x01);
pub const W_OK = @as(c_int, 0x02);
pub const R_OK = @as(c_int, 0x04);
pub const SEEK_SET = @as(c_int, 0);
pub const SEEK_CUR = @as(c_int, 1);
pub const SEEK_END = @as(c_int, 2);
pub const SEEK_DATA = @as(c_int, 3);
pub const SEEK_HOLE = @as(c_int, 4);
pub const L_SET = SEEK_SET;
pub const L_INCR = SEEK_CUR;
pub const L_XTND = SEEK_END;
pub const _PC_LINK_MAX = @as(c_int, 1);
pub const _PC_MAX_CANON = @as(c_int, 2);
pub const _PC_MAX_INPUT = @as(c_int, 3);
pub const _PC_NAME_MAX = @as(c_int, 4);
pub const _PC_PATH_MAX = @as(c_int, 5);
pub const _PC_PIPE_BUF = @as(c_int, 6);
pub const _PC_CHOWN_RESTRICTED = @as(c_int, 7);
pub const _PC_NO_TRUNC = @as(c_int, 8);
pub const _PC_VDISABLE = @as(c_int, 9);
pub const _PC_ASYNC_IO = @as(c_int, 53);
pub const _PC_PRIO_IO = @as(c_int, 54);
pub const _PC_SYNC_IO = @as(c_int, 55);
pub const _PC_ALLOC_SIZE_MIN = @as(c_int, 10);
pub const _PC_FILESIZEBITS = @as(c_int, 12);
pub const _PC_REC_INCR_XFER_SIZE = @as(c_int, 14);
pub const _PC_REC_MAX_XFER_SIZE = @as(c_int, 15);
pub const _PC_REC_MIN_XFER_SIZE = @as(c_int, 16);
pub const _PC_REC_XFER_ALIGN = @as(c_int, 17);
pub const _PC_SYMLINK_MAX = @as(c_int, 18);
pub const _PC_ACL_EXTENDED = @as(c_int, 59);
pub const _PC_ACL_PATH_MAX = @as(c_int, 60);
pub const _PC_CAP_PRESENT = @as(c_int, 61);
pub const _PC_INF_PRESENT = @as(c_int, 62);
pub const _PC_MAC_PRESENT = @as(c_int, 63);
pub const _PC_ACL_NFS4 = @as(c_int, 64);
pub const _PC_DEALLOC_PRESENT = @as(c_int, 65);
pub const _PC_NAMEDATTR_ENABLED = @as(c_int, 66);
pub const _PC_HAS_NAMEDATTR = @as(c_int, 67);
pub const _PC_XATTR_ENABLED = _PC_NAMEDATTR_ENABLED;
pub const _PC_XATTR_EXISTS = _PC_HAS_NAMEDATTR;
pub const _PC_HAS_HIDDENSYSTEM = @as(c_int, 68);
pub const _PC_CLONE_BLKSIZE = @as(c_int, 69);
pub const _PC_MIN_HOLE_SIZE = @as(c_int, 21);
pub const RFNAMEG = @as(c_int, 1) << @as(c_int, 0);
pub const RFENVG = @as(c_int, 1) << @as(c_int, 1);
pub const RFFDG = @as(c_int, 1) << @as(c_int, 2);
pub const RFNOTEG = @as(c_int, 1) << @as(c_int, 3);
pub const RFPROC = @as(c_int, 1) << @as(c_int, 4);
pub const RFMEM = @as(c_int, 1) << @as(c_int, 5);
pub const RFNOWAIT = @as(c_int, 1) << @as(c_int, 6);
pub const RFCNAMEG = @as(c_int, 1) << @as(c_int, 10);
pub const RFCENVG = @as(c_int, 1) << @as(c_int, 11);
pub const RFCFDG = @as(c_int, 1) << @as(c_int, 12);
pub const RFTHREAD = @as(c_int, 1) << @as(c_int, 13);
pub const RFSIGSHARE = @as(c_int, 1) << @as(c_int, 14);
pub const RFLINUXTHPN = @as(c_int, 1) << @as(c_int, 16);
pub const RFSTOPPED = @as(c_int, 1) << @as(c_int, 17);
pub const RFHIGHPID = @as(c_int, 1) << @as(c_int, 18);
pub const RFTSIGZMB = @as(c_int, 1) << @as(c_int, 19);
pub const RFTSIGSHIFT = @as(c_int, 20);
pub const RFTSIGMASK = @as(c_int, 0xFF);
pub inline fn RFTSIGNUM(flags: anytype) @TypeOf((flags >> RFTSIGSHIFT) & RFTSIGMASK) {
    _ = &flags;
    return (flags >> RFTSIGSHIFT) & RFTSIGMASK;
}
pub inline fn RFTSIGFLAGS(signum: anytype) @TypeOf(signum << RFTSIGSHIFT) {
    _ = &signum;
    return signum << RFTSIGSHIFT;
}
pub const RFPROCDESC = @as(c_int, 1) << @as(c_int, 28);
pub const RFPPWAIT = @as(c_int, 1) << @as(c_int, 31);
pub const RFSPAWN = @as(c_uint, 1) << @as(c_int, 31);
pub const RFFLAGS = ((((((((((((RFFDG | RFPROC) | RFMEM) | RFNOWAIT) | RFCFDG) | RFTHREAD) | RFSIGSHARE) | RFLINUXTHPN) | RFSTOPPED) | RFHIGHPID) | RFTSIGZMB) | RFPROCDESC) | RFSPAWN) | RFPPWAIT;
pub const RFKERNELONLY = (RFSTOPPED | RFHIGHPID) | RFPROCDESC;
pub const KCMP_FILE = @as(c_int, 100);
pub const KCMP_FILEOBJ = @as(c_int, 101);
pub const KCMP_FILES = @as(c_int, 102);
pub const KCMP_SIGHAND = @as(c_int, 103);
pub const KCMP_VM = @as(c_int, 104);
pub const SWAPOFF_FORCE = @as(c_int, 0x00000001);
pub const CLOSE_RANGE_CLOEXEC = @as(c_int, 1) << @as(c_int, 2);
pub const CLOSE_RANGE_CLOFORK = @as(c_int, 1) << @as(c_int, 3);
pub const COPY_FILE_RANGE_CLONE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00800000, .hex);
pub const COPY_FILE_RANGE_USERFLAGS = COPY_FILE_RANGE_CLONE;
pub const STDIN_FILENO = @as(c_int, 0);
pub const STDOUT_FILENO = @as(c_int, 1);
pub const STDERR_FILENO = @as(c_int, 2);
pub const F_ULOCK = @as(c_int, 0);
pub const F_LOCK = @as(c_int, 1);
pub const F_TLOCK = @as(c_int, 2);
pub const F_TEST = @as(c_int, 3);
pub const _POSIX_BARRIERS = @as(c_long, 200112);
pub const _POSIX_READER_WRITER_LOCKS = @as(c_long, 200112);
pub const _POSIX_REGEXP = @as(c_int, 1);
pub const _POSIX_SHELL = @as(c_int, 1);
pub const _POSIX_SPAWN = @as(c_long, 200112);
pub const _POSIX_SPIN_LOCKS = @as(c_long, 200112);
pub const _POSIX_THREAD_ATTR_STACKADDR = @as(c_long, 200112);
pub const _POSIX_THREAD_ATTR_STACKSIZE = @as(c_long, 200112);
pub const _POSIX_THREAD_CPUTIME = @as(c_long, 200112);
pub const _POSIX_THREAD_PRIO_INHERIT = @as(c_long, 200112);
pub const _POSIX_THREAD_PRIO_PROTECT = @as(c_long, 200112);
pub const _POSIX_THREAD_PRIORITY_SCHEDULING = @as(c_long, 200112);
pub const _POSIX_THREAD_PROCESS_SHARED = @as(c_long, 200112);
pub const _POSIX_THREAD_SAFE_FUNCTIONS = -@as(c_int, 1);
pub const _POSIX_THREAD_SPORADIC_SERVER = -@as(c_int, 1);
pub const _POSIX_THREADS = @as(c_long, 200112);
pub const _POSIX_TRACE = -@as(c_int, 1);
pub const _POSIX_TRACE_EVENT_FILTER = -@as(c_int, 1);
pub const _POSIX_TRACE_INHERIT = -@as(c_int, 1);
pub const _POSIX_TRACE_LOG = -@as(c_int, 1);
pub const _POSIX2_C_BIND = @as(c_long, 200112);
pub const _POSIX2_C_DEV = -@as(c_int, 1);
pub const _POSIX2_CHAR_TERM = @as(c_int, 1);
pub const _POSIX2_FORT_DEV = -@as(c_int, 1);
pub const _POSIX2_FORT_RUN = @as(c_long, 200112);
pub const _POSIX2_LOCALEDEF = -@as(c_int, 1);
pub const _POSIX2_PBS = -@as(c_int, 1);
pub const _POSIX2_PBS_ACCOUNTING = -@as(c_int, 1);
pub const _POSIX2_PBS_CHECKPOINT = -@as(c_int, 1);
pub const _POSIX2_PBS_LOCATE = -@as(c_int, 1);
pub const _POSIX2_PBS_MESSAGE = -@as(c_int, 1);
pub const _POSIX2_PBS_TRACK = -@as(c_int, 1);
pub const _POSIX2_SW_DEV = -@as(c_int, 1);
pub const _POSIX2_UPE = @as(c_long, 200112);
pub const _V6_ILP32_OFF32 = -@as(c_int, 1);
pub const _V6_ILP32_OFFBIG = @as(c_int, 0);
pub const _V6_LP64_OFF64 = @as(c_int, 0);
pub const _V6_LPBIG_OFFBIG = -@as(c_int, 1);
pub const _XOPEN_CRYPT = -@as(c_int, 1);
pub const _XOPEN_ENH_I18N = -@as(c_int, 1);
pub const _XOPEN_LEGACY = -@as(c_int, 1);
pub const _XOPEN_REALTIME = -@as(c_int, 1);
pub const _XOPEN_REALTIME_THREADS = -@as(c_int, 1);
pub const _XOPEN_UNIX = -@as(c_int, 1);
pub const _POSIX2_VERSION = @as(c_long, 199212);
pub const _SC_ARG_MAX = @as(c_int, 1);
pub const _SC_CHILD_MAX = @as(c_int, 2);
pub const _SC_CLK_TCK = @as(c_int, 3);
pub const _SC_NGROUPS_MAX = @as(c_int, 4);
pub const _SC_OPEN_MAX = @as(c_int, 5);
pub const _SC_JOB_CONTROL = @as(c_int, 6);
pub const _SC_SAVED_IDS = @as(c_int, 7);
pub const _SC_VERSION = @as(c_int, 8);
pub const _SC_BC_BASE_MAX = @as(c_int, 9);
pub const _SC_BC_DIM_MAX = @as(c_int, 10);
pub const _SC_BC_SCALE_MAX = @as(c_int, 11);
pub const _SC_BC_STRING_MAX = @as(c_int, 12);
pub const _SC_COLL_WEIGHTS_MAX = @as(c_int, 13);
pub const _SC_EXPR_NEST_MAX = @as(c_int, 14);
pub const _SC_LINE_MAX = @as(c_int, 15);
pub const _SC_RE_DUP_MAX = @as(c_int, 16);
pub const _SC_2_VERSION = @as(c_int, 17);
pub const _SC_2_C_BIND = @as(c_int, 18);
pub const _SC_2_C_DEV = @as(c_int, 19);
pub const _SC_2_CHAR_TERM = @as(c_int, 20);
pub const _SC_2_FORT_DEV = @as(c_int, 21);
pub const _SC_2_FORT_RUN = @as(c_int, 22);
pub const _SC_2_LOCALEDEF = @as(c_int, 23);
pub const _SC_2_SW_DEV = @as(c_int, 24);
pub const _SC_2_UPE = @as(c_int, 25);
pub const _SC_STREAM_MAX = @as(c_int, 26);
pub const _SC_TZNAME_MAX = @as(c_int, 27);
pub const _SC_ASYNCHRONOUS_IO = @as(c_int, 28);
pub const _SC_MAPPED_FILES = @as(c_int, 29);
pub const _SC_MEMLOCK = @as(c_int, 30);
pub const _SC_MEMLOCK_RANGE = @as(c_int, 31);
pub const _SC_MEMORY_PROTECTION = @as(c_int, 32);
pub const _SC_MESSAGE_PASSING = @as(c_int, 33);
pub const _SC_PRIORITIZED_IO = @as(c_int, 34);
pub const _SC_PRIORITY_SCHEDULING = @as(c_int, 35);
pub const _SC_REALTIME_SIGNALS = @as(c_int, 36);
pub const _SC_SEMAPHORES = @as(c_int, 37);
pub const _SC_FSYNC = @as(c_int, 38);
pub const _SC_SHARED_MEMORY_OBJECTS = @as(c_int, 39);
pub const _SC_SYNCHRONIZED_IO = @as(c_int, 40);
pub const _SC_TIMERS = @as(c_int, 41);
pub const _SC_AIO_LISTIO_MAX = @as(c_int, 42);
pub const _SC_AIO_MAX = @as(c_int, 43);
pub const _SC_AIO_PRIO_DELTA_MAX = @as(c_int, 44);
pub const _SC_DELAYTIMER_MAX = @as(c_int, 45);
pub const _SC_MQ_OPEN_MAX = @as(c_int, 46);
pub const _SC_PAGESIZE = @as(c_int, 47);
pub const _SC_RTSIG_MAX = @as(c_int, 48);
pub const _SC_SEM_NSEMS_MAX = @as(c_int, 49);
pub const _SC_SEM_VALUE_MAX = @as(c_int, 50);
pub const _SC_SIGQUEUE_MAX = @as(c_int, 51);
pub const _SC_TIMER_MAX = @as(c_int, 52);
pub const _SC_2_PBS = @as(c_int, 59);
pub const _SC_2_PBS_ACCOUNTING = @as(c_int, 60);
pub const _SC_2_PBS_CHECKPOINT = @as(c_int, 61);
pub const _SC_2_PBS_LOCATE = @as(c_int, 62);
pub const _SC_2_PBS_MESSAGE = @as(c_int, 63);
pub const _SC_2_PBS_TRACK = @as(c_int, 64);
pub const _SC_ADVISORY_INFO = @as(c_int, 65);
pub const _SC_BARRIERS = @as(c_int, 66);
pub const _SC_CLOCK_SELECTION = @as(c_int, 67);
pub const _SC_CPUTIME = @as(c_int, 68);
pub const _SC_FILE_LOCKING = @as(c_int, 69);
pub const _SC_GETGR_R_SIZE_MAX = @as(c_int, 70);
pub const _SC_GETPW_R_SIZE_MAX = @as(c_int, 71);
pub const _SC_HOST_NAME_MAX = @as(c_int, 72);
pub const _SC_LOGIN_NAME_MAX = @as(c_int, 73);
pub const _SC_MONOTONIC_CLOCK = @as(c_int, 74);
pub const _SC_MQ_PRIO_MAX = @as(c_int, 75);
pub const _SC_READER_WRITER_LOCKS = @as(c_int, 76);
pub const _SC_REGEXP = @as(c_int, 77);
pub const _SC_SHELL = @as(c_int, 78);
pub const _SC_SPAWN = @as(c_int, 79);
pub const _SC_SPIN_LOCKS = @as(c_int, 80);
pub const _SC_SPORADIC_SERVER = @as(c_int, 81);
pub const _SC_THREAD_ATTR_STACKADDR = @as(c_int, 82);
pub const _SC_THREAD_ATTR_STACKSIZE = @as(c_int, 83);
pub const _SC_THREAD_CPUTIME = @as(c_int, 84);
pub const _SC_THREAD_DESTRUCTOR_ITERATIONS = @as(c_int, 85);
pub const _SC_THREAD_KEYS_MAX = @as(c_int, 86);
pub const _SC_THREAD_PRIO_INHERIT = @as(c_int, 87);
pub const _SC_THREAD_PRIO_PROTECT = @as(c_int, 88);
pub const _SC_THREAD_PRIORITY_SCHEDULING = @as(c_int, 89);
pub const _SC_THREAD_PROCESS_SHARED = @as(c_int, 90);
pub const _SC_THREAD_SAFE_FUNCTIONS = @as(c_int, 91);
pub const _SC_THREAD_SPORADIC_SERVER = @as(c_int, 92);
pub const _SC_THREAD_STACK_MIN = @as(c_int, 93);
pub const _SC_THREAD_THREADS_MAX = @as(c_int, 94);
pub const _SC_TIMEOUTS = @as(c_int, 95);
pub const _SC_THREADS = @as(c_int, 96);
pub const _SC_TRACE = @as(c_int, 97);
pub const _SC_TRACE_EVENT_FILTER = @as(c_int, 98);
pub const _SC_TRACE_INHERIT = @as(c_int, 99);
pub const _SC_TRACE_LOG = @as(c_int, 100);
pub const _SC_TTY_NAME_MAX = @as(c_int, 101);
pub const _SC_TYPED_MEMORY_OBJECTS = @as(c_int, 102);
pub const _SC_V6_ILP32_OFF32 = @as(c_int, 103);
pub const _SC_V6_ILP32_OFFBIG = @as(c_int, 104);
pub const _SC_V6_LP64_OFF64 = @as(c_int, 105);
pub const _SC_V6_LPBIG_OFFBIG = @as(c_int, 106);
pub const _SC_IPV6 = @as(c_int, 118);
pub const _SC_RAW_SOCKETS = @as(c_int, 119);
pub const _SC_SYMLOOP_MAX = @as(c_int, 120);
pub const _SC_ATEXIT_MAX = @as(c_int, 107);
pub const _SC_IOV_MAX = @as(c_int, 56);
pub const _SC_PAGE_SIZE = _SC_PAGESIZE;
pub const _SC_XOPEN_CRYPT = @as(c_int, 108);
pub const _SC_XOPEN_ENH_I18N = @as(c_int, 109);
pub const _SC_XOPEN_LEGACY = @as(c_int, 110);
pub const _SC_XOPEN_REALTIME = @as(c_int, 111);
pub const _SC_XOPEN_REALTIME_THREADS = @as(c_int, 112);
pub const _SC_XOPEN_SHM = @as(c_int, 113);
pub const _SC_XOPEN_STREAMS = @as(c_int, 114);
pub const _SC_XOPEN_UNIX = @as(c_int, 115);
pub const _SC_XOPEN_VERSION = @as(c_int, 116);
pub const _SC_XOPEN_XCU_VERSION = @as(c_int, 117);
pub const _SC_NPROCESSORS_CONF = @as(c_int, 57);
pub const _SC_NPROCESSORS_ONLN = @as(c_int, 58);
pub const _SC_CPUSET_SIZE = @as(c_int, 122);
pub const _SC_UEXTERR_MAXLEN = @as(c_int, 123);
pub const _SC_NSIG = @as(c_int, 124);
pub const _SC_PHYS_PAGES = @as(c_int, 121);
pub const _CS_PATH = @as(c_int, 1);
pub const _CS_POSIX_V6_ILP32_OFF32_CFLAGS = @as(c_int, 2);
pub const _CS_POSIX_V6_ILP32_OFF32_LDFLAGS = @as(c_int, 3);
pub const _CS_POSIX_V6_ILP32_OFF32_LIBS = @as(c_int, 4);
pub const _CS_POSIX_V6_ILP32_OFFBIG_CFLAGS = @as(c_int, 5);
pub const _CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS = @as(c_int, 6);
pub const _CS_POSIX_V6_ILP32_OFFBIG_LIBS = @as(c_int, 7);
pub const _CS_POSIX_V6_LP64_OFF64_CFLAGS = @as(c_int, 8);
pub const _CS_POSIX_V6_LP64_OFF64_LDFLAGS = @as(c_int, 9);
pub const _CS_POSIX_V6_LP64_OFF64_LIBS = @as(c_int, 10);
pub const _CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS = @as(c_int, 11);
pub const _CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS = @as(c_int, 12);
pub const _CS_POSIX_V6_LPBIG_OFFBIG_LIBS = @as(c_int, 13);
pub const _CS_POSIX_V6_WIDTH_RESTRICTED_ENVS = @as(c_int, 14);
pub const _GETOPT_DECLARED = "";
pub const _SWAB_DECLARED = "";
pub const _MKDTEMP_DECLARED = "";
pub const _MKNOD_DECLARED = "";
pub const _MKSTEMP_DECLARED = "";
pub const _MKTEMP_DECLARED = "";
pub const _OPTRESET_DECLARED = "";
pub const LIBINPUT_H = "";
pub const _STDLIB_H_ = "";
pub const _WCHAR_T_DECLARED = "";
pub const EXIT_FAILURE = @as(c_int, 1);
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const RAND_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hex);
pub const MB_CUR_MAX = @import("std").zig.c_translation.cast(usize, ___mb_cur_max());
pub const alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`");
// /usr/include/stdlib.h:255:9
pub const _RSIZE_T_DEFINED = "";
pub const _ERRNO_T_DEFINED = "";
pub const __CLANG_STDINT_H = "";
pub const _SYS_STDINT_H_ = "";
pub const _MACHINE__STDINT_H_ = "";
pub inline fn INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const INT64_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const UINT64_C = @import("std").zig.c_translation.Macros.UL_SUFFIX;
pub inline fn INTMAX_C(c: anytype) @TypeOf(INT64_C(c)) {
    _ = &c;
    return INT64_C(c);
}
pub inline fn UINTMAX_C(c: anytype) @TypeOf(UINT64_C(c)) {
    _ = &c;
    return UINT64_C(c);
}
pub const INT8_MIN = -@as(c_int, 0x7f) - @as(c_int, 1);
pub const INT16_MIN = -@as(c_int, 0x7fff) - @as(c_int, 1);
pub const INT32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hex) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 0x7f);
pub const INT16_MAX = @as(c_int, 0x7fff);
pub const INT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hex);
pub const UINT8_MAX = @as(c_int, 0xff);
pub const UINT16_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffff, .hex);
pub const UINT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hex);
pub const INT64_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffffffffffff, .hex) - @as(c_int, 1);
pub const INT64_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffffffffffff, .hex);
pub const UINT64_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffffffffffff, .hex);
pub const INT_LEAST8_MIN = INT8_MIN;
pub const INT_LEAST16_MIN = INT16_MIN;
pub const INT_LEAST32_MIN = INT32_MIN;
pub const INT_LEAST64_MIN = INT64_MIN;
pub const INT_LEAST8_MAX = INT8_MAX;
pub const INT_LEAST16_MAX = INT16_MAX;
pub const INT_LEAST32_MAX = INT32_MAX;
pub const INT_LEAST64_MAX = INT64_MAX;
pub const UINT_LEAST8_MAX = UINT8_MAX;
pub const UINT_LEAST16_MAX = UINT16_MAX;
pub const UINT_LEAST32_MAX = UINT32_MAX;
pub const UINT_LEAST64_MAX = UINT64_MAX;
pub const INT_FAST8_MIN = INT32_MIN;
pub const INT_FAST16_MIN = INT32_MIN;
pub const INT_FAST32_MIN = INT32_MIN;
pub const INT_FAST64_MIN = INT64_MIN;
pub const INT_FAST8_MAX = INT32_MAX;
pub const INT_FAST16_MAX = INT32_MAX;
pub const INT_FAST32_MAX = INT32_MAX;
pub const INT_FAST64_MAX = INT64_MAX;
pub const UINT_FAST8_MAX = UINT32_MAX;
pub const UINT_FAST16_MAX = UINT32_MAX;
pub const UINT_FAST32_MAX = UINT32_MAX;
pub const UINT_FAST64_MAX = UINT64_MAX;
pub const INTPTR_MIN = INT64_MIN;
pub const INTPTR_MAX = INT64_MAX;
pub const UINTPTR_MAX = UINT64_MAX;
pub const INTMAX_MIN = INT64_MIN;
pub const INTMAX_MAX = INT64_MAX;
pub const UINTMAX_MAX = UINT64_MAX;
pub const PTRDIFF_MIN = INT64_MIN;
pub const PTRDIFF_MAX = INT64_MAX;
pub const SIG_ATOMIC_MIN = INT64_MIN;
pub const SIG_ATOMIC_MAX = INT64_MAX;
pub const SIZE_MAX = UINT64_MAX;
pub const WINT_MIN = INT32_MIN;
pub const WINT_MAX = INT32_MAX;
pub const __WORDSIZE = @as(c_int, 64);
pub const WCHAR_MIN = __WCHAR_MIN;
pub const WCHAR_MAX = __WCHAR_MAX;
pub const RSIZE_MAX = SIZE_MAX >> @as(c_int, 1);
pub const __need___va_list = "";
pub const __need_va_list = "";
pub const __need_va_arg = "";
pub const __need___va_copy = "";
pub const __need_va_copy = "";
pub const __STDARG_H = "";
pub const _VA_LIST = "";
pub const va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`");
// /usr/local/lib/zig/include/__stdarg_va_arg.h:17:9
pub const va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`");
// /usr/local/lib/zig/include/__stdarg_va_arg.h:19:9
pub const va_arg = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// /usr/local/lib/zig/include/__stdarg_va_arg.h:20:9
pub const __va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// /usr/local/lib/zig/include/__stdarg___va_copy.h:11:9
pub const va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// /usr/local/lib/zig/include/__stdarg_va_copy.h:11:9
pub const LIBUDEV_H_ = "";
pub const udev_list_entry_foreach = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/local/include/libudev.h:136:9
pub const LIBINPUT_ATTRIBUTE_PRINTF = @compileError("unable to translate macro: undefined identifier `format`");
// /usr/local/include/libinput.h:37:9
pub const LIBINPUT_ATTRIBUTE_DEPRECATED = @compileError("unable to translate macro: undefined identifier `deprecated`");
// /usr/local/include/libinput.h:39:9
pub const __timer = struct___timer;
pub const __mq = struct___mq;
pub const fiodgname_arg = struct_fiodgname_arg;
pub const fiobmap2_arg = struct_fiobmap2_arg;
pub const winsize = struct_winsize;
pub const termios = struct_termios;
pub const pthread = struct_pthread;
pub const pthread_attr = struct_pthread_attr;
pub const pthread_cond = struct_pthread_cond;
pub const pthread_cond_attr = struct_pthread_cond_attr;
pub const pthread_mutex = struct_pthread_mutex;
pub const pthread_mutex_attr = struct_pthread_mutex_attr;
pub const pthread_once = struct_pthread_once;
pub const pthread_rwlock = struct_pthread_rwlock;
pub const pthread_rwlockattr = struct_pthread_rwlockattr;
pub const pthread_barrier = struct_pthread_barrier;
pub const pthread_barrier_attr = struct_pthread_barrier_attr;
pub const pthread_spinlock = struct_pthread_spinlock;
pub const pthread_barrierattr = struct_pthread_barrierattr;
pub const cap_rights = struct_cap_rights;
pub const __sigset = struct___sigset;
pub const timeval = struct_timeval;
pub const timespec = struct_timespec;
pub const itimerspec = struct_itimerspec;
pub const vfnt_map_type = enum_vfnt_map_type;
pub const font_info = struct_font_info;
pub const vfnt_map = struct_vfnt_map;
pub const vt_font = struct_vt_font;
pub const vt_font_bitmap_data = struct_vt_font_bitmap_data;
pub const fontlist = struct_fontlist;
pub const font_list = struct_font_list;
pub const font_header = struct_font_header;
pub const _scr_size = struct__scr_size;
pub const _scrmap = struct__scrmap;
pub const ssaver = struct_ssaver;
pub const mouse_data = struct_mouse_data;
pub const mouse_mode = struct_mouse_mode;
pub const mouse_event = struct_mouse_event;
pub const mouse_info = struct_mouse_info;
pub const cshape = struct_cshape;
pub const fnt8 = struct_fnt8;
pub const fnt14 = struct_fnt14;
pub const fnt16 = struct_fnt16;
pub const vfnt = struct_vfnt;
pub const colors = struct_colors;
pub const vid_info = struct_vid_info;
pub const scrshot = struct_scrshot;
pub const term_info = struct_term_info;
pub const vt_mode = struct_vt_mode;
pub const keyboard_info = struct_keyboard_info;
pub const keyboard_repeat = struct_keyboard_repeat;
pub const keyent_t = struct_keyent_t;
pub const keymap = struct_keymap;
pub const acc_t = struct_acc_t;
pub const accentmap = struct_accentmap;
pub const keyarg = struct_keyarg;
pub const fkeytab = struct_fkeytab;
pub const fkeyarg = struct_fkeyarg;
pub const __oflock = struct___oflock;
pub const spacectl_range = struct_spacectl_range;
pub const dirent = struct_dirent;
pub const _dirdesc = struct__dirdesc;
pub const crypt_data = struct_crypt_data;
pub const udev = struct_udev;
pub const udev_list_entry = struct_udev_list_entry;
pub const udev_device = struct_udev_device;
pub const udev_monitor = struct_udev_monitor;
pub const udev_enumerate = struct_udev_enumerate;
pub const udev_queue = struct_udev_queue;
pub const udev_hwdb = struct_udev_hwdb;
pub const libinput = struct_libinput;
pub const libinput_device = struct_libinput_device;
pub const libinput_device_group = struct_libinput_device_group;
pub const libinput_seat = struct_libinput_seat;
pub const libinput_tablet_tool = struct_libinput_tablet_tool;
pub const libinput_event = struct_libinput_event;
pub const libinput_event_device_notify = struct_libinput_event_device_notify;
pub const libinput_event_keyboard = struct_libinput_event_keyboard;
pub const libinput_event_pointer = struct_libinput_event_pointer;
pub const libinput_event_touch = struct_libinput_event_touch;
pub const libinput_event_tablet_tool = struct_libinput_event_tablet_tool;
pub const libinput_event_tablet_pad = struct_libinput_event_tablet_pad;
pub const libinput_log_priority = enum_libinput_log_priority;
pub const libinput_device_capability = enum_libinput_device_capability;
pub const libinput_key_state = enum_libinput_key_state;
pub const libinput_led = enum_libinput_led;
pub const libinput_button_state = enum_libinput_button_state;
pub const libinput_pointer_axis = enum_libinput_pointer_axis;
pub const libinput_pointer_axis_source = enum_libinput_pointer_axis_source;
pub const libinput_tablet_pad_ring_axis_source = enum_libinput_tablet_pad_ring_axis_source;
pub const libinput_tablet_pad_strip_axis_source = enum_libinput_tablet_pad_strip_axis_source;
pub const libinput_tablet_tool_type = enum_libinput_tablet_tool_type;
pub const libinput_tablet_tool_proximity_state = enum_libinput_tablet_tool_proximity_state;
pub const libinput_tablet_tool_tip_state = enum_libinput_tablet_tool_tip_state;
pub const libinput_tablet_pad_mode_group = struct_libinput_tablet_pad_mode_group;
pub const libinput_switch_state = enum_libinput_switch_state;
pub const libinput_switch = enum_libinput_switch;
pub const libinput_event_switch = struct_libinput_event_switch;
pub const libinput_event_type = enum_libinput_event_type;
pub const libinput_event_gesture = struct_libinput_event_gesture;
pub const libinput_interface = struct_libinput_interface;
pub const libinput_config_status = enum_libinput_config_status;
pub const libinput_config_tap_state = enum_libinput_config_tap_state;
pub const libinput_config_tap_button_map = enum_libinput_config_tap_button_map;
pub const libinput_config_clickfinger_button_map = enum_libinput_config_clickfinger_button_map;
pub const libinput_config_drag_state = enum_libinput_config_drag_state;
pub const libinput_config_drag_lock_state = enum_libinput_config_drag_lock_state;
pub const libinput_config_3fg_drag_state = enum_libinput_config_3fg_drag_state;
pub const libinput_config_area_rectangle = struct_libinput_config_area_rectangle;
pub const libinput_config_send_events_mode = enum_libinput_config_send_events_mode;
pub const libinput_config_accel_profile = enum_libinput_config_accel_profile;
pub const libinput_config_accel = struct_libinput_config_accel;
pub const libinput_config_accel_type = enum_libinput_config_accel_type;
pub const libinput_config_click_method = enum_libinput_config_click_method;
pub const libinput_config_middle_emulation_state = enum_libinput_config_middle_emulation_state;
pub const libinput_config_scroll_method = enum_libinput_config_scroll_method;
pub const libinput_config_scroll_button_lock_state = enum_libinput_config_scroll_button_lock_state;
pub const libinput_config_dwt_state = enum_libinput_config_dwt_state;
pub const libinput_config_dwtp_state = enum_libinput_config_dwtp_state;
