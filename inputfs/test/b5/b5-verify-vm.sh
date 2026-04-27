#!/bin/sh
# b5-verify-vm.sh: B.5 verification, VM pass.
#
# Runs the mouse-path signals from B5_VERIFICATION.md inside a
# GhostBSD VM with USB pass-through. The keyboard-path signal
# (1.3) cannot run in a VM that is driven via USB pass-through:
# unloading inputfs leaves the VM with no working USB input, so
# the operator cannot interact with the script to attach a
# different USB device. The keyboard path is verified on
# bare metal instead.
#
# Signals exercised here:
#   1.1 mouse classifies as pointer
#   1.2 mouse motion still produces raw reports
#   1.3 clean unload (keyboard signal moved to bare-metal pass)
#
# Usage:   ./b5-verify-vm.sh
# Output:  b5-pass1-vm.log and per-signal b5-1.N.log files in $PWD.
# Exit:    0 if all signals passed, 1 if any failed, 2 if a
#          precondition failed, 3 if user aborted.

set -u

B5_LOGDIR=$(pwd)
. "$(dirname "$0")/b5-common.sh"

result=0
trap 'echo "Aborted."; exit 3' INT

# --- Preconditions ---------------------------------------------------

b5_check_patch_applied         || exit 2
b5_check_build                 || exit 2
b5_check_no_prior_load         || exit 2
b5_install_module              || exit 2
b5_unload_competing_drivers    || exit $?

# --- Signal 1.1 ------------------------------------------------------

b5_step "Signal 1.1: mouse classifies as pointer"

b5_pause "Confirm the mouse is NOT currently passed through to the VM (VirtualBox menu Devices > USB, no mouse entry checked)." || exit 3

b5_dmesg_clear
b5_load || { result=1; }

b5_pause "Pass the USB mouse through to the VM via VirtualBox menu Devices > USB. Check the mouse entry."  || exit 3

if command -v usbconfig >/dev/null 2>&1; then
    b5_say "usbconfig output:"
    usbconfig | grep -i mouse || b5_warn "No mouse seen in usbconfig output. Continuing anyway."
fi

b5_rescan
sleep 1
b5_dmesg_capture "${B5_LOGDIR}/b5-1.1.log"

b5_say "Captured log b5-1.1.log:"
cat "${B5_LOGDIR}/b5-1.1.log"

if b5_check_attach_sequence "${B5_LOGDIR}/b5-1.1.log" \
   && b5_check_roles_line "${B5_LOGDIR}/b5-1.1.log" pointer; then
    b5_pass "Signal 1.1: roles=pointer present, attach sequence ordered correctly."
else
    b5_fail "Signal 1.1 failed. See b5-1.1.log"
    result=1
fi

# --- Signal 1.2 ------------------------------------------------------

b5_step "Signal 1.2: mouse motion still produces raw reports"

b5_dmesg_clear
b5_pause "Move the mouse for at least 5 seconds: in different directions, click a button at least once, scroll the wheel if it has one." || exit 3

b5_dmesg_capture "${B5_LOGDIR}/b5-1.2.log"
report_count=$(grep -c 'report id=0x' "${B5_LOGDIR}/b5-1.2.log" 2>/dev/null; true)
b5_say "Captured ${report_count} report lines."

if b5_check_report_lines "${B5_LOGDIR}/b5-1.2.log" 10; then
    b5_pass "Signal 1.2: report stream verified."
else
    b5_fail "Signal 1.2 failed. See b5-1.2.log"
    result=1
fi

# --- Signal 1.3 (clean unload) --------------------------------------
#
# In the VM script this is the clean-unload check. It runs with the
# mouse still attached from signals 1.1 and 1.2, so the unload has
# a real softc to detach. The "keyboard classifies as keyboard"
# signal that lives at this position in the bare-metal script is
# deliberately absent here; see header comment for rationale.

b5_step "Signal 1.3: clean unload"

b5_dmesg_clear
b5_unload || { result=1; }
b5_dmesg_capture "${B5_LOGDIR}/b5-1.3.log"

b5_say "Captured log b5-1.3.log:"
cat "${B5_LOGDIR}/b5-1.3.log"

if b5_check_clean_unload "${B5_LOGDIR}/b5-1.3.log"; then
    b5_pass "Signal 1.3: clean unload verified."
else
    b5_fail "Signal 1.3 failed. See b5-1.3.log"
    result=1
fi

# --- Restore competing drivers if we unloaded them ------------------

b5_reload_competing_drivers

# --- Concatenate ---------------------------------------------------

cat "${B5_LOGDIR}/b5-1.1.log" \
    "${B5_LOGDIR}/b5-1.2.log" \
    "${B5_LOGDIR}/b5-1.3.log" \
    > "${B5_LOGDIR}/b5-pass1-vm.log"
b5_say "Combined transcript: b5-pass1-vm.log"

b5_pass_summary "Pass 1 (VM)" "${result}"
exit "${result}"
