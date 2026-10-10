#!/usr/bin/env bash

info="$(pmset -g batt)"
pct="$(echo "$info" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$pct" ] && exit 0

case "$pct" in
  9[0-9]|100) icon=󰁹 ;;
  [6-8][0-9]) icon=󰂀 ;;
  [3-5][0-9]) icon=󰁾 ;;
  [1-2][0-9]) icon=󰁻 ;;
  *) icon=󰂃 ;;
esac
echo "$info" | grep -q "AC Power" && icon=󰂄

sketchybar --set "$NAME" icon="$icon" label="${pct}%"
