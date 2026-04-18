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
pub const intmax_t = __intmax_t;
pub const uintmax_t = __uintmax_t;
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
pub const union___infinity_un = extern union {
    __uc: [8]u8,
    __ud: f64,
};
pub extern const __infinity: union___infinity_un;
pub const union___nan_un = extern union {
    __uc: [4]u8,
    __uf: f32,
};
pub extern const __nan: union___nan_un;
pub const double_t = __double_t;
pub const float_t = __float_t;
pub extern var signgam: c_int;
pub extern fn __fpclassifyd(f64) c_int;
pub extern fn __fpclassifyf(f32) c_int;
pub extern fn __fpclassifyl(c_longdouble) c_int;
pub extern fn __isfinitef(f32) c_int;
pub extern fn __isfinite(f64) c_int;
pub extern fn __isfinitel(c_longdouble) c_int;
pub extern fn __isinff(f32) c_int;
pub extern fn __isinf(f64) c_int;
pub extern fn __isinfl(c_longdouble) c_int;
pub extern fn __isnormalf(f32) c_int;
pub extern fn __isnormal(f64) c_int;
pub extern fn __isnormall(c_longdouble) c_int;
pub extern fn __signbit(f64) c_int;
pub extern fn __signbitf(f32) c_int;
pub extern fn __signbitl(c_longdouble) c_int;
pub fn __inline_isnan(__x: f64) callconv(.c) c_int {
    _ = &__x;
    return @intFromBool(__x != __x);
}
pub fn __inline_isnanf(__x: f32) callconv(.c) c_int {
    _ = &__x;
    return @intFromBool(__x != __x);
}
pub fn __inline_isnanl(__x: c_longdouble) callconv(.c) c_int {
    _ = &__x;
    return @intFromBool(__x != __x);
}
pub extern fn acos(f64) f64;
pub extern fn asin(f64) f64;
pub extern fn atan(f64) f64;
pub extern fn atan2(f64, f64) f64;
pub extern fn cos(f64) f64;
pub extern fn sin(f64) f64;
pub extern fn tan(f64) f64;
pub extern fn cosh(f64) f64;
pub extern fn sinh(f64) f64;
pub extern fn tanh(f64) f64;
pub extern fn exp(f64) f64;
pub extern fn frexp(f64, [*c]c_int) f64;
pub extern fn ldexp(f64, c_int) f64;
pub extern fn log(f64) f64;
pub extern fn log10(f64) f64;
pub extern fn modf(f64, [*c]f64) f64;
pub extern fn pow(f64, f64) f64;
pub extern fn sqrt(f64) f64;
pub extern fn ceil(f64) f64;
pub extern fn fabs(f64) f64;
pub extern fn floor(f64) f64;
pub extern fn fmod(f64, f64) f64;
pub extern fn acosh(f64) f64;
pub extern fn asinh(f64) f64;
pub extern fn atanh(f64) f64;
pub extern fn cbrt(f64) f64;
pub extern fn erf(f64) f64;
pub extern fn erfc(f64) f64;
pub extern fn exp2(f64) f64;
pub extern fn expm1(f64) f64;
pub extern fn fma(f64, f64, f64) f64;
pub extern fn hypot(f64, f64) f64;
pub extern fn ilogb(f64) c_int;
pub extern fn lgamma(f64) f64;
pub extern fn llrint(f64) c_longlong;
pub extern fn llround(f64) c_longlong;
pub extern fn log1p(f64) f64;
pub extern fn log2(f64) f64;
pub extern fn logb(f64) f64;
pub extern fn lrint(f64) c_long;
pub extern fn lround(f64) c_long;
pub extern fn nan([*c]const u8) f64;
pub extern fn nextafter(f64, f64) f64;
pub extern fn remainder(f64, f64) f64;
pub extern fn remquo(f64, f64, [*c]c_int) f64;
pub extern fn rint(f64) f64;
pub extern fn j0(f64) f64;
pub extern fn j1(f64) f64;
pub extern fn jn(c_int, f64) f64;
pub extern fn y0(f64) f64;
pub extern fn y1(f64) f64;
pub extern fn yn(c_int, f64) f64;
pub extern fn gamma(f64) f64;
pub extern fn scalb(f64, f64) f64;
pub extern fn copysign(f64, f64) f64;
pub extern fn fdim(f64, f64) f64;
pub extern fn fmax(f64, f64) f64;
pub extern fn fmin(f64, f64) f64;
pub extern fn nearbyint(f64) f64;
pub extern fn round(f64) f64;
pub extern fn scalbln(f64, c_long) f64;
pub extern fn scalbn(f64, c_int) f64;
pub extern fn tgamma(f64) f64;
pub extern fn trunc(f64) f64;
pub extern fn drem(f64, f64) f64;
pub extern fn finite(f64) c_int;
pub extern fn isnanf(f32) c_int;
pub extern fn gamma_r(f64, [*c]c_int) f64;
pub extern fn lgamma_r(f64, [*c]c_int) f64;
pub extern fn significand(f64) f64;
pub extern fn acosf(f32) f32;
pub extern fn asinf(f32) f32;
pub extern fn atanf(f32) f32;
pub extern fn atan2f(f32, f32) f32;
pub extern fn cosf(f32) f32;
pub extern fn sinf(f32) f32;
pub extern fn tanf(f32) f32;
pub extern fn coshf(f32) f32;
pub extern fn sinhf(f32) f32;
pub extern fn tanhf(f32) f32;
pub extern fn exp2f(f32) f32;
pub extern fn expf(f32) f32;
pub extern fn expm1f(f32) f32;
pub extern fn frexpf(f32, [*c]c_int) f32;
pub extern fn ilogbf(f32) c_int;
pub extern fn ldexpf(f32, c_int) f32;
pub extern fn log10f(f32) f32;
pub extern fn log1pf(f32) f32;
pub extern fn log2f(f32) f32;
pub extern fn logf(f32) f32;
pub extern fn modff(f32, [*c]f32) f32;
pub extern fn powf(f32, f32) f32;
pub extern fn sqrtf(f32) f32;
pub extern fn ceilf(f32) f32;
pub extern fn fabsf(f32) f32;
pub extern fn floorf(f32) f32;
pub extern fn fmodf(f32, f32) f32;
pub extern fn roundf(f32) f32;
pub extern fn erff(f32) f32;
pub extern fn erfcf(f32) f32;
pub extern fn hypotf(f32, f32) f32;
pub extern fn lgammaf(f32) f32;
pub extern fn tgammaf(f32) f32;
pub extern fn acoshf(f32) f32;
pub extern fn asinhf(f32) f32;
pub extern fn atanhf(f32) f32;
pub extern fn cbrtf(f32) f32;
pub extern fn logbf(f32) f32;
pub extern fn copysignf(f32, f32) f32;
pub extern fn llrintf(f32) c_longlong;
pub extern fn llroundf(f32) c_longlong;
pub extern fn lrintf(f32) c_long;
pub extern fn lroundf(f32) c_long;
pub extern fn nanf([*c]const u8) f32;
pub extern fn nearbyintf(f32) f32;
pub extern fn nextafterf(f32, f32) f32;
pub extern fn remainderf(f32, f32) f32;
pub extern fn remquof(f32, f32, [*c]c_int) f32;
pub extern fn rintf(f32) f32;
pub extern fn scalblnf(f32, c_long) f32;
pub extern fn scalbnf(f32, c_int) f32;
pub extern fn truncf(f32) f32;
pub extern fn fdimf(f32, f32) f32;
pub extern fn fmaf(f32, f32, f32) f32;
pub extern fn fmaxf(f32, f32) f32;
pub extern fn fminf(f32, f32) f32;
pub extern fn dremf(f32, f32) f32;
pub extern fn finitef(f32) c_int;
pub extern fn gammaf(f32) f32;
pub extern fn j0f(f32) f32;
pub extern fn j1f(f32) f32;
pub extern fn jnf(c_int, f32) f32;
pub extern fn scalbf(f32, f32) f32;
pub extern fn y0f(f32) f32;
pub extern fn y1f(f32) f32;
pub extern fn ynf(c_int, f32) f32;
pub extern fn gammaf_r(f32, [*c]c_int) f32;
pub extern fn lgammaf_r(f32, [*c]c_int) f32;
pub extern fn significandf(f32) f32;
pub extern fn acoshl(c_longdouble) c_longdouble;
pub extern fn acosl(c_longdouble) c_longdouble;
pub extern fn asinhl(c_longdouble) c_longdouble;
pub extern fn asinl(c_longdouble) c_longdouble;
pub extern fn atan2l(c_longdouble, c_longdouble) c_longdouble;
pub extern fn atanhl(c_longdouble) c_longdouble;
pub extern fn atanl(c_longdouble) c_longdouble;
pub extern fn cbrtl(c_longdouble) c_longdouble;
pub extern fn ceill(c_longdouble) c_longdouble;
pub extern fn copysignl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn coshl(c_longdouble) c_longdouble;
pub extern fn cosl(c_longdouble) c_longdouble;
pub extern fn erfcl(c_longdouble) c_longdouble;
pub extern fn erfl(c_longdouble) c_longdouble;
pub extern fn exp2l(c_longdouble) c_longdouble;
pub extern fn expl(c_longdouble) c_longdouble;
pub extern fn expm1l(c_longdouble) c_longdouble;
pub extern fn fabsl(c_longdouble) c_longdouble;
pub extern fn fdiml(c_longdouble, c_longdouble) c_longdouble;
pub extern fn floorl(c_longdouble) c_longdouble;
pub extern fn fmal(c_longdouble, c_longdouble, c_longdouble) c_longdouble;
pub extern fn fmaxl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn fminl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn fmodl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn frexpl(c_longdouble, [*c]c_int) c_longdouble;
pub extern fn hypotl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn ilogbl(c_longdouble) c_int;
pub extern fn ldexpl(c_longdouble, c_int) c_longdouble;
pub extern fn lgammal(c_longdouble) c_longdouble;
pub extern fn llrintl(c_longdouble) c_longlong;
pub extern fn llroundl(c_longdouble) c_longlong;
pub extern fn log10l(c_longdouble) c_longdouble;
pub extern fn log1pl(c_longdouble) c_longdouble;
pub extern fn log2l(c_longdouble) c_longdouble;
pub extern fn logbl(c_longdouble) c_longdouble;
pub extern fn logl(c_longdouble) c_longdouble;
pub extern fn lrintl(c_longdouble) c_long;
pub extern fn lroundl(c_longdouble) c_long;
pub extern fn modfl(c_longdouble, [*c]c_longdouble) c_longdouble;
pub extern fn nanl([*c]const u8) c_longdouble;
pub extern fn nearbyintl(c_longdouble) c_longdouble;
pub extern fn nextafterl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn nexttoward(f64, c_longdouble) f64;
pub extern fn nexttowardf(f32, c_longdouble) f32;
pub extern fn nexttowardl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn powl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn remainderl(c_longdouble, c_longdouble) c_longdouble;
pub extern fn remquol(c_longdouble, c_longdouble, [*c]c_int) c_longdouble;
pub extern fn rintl(c_longdouble) c_longdouble;
pub extern fn roundl(c_longdouble) c_longdouble;
pub extern fn scalblnl(c_longdouble, c_long) c_longdouble;
pub extern fn scalbnl(c_longdouble, c_int) c_longdouble;
pub extern fn sinhl(c_longdouble) c_longdouble;
pub extern fn sinl(c_longdouble) c_longdouble;
pub extern fn sqrtl(c_longdouble) c_longdouble;
pub extern fn tanhl(c_longdouble) c_longdouble;
pub extern fn tanl(c_longdouble) c_longdouble;
pub extern fn tgammal(c_longdouble) c_longdouble;
pub extern fn truncl(c_longdouble) c_longdouble;
pub extern fn lgammal_r(c_longdouble, [*c]c_int) c_longdouble;
pub extern fn sincos(f64, [*c]f64, [*c]f64) void;
pub extern fn sincosf(f32, [*c]f32, [*c]f32) void;
pub extern fn sincosl(c_longdouble, [*c]c_longdouble, [*c]c_longdouble) void;
pub extern fn cospi(f64) f64;
pub extern fn cospif(f32) f32;
pub extern fn cospil(c_longdouble) c_longdouble;
pub extern fn sinpi(f64) f64;
pub extern fn sinpif(f32) f32;
pub extern fn sinpil(c_longdouble) c_longdouble;
pub extern fn tanpi(f64) f64;
pub extern fn tanpif(f32) f32;
pub extern fn tanpil(c_longdouble) c_longdouble;
pub const ptrdiff_t = c_long;
pub const wchar_t = c_int;
pub const max_align_t = extern struct {
    __clang_max_align_nonce1: c_longlong align(8) = @import("std").mem.zeroes(c_longlong),
    __clang_max_align_nonce2: c_longdouble align(16) = @import("std").mem.zeroes(c_longdouble),
};
pub const imaxdiv_t = extern struct {
    quot: intmax_t = @import("std").mem.zeroes(intmax_t),
    rem: intmax_t = @import("std").mem.zeroes(intmax_t),
};
pub extern fn imaxabs(intmax_t) intmax_t;
pub extern fn imaxdiv(intmax_t, intmax_t) imaxdiv_t;
pub extern fn strtoimax(noalias [*c]const u8, noalias [*c][*c]u8, c_int) intmax_t;
pub extern fn strtoumax(noalias [*c]const u8, noalias [*c][*c]u8, c_int) uintmax_t;
pub extern fn wcstoimax(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t, c_int) intmax_t;
pub extern fn wcstoumax(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t, c_int) uintmax_t;
pub const va_list = __builtin_va_list;
pub const struct_wl_object = opaque {};
pub const struct_wl_interface = extern struct {
    name: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    version: c_int = @import("std").mem.zeroes(c_int),
    method_count: c_int = @import("std").mem.zeroes(c_int),
    methods: [*c]const struct_wl_message = @import("std").mem.zeroes([*c]const struct_wl_message),
    event_count: c_int = @import("std").mem.zeroes(c_int),
    events: [*c]const struct_wl_message = @import("std").mem.zeroes([*c]const struct_wl_message),
};
pub const struct_wl_message = extern struct {
    name: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    signature: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    types: [*c][*c]const struct_wl_interface = @import("std").mem.zeroes([*c][*c]const struct_wl_interface),
};
pub const struct_wl_list = extern struct {
    prev: [*c]struct_wl_list = @import("std").mem.zeroes([*c]struct_wl_list),
    next: [*c]struct_wl_list = @import("std").mem.zeroes([*c]struct_wl_list),
};
pub extern fn wl_list_init(list: [*c]struct_wl_list) void;
pub extern fn wl_list_insert(list: [*c]struct_wl_list, elm: [*c]struct_wl_list) void;
pub extern fn wl_list_remove(elm: [*c]struct_wl_list) void;
pub extern fn wl_list_length(list: [*c]const struct_wl_list) c_int;
pub extern fn wl_list_empty(list: [*c]const struct_wl_list) c_int;
pub extern fn wl_list_insert_list(list: [*c]struct_wl_list, other: [*c]struct_wl_list) void;
pub const struct_wl_array = extern struct {
    size: usize = @import("std").mem.zeroes(usize),
    alloc: usize = @import("std").mem.zeroes(usize),
    data: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub extern fn wl_array_init(array: [*c]struct_wl_array) void;
pub extern fn wl_array_release(array: [*c]struct_wl_array) void;
pub extern fn wl_array_add(array: [*c]struct_wl_array, size: usize) ?*anyopaque;
pub extern fn wl_array_copy(array: [*c]struct_wl_array, source: [*c]struct_wl_array) c_int;
pub const wl_fixed_t = i32;
pub fn wl_fixed_to_double(arg_f: wl_fixed_t) callconv(.c) f64 {
    var f = arg_f;
    _ = &f;
    return @as(f64, @floatFromInt(f)) / 256.0;
}
pub fn wl_fixed_from_double(arg_d: f64) callconv(.c) wl_fixed_t {
    var d = arg_d;
    _ = &d;
    return @as(wl_fixed_t, @intFromFloat(round(d * 256.0)));
}
pub fn wl_fixed_to_int(arg_f: wl_fixed_t) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    return @divTrunc(f, @as(c_int, 256));
}
pub fn wl_fixed_from_int(arg_i: c_int) callconv(.c) wl_fixed_t {
    var i = arg_i;
    _ = &i;
    return i * @as(c_int, 256);
}
pub const union_wl_argument = extern union {
    i: i32,
    u: u32,
    f: wl_fixed_t,
    s: [*c]const u8,
    o: ?*struct_wl_object,
    n: u32,
    a: [*c]struct_wl_array,
    h: i32,
};
pub const wl_dispatcher_func_t = ?*const fn (?*const anyopaque, ?*anyopaque, u32, [*c]const struct_wl_message, [*c]union_wl_argument) callconv(.c) c_int;
pub const wl_log_func_t = ?*const fn ([*c]const u8, [*c]struct___va_list_tag_1) callconv(.c) void;
pub const WL_ITERATOR_STOP: c_int = 0;
pub const WL_ITERATOR_CONTINUE: c_int = 1;
pub const enum_wl_iterator_result = c_uint;
pub const time_t = __time_t;
pub const struct_timespec = extern struct {
    tv_sec: time_t = @import("std").mem.zeroes(time_t),
    tv_nsec: c_long = @import("std").mem.zeroes(c_long),
};
pub const struct_wl_proxy = opaque {};
pub const struct_wl_display = opaque {};
pub const struct_wl_event_queue = opaque {};
pub extern fn wl_event_queue_destroy(queue: ?*struct_wl_event_queue) void;
pub extern fn wl_proxy_marshal_flags(proxy: ?*struct_wl_proxy, opcode: u32, interface: [*c]const struct_wl_interface, version: u32, flags: u32, ...) ?*struct_wl_proxy;
pub extern fn wl_proxy_marshal_array_flags(proxy: ?*struct_wl_proxy, opcode: u32, interface: [*c]const struct_wl_interface, version: u32, flags: u32, args: [*c]union_wl_argument) ?*struct_wl_proxy;
pub extern fn wl_proxy_marshal(p: ?*struct_wl_proxy, opcode: u32, ...) void;
pub extern fn wl_proxy_marshal_array(p: ?*struct_wl_proxy, opcode: u32, args: [*c]union_wl_argument) void;
pub extern fn wl_proxy_create(factory: ?*struct_wl_proxy, interface: [*c]const struct_wl_interface) ?*struct_wl_proxy;
pub extern fn wl_proxy_create_wrapper(proxy: ?*anyopaque) ?*anyopaque;
pub extern fn wl_proxy_wrapper_destroy(proxy_wrapper: ?*anyopaque) void;
pub extern fn wl_proxy_marshal_constructor(proxy: ?*struct_wl_proxy, opcode: u32, interface: [*c]const struct_wl_interface, ...) ?*struct_wl_proxy;
pub extern fn wl_proxy_marshal_constructor_versioned(proxy: ?*struct_wl_proxy, opcode: u32, interface: [*c]const struct_wl_interface, version: u32, ...) ?*struct_wl_proxy;
pub extern fn wl_proxy_marshal_array_constructor(proxy: ?*struct_wl_proxy, opcode: u32, args: [*c]union_wl_argument, interface: [*c]const struct_wl_interface) ?*struct_wl_proxy;
pub extern fn wl_proxy_marshal_array_constructor_versioned(proxy: ?*struct_wl_proxy, opcode: u32, args: [*c]union_wl_argument, interface: [*c]const struct_wl_interface, version: u32) ?*struct_wl_proxy;
pub extern fn wl_proxy_destroy(proxy: ?*struct_wl_proxy) void;
pub extern fn wl_proxy_add_listener(proxy: ?*struct_wl_proxy, implementation: [*c]?*const fn () callconv(.c) void, data: ?*anyopaque) c_int;
pub extern fn wl_proxy_get_listener(proxy: ?*struct_wl_proxy) ?*const anyopaque;
pub extern fn wl_proxy_add_dispatcher(proxy: ?*struct_wl_proxy, dispatcher_func: wl_dispatcher_func_t, dispatcher_data: ?*const anyopaque, data: ?*anyopaque) c_int;
pub extern fn wl_proxy_set_user_data(proxy: ?*struct_wl_proxy, user_data: ?*anyopaque) void;
pub extern fn wl_proxy_get_user_data(proxy: ?*struct_wl_proxy) ?*anyopaque;
pub extern fn wl_proxy_get_version(proxy: ?*struct_wl_proxy) u32;
pub extern fn wl_proxy_get_id(proxy: ?*struct_wl_proxy) u32;
pub extern fn wl_proxy_set_tag(proxy: ?*struct_wl_proxy, tag: [*c]const [*c]const u8) void;
pub extern fn wl_proxy_get_tag(proxy: ?*struct_wl_proxy) [*c]const [*c]const u8;
pub extern fn wl_proxy_get_class(proxy: ?*struct_wl_proxy) [*c]const u8;
pub extern fn wl_proxy_get_interface(proxy: ?*struct_wl_proxy) [*c]const struct_wl_interface;
pub extern fn wl_proxy_get_display(proxy: ?*struct_wl_proxy) ?*struct_wl_display;
pub extern fn wl_proxy_set_queue(proxy: ?*struct_wl_proxy, queue: ?*struct_wl_event_queue) void;
pub extern fn wl_proxy_get_queue(proxy: ?*const struct_wl_proxy) ?*struct_wl_event_queue;
pub extern fn wl_event_queue_get_name(queue: ?*const struct_wl_event_queue) [*c]const u8;
pub extern fn wl_display_connect(name: [*c]const u8) ?*struct_wl_display;
pub extern fn wl_display_connect_to_fd(fd: c_int) ?*struct_wl_display;
pub extern fn wl_display_disconnect(display: ?*struct_wl_display) void;
pub extern fn wl_display_get_fd(display: ?*struct_wl_display) c_int;
pub extern fn wl_display_dispatch(display: ?*struct_wl_display) c_int;
pub extern fn wl_display_dispatch_queue(display: ?*struct_wl_display, queue: ?*struct_wl_event_queue) c_int;
pub extern fn wl_display_dispatch_timeout(display: ?*struct_wl_display, timeout: [*c]const struct_timespec) c_int;
pub extern fn wl_display_dispatch_queue_timeout(display: ?*struct_wl_display, queue: ?*struct_wl_event_queue, timeout: [*c]const struct_timespec) c_int;
pub extern fn wl_display_dispatch_queue_pending(display: ?*struct_wl_display, queue: ?*struct_wl_event_queue) c_int;
pub extern fn wl_display_dispatch_pending(display: ?*struct_wl_display) c_int;
pub extern fn wl_display_get_error(display: ?*struct_wl_display) c_int;
pub extern fn wl_display_get_protocol_error(display: ?*struct_wl_display, interface: [*c][*c]const struct_wl_interface, id: [*c]u32) u32;
pub extern fn wl_display_flush(display: ?*struct_wl_display) c_int;
pub extern fn wl_display_roundtrip_queue(display: ?*struct_wl_display, queue: ?*struct_wl_event_queue) c_int;
pub extern fn wl_display_roundtrip(display: ?*struct_wl_display) c_int;
pub extern fn wl_display_create_queue(display: ?*struct_wl_display) ?*struct_wl_event_queue;
pub extern fn wl_display_create_queue_with_name(display: ?*struct_wl_display, name: [*c]const u8) ?*struct_wl_event_queue;
pub extern fn wl_display_prepare_read_queue(display: ?*struct_wl_display, queue: ?*struct_wl_event_queue) c_int;
pub extern fn wl_display_prepare_read(display: ?*struct_wl_display) c_int;
pub extern fn wl_display_cancel_read(display: ?*struct_wl_display) void;
pub extern fn wl_display_read_events(display: ?*struct_wl_display) c_int;
pub extern fn wl_log_set_handler_client(handler: wl_log_func_t) void;
pub extern fn wl_display_set_max_buffer_size(display: ?*struct_wl_display, max_buffer_size: usize) void;
pub const struct_shm_largepage_conf = extern struct {
    psind: c_int = @import("std").mem.zeroes(c_int),
    alloc_policy: c_int = @import("std").mem.zeroes(c_int),
    pad: [10]c_int = @import("std").mem.zeroes([10]c_int),
};
pub const mode_t = __mode_t;
pub const off_t = __off_t;
pub extern fn getpagesizes([*c]usize, c_int) c_int;
pub extern fn madvise(?*anyopaque, usize, c_int) c_int;
pub extern fn mincore(?*const anyopaque, usize, [*c]u8) c_int;
pub extern fn minherit(?*anyopaque, usize, c_int) c_int;
pub extern fn mlock(?*const anyopaque, usize) c_int;
pub extern fn mmap(?*anyopaque, usize, c_int, c_int, c_int, off_t) ?*anyopaque;
pub extern fn mprotect(?*anyopaque, usize, c_int) c_int;
pub extern fn msync(?*anyopaque, usize, c_int) c_int;
pub extern fn munlock(?*const anyopaque, usize) c_int;
pub extern fn munmap(?*anyopaque, usize) c_int;
pub extern fn posix_madvise(?*anyopaque, usize, c_int) c_int;
pub extern fn mlockall(c_int) c_int;
pub extern fn munlockall() c_int;
pub extern fn shm_open([*c]const u8, c_int, mode_t) c_int;
pub extern fn shm_unlink([*c]const u8) c_int;
pub extern fn memfd_create([*c]const u8, c_uint) c_int;
pub extern fn shm_create_largepage([*c]const u8, c_int, c_int, c_int, mode_t) c_int;
pub extern fn shm_rename([*c]const u8, [*c]const u8, c_int) c_int;
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
pub const accmode_t = __accmode_t;
pub const nlink_t = __nlink_t;
pub const off64_t = __off64_t;
pub const pid_t = __pid_t;
pub const register_t = __register_t;
pub const rlim_t = __rlim_t;
pub const sbintime_t = __sbintime_t;
pub const segsz_t = __segsz_t;
pub const suseconds_t = __suseconds_t;
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
pub const struct_itimerspec = extern struct {
    it_interval: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    it_value: struct_timespec = @import("std").mem.zeroes(struct_timespec),
};
pub const __fd_mask = c_ulong;
pub const fd_mask = __fd_mask;
pub const sigset_t = __sigset_t;
pub inline fn __ssp_overlap(arg_leftp: ?*const anyopaque, arg_rightp: ?*const anyopaque, arg_sz: __size_t) c_int {
    var leftp = arg_leftp;
    _ = &leftp;
    var rightp = arg_rightp;
    _ = &rightp;
    var sz = arg_sz;
    _ = &sz;
    var left: __uintptr_t = @as(__uintptr_t, @intCast(@intFromPtr(leftp)));
    _ = &left;
    var right: __uintptr_t = @as(__uintptr_t, @intCast(@intFromPtr(rightp)));
    _ = &right;
    if (left <= right) return @intFromBool(((@as(c_ulong, 18446744073709551615) -% sz) < left) or (right < (left +% sz)));
    return @intFromBool(((@as(c_ulong, 18446744073709551615) -% sz) < right) or (left < (right +% sz)));
}
pub const struct_iovec = extern struct {
    iov_base: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    iov_len: usize = @import("std").mem.zeroes(usize),
};
pub extern fn __stack_chk_fail() noreturn;
pub extern fn __chk_fail() noreturn;
pub inline fn __ssp_check_iovec(arg_iov: [*c]const struct_iovec, arg_iovcnt: c_int) void {
    var iov = arg_iov;
    _ = &iov;
    var iovcnt = arg_iovcnt;
    _ = &iovcnt;
    const iovsz: usize = __builtin_object_size(@as(?*const anyopaque, @ptrCast(iov)), @intFromBool(@as(c_int, 2) > @as(c_int, 1)));
    _ = &iovsz;
    var i: c_int = undefined;
    _ = &i;
    if ((iovsz != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and ((iovsz / @sizeOf(struct_iovec)) < @as(usize, @bitCast(@as(c_long, iovcnt))))) {
        __chk_fail();
    }
    {
        i = 0;
        while (i < iovcnt) : (i += 1) {
            if (__builtin_object_size((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk iov + @as(usize, @intCast(tmp)) else break :blk iov - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*.iov_base, @intFromBool(@as(c_int, 2) > @as(c_int, 1))) < (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk iov + @as(usize, @intCast(tmp)) else break :blk iov - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*.iov_len) {
                __chk_fail();
            }
        }
    }
}
pub const struct_fd_set = extern struct {
    __fds_bits: [16]__fd_mask = @import("std").mem.zeroes([16]__fd_mask),
};
pub const fd_set = struct_fd_set;
pub inline fn __fdset_idx(arg_p: [*c]const fd_set, arg_idx: c_ulong) c_ulong {
    var p = arg_p;
    _ = &p;
    var idx = arg_idx;
    _ = &idx;
    var psz: __size_t = __builtin_object_size(@as(?*const anyopaque, @ptrCast(p)), @as(c_int, 0));
    _ = &psz;
    var sidx: c_ulong = idx / (@sizeOf(__fd_mask) *% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 8)))));
    _ = &sidx;
    if (idx >= @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1024))))) {
        __chk_fail();
    }
    if ((psz / @sizeOf(__fd_mask)) < (sidx +% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1)))))) {
        __chk_fail();
    }
    return sidx;
}
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
pub extern fn truncate([*c]const u8, off_t) c_int;
pub inline fn __ssp_gid_bos(arg_ptr: ?*const anyopaque) usize {
    var ptr = arg_ptr;
    _ = &ptr;
    var ptrsize: usize = __builtin_object_size(ptr, @intFromBool(@as(c_int, 2) > @as(c_int, 1)));
    _ = &ptrsize;
    if (ptrsize == @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) return ptrsize;
    return ptrsize / @sizeOf(gid_t);
}
pub extern fn __ssp_real_getgrouplist(__name: [*c]const u8, __base: gid_t, __buf: [*c]gid_t, __lenp: [*c]c_int) c_int;
pub inline fn getgrouplist(arg___name: [*c]const u8, arg___base: gid_t, arg___buf: [*c]gid_t, arg___lenp: [*c]c_int) c_int {
    var __name = arg___name;
    _ = &__name;
    var __base = arg___base;
    _ = &__base;
    var __buf = arg___buf;
    _ = &__buf;
    var __lenp = arg___lenp;
    _ = &__lenp;
    if (true) if ((__ssp_gid_bos(@as(?*const anyopaque, @ptrCast(__buf))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (@as(usize, @bitCast(@as(c_long, __lenp.*))) > __ssp_gid_bos(@as(?*const anyopaque, @ptrCast(__buf))))) {
        __chk_fail();
    };
    return __ssp_real_getgrouplist(__name, __base, __buf, __lenp);
}
pub extern fn __ssp_real_getgroups(__len: c_int, __buf: [*c]gid_t) c_int;
pub inline fn getgroups(arg___len: c_int, arg___buf: [*c]gid_t) c_int {
    var __len = arg___len;
    _ = &__len;
    var __buf = arg___buf;
    _ = &__buf;
    if (true) if ((__ssp_gid_bos(@as(?*const anyopaque, @ptrCast(__buf))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (@as(usize, @bitCast(@as(c_long, __len))) > __ssp_gid_bos(@as(?*const anyopaque, @ptrCast(__buf))))) {
        __chk_fail();
    };
    return __ssp_real_getgroups(__len, __buf);
}
pub extern fn __ssp_real_getloginclass(__buf: [*c]u8, __len: usize) c_int;
pub inline fn getloginclass(arg___buf: [*c]u8, arg___len: usize) c_int {
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_getloginclass(__buf, __len);
}
pub extern fn __ssp_real_read(__fd: c_int, __buf: ?*anyopaque, __len: usize) isize;
pub inline fn read(arg___fd: c_int, arg___buf: ?*anyopaque, arg___len: usize) isize {
    var __fd = arg___fd;
    _ = &__fd;
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(__buf, @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(__buf, @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_read(__fd, __buf, __len);
}
pub extern fn __ssp_real_pread(__fd: c_int, __buf: ?*anyopaque, __len: usize, __offset: off_t) isize;
pub inline fn pread(arg___fd: c_int, arg___buf: ?*anyopaque, arg___len: usize, arg___offset: off_t) isize {
    var __fd = arg___fd;
    _ = &__fd;
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    var __offset = arg___offset;
    _ = &__offset;
    if (true) if ((__builtin_object_size(__buf, @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(__buf, @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_pread(__fd, __buf, __len, __offset);
}
pub extern fn __ssp_real_readlink(noalias __path: [*c]const u8, noalias __buf: [*c]u8, __len: usize) isize;
pub inline fn readlink(noalias arg___path: [*c]const u8, noalias arg___buf: [*c]u8, arg___len: usize) isize {
    var __path = arg___path;
    _ = &__path;
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_readlink(__path, __buf, __len);
}
pub extern fn __ssp_real_readlinkat(__fd: c_int, noalias __path: [*c]const u8, noalias __buf: [*c]u8, __len: usize) isize;
pub inline fn readlinkat(arg___fd: c_int, noalias arg___path: [*c]const u8, noalias arg___buf: [*c]u8, arg___len: usize) isize {
    var __fd = arg___fd;
    _ = &__fd;
    var __path = arg___path;
    _ = &__path;
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_readlinkat(__fd, __path, __buf, __len);
}
pub extern fn __ssp_real_getcwd(__buf: [*c]u8, __len: usize) [*c]u8;
pub inline fn getcwd(arg___buf: [*c]u8, arg___len: usize) [*c]u8 {
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (__buf != null) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_getcwd(__buf, __len);
}
pub extern fn __ssp_real_getdomainname(__buf: [*c]u8, __len: c_int) c_int;
pub inline fn getdomainname(arg___buf: [*c]u8, arg___len: c_int) c_int {
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (@as(usize, @bitCast(@as(c_long, __len))) > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_getdomainname(__buf, __len);
}
pub extern fn __ssp_real_getentropy(__buf: ?*anyopaque, __len: usize) c_int;
pub inline fn getentropy(arg___buf: ?*anyopaque, arg___len: usize) c_int {
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(__buf, @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(__buf, @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_getentropy(__buf, __len);
}
pub extern fn __ssp_real_gethostname(__buf: [*c]u8, __len: usize) c_int;
pub inline fn gethostname(arg___buf: [*c]u8, arg___len: usize) c_int {
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_gethostname(__buf, __len);
}
pub extern fn __ssp_real_getlogin_r(__buf: [*c]u8, __len: usize) c_int;
pub inline fn getlogin_r(arg___buf: [*c]u8, arg___len: usize) c_int {
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_getlogin_r(__buf, __len);
}
pub extern fn __ssp_real_ttyname_r(__fd: c_int, __buf: [*c]u8, __len: usize) c_int;
pub inline fn ttyname_r(arg___fd: c_int, arg___buf: [*c]u8, arg___len: usize) c_int {
    var __fd = arg___fd;
    _ = &__fd;
    var __buf = arg___buf;
    _ = &__buf;
    var __len = arg___len;
    _ = &__len;
    if (true) if ((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))) != @as(usize, @bitCast(@as(c_long, -@as(c_int, 1))))) and (__len > __builtin_object_size(@as(?*const anyopaque, @ptrCast(__buf)), @intFromBool(@as(c_int, 2) > @as(c_int, 1))))) {
        __chk_fail();
    };
    return __ssp_real_ttyname_r(__fd, __buf, __len);
}
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
pub extern fn getegid() gid_t;
pub extern fn geteuid() uid_t;
pub extern fn getgid() gid_t;
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
pub extern fn fchown(c_int, uid_t, gid_t) c_int;
pub extern fn setegid(gid_t) c_int;
pub extern fn seteuid(uid_t) c_int;
pub extern fn getsid(_pid: pid_t) c_int;
pub extern fn fchdir(c_int) c_int;
pub extern fn getpgid(_pid: pid_t) c_int;
pub extern fn lchown([*c]const u8, uid_t, gid_t) c_int;
pub extern fn pwrite(c_int, ?*const anyopaque, usize, off_t) isize;
pub extern fn faccessat(c_int, [*c]const u8, c_int, c_int) c_int;
pub extern fn fchownat(c_int, [*c]const u8, uid_t, gid_t, c_int) c_int;
pub extern fn fexecve(c_int, [*c]const [*c]u8, [*c]const [*c]u8) c_int;
pub extern fn linkat(c_int, [*c]const u8, c_int, [*c]const u8, c_int) c_int;
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
pub const __OPTIMIZE__ = @as(c_int, 1);
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
// (no file):96:9
pub const __INTMAX_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):103:9
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
// (no file):207:9
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
// (no file):232:9
pub const __UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):241:9
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
pub const _FORTIFY_SOURCE = @as(c_int, 2);
pub const __FreeBSD_version = @import("std").zig.c_translation.promoteIntLiteral(c_int, 1500500, .decimal);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const WAYLAND_CLIENT_CORE_H = "";
pub const __CLANG_STDINT_H = "";
pub const _SYS_STDINT_H_ = "";
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
pub inline fn __predict_true(exp_1: anytype) @TypeOf(__builtin_expect(exp_1, @as(c_int, 1))) {
    _ = &exp_1;
    return __builtin_expect(exp_1, @as(c_int, 1));
}
pub inline fn __predict_false(exp_1: anytype) @TypeOf(__builtin_expect(exp_1, @as(c_int, 0))) {
    _ = &exp_1;
    return __builtin_expect(exp_1, @as(c_int, 0));
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
pub const __WORDSIZE = @as(c_int, 64);
pub const WCHAR_MIN = __WCHAR_MIN;
pub const WCHAR_MAX = __WCHAR_MAX;
pub const RSIZE_MAX = SIZE_MAX >> @as(c_int, 1);
pub const WAYLAND_UTIL_H = "";
pub const _MATH_H_ = "";
pub const __MATH_BUILTIN_CONSTANTS = "";
pub const __MATH_BUILTIN_RELOPS = "";
pub const HUGE_VAL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_val`");
// /usr/include/math.h:39:9
pub const FP_ILOGB0 = -__INT_MAX;
pub const FP_ILOGBNAN = __INT_MAX;
pub const HUGE_VALF = __builtin_huge_valf();
pub const HUGE_VALL = @compileError("unable to translate macro: undefined identifier `__builtin_huge_vall`");
// /usr/include/math.h:50:9
pub const INFINITY = __builtin_inff();
pub const NAN = __builtin_nanf("");
pub const MATH_ERRNO = @as(c_int, 1);
pub const MATH_ERREXCEPT = @as(c_int, 2);
pub const math_errhandling = MATH_ERREXCEPT;
pub const FP_FAST_FMAF = @as(c_int, 1);
pub const FP_INFINITE = @as(c_int, 0x01);
pub const FP_NAN = @as(c_int, 0x02);
pub const FP_NORMAL = @as(c_int, 0x04);
pub const FP_SUBNORMAL = @as(c_int, 0x08);
pub const FP_ZERO = @as(c_int, 0x10);
pub const __fp_type_select = @compileError("unable to translate C expr: unexpected token '__extension__'");
// /usr/include/math.h:74:9
pub inline fn fpclassify(x: anytype) @TypeOf(__fp_type_select(x, __fpclassifyf, __fpclassifyd, __fpclassifyl)) {
    _ = &x;
    return __fp_type_select(x, __fpclassifyf, __fpclassifyd, __fpclassifyl);
}
pub inline fn isfinite(x: anytype) @TypeOf(__fp_type_select(x, __isfinitef, __isfinite, __isfinitel)) {
    _ = &x;
    return __fp_type_select(x, __isfinitef, __isfinite, __isfinitel);
}
pub inline fn isinf(x: anytype) @TypeOf(__fp_type_select(x, __isinff, __isinf, __isinfl)) {
    _ = &x;
    return __fp_type_select(x, __isinff, __isinf, __isinfl);
}
pub inline fn isnan(x: anytype) @TypeOf(__fp_type_select(x, __inline_isnanf, __inline_isnan, __inline_isnanl)) {
    _ = &x;
    return __fp_type_select(x, __inline_isnanf, __inline_isnan, __inline_isnanl);
}
pub inline fn isnormal(x: anytype) @TypeOf(__fp_type_select(x, __isnormalf, __isnormal, __isnormall)) {
    _ = &x;
    return __fp_type_select(x, __isnormalf, __isnormal, __isnormall);
}
pub const isgreater = @compileError("unable to translate macro: undefined identifier `__builtin_isgreater`");
// /usr/include/math.h:101:9
pub const isgreaterequal = @compileError("unable to translate macro: undefined identifier `__builtin_isgreaterequal`");
// /usr/include/math.h:102:9
pub const isless = @compileError("unable to translate macro: undefined identifier `__builtin_isless`");
// /usr/include/math.h:103:9
pub const islessequal = @compileError("unable to translate macro: undefined identifier `__builtin_islessequal`");
// /usr/include/math.h:104:9
pub const islessgreater = @compileError("unable to translate macro: undefined identifier `__builtin_islessgreater`");
// /usr/include/math.h:105:9
pub const isunordered = @compileError("unable to translate macro: undefined identifier `__builtin_isunordered`");
// /usr/include/math.h:106:9
pub inline fn signbit(x: anytype) @TypeOf(__fp_type_select(x, __signbitf, __signbit, __signbitl)) {
    _ = &x;
    return __fp_type_select(x, __signbitf, __signbit, __signbitl);
}
pub const M_E = @as(f64, 2.7182818284590452354);
pub const M_LOG2E = @as(f64, 1.4426950408889634074);
pub const M_LOG10E = @as(f64, 0.43429448190325182765);
pub const M_LN2 = @as(f64, 0.69314718055994530942);
pub const M_LN10 = @as(f64, 2.30258509299404568402);
pub const M_PI = @as(f64, 3.14159265358979323846);
pub const M_PI_2 = @as(f64, 1.57079632679489661923);
pub const M_PI_4 = @as(f64, 0.78539816339744830962);
pub const M_1_PI = @as(f64, 0.31830988618379067154);
pub const M_2_PI = @as(f64, 0.63661977236758134308);
pub const M_2_SQRTPI = @as(f64, 1.12837916709551257390);
pub const M_SQRT2 = @as(f64, 1.41421356237309504880);
pub const M_SQRT1_2 = @as(f64, 0.70710678118654752440);
pub const M_El = @as(c_longdouble, 2.718281828459045235360287471352662498);
pub const M_LOG2El = @as(c_longdouble, 1.442695040888963407359924681001892137);
pub const M_LOG10El = @as(c_longdouble, 0.434294481903251827651128918916605082);
pub const M_LN2l = @as(c_longdouble, 0.693147180559945309417232121458176568);
pub const M_LN10l = @as(c_longdouble, 2.302585092994045684017991454684364208);
pub const M_PIl = @as(c_longdouble, 3.141592653589793238462643383279502884);
pub const M_PI_2l = @as(c_longdouble, 1.570796326794896619231321691639751442);
pub const M_PI_4l = @as(c_longdouble, 0.785398163397448309615660845819875721);
pub const M_1_PIl = @as(c_longdouble, 0.318309886183790671537767526745028724);
pub const M_2_PIl = @as(c_longdouble, 0.636619772367581343075535053490057448);
pub const M_2_SQRTPIl = @as(c_longdouble, 1.128379167095512573896158903121545172);
pub const M_SQRT2l = @as(c_longdouble, 1.414213562373095048801688724209698079);
pub const M_SQRT1_2l = @as(c_longdouble, 0.707106781186547524400844362104849039);
pub const MAXFLOAT = @import("std").zig.c_translation.cast(f32, @as(f64, 3.40282346638528860e+38));
pub const HUGE = MAXFLOAT;
pub const __isnan = __inline_isnan;
pub const __isnanf = __inline_isnanf;
pub const __need_ptrdiff_t = "";
pub const __need_size_t = "";
pub const __need_wchar_t = "";
pub const __need_NULL = "";
pub const __need_max_align_t = "";
pub const __need_offsetof = "";
pub const __STDDEF_H = "";
pub const _PTRDIFF_T = "";
pub const _SIZE_T = "";
pub const _WCHAR_T = "";
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const __CLANG_MAX_ALIGN_T_DEFINED = "";
pub const offsetof = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// /usr/local/lib/zig/include/__stddef_offsetof.h:16:9
pub const __CLANG_INTTYPES_H = "";
pub const _INTTYPES_H_ = "";
pub const _MACHINE_INTTYPES_H_ = "";
pub const __PRI64 = "l";
pub const __PRIptr = "l";
pub const PRId8 = "d";
pub const PRId16 = "d";
pub const PRId32 = "d";
pub const PRId64 = __PRI64 ++ "d";
pub const PRIdLEAST8 = "d";
pub const PRIdLEAST16 = "d";
pub const PRIdLEAST32 = "d";
pub const PRIdLEAST64 = __PRI64 ++ "d";
pub const PRIdFAST8 = "d";
pub const PRIdFAST16 = "d";
pub const PRIdFAST32 = "d";
pub const PRIdFAST64 = __PRI64 ++ "d";
pub const PRIdMAX = "jd";
pub const PRIdPTR = __PRIptr ++ "d";
pub const PRIi8 = "i";
pub const PRIi16 = "i";
pub const PRIi32 = "i";
pub const PRIi64 = __PRI64 ++ "i";
pub const PRIiLEAST8 = "i";
pub const PRIiLEAST16 = "i";
pub const PRIiLEAST32 = "i";
pub const PRIiLEAST64 = __PRI64 ++ "i";
pub const PRIiFAST8 = "i";
pub const PRIiFAST16 = "i";
pub const PRIiFAST32 = "i";
pub const PRIiFAST64 = __PRI64 ++ "i";
pub const PRIiMAX = "ji";
pub const PRIiPTR = __PRIptr ++ "i";
pub const PRIo8 = "o";
pub const PRIo16 = "o";
pub const PRIo32 = "o";
pub const PRIo64 = __PRI64 ++ "o";
pub const PRIoLEAST8 = "o";
pub const PRIoLEAST16 = "o";
pub const PRIoLEAST32 = "o";
pub const PRIoLEAST64 = __PRI64 ++ "o";
pub const PRIoFAST8 = "o";
pub const PRIoFAST16 = "o";
pub const PRIoFAST32 = "o";
pub const PRIoFAST64 = __PRI64 ++ "o";
pub const PRIoMAX = "jo";
pub const PRIoPTR = __PRIptr ++ "o";
pub const PRIu8 = "u";
pub const PRIu16 = "u";
pub const PRIu32 = "u";
pub const PRIu64 = __PRI64 ++ "u";
pub const PRIuLEAST8 = "u";
pub const PRIuLEAST16 = "u";
pub const PRIuLEAST32 = "u";
pub const PRIuLEAST64 = __PRI64 ++ "u";
pub const PRIuFAST8 = "u";
pub const PRIuFAST16 = "u";
pub const PRIuFAST32 = "u";
pub const PRIuFAST64 = __PRI64 ++ "u";
pub const PRIuMAX = "ju";
pub const PRIuPTR = __PRIptr ++ "u";
pub const PRIx8 = "x";
pub const PRIx16 = "x";
pub const PRIx32 = "x";
pub const PRIx64 = __PRI64 ++ "x";
pub const PRIxLEAST8 = "x";
pub const PRIxLEAST16 = "x";
pub const PRIxLEAST32 = "x";
pub const PRIxLEAST64 = __PRI64 ++ "x";
pub const PRIxFAST8 = "x";
pub const PRIxFAST16 = "x";
pub const PRIxFAST32 = "x";
pub const PRIxFAST64 = __PRI64 ++ "x";
pub const PRIxMAX = "jx";
pub const PRIxPTR = __PRIptr ++ "x";
pub const PRIX8 = "X";
pub const PRIX16 = "X";
pub const PRIX32 = "X";
pub const PRIX64 = __PRI64 ++ "X";
pub const PRIXLEAST8 = "X";
pub const PRIXLEAST16 = "X";
pub const PRIXLEAST32 = "X";
pub const PRIXLEAST64 = __PRI64 ++ "X";
pub const PRIXFAST8 = "X";
pub const PRIXFAST16 = "X";
pub const PRIXFAST32 = "X";
pub const PRIXFAST64 = __PRI64 ++ "X";
pub const PRIXMAX = "jX";
pub const PRIXPTR = __PRIptr ++ "X";
pub const SCNd8 = "hhd";
pub const SCNd16 = "hd";
pub const SCNd32 = "d";
pub const SCNd64 = __PRI64 ++ "d";
pub const SCNdLEAST8 = "hhd";
pub const SCNdLEAST16 = "hd";
pub const SCNdLEAST32 = "d";
pub const SCNdLEAST64 = __PRI64 ++ "d";
pub const SCNdFAST8 = "d";
pub const SCNdFAST16 = "d";
pub const SCNdFAST32 = "d";
pub const SCNdFAST64 = __PRI64 ++ "d";
pub const SCNdMAX = "jd";
pub const SCNdPTR = __PRIptr ++ "d";
pub const SCNi8 = "hhi";
pub const SCNi16 = "hi";
pub const SCNi32 = "i";
pub const SCNi64 = __PRI64 ++ "i";
pub const SCNiLEAST8 = "hhi";
pub const SCNiLEAST16 = "hi";
pub const SCNiLEAST32 = "i";
pub const SCNiLEAST64 = __PRI64 ++ "i";
pub const SCNiFAST8 = "i";
pub const SCNiFAST16 = "i";
pub const SCNiFAST32 = "i";
pub const SCNiFAST64 = __PRI64 ++ "i";
pub const SCNiMAX = "ji";
pub const SCNiPTR = __PRIptr ++ "i";
pub const SCNo8 = "hho";
pub const SCNo16 = "ho";
pub const SCNo32 = "o";
pub const SCNo64 = __PRI64 ++ "o";
pub const SCNoLEAST8 = "hho";
pub const SCNoLEAST16 = "ho";
pub const SCNoLEAST32 = "o";
pub const SCNoLEAST64 = __PRI64 ++ "o";
pub const SCNoFAST8 = "o";
pub const SCNoFAST16 = "o";
pub const SCNoFAST32 = "o";
pub const SCNoFAST64 = __PRI64 ++ "o";
pub const SCNoMAX = "jo";
pub const SCNoPTR = __PRIptr ++ "o";
pub const SCNu8 = "hhu";
pub const SCNu16 = "hu";
pub const SCNu32 = "u";
pub const SCNu64 = __PRI64 ++ "u";
pub const SCNuLEAST8 = "hhu";
pub const SCNuLEAST16 = "hu";
pub const SCNuLEAST32 = "u";
pub const SCNuLEAST64 = __PRI64 ++ "u";
pub const SCNuFAST8 = "u";
pub const SCNuFAST16 = "u";
pub const SCNuFAST32 = "u";
pub const SCNuFAST64 = __PRI64 ++ "u";
pub const SCNuMAX = "ju";
pub const SCNuPTR = __PRIptr ++ "u";
pub const SCNx8 = "hhx";
pub const SCNx16 = "hx";
pub const SCNx32 = "x";
pub const SCNx64 = __PRI64 ++ "x";
pub const SCNxLEAST8 = "hhx";
pub const SCNxLEAST16 = "hx";
pub const SCNxLEAST32 = "x";
pub const SCNxLEAST64 = __PRI64 ++ "x";
pub const SCNxFAST8 = "x";
pub const SCNxFAST16 = "x";
pub const SCNxFAST32 = "x";
pub const SCNxFAST64 = __PRI64 ++ "x";
pub const SCNxMAX = "jx";
pub const SCNxPTR = __PRIptr ++ "x";
pub const _WCHAR_T_DECLARED = "";
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
pub const WL_EXPORT = @compileError("unable to translate macro: undefined identifier `visibility`");
// /usr/local/include/wayland-util.h:45:9
pub const WL_DEPRECATED = @compileError("unable to translate macro: undefined identifier `deprecated`");
// /usr/local/include/wayland-util.h:54:9
pub const WL_PRINTF = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/local/include/wayland-util.h:68:9
pub const WL_TYPEOF = @compileError("unable to translate C expr: unexpected token '__typeof__'");
// /usr/local/include/wayland-util.h:76:9
pub const WL_MAX_MESSAGE_SIZE = @as(c_int, 4096);
pub inline fn wl_container_of(ptr: anytype, sample: anytype, member: anytype) @TypeOf(WL_TYPEOF(sample)(@import("std").zig.c_translation.cast([*c]u8, ptr) - offsetof(WL_TYPEOF(sample.*), member))) {
    _ = &ptr;
    _ = &sample;
    _ = &member;
    return WL_TYPEOF(sample)(@import("std").zig.c_translation.cast([*c]u8, ptr) - offsetof(WL_TYPEOF(sample.*), member));
}
pub const wl_list_for_each = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/local/include/wayland-util.h:458:9
pub const wl_list_for_each_safe = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/local/include/wayland-util.h:478:9
pub const wl_list_for_each_reverse = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/local/include/wayland-util.h:496:9
pub const wl_list_for_each_reverse_safe = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/local/include/wayland-util.h:516:9
pub const wl_array_for_each = @compileError("unable to translate C expr: unexpected token 'for'");
// /usr/local/include/wayland-util.h:607:9
pub const WAYLAND_VERSION_H = "";
pub const WAYLAND_VERSION_MAJOR = @as(c_int, 1);
pub const WAYLAND_VERSION_MINOR = @as(c_int, 24);
pub const WAYLAND_VERSION_MICRO = @as(c_int, 0);
pub const WAYLAND_VERSION = "1.24.0";
pub const WL_MARSHAL_FLAG_DESTROY = @as(c_int, 1) << @as(c_int, 0);
pub const _SYS_MMAN_H_ = "";
pub const INHERIT_SHARE = @as(c_int, 0);
pub const INHERIT_COPY = @as(c_int, 1);
pub const INHERIT_NONE = @as(c_int, 2);
pub const INHERIT_ZERO = @as(c_int, 3);
pub const PROT_NONE = @as(c_int, 0x00);
pub const PROT_READ = @as(c_int, 0x01);
pub const PROT_WRITE = @as(c_int, 0x02);
pub const PROT_EXEC = @as(c_int, 0x04);
pub const PROT_CHERI0 = @as(c_int, 0x08);
pub const PROT_CHERI1 = @as(c_int, 0x10);
pub const _PROT_ALL = (PROT_READ | PROT_WRITE) | PROT_EXEC;
pub inline fn PROT_EXTRACT(prot: anytype) @TypeOf(prot & _PROT_ALL) {
    _ = &prot;
    return prot & _PROT_ALL;
}
pub const _PROT_MAX_SHIFT = @as(c_int, 16);
pub inline fn PROT_MAX(prot: anytype) @TypeOf(prot << _PROT_MAX_SHIFT) {
    _ = &prot;
    return prot << _PROT_MAX_SHIFT;
}
pub inline fn PROT_MAX_EXTRACT(prot: anytype) @TypeOf((prot >> _PROT_MAX_SHIFT) & _PROT_ALL) {
    _ = &prot;
    return (prot >> _PROT_MAX_SHIFT) & _PROT_ALL;
}
pub const MAP_SHARED = @as(c_int, 0x0001);
pub const MAP_PRIVATE = @as(c_int, 0x0002);
pub const MAP_COPY = MAP_PRIVATE;
pub const MAP_FIXED = @as(c_int, 0x0010);
pub const MAP_RESERVED0020 = @as(c_int, 0x0020);
pub const MAP_RESERVED0040 = @as(c_int, 0x0040);
pub const MAP_RESERVED0080 = @as(c_int, 0x0080);
pub const MAP_RESERVED0100 = @as(c_int, 0x0100);
pub const MAP_HASSEMAPHORE = @as(c_int, 0x0200);
pub const MAP_STACK = @as(c_int, 0x0400);
pub const MAP_NOSYNC = @as(c_int, 0x0800);
pub const MAP_FILE = @as(c_int, 0x0000);
pub const MAP_ANON = @as(c_int, 0x1000);
pub const MAP_ANONYMOUS = MAP_ANON;
pub const MAP_GUARD = @as(c_int, 0x00002000);
pub const MAP_EXCL = @as(c_int, 0x00004000);
pub const MAP_NOCORE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00020000, .hex);
pub const MAP_PREFAULT_READ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00040000, .hex);
pub const MAP_32BIT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hex);
pub inline fn MAP_ALIGNED(n: anytype) @TypeOf(n << MAP_ALIGNMENT_SHIFT) {
    _ = &n;
    return n << MAP_ALIGNMENT_SHIFT;
}
pub const MAP_ALIGNMENT_SHIFT = @as(c_int, 24);
pub const MAP_ALIGNMENT_MASK = MAP_ALIGNED(@as(c_int, 0xff));
pub const MAP_ALIGNED_SUPER = MAP_ALIGNED(@as(c_int, 1));
pub const SHM_RENAME_NOREPLACE = @as(c_int, 1) << @as(c_int, 0);
pub const SHM_RENAME_EXCHANGE = @as(c_int, 1) << @as(c_int, 1);
pub const MCL_CURRENT = @as(c_int, 0x0001);
pub const MCL_FUTURE = @as(c_int, 0x0002);
pub const MAP_FAILED = @import("std").zig.c_translation.cast(?*anyopaque, -@as(c_int, 1));
pub const MS_SYNC = @as(c_int, 0x0000);
pub const MS_ASYNC = @as(c_int, 0x0001);
pub const MS_INVALIDATE = @as(c_int, 0x0002);
pub const _MADV_NORMAL = @as(c_int, 0);
pub const _MADV_RANDOM = @as(c_int, 1);
pub const _MADV_SEQUENTIAL = @as(c_int, 2);
pub const _MADV_WILLNEED = @as(c_int, 3);
pub const _MADV_DONTNEED = @as(c_int, 4);
pub const MADV_NORMAL = _MADV_NORMAL;
pub const MADV_RANDOM = _MADV_RANDOM;
pub const MADV_SEQUENTIAL = _MADV_SEQUENTIAL;
pub const MADV_WILLNEED = _MADV_WILLNEED;
pub const MADV_DONTNEED = _MADV_DONTNEED;
pub const MADV_FREE = @as(c_int, 5);
pub const MADV_NOSYNC = @as(c_int, 6);
pub const MADV_AUTOSYNC = @as(c_int, 7);
pub const MADV_NOCORE = @as(c_int, 8);
pub const MADV_CORE = @as(c_int, 9);
pub const MADV_PROTECT = @as(c_int, 10);
pub const MINCORE_INCORE = @as(c_int, 0x1);
pub const MINCORE_REFERENCED = @as(c_int, 0x2);
pub const MINCORE_MODIFIED = @as(c_int, 0x4);
pub const MINCORE_REFERENCED_OTHER = @as(c_int, 0x8);
pub const MINCORE_MODIFIED_OTHER = @as(c_int, 0x10);
pub const MINCORE_SUPER = @as(c_int, 0x60);
pub const MINCORE_PSIND_SHIFT = @as(c_int, 5);
pub inline fn MINCORE_PSIND(i: anytype) @TypeOf((i << MINCORE_PSIND_SHIFT) & MINCORE_SUPER) {
    _ = &i;
    return (i << MINCORE_PSIND_SHIFT) & MINCORE_SUPER;
}
pub const SHM_ANON = @import("std").zig.c_translation.cast([*c]u8, @as(c_int, 1));
pub const SHM_ALLOW_SEALING = @as(c_int, 0x00000001);
pub const SHM_GROW_ON_WRITE = @as(c_int, 0x00000002);
pub const SHM_LARGEPAGE = @as(c_int, 0x00000004);
pub const SHM_LARGEPAGE_ALLOC_DEFAULT = @as(c_int, 0);
pub const SHM_LARGEPAGE_ALLOC_NOWAIT = @as(c_int, 1);
pub const SHM_LARGEPAGE_ALLOC_HARD = @as(c_int, 2);
pub const MFD_CLOEXEC = @as(c_int, 0x00000001);
pub const MFD_ALLOW_SEALING = @as(c_int, 0x00000002);
pub const MFD_HUGETLB = @as(c_int, 0x00000004);
pub const MFD_HUGE_MASK = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFC000000, .hex);
pub const MFD_HUGE_SHIFT = @as(c_int, 26);
pub const MFD_HUGE_64KB = @as(c_int, 16) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_512KB = @as(c_int, 19) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_1MB = @as(c_int, 20) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_2MB = @as(c_int, 21) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_8MB = @as(c_int, 23) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_16MB = @as(c_int, 24) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_32MB = @as(c_int, 25) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_256MB = @as(c_int, 28) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_512MB = @as(c_int, 29) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_1GB = @as(c_int, 30) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_2GB = @as(c_int, 31) << MFD_HUGE_SHIFT;
pub const MFD_HUGE_16GB = @as(c_int, 34) << MFD_HUGE_SHIFT;
pub const POSIX_MADV_NORMAL = _MADV_NORMAL;
pub const POSIX_MADV_RANDOM = _MADV_RANDOM;
pub const POSIX_MADV_SEQUENTIAL = _MADV_SEQUENTIAL;
pub const POSIX_MADV_WILLNEED = _MADV_WILLNEED;
pub const POSIX_MADV_DONTNEED = _MADV_DONTNEED;
pub const _MODE_T_DECLARED = "";
pub const _OFF_T_DECLARED = "";
pub const _SIZE_T_DECLARED = "";
pub const _MMAP_DECLARED = "";
pub const _UNISTD_H_ = "";
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
pub const _ACCMODE_T_DECLARED = "";
pub const _NLINK_T_DECLARED = "";
pub const _OFF64_T_DECLARED = "";
pub const _PID_T_DECLARED = "";
pub const _RLIM_T_DECLARED = "";
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
pub const _SSP_SSP_H_ = "";
pub const __SSP_FORTIFY_LEVEL = @as(c_int, 2);
pub const __ssp_var = @compileError("unable to translate macro: undefined identifier `__ssp_`");
// /usr/include/ssp/ssp.h:54:9
pub const __ssp_real_ = @compileError("unable to translate C expr: unexpected token '##'");
// /usr/include/ssp/ssp.h:60:9
pub inline fn __ssp_real(fun: anytype) @TypeOf(__ssp_real_(fun)) {
    _ = &fun;
    return __ssp_real_(fun);
}
pub const __ssp_inline = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// /usr/include/ssp/ssp.h:64:9
pub inline fn __ssp_bos(ptr: anytype) @TypeOf(__builtin_object_size(ptr, __SSP_FORTIFY_LEVEL > @as(c_int, 1))) {
    _ = &ptr;
    return __builtin_object_size(ptr, __SSP_FORTIFY_LEVEL > @as(c_int, 1));
}
pub inline fn __ssp_bos0(ptr: anytype) @TypeOf(__builtin_object_size(ptr, @as(c_int, 0))) {
    _ = &ptr;
    return __builtin_object_size(ptr, @as(c_int, 0));
}
pub const __ssp_check = @compileError("unable to translate C expr: unexpected token 'if'");
// /usr/include/ssp/ssp.h:69:9
pub const __ssp_redirect_raw_impl = @compileError("unable to translate macro: undefined identifier `__ssp_protected_`");
// /usr/include/ssp/ssp.h:73:9
pub const __ssp_redirect_raw = @compileError("unable to translate macro: undefined identifier `__buf`");
// /usr/include/ssp/ssp.h:78:9
pub const __ssp_redirect = @compileError("unable to translate macro: undefined identifier `__len`");
// /usr/include/ssp/ssp.h:85:9
pub const __ssp_redirect0 = @compileError("unable to translate macro: undefined identifier `__len`");
// /usr/include/ssp/ssp.h:87:9
pub const _SYS__IOVEC_H_ = "";
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
pub const __enum_uint8_decl = @compileError("unable to translate macro: undefined identifier `enum_`");
// /usr/include/sys/types.h:352:9
pub const __enum_uint8 = @compileError("unable to translate macro: undefined identifier `enum_`");
// /usr/include/sys/types.h:353:9
pub const _FTRUNCATE_DECLARED = "";
pub const _LSEEK_DECLARED = "";
pub const _TRUNCATE_DECLARED = "";
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
pub const _POSIX_VDISABLE = @as(c_int, 0xff);
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
pub const _SSP_UNISTD_H_ = "";
pub const _FORTIFY_SOURCE_read = read;
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
pub const __timer = struct___timer;
pub const __mq = struct___mq;
pub const __infinity_un = union___infinity_un;
pub const __nan_un = union___nan_un;
pub const wl_object = struct_wl_object;
pub const wl_interface = struct_wl_interface;
pub const wl_message = struct_wl_message;
pub const wl_list = struct_wl_list;
pub const wl_array = struct_wl_array;
pub const wl_argument = union_wl_argument;
pub const wl_iterator_result = enum_wl_iterator_result;
pub const timespec = struct_timespec;
pub const wl_proxy = struct_wl_proxy;
pub const wl_display = struct_wl_display;
pub const wl_event_queue = struct_wl_event_queue;
pub const shm_largepage_conf = struct_shm_largepage_conf;
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
pub const itimerspec = struct_itimerspec;
pub const iovec = struct_iovec;
pub const crypt_data = struct_crypt_data;
pub const __oflock = struct___oflock;
pub const spacectl_range = struct_spacectl_range;
