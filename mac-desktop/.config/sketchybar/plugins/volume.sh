#!/usr/bin/env bash
# Volume icon and level. A click toggles mute.

if [ "$SENDER" = "mouse.clicked" ]; then
  osascript -e 'set volume output muted not (output muted of (get volume settings))'
fi

if [ "$SENDER" = "volume_change" ]; then
  vol="$INFO"
else
  vol="$(osascript -e 'output volume of (get volume settings)')"
fi
muted="$(osascript -e 'output muted of (get volume settings)')"

if [ "$muted" = "true" ] || [ "$vol" = "0" ]; then
  icon=󰝟
else
  case "$vol" in
    [0-9]|[1-3][0-9]) icon=󰕿 ;;
    [4-6][0-9]) icon=󰖀 ;;
    *) icon=󰕾 ;;
  esac
fi

sketchybar --set "$NAME" icon="$icon" label="${vol}%"
