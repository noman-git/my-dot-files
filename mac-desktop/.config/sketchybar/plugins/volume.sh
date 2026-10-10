#!/usr/bin/env bash

[ "$SENDER" = "volume_change" ] || exit 0

case "$INFO" in
  0) icon=󰝟 ;;
  [0-9]|[1-3][0-9]) icon=󰕿 ;;
  [4-6][0-9]) icon=󰖀 ;;
  *) icon=󰕾 ;;
esac

sketchybar --set "$NAME" icon="$icon" label="${INFO}%"
