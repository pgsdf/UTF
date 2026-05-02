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

# Detect OS early so all downstream messages and the drawfs build inherit
# UTF_OS and UTF_OS_VERSION via the environment.
. "$SCRIPT_DIR/scripts/detect-os.sh"
echo "Host OS: $UTF_OS $UTF_OS_VERSION"

BINARIES="semaaud semainputd semadrawd chrono_dump semadraw-term inputdump"

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
    for svc in inputfs semaaud semainput semadraw; do
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
    sysrc -x inputfs_enable 2>/dev/null   && echo "  removed  inputfs_enable"   || echo "  skip     inputfs_enable (not set)"
    sysrc -x semaaud_enable 2>/dev/null   && echo "  removed  semaaud_enable"   || echo "  skip     semaaud_enable (not set)"
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

    # Safety net: install.sh never adds inputfs_load to loader.conf
    # (the kernel module panics when loaded that early; see INSTALL.md
    # hazard 1). But a user may have added it by hand, hit the panic,
    # and reinstalled. Strip it on uninstall as a defensive cleanup so
    # any future install attempt starts from a clean state.
    if grep -q "inputfs_load" /boot/loader.conf 2>/dev/null; then
        sed -i '' '/inputfs_load/d' /boot/loader.conf
        echo "  removed  inputfs_load from /boot/loader.conf (defensive cleanup)"
    fi

    echo "=== Done ==="
    exit 0
fi

# ============================================================================
# Build
# ============================================================================

echo "=== Building UTF (optimize=ReleaseSafe) ==="

# Read .config early so drawfs/build.sh sees DRAWFS_DRM via environment.
# Default is false: swap-only kernel build, zero drm-kmod dependency.
CONFIG="$SCRIPT_DIR/.config"
DRAWFS_DRM="${DRAWFS_DRM:-false}"
if [ -f "$CONFIG" ]; then
    echo "Reading configuration from $CONFIG"
    . "$CONFIG"
    DRAWFS_DRM="${DRAWFS_DRM:-false}"
fi
export DRAWFS_DRM
echo "drawfs DRM/KMS backend: ${DRAWFS_DRM}"

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

# Build inputfs kernel module. Mirrors the drawfs pattern: install
# sources into /usr/src/sys/, build, deploy to /boot/modules/.
# Unlike drawfs, inputfs is NOT auto-loaded from /boot/loader.conf:
# the state kthread panics when loaded before /var/run is mounted.
# The deploy step explicitly does not add inputfs_load. See
# INSTALL.md hazard 1.
echo ""
echo "--- Building inputfs kernel module ---"
if [ -f "$SCRIPT_DIR/inputfs/build.sh" ]; then
    sh "$SCRIPT_DIR/inputfs/build.sh" install
    sh "$SCRIPT_DIR/inputfs/build.sh" build
    sh "$SCRIPT_DIR/inputfs/build.sh" deploy
else
    echo "WARNING: inputfs/build.sh not found — skipping kernel module"
fi

# Semadraw backend flags. DRAWFS_DRM was already consumed above for the kernel
# build; here we pick up the semadraw userspace backend selections.
SEMADRAW_FLAGS=""
if [ -f "$CONFIG" ]; then
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
build_sub "inputfs (userland)" "inputfs"

# ============================================================================
# Install
# ============================================================================

echo ""
echo "=== Installing to $PREFIX/bin/ ==="
mkdir -p "$PREFIX/bin"

# AD-12.1: Stop running daemons before replacing binaries.
#
# `cp` cannot replace a binary that is currently being executed (FreeBSD
# returns ETXTBSY, "Text file busy"). The pre-AD-12.1 behaviour was to
# bail out partway through the install with a confusing error, leaving
# the operator to manually stop services and re-run install.sh. This
# block records which services were running, stops them with
# confirmation, and the corresponding restart block at the end of the
# script brings them back. Services that were not running before the
# install are left stopped.
#
# rc.d's "stop" subcommand sends SIGTERM and trusts the daemon to die.
# We add a wait-with-timeout to confirm death; if a daemon does not
# exit within RESTART_TIMEOUT seconds, we SIGKILL it and warn.
#
# Determining "is running" via `service NAME status` works regardless
# of whether the operator started it via service or via direct
# invocation: pgrep on the binary name catches both.
SERVICES_TO_RESTART=""
INPUTFS_WAS_LOADED=0
RESTART_TIMEOUT=5

