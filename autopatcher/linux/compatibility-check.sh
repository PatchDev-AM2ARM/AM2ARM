#!/bin/sh
# Runs before the bundled runtime, including on unsupported 32-bit systems.
set -u
am2r_check_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
am2r_check_report="$am2r_check_root/compatibility.txt"
am2r_check_status=0
{
    printf '%s\n' 'AM2ARM Linux compatibility check' 'No firmware or network settings were changed.' ''
    printf 'Architecture: '; uname -m
    printf 'Kernel: '; uname -r
    if [ -r /proc/device-tree/model ]; then
        printf 'Model: '; tr '\000' ' ' < /proc/device-tree/model; printf '\n'
    fi
    if [ -r /etc/os-release ]; then
        sed -n '/^ID=/p; /^VERSION_ID=/p; /^PRETTY_NAME=/p' /etc/os-release
    fi
    sed -n '/^MemTotal:/p' /proc/meminfo 2>/dev/null
    printf 'C library: '
    getconf GNU_LIBC_VERSION 2>/dev/null || printf '%s\n' 'unavailable (the runtime check below is authoritative)'
    printf '\nInput devices:\n'
    for am2r_check_input in /sys/class/input/event*/device; do
        [ -r "$am2r_check_input/name" ] || continue
        cat "$am2r_check_input/name"
        for am2r_check_bits in key abs; do
            printf '  %s: ' "$am2r_check_bits"
            cat "$am2r_check_input/capabilities/$am2r_check_bits" 2>/dev/null || printf '\n'
        done
    done
    printf '\nDisplay sockets:\n'
    for am2r_check_dir in "${XDG_RUNTIME_DIR:-/nonexistent}" /var/run /run /run/user/*; do
        for am2r_check_socket in "$am2r_check_dir"/wayland-*; do
            [ -S "$am2r_check_socket" ] && printf '%s\n' "$am2r_check_socket"
        done
    done
    printf '\nFree space (KiB):\n'
    df -Pk "$am2r_check_root" 2>/dev/null
    printf '\nResult:\n'
    case "$(uname -m)" in
        aarch64|arm64) ;;
        *) printf '%s\n' 'STOP: this package requires ARM64 Linux. It cannot run on the original 32-bit RG35XX.'
           am2r_check_status=1 ;;
    esac
    if [ "$am2r_check_status" -eq 0 ]; then
        if ! /lib/ld-linux-aarch64.so.1 --library-path "$am2r_check_root/runtime/lib" "$am2r_check_root/runtime/python/usr/bin/python3.11" -c 'import tkinter, hashlib, lzma, ctypes' 2>&1; then
            printf '%s\n' 'STOP: the bundled runtime cannot load. This may be an older C library, a missing dependency, or an SD card mounted noexec.'
            am2r_check_status=1
        fi
    fi
    if [ "$am2r_check_status" -eq 0 ]; then
        printf '%s\n' 'Runtime loads. Display and game compatibility still require testing.'
    else
        printf '%s\n' 'Keep the existing firmware. Send this report with the model and firmware version.'
    fi
} > "$am2r_check_report" 2>&1 || exit 1
cat "$am2r_check_report"
exit "$am2r_check_status"
