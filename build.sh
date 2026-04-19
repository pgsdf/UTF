#!/bin/sh
# UTF build wrapper — runs zig build and tees output to a log file.
#
# Usage:
#   sh build.sh                    # build all subprojects
#   sh build.sh -Dx11=true         # pass flags to zig build
#   sh build.sh test               # run all test suites
#   sh build.sh --check            # verify dependencies only, do not build
#
# Log file: build-YYYYMMDD-HHMMSS.log in the UTF root directory.
# Symlink:  build-latest.log always points to the most recent log.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Re-detect OS at build time rather than trusting .config. Catches the case
# where .config was generated on a different host and copied over. The
# detection is fast and has no side effects.
. "$SCRIPT_DIR/scripts/detect-os.sh"
BUILD_HOST_OS="$UTF_OS"
BUILD_HOST_OS_VERSION="$UTF_OS_VERSION"

# Handle --check before setting up the log
if [ "${1:-}" = "--check" ]; then
    echo "=== UTF dependency check ==="
    OK=1
    if command -v zig >/dev/null 2>&1; then
        echo "  ok  zig $(zig version)"
    else
        echo "  MISSING  zig — install from https://ziglang.org/download/"
        OK=0
    fi
    echo "  ok  host: $BUILD_HOST_OS $BUILD_HOST_OS_VERSION"
    if [ -f "$SCRIPT_DIR/.config" ]; then
        echo "  ok  .config found"
        cat "$SCRIPT_DIR/.config"
    else
        echo "  --  .config not found (run: sh configure.sh)"
    fi
    [ "$OK" -eq 1 ] && echo "All dependencies present." || echo "Missing dependencies."
    exit $((1 - OK))
fi
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$SCRIPT_DIR/build-${TIMESTAMP}.log"
LATEST="$SCRIPT_DIR/build-latest.log"

# Read configuration from .config if present and no args given
CONFIG="$SCRIPT_DIR/.config"
BUILD_FLAGS=""
# DRAWFS_DRM is exported so that drawfs/build.sh and any nested make(1)
# invocations see it without us having to plumb it through every call site.
# Default: unset/false → swap-only kernel build with zero DRM references.
DRAWFS_DRM="${DRAWFS_DRM:-false}"
# Preserve any UTF_OS the caller set in the environment before we overwrite
# it from .config; we use it below to detect a stale .config.
CONFIG_UTF_OS=""
if [ -f "$CONFIG" ] && [ $# -eq 0 ]; then
    . "$CONFIG"
    [ "${SEMADRAW_VULKAN:-false}"  = "true" ] && BUILD_FLAGS="$BUILD_FLAGS -Dvulkan=true"
    [ "${SEMADRAW_VULKAN:-false}"  = "false" ] && BUILD_FLAGS="$BUILD_FLAGS -Dvulkan=false"
    [ "${SEMADRAW_X11:-false}"     = "true" ] && BUILD_FLAGS="$BUILD_FLAGS -Dx11=true"
    [ "${SEMADRAW_WAYLAND:-false}" = "true" ] && BUILD_FLAGS="$BUILD_FLAGS -Dwayland=true"
    [ "${SEMADRAW_BSDINPUT:-false}" = "true" ] && BUILD_FLAGS="$BUILD_FLAGS -Dbsdinput=true"
    [ "${SEMADRAW_BSDINPUT:-false}" = "false" ] && BUILD_FLAGS="$BUILD_FLAGS -Dbsdinput=false"
    # DRAWFS_DRM does not go through zig build; it's consumed only by the
    # kernel Makefiles via drawfs/build.sh. Export it for child processes.
    DRAWFS_DRM="${DRAWFS_DRM:-false}"
    # Record the UTF_OS .config claimed, for the stale-config warning below.
    CONFIG_UTF_OS="${UTF_OS:-}"
fi
export DRAWFS_DRM

# Warn loudly if .config claims a different OS family than the host we're
# actually running on. .config may have been copied from another machine.
# We then force UTF_OS back to the detected value for the rest of this run.
if [ -n "$CONFIG_UTF_OS" ] && [ "$CONFIG_UTF_OS" != "$BUILD_HOST_OS" ] \
   && [ "$CONFIG_UTF_OS" != "unknown" ] && [ "$BUILD_HOST_OS" != "unknown" ]; then
    echo "WARNING: .config records UTF_OS=$CONFIG_UTF_OS but this host is $BUILD_HOST_OS."
    echo "         .config may have been copied from another machine."
    echo "         Re-run: sh configure.sh"
    echo ""
fi
export UTF_OS="$BUILD_HOST_OS"
export UTF_OS_VERSION="$BUILD_HOST_OS_VERSION"

echo "UTF build — $(date)"
echo "Log: $LOG"
echo ""

# Run zig build, tee stdout+stderr to log file
{
    echo "=== UTF build ==="
    echo "Date:      $(date)"
    echo "Host:      $(uname -n)"
    echo "OS:        $(uname -sr)"
    echo "OS family: $BUILD_HOST_OS $BUILD_HOST_OS_VERSION"
    echo "Zig:       $(zig version 2>/dev/null || echo 'not found')"
    echo "Config:    ${CONFIG} ($([ -f "$CONFIG" ] && echo found || echo not found))"
    echo "Flags:     ${BUILD_FLAGS:-none}"
    echo "DRAWFS_DRM:${DRAWFS_DRM}"
    echo "Args:      $*"
    echo ""

    cd "$SCRIPT_DIR"
    zig build $BUILD_FLAGS "$@" 2>&1
    STATUS=$?

    echo ""
    if [ $STATUS -eq 0 ]; then
        echo "=== BUILD SUCCEEDED ==="
    else
        echo "=== BUILD FAILED (exit $STATUS) ==="
    fi
    exit $STATUS
} | tee "$LOG"

STATUS=${PIPESTATUS:-$?}

# Update symlink to latest log
ln -sf "$LOG" "$LATEST"

echo ""
echo "Full log: $LOG"
exit $STATUS
