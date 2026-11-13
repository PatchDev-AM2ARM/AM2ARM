#!/bin/sh
set -eu
am2r_ports_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec sh "$am2r_ports_dir"/'AM2ARM Autopatcher'/launch.sh "$@"
