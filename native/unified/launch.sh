#!/bin/sh
set -eu
base=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export AM2ARM_FRONTEND="${AM2ARM_FRONTEND:-ports}"
case "${1:-}" in auto|patcher) ;; *) set -- auto "$@" ;; esac
exec /bin/sh "$base/runtime/start.sh" "$@"
