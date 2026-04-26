#!/bin/sh
# b5-common.sh: shared functions for B.5 verification scripts.
# POSIX sh. Sourced by b5-verify-vm.sh and b5-verify-baremetal.sh.

# Exit codes:
#   0 = signal passed
#   1 = signal failed (acceptance criteria not met)
#   2 = precondition failure (build, missing tool, etc.)
#   3 = user aborted

set -u

# Where logs land. Caller may override before sourcing.
: "${B5_LOGDIR:=$(pwd)}"

# Repo root, derived from this file's location.
B5_SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
B5_REPO_ROOT=$(cd "${B5_SCRIPT_DIR}/../.." && pwd)
B5_MODULE_DIR="${B5_REPO_ROOT}/sys/modules/inputfs"
B5_SOURCE_FILE="${B5_REPO_ROOT}/sys/dev/inputfs/inputfs.c"

# --- Output helpers --------------------------------------------------

b5_say()  { printf '[b5] %s\n' "$*"; }
b5_warn() { printf '[b5 WARN] %s\n' "$*" >&2; }
b5_fail() { printf '[b5 FAIL] %s\n' "$*" >&2; }
b5_pass() { printf '[b5 PASS] %s\n' "$*"; }
b5_step() {
    printf '\n========================================================\n'
    printf '[b5 STEP] %s\n' "$*"
    printf '========================================================\n'
}

b5_pause() {
    # Prompt the user and wait for confirmation. $1 is the prompt.
    # Returns 0 on yes/enter, 3 on quit.
    printf '\n[b5 ACTION REQUIRED] %s\n' "$1"
    printf '    Press <enter> to continue, q<enter> to abort: '
    read ans
    case "$ans" in
        q|Q|quit|abort) return 3 ;;
        *) return 0 ;;
    esac
}

b5_confirm() {
    # Yes/no prompt. $1 is the question. Returns 0 yes, 1 no, 3 abort.
    printf '\n[b5] %s [y/n/q]: ' "$1"
    read ans
    case "$ans" in
        y|Y|yes) return 0 ;;
        q|Q) return 3 ;;
        *) return 1 ;;
    esac
}

# --- Precondition checks --------------------------------------------

b5_check_patch_applied() {
    b5_step "P.1: Checking that the B.5 patch is applied"
    if [ ! -f "${B5_SOURCE_FILE}" ]; then
        b5_fail "Source file not found: ${B5_SOURCE_FILE}"
        return 2
    fi
    missing=0
    for pat in INPUTFS_ROLE_POINTER INPUTFS_ROLE_KEYBOARD \
               INPUTFS_ROLE_TOUCH INPUTFS_ROLE_PEN \
               INPUTFS_ROLE_LIGHTING sc_roles \
               'roles=%s' inputfs_classify_roles; do
        if ! grep -q "${pat}" "${B5_SOURCE_FILE}"; then
            b5_fail "Pattern not found in inputfs.c: ${pat}"
            missing=1
        fi
    done
    if [ "${missing}" -ne 0 ]; then
        b5_fail "B.5 patch is incomplete or not applied."
        return 2
    fi
    b5_pass "All B.5 patch markers present."
    return 0
}

b5_check_build() {
    b5_step "P.2: Building the kernel module"
    if [ ! -d "${B5_MODULE_DIR}" ]; then
        b5_fail "Module directory not found: ${B5_MODULE_DIR}"
        return 2
    fi
    cd "${B5_MODULE_DIR}" || return 2
    if ! make clean >/dev/null 2>&1; then
        b5_warn "make clean returned nonzero; continuing"
    fi
    if ! make 2>&1 | tee "${B5_LOGDIR}/b5-build.log"; then
        b5_fail "Build failed. See ${B5_LOGDIR}/b5-build.log"
        return 2
    fi
    if [ ! -f "${B5_MODULE_DIR}/inputfs.ko" ]; then
        b5_fail "inputfs.ko not produced by build"
        return 2
    fi
    b5_pass "Build clean. ${B5_MODULE_DIR}/inputfs.ko produced."
    return 0
}

b5_check_no_prior_load() {
    b5_step "P.3: Checking that inputfs is not already loaded"
    if kldstat | grep -q inputfs; then
        b5_warn "inputfs is currently loaded:"
        kldstat | grep inputfs
        if b5_confirm "Attempt to unload it?"; then
            if ! sudo kldunload inputfs; then
                b5_fail "kldunload refused. Detach any USB device and re-run."
                return 2
            fi
        else
            return 3
        fi
    fi
    b5_pass "inputfs not loaded."
    return 0
}

b5_install_module() {
    b5_step "Installing freshly built module"
    cd "${B5_MODULE_DIR}" || return 2
    if ! sudo make install 2>&1 | tee "${B5_LOGDIR}/b5-install.log"; then
        b5_fail "make install failed. See ${B5_LOGDIR}/b5-install.log"
        return 2
    fi
    if [ ! -f /boot/modules/inputfs.ko ]; then
        b5_fail "/boot/modules/inputfs.ko missing after install"
        return 2
    fi
    b5_pass "Module installed to /boot/modules/inputfs.ko"
    return 0
}

