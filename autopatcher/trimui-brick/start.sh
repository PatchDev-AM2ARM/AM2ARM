#!/bin/sh
set -eu
ulimit -c 0
am2arm_runtime=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
am2arm_root=$(dirname -- "$am2arm_runtime")
mkdir -p "$am2arm_root/logs"
umask 077
am2arm_stamp=$(date '+%Y%m%d-%H%M%S')-$$
exec >> "$am2arm_root/logs/launch-$am2arm_stamp.log" 2>&1
printf 'AM2ARM TrimUI (%s): %s\n' "${AM2ARM_FRONTEND:-nextui}" "${1:-patcher}"
if [ "${AM2ARM_FRONTEND:-nextui}" = stock ]; then
    if [ "$(uname -m)" != aarch64 ] || [ ! -x /usr/trimui/bin/MainUI ]; then
        printf 'This package requires supported TrimUI ARM64 stock firmware.\n'
        exit 1
    fi
else
    if [ "$(uname -m)" != aarch64 ] || [ "${PLATFORM:-}" != tg5040 ]; then
        printf 'This package requires supported TrimUI NextUI firmware (tg5040).\n'
        exit 1
    fi
    case "${DEVICE:-}" in
        brick|smartpro) ;;
        *) printf 'Supported models: TrimUI Brick and original Smart Pro.\n'; exit 1 ;;
    esac
fi
export PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PYTHONNOUSERSITE=1
export PYTHONHOME="$am2arm_runtime/python/usr"
export PYTHONPATH="$am2arm_runtime:$am2arm_root/patcher"
exec "$am2arm_runtime/core/ld-linux-aarch64.so.1" \
    --library-path "$am2arm_runtime/core:$am2arm_runtime/lib:${LD_LIBRARY_PATH:-}" \
    "$am2arm_runtime/python/usr/bin/python3.11" "$am2arm_runtime/nextui_session.py" "${1:-patcher}"