# Note inputfs's load state before we touch anything. inputfs.ko is a
# kernel module, not a userland daemon: the file on disk can be replaced
# while it's loaded (the running module keeps using its in-memory image),
# so we don't need to unload it for the binary install. But if the
# operator has already started using inputfs and they're running this
# install.sh to upgrade userland, the post-install restart block should
# restart inputfs too — bumping it onto the new module file gives them
# the upgrade they probably wanted.
if kldstat -q -m inputfs 2>/dev/null; then
    INPUTFS_WAS_LOADED=1
fi

stop_service_if_running() {
    svc="$1"   # rc.d service name (semaaud, semainput, semadraw)
    bin="$2"   # binary name as it appears in `ps` (semaaud, semainputd, semadrawd)
    if pgrep -x "$bin" >/dev/null 2>&1; then
        echo "  stopping  $svc (was running)"
        # Try the rc.d stop first; falls through to direct kill if rc.d
        # path is missing or fails.
        if [ -f "$PREFIX/etc/rc.d/$svc" ] || [ -f "/etc/rc.d/$svc" ]; then
            service "$svc" stop >/dev/null 2>&1 || true
        fi
        # Wait for the process to actually die.
        waited=0
        while pgrep -x "$bin" >/dev/null 2>&1; do
            if [ "$waited" -ge "$RESTART_TIMEOUT" ]; then
                echo "  WARNING: $bin did not exit within ${RESTART_TIMEOUT}s, sending SIGKILL" >&2
                pkill -9 -x "$bin" 2>/dev/null || true
                sleep 1
                break
            fi
            sleep 1
            waited=$((waited + 1))
        done
        SERVICES_TO_RESTART="$SERVICES_TO_RESTART $svc"
    fi
}

stop_service_if_running semadraw  semadrawd
stop_service_if_running semainput semainputd
stop_service_if_running semaaud   semaaud

# install_bin: copy a built binary into PREFIX/bin atomically.
#
# The copy goes to a sibling temp path (.NEW suffix), gets its mode
# set, then is renamed over the destination. rename(2) is atomic on
# the same filesystem, so the destination is either the old version
# (if anything before the rename failed) or the new version (if the
# rename succeeded). Avoids partial-replacement states on disk-full,
# operator interrupt, or other mid-copy failures.
install_bin() {
    src="$1"
    dst="$PREFIX/bin/$(basename "$src")"
    tmp="$dst.NEW.$$"
    if [ -f "$src" ]; then
        cp "$src" "$tmp" || {
            echo "  ERROR: cp $src $tmp failed" >&2
            rm -f "$tmp"
            return 1
        }
        chmod 755 "$tmp"
        mv "$tmp" "$dst" || {
            echo "  ERROR: mv $tmp $dst failed" >&2
            rm -f "$tmp"
            return 1
        }
        echo "  installed  $dst"
    else
        echo "  WARNING: $src not found — skipping" >&2
    fi
}

install_bin "$SCRIPT_DIR/semaaud/zig-out/bin/semaaud"
install_bin "$SCRIPT_DIR/semainput/zig-out/bin/semainputd"
install_bin "$SCRIPT_DIR/semadraw/zig-out/bin/semadrawd"
install_bin "$SCRIPT_DIR/chronofs/zig-out/bin/chrono_dump"
install_bin "$SCRIPT_DIR/semadraw/zig-out/bin/semadraw-term"
install_bin "$SCRIPT_DIR/inputfs/zig-out/bin/inputdump"

# ============================================================================
# rc.d scripts (FreeBSD service integration)
# ============================================================================