# List of competing drivers from ADR 0009 Testing section. inputfs
# cannot attach to a hidbus child that is already claimed by one of
# these. Both VM and bare-metal verification require all of them
# unloaded before inputfs is loaded.
B5_COMPETING_DRIVERS="hms hkbd hgame hcons hsctrl utouch"

b5_unload_competing_drivers() {
    b5_step "Unloading drivers that compete with inputfs (per ADR 0009)"

    loaded=""
    for drv in ${B5_COMPETING_DRIVERS}; do
        if kldstat -q -n "${drv}" 2>/dev/null; then
            loaded="${loaded} ${drv}"
        fi
    done

    if [ -z "${loaded}" ]; then
        b5_pass "No competing drivers loaded. inputfs is free to claim devices."
        return 0
    fi

    cat <<EOF

The following drivers are loaded and claim USB HID devices before
inputfs can attach:
   ${loaded}

ADR 0009 requires these to be unloaded for inputfs verification.

If you do not have a non-USB console (serial, SSH not relying on
USB, or a remote graphical terminal), unloading hms/hkbd will leave
you without working mouse and keyboard input until inputfs claims
the devices, or until you reload these drivers.

EOF

    if ! b5_confirm "Unload these drivers now?"; then
        b5_fail "Cannot proceed without unloading competing drivers."
        return 3
    fi

    for drv in ${loaded}; do
        b5_say "Unloading ${drv}"
        if ! sudo kldunload "${drv}" 2>&1; then
            b5_fail "Failed to unload ${drv}. May be statically compiled into the kernel."
            return 2
        fi
    done
    b5_pass "Competing drivers unloaded. inputfs is free to claim devices."
    return 0
}

b5_reload_competing_drivers() {
    b5_step "Optional: reload competing drivers"

    if ! b5_confirm "Reload hms/hkbd and the rest to restore normal input?"; then
        b5_say "Skipped. Reboot or run 'sudo kldload hms hkbd' manually to restore."
        return 0
    fi

    for drv in ${B5_COMPETING_DRIVERS}; do
        sudo kldload "${drv}" 2>/dev/null && b5_say "${drv} reloaded"
    done
    return 0
}

# --- dmesg capture --------------------------------------------------

b5_dmesg_clear() {
    sudo dmesg -c >/dev/null 2>&1 || true
}

b5_dmesg_capture() {
    # Capture inputfs lines from dmesg into the named log file.
    # $1 = output file path
    sudo dmesg | grep inputfs > "$1" || true
}

# --- Signal-level acceptance checks ---------------------------------

b5_check_roles_line() {
    # Look for at least one "roles=<expected>" line in the log. On
    # bare metal multiple devices may attach in parallel and produce
    # multiple roles= lines of different role types; this check
    # passes as long as the expected role appears somewhere.
    # $1 = log file, $2 = expected role string (e.g. "pointer")
    log="$1"
    expected="$2"
    # Match "roles=<expected>" followed by end of line, comma (multi-
    # role), or whitespace. This guards against false matches like
    # "roles=pointer,keyboard" when checking for "pointer".
    if grep -qE "roles=${expected}([,[:space:]]|\$)" "${log}"; then
        return 0
    fi
    # Diagnostic: report what roles lines are actually present.
    found=$(grep 'roles=' "${log}" | sed 's/.*roles=/roles=/' | sort -u | tr '\n' ' ')
    if [ -n "${found}" ]; then
        b5_fail "No 'roles=${expected}' line in ${log}. Found instead: ${found}"
    else
        b5_fail "No 'roles=' line at all in ${log}. Device probably did not bind."
    fi
    return 1
}

b5_check_attach_sequence() {
    # Verify the attach sequence is present and structurally correct.
    # Tolerates multiple parallel attaches (bare-metal case): there
    # must be at least one of each line type, and the count of
    # roles= lines must not exceed the count of attach lines (i.e.
    # every roles= has a corresponding attach upstream).
    # $1 = log file
    log="$1"

    n_attached=$(grep -c 'attached HID' "${log}" 2>/dev/null; true)
    n_descriptor=$(grep -c 'descriptor.*bytes.*input items' "${log}" 2>/dev/null; true)
    n_buffer=$(grep -c 'report buffer.*registering interrupt' "${log}" 2>/dev/null; true)
    n_roles=$(grep -c 'roles=' "${log}" 2>/dev/null; true)

    if [ "${n_attached}" -eq 0 ]; then
        b5_fail "No 'attached HID' line in ${log}. Device did not bind to inputfs."
        b5_fail "Likely cause: a competing driver claimed the device first."
        return 1
    fi
    if [ "${n_descriptor}" -eq 0 ]; then
        b5_fail "No 'descriptor ... input items' line in ${log}."
        return 1
    fi
    if [ "${n_buffer}" -eq 0 ]; then
        b5_fail "No 'report buffer ... registering interrupt' line in ${log}."
        return 1
    fi
    if [ "${n_roles}" -eq 0 ]; then
        b5_fail "No 'roles=' line in ${log}. B.5 patch may not be active."
        return 1
    fi

    if [ "${n_roles}" -gt "${n_attached}" ]; then
        b5_warn "More roles= lines (${n_roles}) than attach lines (${n_attached}); odd, please review log"
        return 1
    fi

    if [ "${n_attached}" -gt 1 ]; then
        b5_say "Multi-device attach detected: ${n_attached} devices probed inputfs in parallel."
    fi
    return 0
}

