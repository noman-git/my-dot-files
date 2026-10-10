#!/usr/bin/env bash
# Memory in use, from the free percentage that memory_pressure reports.

free="$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/ {gsub("%", "", $2); print $2}')"
[ -n "$free" ] && sketchybar --set "$NAME" label="$((100 - free))%"
