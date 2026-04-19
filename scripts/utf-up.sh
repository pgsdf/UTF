#!/bin/sh
#
# utf-up — bring up the UTF stack
#
# Loads the drawfs kernel module and starts the daemons in dependency
# order (chronofs first; semadrawd last). Delegates each start to the
# rc.d scripts so boot-time and interactive startup share one code path.
#
# Requires root.

set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "utf-up: must be run as root" >&2
    exit 1
fi

# 1. Kernel module
if kldstat -q -m drawfs; then
    echo "drawfs: already loaded"
else
    echo "drawfs: loading kernel module"
    kldload drawfs
fi

# 2. Daemons, in dependency order. rc.d enforces REQUIRE: lines, so
#    starting semadrawd last is sufficient — service(8) would chain
#    back — but we start each explicitly for clearer progress output.
for svc in chronofs semaaud semainput semadrawd; do
    if service "${svc}" onestatus >/dev/null 2>&1; then
        echo "${svc}: already running"
    else
        echo "${svc}: starting"
        service "${svc}" onestart
    fi
done

echo
echo "utf-up: stack is up"
echo "        run 'chrono_dump' to verify the fabric is coherent"
