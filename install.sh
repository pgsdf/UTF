#!/bin/sh
# UTF install script
# Builds all daemons and installs them to PREFIX (default: /usr/local).
#
# Usage:
#   sh install.sh                  # install to /usr/local (requires root)
#   sh install.sh --prefix ~/utf   # install to custom prefix
#   sh install.sh --check          # verify dependencies only
#   sh install.sh --uninstall      # remove installed files
#
# Installed binaries:
#   $PREFIX/bin/semaaud        — audio routing daemon
#   $PREFIX/bin/semainputd    — input classification daemon
#   $PREFIX/bin/semadrawd     — semantic rendering compositor
#   $PREFIX/bin/chrono_dump   — chronofs diagnostic tool

set -eu

# ============================================================================
# Configuration
# ============================================================================

PREFIX="/usr/local"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UNINSTALL=0
CHECK_ONLY=0

BINARIES="semaaud semainputd semadrawd chrono_dump"

# ============================================================================
# Argument parsing
# ============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)
            PREFIX="$2"; shift 2 ;;
        --prefix=*)
            PREFIX="${1#--prefix=}"; shift ;;
        --uninstall)
            UNINSTALL=1; shift ;;
        --check)
            CHECK_ONLY=1; shift ;;
        --help|-h)
            sed -n '2,15p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *)
            echo "unknown argument: $1" >&2; exit 1 ;;
    esac
done

# ============================================================================
# Dependency check
# ============================================================================

check_dep() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: $1 not found — $2" >&2
        return 1
    fi
    echo "  ok  $1 ($(command -v "$1"))"
    return 0
}

echo "=== Checking dependencies ==="
DEPS_OK=1
check_dep zig      "install from https://ziglang.org/download/" || DEPS_OK=0

# Check Zig version
if command -v zig >/dev/null 2>&1; then
    ZIG_VER=$(zig version 2>/dev/null | head -1)
    echo "      version: $ZIG_VER"
fi

if [ "$DEPS_OK" -eq 0 ]; then
    echo "ERROR: missing dependencies, cannot build." >&2
    exit 1
fi

[ "$CHECK_ONLY" -eq 1 ] && { echo "All dependencies present."; exit 0; }

# ============================================================================
# Uninstall
# ============================================================================

if [ "$UNINSTALL" -eq 1 ]; then
    echo "=== Uninstalling from $PREFIX/bin/ ==="
    for bin in $BINARIES; do
        target="$PREFIX/bin/$bin"
        if [ -f "$target" ]; then
            rm -f "$target"
            echo "  removed  $target"
        else
            echo "  skip     $target (not found)"
        fi
    done

    RCDDIR="$PREFIX/etc/rc.d"
    for svc in semaaud semainput semadraw; do
        target="$RCDDIR/$svc"
        if [ -f "$target" ]; then
            rm -f "$target"
            echo "  removed  $target"
        else
            echo "  skip     $target (not found)"
        fi
    done

    echo ""
    echo "=== Disabling daemons in /etc/rc.conf ==="
    sysrc -x semaaud_enable 2>/dev/null  && echo "  removed  semaaud_enable"  || echo "  skip     semaaud_enable (not set)"
    sysrc -x semainput_enable 2>/dev/null && echo "  removed  semainput_enable" || echo "  skip     semainput_enable (not set)"
    sysrc -x semadraw_enable 2>/dev/null  && echo "  removed  semadraw_enable"  || echo "  skip     semadraw_enable (not set)"

    echo ""
    echo "=== Removing drawfs from /boot/loader.conf ==="
    if grep -q "drawfs_load" /boot/loader.conf 2>/dev/null; then
        sed -i '' '/drawfs_load/d' /boot/loader.conf
        echo "  removed  drawfs_load from /boot/loader.conf"
    else
        echo "  skip     drawfs_load (not found)"
    fi

    echo "=== Done ==="
    exit 0
fi

# ============================================================================
# Build
# ============================================================================

