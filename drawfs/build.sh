#!/bin/sh
#
# drawfs build helper
#
# Goals:
#   - Make repo -> /usr/src installation reproducible
#   - Avoid "stale /usr/src tree" issues during iteration
#
# DRM/KMS support:
#   The DRM/KMS backend (drawfs_drm.c) is OPTIONAL and excluded from the
#   default build. To enable it, either:
#     - Export DRAWFS_DRM=true before running this script, or
#     - Set DRAWFS_DRM=true in UTF/.config (see configure.sh)
#   When disabled (default), drawfs.ko contains no DRM symbols and has
#   no drm-kmod build or runtime dependency.
#
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# OS detection — prefer env-inherited values from the parent build.sh /
# install.sh, fall back to local detection when run standalone.
if [ -z "${UTF_OS:-}" ]; then
    . "$REPO_ROOT/../scripts/detect-os.sh"
fi

SRCROOT=${SRCROOT:-/usr/src}

DEVDEST="$SRCROOT/sys/dev/drawfs"
MODDEST="$SRCROOT/sys/modules/drawfs"
KMODDIR="$MODDEST"

# ---------------------------------------------------------------------------
# DRM gating
#
# The kernel Makefile uses make(1) variables (not cpp macros) to decide
# whether to compile drawfs_drm.c. We translate the shell boolean into a
# MAKEFLAGS setting that both the dev and modules Makefiles observe. The
# C-side macro name is DRAWFS_DRM_ENABLED (preserved — it already appears
# in #ifdef blocks in drawfs.c). The build-system name is DRAWFS_DRM.
# ---------------------------------------------------------------------------

# Inherit DRAWFS_DRM from environment; fall back to reading the root .config.
DRAWFS_DRM="${DRAWFS_DRM:-}"
if [ -z "$DRAWFS_DRM" ]; then
    UTF_CONFIG="$REPO_ROOT/../.config"
    if [ -f "$UTF_CONFIG" ]; then
        # shellcheck disable=SC1090
        . "$UTF_CONFIG"
        DRAWFS_DRM="${DRAWFS_DRM:-false}"
    else
        DRAWFS_DRM=false
    fi
fi

# Build the make(1) flag set. Empty string = pure swap build.
# The [OS] tag in the banner helps in build logs when .config has been
# moved between a FreeBSD and a GhostBSD host.
if [ "$DRAWFS_DRM" = "true" ]; then
    DRM_MAKE_FLAGS="DRAWFS_DRM_ENABLED=1"
    DRM_BANNER="[DRM/KMS backend: ENABLED — requires drm-kmod headers] [${UTF_OS:-unknown}]"
else
    DRM_MAKE_FLAGS=""
    DRM_BANNER="[DRM/KMS backend: disabled (default, swap-only)] [${UTF_OS:-unknown}]"
fi

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script must run as root."
    echo "Try: sudo $0 $*"
    exit 1
  fi
}

usage() {
  cat <<'USAGE'
Usage:
  sudo ./build.sh install
  sudo ./build.sh build
  sudo ./build.sh deploy
  sudo ./build.sh load
  sudo ./build.sh unload
  sudo ./build.sh test [tests/stepXX_*.py]
  sudo ./build.sh all [tests/stepXX_*.py]
  ./build.sh verify
  ./build.sh help

Commands:
  install  Copy drawfs sources into /usr/src kernel tree
  build    Compile drawfs.ko from kernel sources
  deploy   Install drawfs.ko to /boot/modules/ (run after build)
  load     Load drawfs.ko from build directory (for testing)
  unload   Unload drawfs kernel module
  test     Run Python integration tests
  all      install + build + deploy + load + test
  verify   Check source and build state without changing anything

Environment:
  SRCROOT=/usr/src   Root of FreeBSD source tree (default: /usr/src)
  DRAWFS_DRM=true    Build with optional DRM/KMS backend (default: false)
USAGE
}

cmd=${1:-help}
shift || true

