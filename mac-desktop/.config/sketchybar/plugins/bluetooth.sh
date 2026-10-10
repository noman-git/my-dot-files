#!/usr/bin/env bash
# Bluetooth power and the number of connected devices (blueutil).

command -v blueutil >/dev/null 2>&1 || { sketchybar --set "$NAME" drawing=off; exit 0; }

if [ "$(blueutil --power)" != "1" ]; then
  sketchybar --set "$NAME" icon=󰂲 label.drawing=off
  exit 0
fi

count="$(blueutil --connected --format json 2>/dev/null | jq 'length')"
if [ "${count:-0}" -gt 0 ]; then
  sketchybar --set "$NAME" icon=󰂱 label="$count" label.drawing=on
else
  sketchybar --set "$NAME" icon=󰂯 label.drawing=off
fi
