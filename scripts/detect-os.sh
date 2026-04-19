#!/bin/sh
# UTF OS detection helper — sourced, not executed.
#
# Distinguishes GhostBSD from FreeBSD proper. The detection is deliberately
# minimal: both systems are binary-compatible, share a kernel family, and for
# most UTF build decisions behave identically. We detect mainly to:
#
#   - Give accurate messaging in configure.sh and build logs
#   - Avoid FreeBSD-specific advice (like "disable FreeBSD-ports-kmods") on
#     GhostBSD hosts where it does not apply
#   - Have the hook in place if a concrete divergence ever shows up
#
# DO NOT use this to branch build behavior unless there is a real reason.
# Speculative branching creates bugs that only surface on one of the two OSes.
#
# Usage:
#   . "$(dirname "$0")/scripts/detect-os.sh"
#   echo "$UTF_OS"             # "ghostbsd" | "freebsd" | "unknown"
#   echo "$UTF_OS_VERSION"     # e.g. "25.1-STABLE" or "15.0-RELEASE"
#
# This script only sets variables. It does not print, exit, or side-effect.

# ghostbsd-version(1) is a GhostBSD-only helper installed to /usr/local/bin.
# FreeBSD proper does not ship it. This is the canonical check recommended
# by the GhostBSD project itself.
if command -v ghostbsd-version >/dev/null 2>&1; then
    UTF_OS="ghostbsd"
    # ghostbsd-version prints e.g. "GhostBSD 25.1-STABLE" — strip the prefix.
    UTF_OS_VERSION="$(ghostbsd-version 2>/dev/null | sed 's/^GhostBSD //')"
elif [ "$(uname -s 2>/dev/null)" = "FreeBSD" ]; then
    UTF_OS="freebsd"
    UTF_OS_VERSION="$(freebsd-version 2>/dev/null || uname -r)"
else
    UTF_OS="unknown"
    UTF_OS_VERSION="$(uname -sr 2>/dev/null || echo unknown)"
fi

export UTF_OS UTF_OS_VERSION