case "$cmd" in
  help|-h|--help)
    usage
    ;;

  install)
    need_root "$cmd"
    echo "Installing drawfs sources into $SRCROOT"
    echo "$DRM_BANNER"
    mkdir -p "$DEVDEST" "$MODDEST"
    rsync -a --delete "$REPO_ROOT/sys/dev/drawfs/" "$DEVDEST/"
    rsync -a --delete "$REPO_ROOT/sys/modules/drawfs/" "$MODDEST/"
    echo "OK: install"
    ;;

  build)
    need_root "$cmd"
    echo "Building kernel module in $KMODDIR"
    echo "$DRM_BANNER"
    # DRM_MAKE_FLAGS is intentionally unquoted: empty string must vanish,
    # and "DRAWFS_DRM_ENABLED=1" must be a single argv entry.
    ( cd "$KMODDIR" && make clean && make $DRM_MAKE_FLAGS )
    echo "OK: build"
    ;;

  load)
    need_root "$cmd"
    OBJDIR=$(make -C "$KMODDIR" $DRM_MAKE_FLAGS -V .OBJDIR)
    KO="$OBJDIR/drawfs.ko"
    if [ ! -f "$KO" ]; then
      echo "ERROR: missing $KO"
      echo "Run: sudo ./build.sh build"
      exit 1
    fi
    echo "Loading $KO"
    kldunload drawfs 2>/dev/null || true
    kldload "$KO"
    echo "OK: load"
    ;;

  deploy)
    need_root "$cmd"
    echo "Installing drawfs.ko to /boot/modules/"
    echo "$DRM_BANNER"

    # Find the built module
    KO=""

    # Try make install first (cleanest approach)
    if ( cd "$KMODDIR" && make $DRM_MAKE_FLAGS install ) 2>/dev/null; then
        echo "OK: deploy (via make install)"
        kldxref /boot/modules
        echo ""
        echo "To load now:       kldload drawfs"
        echo "To load at boot:   echo 'drawfs_load=\"YES\"' >> /boot/loader.conf"
        exit 0
    fi

    # Fall back to locating the .ko manually
    OBJDIR=$(make -C "$KMODDIR" $DRM_MAKE_FLAGS -V .OBJDIR 2>/dev/null || echo "")
    if [ -n "$OBJDIR" ] && [ -f "$OBJDIR/drawfs.ko" ]; then
        KO="$OBJDIR/drawfs.ko"
    fi

    # Last resort: search common FreeBSD obj tree locations
    if [ -z "$KO" ]; then
        for candidate in \
            /usr/obj/usr/src/amd64.amd64/sys/modules/drawfs/drawfs.ko \
            /usr/obj/usr/src/arm64.aarch64/sys/modules/drawfs/drawfs.ko \
            /usr/obj/usr/src/sys/modules/drawfs/drawfs.ko
        do
            if [ -f "$candidate" ]; then
                KO="$candidate"
                break
            fi
        done
    fi

    # Search anywhere under /usr/obj as a final fallback
    if [ -z "$KO" ]; then
        KO=$(find /usr/obj -name "drawfs.ko" 2>/dev/null | head -1)
    fi

    if [ -z "$KO" ] || [ ! -f "$KO" ]; then
        echo "ERROR: drawfs.ko not found — run: sudo ./build.sh build"
        exit 1
    fi

    echo "Found: $KO"
    cp "$KO" /boot/modules/drawfs.ko
    kldxref /boot/modules
    echo "OK: deploy"
    echo ""
    echo "To load now:       kldload drawfs"
    echo "To load at boot:   echo 'drawfs_load=\"YES\"' >> /boot/loader.conf"
    ;;

  unload)
    need_root "$cmd"
    kldunload drawfs 2>/dev/null || true
    echo "OK: unload"
    ;;

  test)
    need_root "$cmd"
    testfile=${1:-tests/step11_surface_mmap_test.py}
    if [ ! -f "$REPO_ROOT/$testfile" ]; then
      echo "ERROR: test file not found: $testfile"
      exit 1
    fi
    echo "Running $testfile"
    ( cd "$REPO_ROOT" && python3 "$testfile" )
    echo "OK: test"
    ;;

  all)
    need_root "$cmd"
    testfile=${1:-tests/step11_surface_mmap_test.py}
    "$0" install
    "$0" build
    "$0" deploy
    "$0" load
    "$0" test "$testfile"
    ;;

  verify)
    echo "Repo root: $REPO_ROOT"
    echo "SRCROOT:   $SRCROOT"
    echo "Host OS:   ${UTF_OS:-unknown} ${UTF_OS_VERSION:-}"
    echo "$DRM_BANNER"
    echo
    echo "Repo dev drawfs.c:"
    ls -l "$REPO_ROOT/sys/dev/drawfs/drawfs.c" 2>/dev/null || echo "  not found"
    echo "Installed dev drawfs.c:"
    ls -l "$DEVDEST/drawfs.c" 2>/dev/null || echo "  not found"
    echo
    echo "Installed symbol check (surface_present):"
    if [ -f "$DEVDEST/drawfs.c" ]; then
      grep -n "drawfs_reply_surface_present" "$DEVDEST/drawfs.c" || true
    fi
    echo
    echo "Module OBJDIR:"
    OBJDIR=$(make -C "$KMODDIR" $DRM_MAKE_FLAGS -V .OBJDIR 2>/dev/null || echo "unknown")
    echo "  $OBJDIR"
    echo "Built module:"
    ls -l "$OBJDIR/drawfs.ko" 2>/dev/null || echo "  not found — run: sudo ./build.sh build"
    echo "/boot/modules/drawfs.ko:"
    ls -l /boot/modules/drawfs.ko 2>/dev/null || echo "  not found — run: sudo ./build.sh deploy"
    echo "Loaded:"
    kldstat 2>/dev/null | grep drawfs || echo "  not loaded"
    ;;

  *)
    echo "Unknown command: $cmd"
    echo
    usage
    exit 2
    ;;
esac