RCDDIR="$PREFIX/etc/rc.d"
if [ -d /etc/rc.d ] || [ -d "$RCDDIR" ]; then
    echo ""
    echo "=== Installing rc.d service scripts to $RCDDIR/ ==="
    mkdir -p "$RCDDIR"

    cat > "$RCDDIR/inputfs" << RCEOF
#!/bin/sh
# PROVIDE: inputfs inputfs_loaded
# REQUIRE: FILESYSTEMS
# KEYWORD: shutdown

# AD-12.3: rc.d service for inputfs.
#
# inputfs cannot be loaded via /boot/loader.conf because the module's
# kthread starts publishing state files before /var before /var/run is
# mounted, panicking on AT_FDCWD. INSTALL.md Hazard 1 documents this.
# This rc.d service deferred load to userland-startup time avoids the
# bug: REQUIRE: FILESYSTEMS guarantees /var/run is mounted before
# kldload runs.
#
# AD-12.2: PROVIDE: 'inputfs_loaded' is the abstract capability name
# that consumer daemons express dependency on (REQUIRE: inputfs_loaded).
# 'inputfs' is the service name; 'inputfs_loaded' future-proofs the
# rcorder graph so a future implementation could provide the same
# capability without consumer rc.d edits. Replaces the previous
# 'BEFORE: semadraw semainput' line, which expressed the inverse
# relationship (provider declaring consumer dependency); consumers
# now express their own dependency via REQUIRE:.

. /etc/rc.subr
name="inputfs"
rcvar="inputfs_enable"
: \${inputfs_enable:="NO"}

start_cmd="inputfs_start"
stop_cmd="inputfs_stop"
status_cmd="inputfs_status"

inputfs_start() {
    if kldstat -q -m inputfs; then
        echo "\${name} already loaded."
        return 0
    fi
    echo "Loading \${name}."
    kldload inputfs
}

inputfs_stop() {
    if ! kldstat -q -m inputfs; then
        echo "\${name} not loaded."
        return 0
    fi
    echo "Unloading \${name}."
    kldunload inputfs
}

inputfs_status() {
    if kldstat -q -m inputfs; then
        echo "\${name} is loaded."
    else
        echo "\${name} is not loaded."
        return 1
    fi
}

load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/inputfs"
    echo "  installed  $RCDDIR/inputfs"

    cat > "$RCDDIR/semaaud" << RCEOF
#!/bin/sh
# PROVIDE: semaaud utf_clock
# REQUIRE: FILESYSTEMS
# KEYWORD: shutdown

# AD-12.2: 'utf_clock' is the abstract capability name for the UTF
# audio-driven monotonic clock published at /var/run/sema/clock.
# semaaud is currently the only provider; future audio replacements
# (AD-3) would provide the same capability without consumer rc.d
# edits. semadraw and any future UTF daemon that consumes the clock
# expresses its dependency via REQUIRE: utf_clock rather than
# REQUIRE: semaaud.
#
# REQUIRE: FILESYSTEMS replaces the previous REQUIRE: LOGIN. semaaud
# does not depend on user-login state; it needs /var/run mounted (so
# /var/run/sema/clock can be created) and /dev/dsp available (which
# /etc/rc.d/devd handles before FILESYSTEMS completes).

. /etc/rc.subr
name="semaaud"
rcvar="semaaud_enable"
command="$PREFIX/bin/semaaud"
command_interpreter=""
pidfile="/var/run/semaaud.pid"
: \${semaaud_enable:="NO"}
: \${semaaud_flags:=""}

# AD-12.4: stop with confirmation. The default rc.d stop sends a
# SIGTERM via \`kill\` and returns immediately, leaving \`service stop\`
# claiming success while the daemon may still be alive. The custom
# stop below waits up to STOP_TIMEOUT seconds for the process to
# actually exit, escalates to SIGKILL on timeout, and preserves the
# pidfile if SIGKILL also fails so a subsequent operator action can
# find the still-alive process. Polling cost is one \`kill -0\` per
# second; the daemon exits within milliseconds in the typical case.
STOP_TIMEOUT=5

start_cmd="semaaud_start"
stop_cmd="semaaud_stop"

