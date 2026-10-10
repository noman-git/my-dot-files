#!/usr/bin/env bash
# CPU use of all processes as a share of all cores.

cores="$(sysctl -n hw.ncpu)"
pct="$(ps -A -o %cpu= | awk -v c="$cores" '{s += $1} END {printf "%d", s / c}')"
sketchybar --set "$NAME" label="${pct}%"
