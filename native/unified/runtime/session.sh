#!/bin/sh
# route.py passes the resolved display environment to this whole session.
set -eu
rt=${AM2ARM_RUNTIME_DIR:?}
app=$(dirname -- "$rt")
backend=${AM2ARM_DISPLAY_PATH:?}
loader="$rt/core/ld-linux-aarch64.so.1"
libs="$rt/core:$rt/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
printf 'Display path: %s\n' "$backend"
case "$backend" in ports|direct) ;; *) exit 1 ;; esac
bundled_python() {
    "$loader" --library-path "$libs" "$rt/python/usr/bin/python3.11" "$@"
}
if ! bundled_python "$rt/first_run.py"; then
    if [ "$backend" = ports ]; then
        /bin/sh "$app/patcher/launch.sh" "$@" || exit $?
    else
        bundled_python "$rt/nextui_session.py" || exit $?
    fi
    if ! bundled_python "$rt/first_run.py"; then echo 'The game is not installed.'; exit 1; fi
fi
bundled_python "$rt/play.py"