semaaud_start() {
    echo "Starting \${name}."
    /usr/sbin/daemon -p "\${pidfile}" -f \${command} \${semaaud_flags}
}

semaaud_stop() {
    if [ ! -f "\${pidfile}" ]; then
        echo "\${name} not running."
        return 0
    fi
    pid=\$(cat "\${pidfile}" 2>/dev/null)
    if [ -z "\${pid}" ] || ! kill -0 "\${pid}" 2>/dev/null; then
        echo "\${name} pidfile present but process not running; cleaning up."
        rm -f "\${pidfile}"
        return 0
    fi
    echo "Stopping \${name}."
    kill "\${pid}" 2>/dev/null || true
    waited=0
    while kill -0 "\${pid}" 2>/dev/null; do
        if [ "\${waited}" -ge "\${STOP_TIMEOUT}" ]; then
            echo "\${name} did not exit within \${STOP_TIMEOUT}s, sending SIGKILL." >&2
            kill -9 "\${pid}" 2>/dev/null || true
            sleep 1
            break
        fi
        sleep 1
        waited=\$((waited + 1))
    done
    if kill -0 "\${pid}" 2>/dev/null; then
        echo "\${name} STILL RUNNING after SIGKILL (pid=\${pid}); pidfile preserved." >&2
        return 1
    fi
    rm -f "\${pidfile}"
    echo "Stopped \${name}."
}

load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semaaud"
    echo "  installed  $RCDDIR/semaaud"

    cat > "$RCDDIR/semainput" << RCEOF
#!/bin/sh
# PROVIDE: semainput
# REQUIRE: FILESYSTEMS semadraw
# KEYWORD: shutdown

# AD-12.2: semainputd is the legacy evdev-to-semadrawd injection
# bridge (retiring under AD-2 Phase 3). It connects to semadrawd's
# socket and injects events synthesised from evdev. The dependency
# direction is therefore semainput -> semadraw, not the reverse.
# Pre-AD-12.2, the rc.d ordering had semadraw require semainput,
# which was backwards: it made semadraw wait for the bridge that
# wants to talk to it. The current ordering matches the actual
# socket-direction: semadrawd is a server, semainputd is a client.
# semainputd's existing in-process retry loop kept the old ordering
# from causing visible failures, but the BACKLOG dependency graph
# has had this direction documented correctly since AD-12 was filed.

. /etc/rc.subr
name="semainput"
rcvar="semainput_enable"
command="$PREFIX/bin/semainputd"
command_interpreter=""
pidfile="/var/run/semainput.pid"
: \${semainput_enable:="NO"}
: \${semainput_flags:=""}

# AD-12.4: stop with confirmation; see semaaud rc.d for the rationale.
STOP_TIMEOUT=5

start_cmd="semainput_start"
stop_cmd="semainput_stop"

semainput_start() {
    echo "Starting \${name}."
    /usr/sbin/daemon -p "\${pidfile}" -f \${command} \${semainput_flags}
}

semainput_stop() {
    if [ ! -f "\${pidfile}" ]; then
        echo "\${name} not running."
        return 0
    fi
    pid=\$(cat "\${pidfile}" 2>/dev/null)
    if [ -z "\${pid}" ] || ! kill -0 "\${pid}" 2>/dev/null; then
        echo "\${name} pidfile present but process not running; cleaning up."
        rm -f "\${pidfile}"
        return 0
    fi
    echo "Stopping \${name}."
    kill "\${pid}" 2>/dev/null || true
    waited=0
    while kill -0 "\${pid}" 2>/dev/null; do
        if [ "\${waited}" -ge "\${STOP_TIMEOUT}" ]; then
            echo "\${name} did not exit within \${STOP_TIMEOUT}s, sending SIGKILL." >&2
            kill -9 "\${pid}" 2>/dev/null || true
            sleep 1
            break
        fi
        sleep 1
        waited=\$((waited + 1))
    done
    if kill -0 "\${pid}" 2>/dev/null; then
        echo "\${name} STILL RUNNING after SIGKILL (pid=\${pid}); pidfile preserved." >&2
        return 1
    fi
    rm -f "\${pidfile}"
    echo "Stopped \${name}."
}

