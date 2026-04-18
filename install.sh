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

    echo "=== Done ==="
    exit 0
fi

# ============================================================================
# Build
# ============================================================================

echo "=== Building UTF (optimize=ReleaseSafe) ==="

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
: \${semaaud_enable:="NO"}
load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semaaud"
    echo "  installed  $RCDDIR/semaaud"

    cat > "$RCDDIR/semainput" << RCEOF
#!/bin/sh
# PROVIDE: semainput
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr
name="semainput"
rcvar="semainput_enable"
command="$PREFIX/bin/semainputd"
: \${semainput_enable:="NO"}
load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semainput"
    echo "  installed  $RCDDIR/semainput"

    cat > "$RCDDIR/semadraw" << RCEOF
#!/bin/sh
# PROVIDE: semadraw
# REQUIRE: LOGIN semaaud
# KEYWORD: shutdown

. /etc/rc.subr
name="semadraw"
rcvar="semadraw_enable"
command="$PREFIX/bin/semadrawd"
: \${semadraw_enable:="NO"}
load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semadraw"
    echo "  installed  $RCDDIR/semadraw"

    echo ""
    echo "To enable daemons at boot, add to /etc/rc.conf:"
    echo "  semaaud_enable=\"YES\""
    echo "  semainput_enable=\"YES\""
    echo "  semadraw_enable=\"YES\""
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
echo "Quick start:"
echo "  sudo $PREFIX/bin/semaaud     &   # audio daemon"
echo "  sudo $PREFIX/bin/semainputd &   # input daemon"
echo "  $PREFIX/bin/semadrawd       &   # compositor"
echo "  $PREFIX/bin/chrono_dump --drift     # live timeline"
echo ""
echo "To remove:  sh install.sh --uninstall --prefix $PREFIX"
