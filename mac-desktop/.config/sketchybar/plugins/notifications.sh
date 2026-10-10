#!/usr/bin/env bash
# Bell with the number of unread items from the Dock badges of running apps
# (Slack, Mail and others), read with lsappinfo. A click opens the
# Notification Center through hammerspoon://notification-center.

PARENT=notifications

if [ "$SENDER" = "mouse.clicked" ]; then
  open -g "hammerspoon://notification-center"
  exit 0
fi

total=0
other=0
while IFS= read -r app; do
  label="$(lsappinfo info -only StatusLabel "$app" 2>/dev/null |
    grep -o '"label"="[^"]*"' | cut -d'"' -f4)"
  [ -n "$label" ] || continue
  if [[ "$label" =~ ^[0-9]+$ ]]; then
    total=$((total + label))
  else
    other=1
  fi
done < <(lsappinfo list 2>/dev/null | awk '
  /^ *[0-9]+\) "/ { match($0, /"[^"]+"/); name = substr($0, RSTART + 1, RLENGTH - 2) }
  /type="Foreground"/ { print name }')

if [ "$total" -gt 0 ]; then
  sketchybar --set $PARENT icon=󰂚 label="$total" label.drawing=on
elif [ "$other" = 1 ]; then
  sketchybar --set $PARENT icon=󰂚 label="•" label.drawing=on
else
  sketchybar --set $PARENT icon=󰂜 label.drawing=off
fi
