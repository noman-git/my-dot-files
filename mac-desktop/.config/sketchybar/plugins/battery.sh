#!/usr/bin/env bash
# Battery icon and percentage. A click opens a menu with the power source,
# the time left and the settings.

PARENT=battery
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

source_line="$(echo "$info" | head -1 | sed -E "s/.*'(.*)'.*/\1/")"
remaining="$(echo "$info" | grep -Eo '[0-9]+:[0-9]+ remaining' | head -1)"
state="$(echo "$info" | grep -Eo '(charging|discharging|charged|finishing charge)' | head -1)"

sketchybar --set $PARENT icon="$icon" label="${pct}%" \
  --set battery.source label="$source_line" \
  --set battery.state label="${state:-unknown}${remaining:+, $remaining}"

case "$SENDER" in
  mouse.clicked) sketchybar --set $PARENT popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off ;;
esac
