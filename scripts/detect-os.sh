#!/bin/sh
# UTF OS detection helper. Sourced, not executed.
#
# UTF targets PGSD, a distribution founded on FreeBSD. This script
# distinguishes a FreeBSD host from anything else, primarily so that
# build banners and configure messages can name the running system
# accurately. The detection is intentionally minimal; UTF does not
# branch build behavior on OS variants.
#
# Usage:
#   . "$(dirname "$0")/scripts/detect-os.sh"
#   echo "$UTF_OS"             # "freebsd" | "unknown"
#   echo "$UTF_OS_VERSION"     # e.g. "15.0-RELEASE"
#
# This script only sets variables. It does not print, exit, or
# side-effect.

if [ "$(uname -s 2>/dev/null)" = "FreeBSD" ]; then
    UTF_OS="freebsd"
    UTF_OS_VERSION="$(freebsd-version 2>/dev/null || uname -r)"
else
    UTF_OS="unknown"
    UTF_OS_VERSION="$(uname -sr 2>/dev/null || echo unknown)"
fi

export UTF_OS UTF_OS_VERSION
