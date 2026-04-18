#!/bin/sh
#
# drawfs build helper
#
# Goals:
#   - Make repo -> /usr/src installation reproducible
#   - Avoid "stale /usr/src tree" issues during iteration
#
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRCROOT=${SRCROOT:-/usr/src}

DEVDEST="$SRCROOT/sys/dev/drawfs"
MODDEST="$SRCROOT/sys/modules/drawfs"
KMODDIR="$MODDEST"

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
    mkdir -p "$DEVDEST" "$MODDEST"
    rsync -a --delete "$REPO_ROOT/sys/dev/drawfs/" "$DEVDEST/"
    rsync -a --delete "$REPO_ROOT/sys/modules/drawfs/" "$MODDEST/"
    echo "OK: install"
    ;;

  build)
    need_root "$cmd"
    echo "Building kernel module in $KMODDIR"
    ( cd "$KMODDIR" && make clean && make )
    echo "OK: build"
    ;;

  load)
    need_root "$cmd"
    OBJDIR=$(make -C "$KMODDIR" -V .OBJDIR)
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

    # Find the built module
    KO=""

    # Try make install first (cleanest approach)
    if ( cd "$KMODDIR" && make install ) 2>/dev/null; then
        echo "OK: deploy (via make install)"
        kldxref /boot/modules
        echo ""
        echo "To load now:       kldload drawfs"
        echo "To load at boot:   echo 'drawfs_load=\"YES\"' >> /boot/loader.conf"
        exit 0
    fi

    # Fall back to locating the .ko manually
    OBJDIR=$(make -C "$KMODDIR" -V .OBJDIR 2>/dev/null || echo "")
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
    OBJDIR=$(make -C "$KMODDIR" -V .OBJDIR 2>/dev/null || echo "unknown")
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