echo "=== Building UTF (optimize=ReleaseSafe) ==="

# Build drawfs kernel module first
echo ""
echo "--- Building drawfs kernel module ---"
if [ -f "$SCRIPT_DIR/drawfs/build.sh" ]; then
    sh "$SCRIPT_DIR/drawfs/build.sh" install
    sh "$SCRIPT_DIR/drawfs/build.sh" build
    sh "$SCRIPT_DIR/drawfs/build.sh" deploy
else
    echo "WARNING: drawfs/build.sh not found — skipping kernel module"
fi

# Read backend configuration from .config if present
CONFIG="$SCRIPT_DIR/.config"
SEMADRAW_FLAGS=""
if [ -f "$CONFIG" ]; then
    echo "Reading configuration from $CONFIG"
    . "$CONFIG"
    [ "${SEMADRAW_VULKAN:-false}"   = "true"  ] && SEMADRAW_FLAGS="$SEMADRAW_FLAGS -Dvulkan=true"
    [ "${SEMADRAW_VULKAN:-false}"   = "false" ] && SEMADRAW_FLAGS="$SEMADRAW_FLAGS -Dvulkan=false"
    [ "${SEMADRAW_X11:-false}"      = "true"  ] && SEMADRAW_FLAGS="$SEMADRAW_FLAGS -Dx11=true"
    [ "${SEMADRAW_WAYLAND:-false}"  = "true"  ] && SEMADRAW_FLAGS="$SEMADRAW_FLAGS -Dwayland=true"
    [ "${SEMADRAW_BSDINPUT:-false}" = "true"  ] && SEMADRAW_FLAGS="$SEMADRAW_FLAGS -Dbsdinput=true"
    [ "${SEMADRAW_BSDINPUT:-false}" = "false" ] && SEMADRAW_FLAGS="$SEMADRAW_FLAGS -Dbsdinput=false"
else
    echo "No .config found — using defaults (run sh configure.sh to configure)"
fi

build_sub() {
    name="$1"
    dir="$SCRIPT_DIR/$2"
    shift 2
    echo ""
    echo "--- Building $name ---"
    cd "$dir"
    zig build -Doptimize=ReleaseSafe "$@"
    cd "$SCRIPT_DIR"
}

build_sub "semaaud"   "semaaud"
build_sub "semainput" "semainput"
build_sub "semadraw"  "semadraw"  $SEMADRAW_FLAGS
build_sub "chronofs"  "chronofs"

# ============================================================================
# Install
# ============================================================================

echo ""
echo "=== Installing to $PREFIX/bin/ ==="
mkdir -p "$PREFIX/bin"

install_bin() {
    src="$1"
    dst="$PREFIX/bin/$(basename "$src")"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        chmod 755 "$dst"
        echo "  installed  $dst"
    else
        echo "  WARNING: $src not found — skipping" >&2
    fi
}

install_bin "$SCRIPT_DIR/semaaud/zig-out/bin/semaaud"
install_bin "$SCRIPT_DIR/semainput/zig-out/bin/semainputd"
install_bin "$SCRIPT_DIR/semadraw/zig-out/bin/semadrawd"
install_bin "$SCRIPT_DIR/chronofs/zig-out/bin/chrono_dump"

# ============================================================================
# rc.d scripts (FreeBSD service integration)
# ============================================================================

RCDDIR="$PREFIX/etc/rc.d"
if [ -d /etc/rc.d ] || [ -d "$RCDDIR" ]; then
    echo ""
    echo "=== Installing rc.d service scripts to $RCDDIR/ ==="
    mkdir -p "$RCDDIR"

    cat > "$RCDDIR/semaaud" << RCEOF
#!/bin/sh
# PROVIDE: semaaud
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr
name="semaaud"
rcvar="semaaud_enable"
command="$PREFIX/bin/semaaud"
command_interpreter=""
pidfile="/var/run/semaaud.pid"
: \${semaaud_enable:="NO"}
: \${semaaud_flags:=""}

