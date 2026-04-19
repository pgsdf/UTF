#!/bin/sh
#
# utf-down — tear down the UTF stack
#
# Stops the daemons in reverse dependency order (semadrawd first;
# chronofs last) and unloads the drawfs kernel module.
#
# Requires root.

set -u

if [ "$(id -u)" -ne 0 ]; then
    echo "utf-down: must be run as root" >&2
    exit 1
fi

# 1. Daemons, in reverse dependency order.
for svc in semadrawd semainput semaaud chronofs; do
    if service "${svc}" onestatus >/dev/null 2>&1; then
        echo "${svc}: stopping"
        service "${svc}" onestop || echo "${svc}: stop failed (continuing)"
    else
        echo "${svc}: not running"
    fi
done

# 2. Kernel module.
if kldstat -q -m drawfs; then
    echo "drawfs: unloading kernel module"
    kldunload drawfs || echo "drawfs: unload failed (in-use?)"
else
    echo "drawfs: not loaded"
fi

echo
echo "utf-down: stack is down"
