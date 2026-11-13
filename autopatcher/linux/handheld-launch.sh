#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ulimit -c 0
mkdir -p state/tmp
export PYTHONHOME="$PWD/runtime/python/usr"
export PYTHONNOUSERSITE=1
export PYTHONDONTWRITEBYTECODE=1
export TCL_LIBRARY="$PWD/runtime/python/usr/share/tcltk/tcl8.6"
export TK_LIBRARY="$PWD/runtime/python/usr/share/tcltk/tk8.6"
export TMPDIR="$PWD/state/tmp"
sh "$PWD/compatibility-check.sh" >"$PWD/state/compatibility.log" 2>&1 || exit 1
exec /lib/ld-linux-aarch64.so.1 --library-path "$PWD/runtime/lib" "$PWD/runtime/python/usr/bin/python3.11" "$PWD/handheld_launch.py" "$@" > state/launcher.log 2>&1