start_cmd="semaaud_start"
stop_cmd="semaaud_stop"

semaaud_start() {
    echo "Starting \${name}."
    /usr/sbin/daemon -p "\${pidfile}" -f \${command} \${semaaud_flags}
}

semaaud_stop() {
    if [ -f "\${pidfile}" ]; then
        kill \$(cat "\${pidfile}") 2>/dev/null || true
        rm -f "\${pidfile}"
        echo "Stopped \${name}."
    fi
}

load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semaaud"
    echo "  installed  $RCDDIR/semaaud"

    cat > "$RCDDIR/semainput" << RCEOF
#!/bin/sh
# PROVIDE: semainput
# REQUIRE: LOGIN semaaud
# KEYWORD: shutdown

. /etc/rc.subr
name="semainput"
rcvar="semainput_enable"
command="$PREFIX/bin/semainputd"
command_interpreter=""
pidfile="/var/run/semainput.pid"
: \${semainput_enable:="NO"}
: \${semainput_flags:=""}

start_cmd="semainput_start"
stop_cmd="semainput_stop"

semainput_start() {
    echo "Starting \${name}."
    /usr/sbin/daemon -p "\${pidfile}" -f \${command} \${semainput_flags}
}

semainput_stop() {
    if [ -f "\${pidfile}" ]; then
        kill \$(cat "\${pidfile}") 2>/dev/null || true
        rm -f "\${pidfile}"
        echo "Stopped \${name}."
    fi
}

load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semainput"
    echo "  installed  $RCDDIR/semainput"

    cat > "$RCDDIR/semadraw" << RCEOF
#!/bin/sh
# PROVIDE: semadraw
# REQUIRE: LOGIN semaaud semainput
# KEYWORD: shutdown

. /etc/rc.subr
name="semadraw"
rcvar="semadraw_enable"
command="$PREFIX/bin/semadrawd"
command_interpreter=""
pidfile="/var/run/semadraw.pid"
: \${semadraw_enable:="NO"}
: \${semadraw_flags:="-b drawfs"}

start_cmd="semadraw_start"
stop_cmd="semadraw_stop"

semadraw_start() {
    echo "Starting \${name}."
    /usr/sbin/daemon -p "\${pidfile}" -f \${command} \${semadraw_flags}
}

semadraw_stop() {
    if [ -f "\${pidfile}" ]; then
        kill \$(cat "\${pidfile}") 2>/dev/null || true
        rm -f "\${pidfile}"
        echo "Stopped \${name}."
    fi
}

load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semadraw"
    echo "  installed  $RCDDIR/semadraw"

    echo ""
    echo "=== Enabling daemons in /etc/rc.conf ==="
    sysrc semaaud_enable="YES"
    sysrc semainput_enable="YES"
    sysrc semadraw_enable="YES"
fi

# ============================================================================
# loader.conf — load drawfs at boot
# ============================================================================

LOADER_CONF="/boot/loader.conf"
echo ""
echo "=== Configuring /boot/loader.conf ==="
if grep -q "drawfs_load" "$LOADER_CONF" 2>/dev/null; then
    echo "  already set  drawfs_load=\"YES\""
else
    echo "drawfs_load=\"YES\"" >> "$LOADER_CONF"
    echo "  added  drawfs_load=\"YES\" to $LOADER_CONF"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=== UTF installation complete ==="
echo ""
echo "Installed binaries:"
for bin in $BINARIES; do
    target="$PREFIX/bin/$bin"
    if [ -f "$target" ]; then
        echo "  $target"
    fi
done
echo ""
echo "drawfs will load automatically at next boot (loader.conf)."
echo "Daemons will start automatically at next boot (rc.conf)."
echo ""
echo "To start now without rebooting:"
echo "  kldload drawfs"
echo "  service semaaud start"
echo "  service semainput start"
echo "  service semadraw start"
echo ""
echo "To remove:  sh install.sh --uninstall --prefix $PREFIX"