load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semainput"
    echo "  installed  $RCDDIR/semainput"

    cat > "$RCDDIR/semadraw" << RCEOF
#!/bin/sh
# PROVIDE: semadraw
# REQUIRE: FILESYSTEMS utf_clock inputfs_loaded
# KEYWORD: shutdown

# AD-12.2: semadrawd's dependencies expressed as abstract
# capabilities rather than service names. utf_clock is provided by
# semaaud (or any future replacement). inputfs_loaded is provided
# by inputfs (the kernel module's rc.d service). Pre-AD-12.2:
# REQUIRE: LOGIN semaaud semainput, which had two problems: LOGIN
# is not a real dependency for a daemon that runs as root; semainput
# was a reverse dependency (semainputd is a client of semadrawd,
# not a precondition).

. /etc/rc.subr
name="semadraw"
rcvar="semadraw_enable"
command="$PREFIX/bin/semadrawd"
command_interpreter=""
pidfile="/var/run/semadraw.pid"
: \${semadraw_enable:="NO"}
: \${semadraw_flags:="-b drawfs"}

# AD-12.4: stop with confirmation; see semaaud rc.d for the rationale.
STOP_TIMEOUT=5

start_cmd="semadraw_start"
stop_cmd="semadraw_stop"

# AD-15.1: query the EFI framebuffer geometry from drawfs sysctls at
# start time and pass it as -r WIDTHxHEIGHT to semadrawd. semadrawd
# defaults to 1920x1080 when no -r flag is given (its compile-time
# default), but the actual EFI framebuffer on PGSD bare metal is
# typically larger (3840x2160 on the development machine). Without
# this, semadrawd's compositor surface is sized at the default and
# only the top-left corner of the framebuffer gets rendered to,
# producing the partial-screen rendering that AD-15 documents.
#
# The sysctls hw.drawfs.efifb.width and hw.drawfs.efifb.height are
# published by drawfs (D.2 in inputfs's Stage D scope ADR; the
# sysctls predate AD-15 and were already exposed for inputfs's
# coordinate-transform setup). They become available as soon as
# drawfs is loaded, which happens via /boot/loader.conf at boot,
# so they are reliably present by the time this rc.d script runs.
#
# If the sysctls are not present (drawfs not loaded, or older
# version without the publish) the start function falls through
# to semadrawd's default. The result is the pre-AD-15.1
# partial-rendering symptom, but semadrawd still starts and is
# operational. Filed as a fallback rather than a hard error
# because semadrawd is usable at any geometry; AD-15 is polish.
#
# AD-17 (filed) captures the principled fix: semadrawd should
# auto-detect the framebuffer size from its drawfs backend at
# runtime via a backend-interface query, removing the need for
# rc.d-side resolution detection. This rc.d-side fix is the
# operator-side workaround until AD-17 lands.
semadraw_detect_resolution() {
    # Read drawfs efifb sysctls. -n gets value-only (no key= prefix).
    # 2>/dev/null swallows the error if the sysctl is absent.
    fb_w=\$(sysctl -n hw.drawfs.efifb.width 2>/dev/null)
    fb_h=\$(sysctl -n hw.drawfs.efifb.height 2>/dev/null)
    # Both must be present and non-zero. drawfs publishes both atomically
    # at module load; partial publication is treated as unreliable
    # (drawfs version mismatch) and we fall through to semadrawd's
    # default rather than guess.
    if [ -n "\${fb_w}" ] && [ -n "\${fb_h}" ] && [ "\${fb_w}" -gt 0 ] && [ "\${fb_h}" -gt 0 ]; then
        echo "-r \${fb_w}x\${fb_h}"
    fi
}

semadraw_start() {
    echo "Starting \${name}."
    res_flag=\$(semadraw_detect_resolution)
    if [ -n "\${res_flag}" ]; then
        echo "  detected framebuffer: \${res_flag}"
    else
        echo "  framebuffer geometry sysctls absent; using semadrawd default 1920x1080"
    fi
    /usr/sbin/daemon -p "\${pidfile}" -f \${command} \${semadraw_flags} \${res_flag}
}

