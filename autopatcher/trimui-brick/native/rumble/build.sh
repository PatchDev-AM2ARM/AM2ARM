#!/bin/sh
set -eu
: "${SYSROOT:?Set SYSROOT to the Debian 12 ARM64 development sysroot}"
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build_dir=$(mktemp -d)
trap 'rm -f "$build_dir/evdev.o"; rmdir "$build_dir"' EXIT
compiler=${CC:-clang}
"$compiler" --target=aarch64-linux-gnu --sysroot="$SYSROOT" \
    --gcc-install-dir="$SYSROOT/usr/lib/gcc/aarch64-linux-gnu/12" \
    -I"$SYSROOT/usr/include/aarch64-linux-gnu" -ffile-prefix-map="$source_dir"=rumble \
    -Wall -Wextra -Werror -O2 -fPIC -fvisibility=hidden \
    -DAM2ARM_Rumble=AM2ARM_EvdevRumble -DAM2ARM_RumbleStop=AM2ARM_EvdevRumbleStop \
    -c "$source_dir/evdev_rumble.c" -o "$build_dir/evdev.o"
"$compiler" --target=aarch64-linux-gnu --sysroot="$SYSROOT" \
    --gcc-install-dir="$SYSROOT/usr/lib/gcc/aarch64-linux-gnu/12" \
    -I"$SYSROOT/usr/include/aarch64-linux-gnu" -ffile-prefix-map="$source_dir"=rumble \
    -Wall -Wextra -Werror -O2 -fPIC -fvisibility=hidden -fuse-ld=lld \
    -shared "$source_dir/brick_rumble.c" "$build_dir/evdev.o" -lm -o "$1"
llvm-strip --strip-unneeded "$1"
