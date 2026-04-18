#!/bin/sh
# UTF build wrapper — runs zig build and tees output to a log file.
#
# Usage:
#   sh build.sh                    # build all subprojects
#   sh build.sh -Dx11=true         # pass flags to zig build
#   sh build.sh test               # run all test suites
#
# Log file: build-YYYYMMDD-HHMMSS.log in the UTF root directory.
# Symlink:  build-latest.log always points to the most recent log.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$SCRIPT_DIR/build-${TIMESTAMP}.log"
LATEST="$SCRIPT_DIR/build-latest.log"

echo "UTF build — $(date)"
echo "Log: $LOG"
echo ""

# Run zig build, tee stdout+stderr to log file
{
    echo "=== UTF build ==="
    echo "Date:      $(date)"
    echo "Host:      $(uname -n)"
    echo "OS:        $(uname -sr)"
    echo "Zig:       $(zig version 2>/dev/null || echo 'not found')"
    echo "Args:      $*"
    echo ""

    cd "$SCRIPT_DIR"
    zig build "$@" 2>&1
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