semadraw_stop() {
    if [ ! -f "\${pidfile}" ]; then
        echo "\${name} not running."
        return 0
    fi
    pid=\$(cat "\${pidfile}" 2>/dev/null)
    if [ -z "\${pid}" ] || ! kill -0 "\${pid}" 2>/dev/null; then
        echo "\${name} pidfile present but process not running; cleaning up."
        rm -f "\${pidfile}"
        return 0
    fi
    echo "Stopping \${name}."
    kill "\${pid}" 2>/dev/null || true
    waited=0
    while kill -0 "\${pid}" 2>/dev/null; do
        if [ "\${waited}" -ge "\${STOP_TIMEOUT}" ]; then
            echo "\${name} did not exit within \${STOP_TIMEOUT}s, sending SIGKILL." >&2
            kill -9 "\${pid}" 2>/dev/null || true
            sleep 1
            break
        fi
        sleep 1
        waited=\$((waited + 1))
    done
    if kill -0 "\${pid}" 2>/dev/null; then
        echo "\${name} STILL RUNNING after SIGKILL (pid=\${pid}); pidfile preserved." >&2
        return 1
    fi
    rm -f "\${pidfile}"
    echo "Stopped \${name}."
}

load_rc_config \$name
run_rc_command "\$1"
RCEOF
    chmod 555 "$RCDDIR/semadraw"
    echo "  installed  $RCDDIR/semadraw"

    echo ""
    echo "=== Enabling daemons in /etc/rc.conf ==="
    sysrc inputfs_enable="YES"
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
# Restart services that were running before the install
# ============================================================================
# AD-12.1 and AD-12.3 counterpart to the stop_service_if_running block
# earlier. Services not previously running are deliberately not started:
# install.sh is an upgrade-preserving-state tool, not a "start everything"
# tool.

if [ "$INPUTFS_WAS_LOADED" -eq 1 ] || [ -n "$SERVICES_TO_RESTART" ]; then
    echo ""
    echo "=== Restarting previously-running services ==="

    # AD-12.3: restart inputfs first if it was loaded before. inputfs
    # publishes /var/run/sema/input/{state,events}; semadrawd's drawfs
    # backend opens those files at init. Restarting inputfs after
    # semadrawd would leave semadrawd holding a stale ring view.
    # Bump-the-module-onto-the-new-image is a kldunload-then-kldload,
    # since we need the userland daemons stopped first (they have the
    # event ring mmapped) — the AD-12.1 stop block already stopped them
    # if they were running.
    if [ "$INPUTFS_WAS_LOADED" -eq 1 ]; then
        if kldstat -q -m inputfs 2>/dev/null; then
            kldunload inputfs 2>/dev/null && echo "  unloaded  inputfs (for refresh)" \
                || echo "  WARNING: kldunload inputfs failed; module may still be in use" >&2
        fi
        if kldload inputfs 2>/dev/null; then
            echo "  loaded    inputfs"
        else
            echo "  WARNING: kldload inputfs failed" >&2
        fi
    fi

    # AD-12.1: dependency order for userland daemons.
    # semaaud (provides utf_clock) before semadraw (consumes clock)
    # before semainput (legacy, consumes semadraw).
    for svc in semaaud semadraw semainput; do
        case " $SERVICES_TO_RESTART " in
            *" $svc "*)
                if service "$svc" start >/dev/null 2>&1; then
                    echo "  started   $svc"
                else
                    echo "  WARNING: service $svc start failed" >&2
                fi
                ;;
        esac
    done
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
echo "inputfs and the daemons will start automatically at next boot (rc.conf)."
echo ""
echo "To start now without rebooting:"
echo "  kldload drawfs"
echo "  service inputfs start"
echo "  service semaaud start"
echo "  service semainput start"
echo "  service semadraw start"
echo ""
echo "To remove:  sh install.sh --uninstall --prefix $PREFIX"
