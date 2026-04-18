#!/bin/sh
# UTF startup script — starts all daemons in dependency order.
#
# Startup order:
#   1. semaaud    — publishes audio hardware clock to /var/run/sema/clock
#   2. semainput  — reads clock region for ts_audio_samples timestamping
#   3. semadraw   — reads clock region for frame scheduler
#   4. chrono_dump — optional live timeline viewer
#
# Usage:
#   sh start.sh                        # start all daemons, drawfs backend
#   sh start.sh --backend software     # use software backend
#   sh start.sh --timeline             # pipe output to chrono_dump
#   sh start.sh --stop                 # stop all running UTF daemons

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-/usr/local}"
BACKEND="${BACKEND:-drawfs}"
TIMELINE=0
STOP=0

for arg in "$@"; do
    case "$arg" in
        --backend=*) BACKEND="${arg#--backend=}" ;;
        --backend)   shift; BACKEND="$1" ;;
        --timeline)  TIMELINE=1 ;;
        --stop)      STOP=1 ;;
        --help|-h)
            sed -n '2,15p' "$0" | sed 's/^# \?//'
            exit 0 ;;
    esac
done

# ============================================================================
# Stop
# ============================================================================

if [ "$STOP" -eq 1 ]; then
    echo "=== Stopping UTF daemons ==="
    for daemon in semadrawd semainputd semaaud; do
        if pgrep -x "$daemon" >/dev/null 2>&1; then
            pkill -x "$daemon" && echo "  stopped  $daemon"
        else
            echo "  skip     $daemon (not running)"
        fi
    done
    exit 0
fi

# ============================================================================
# Find binaries — prefer installed, fall back to build directory
# ============================================================================

find_bin() {
    name="$1"
    subdir="$2"
    if [ -x "$PREFIX/bin/$name" ]; then
        echo "$PREFIX/bin/$name"
    elif [ -x "$SCRIPT_DIR/$subdir/zig-out/bin/$name" ]; then
        echo "$SCRIPT_DIR/$subdir/zig-out/bin/$name"
    else
        echo ""
    fi
}

SEMAAUD=$(find_bin semaaud semaaud)
SEMAINPUT=$(find_bin semainputd semainput)
SEMADRAW=$(find_bin semadrawd semadraw)
CHRONO_DUMP=$(find_bin chrono_dump chronofs)

for bin in "$SEMAAUD" "$SEMAINPUT" "$SEMADRAW"; do
    if [ -z "$bin" ]; then
        echo "ERROR: binary not found — run: sh build.sh && sh install.sh" >&2
        exit 1
    fi
done

# ============================================================================
# Start
# ============================================================================

echo "=== Starting UTF ==="
echo "  Backend: $BACKEND"
echo ""

# 1. semaaud — must be first (publishes clock)
echo "Starting semaaud..."
sudo "$SEMAAUD" &
SEMAAUD_PID=$!
sleep 1
echo "  pid $SEMAAUD_PID"

# 2. semainputd — requires semaaud clock
echo "Starting semainputd..."
sudo "$SEMAINPUT" &
SEMAINPUT_PID=$!
sleep 1
echo "  pid $SEMAINPUT_PID"

# 3. semadrawd — requires semaaud clock
echo "Starting semadrawd (backend: $BACKEND)..."
if [ "$TIMELINE" -eq 1 ] && [ -n "$CHRONO_DUMP" ]; then
    echo ""
    echo "=== Live timeline (ctrl-c to stop) ==="
    { sudo "$SEMADRAW" -b "$BACKEND" 2>&1; } | "$CHRONO_DUMP"
else
    sudo "$SEMADRAW" -b "$BACKEND" &
    SEMADRAW_PID=$!
    echo "  pid $SEMADRAW_PID"
    echo ""
    echo "=== UTF running ==="
    echo "  semaaud:    pid $SEMAAUD_PID"
    echo "  semainputd: pid $SEMAINPUT_PID"
    echo "  semadrawd:  pid $SEMADRAW_PID"
    echo ""
    echo "To view timeline: $CHRONO_DUMP"
    echo "To stop:          sh start.sh --stop"
fi