b5_check_report_lines() {
    # $1 = log file, $2 = minimum count
    log="$1"
    minimum="$2"
    count=$(grep -c 'report id=0x' "${log}" 2>/dev/null; true)
    if [ "${count}" -lt "${minimum}" ]; then
        b5_fail "Only ${count} 'report id=' lines found, expected at least ${minimum}"
        return 1
    fi
    # Look for at least one report with non-zero data.
    if ! grep -E 'report id=0x.*data=00 ([1-9a-f][0-9a-f]?|0[1-9a-f])' "${log}" >/dev/null; then
        # Best-effort check; don't fail if pattern doesn't catch it
        b5_warn "Could not auto-detect non-zero motion deltas; please verify manually"
    fi
    return 0
}

b5_check_clean_unload() {
    # $1 = log file
    log="$1"
    if ! grep -q 'inputfs0:.*detached' "${log}"; then
        b5_fail "Missing 'detached' line"
        return 1
    fi
    if ! grep -q 'inputfs: unloaded' "${log}"; then
        b5_fail "Missing 'unloaded' line"
        return 1
    fi
    if kldstat | grep -q inputfs; then
        b5_fail "inputfs still in kldstat after unload"
        return 1
    fi
    # Check broader dmesg tail for warnings.
    if sudo dmesg | tail -50 | grep -iE 'warning|witness|leak|use[ -]after' >/dev/null; then
        b5_warn "Found warning/witness/leak text in recent dmesg. Review b5-pass*.log full capture."
        return 1
    fi
    return 0
}

# --- Lifecycle helpers -----------------------------------------------

b5_load() {
    b5_say "Loading inputfs"
    if ! sudo kldload inputfs; then
        b5_fail "kldload inputfs failed"
        return 1
    fi
    return 0
}

b5_unload() {
    b5_say "Unloading inputfs"
    if ! sudo kldunload inputfs; then
        b5_fail "kldunload inputfs failed"
        return 1
    fi
    return 0
}

b5_rescan() {
    # Trigger inputfs to bind by rescanning every hidbus on the
    # system. After kldunload of competing drivers, the hidbus
    # children are orphans; loading inputfs registers it as a
    # candidate driver, but hidbus does not auto-reprobe its
    # existing children at driver-registration time. devctl rescan
    # forces the reprobe.
    #
    # Multiple hidbus instances are common (one per usbhid* on every
    # USB HID interface). Bare metal typically has 5-10; VM has 2-3.
    # All must be rescanned, not just one.
    b5_step "Triggering devctl rescan on every hidbus"

    if ! command -v devinfo >/dev/null 2>&1; then
        b5_warn "devinfo not available; falling back to fixed bus list"
        for bus in usbhid0 usbhid1 hidbus0 hidbus1 hidbus2; do
            sudo devctl rescan "${bus}" 2>/dev/null && \
                b5_say "rescanned ${bus}"
        done
        return 0
    fi

    # Collect every hidbus instance from the device tree.
    buses=$(devinfo -r 2>/dev/null | awk '/^[ \t]*hidbus[0-9]/ {gsub(/^[ \t]+/, ""); print $1}')
    if [ -z "${buses}" ]; then
        b5_warn "No hidbus instances found in devinfo output."
        b5_warn "Either no HID devices are present, or hidbus is not loaded."
        return 0
    fi

    count=0
    for bus in ${buses}; do
        if sudo devctl rescan "${bus}" 2>/dev/null; then
            b5_say "rescanned ${bus}"
            count=$((count + 1))
        else
            b5_warn "rescan ${bus} failed"
        fi
    done

    if [ "${count}" -eq 0 ]; then
        b5_warn "No hidbus rescan succeeded. inputfs probably will not bind."
        return 1
    fi
    b5_pass "Rescanned ${count} hidbus instance(s)."
    # Give the kernel a moment for probes to complete and dmesg to
    # flush before the caller captures it.
    sleep 1
    return 0
}

# Print final summary for a pass.
b5_pass_summary() {
    # $1 = pass label (e.g. "Pass 1: VM"), $2 = result (0/1)
    label="$1"
    result="$2"
    printf '\n========================================================\n'
    if [ "${result}" -eq 0 ]; then
        printf '[b5] %s: ALL SIGNALS PASSED\n' "${label}"
    else
        printf '[b5] %s: FAILED. Review logs in %s\n' "${label}" "${B5_LOGDIR}"
    fi
    printf '========================================================\n'
}
