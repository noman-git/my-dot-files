#!/usr/bin/env bash
# Bluetooth icon with the number of connected devices. A click opens a menu
# with an on/off switch and the paired devices; a click on a device connects
# or disconnects it. Uses blueutil.
#   bluetooth.sh toggle            turn Bluetooth on or off
#   bluetooth.sh device <address>  connect or disconnect one device

PARENT=bluetooth
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
command -v blueutil >/dev/null 2>&1 || { sketchybar --set $PARENT drawing=off; exit 0; }

update() {
  if [ "$(blueutil --power)" != "1" ]; then
    sketchybar --set $PARENT icon=󰂲 label.drawing=off --set bt.toggle label="Turn Bluetooth On"
    return
  fi
  local count
  count="$(blueutil --connected --format json 2>/dev/null | jq 'length')"
  if [ "${count:-0}" -gt 0 ]; then
    sketchybar --set $PARENT icon=󰂱 label="$count" label.drawing=on
  else
    sketchybar --set $PARENT icon=󰂯 label.drawing=off
  fi
  sketchybar --set bt.toggle label="Turn Bluetooth Off"
}

devices() {
  sketchybar --remove '/bt\.dev\..*/' >/dev/null 2>&1
  [ "$(blueutil --power)" = "1" ] || return
  local i=0 addr name connected icon
  while IFS=$'\t' read -r addr connected name; do
    i=$((i + 1))
    if [ "$connected" = "true" ]; then icon=󰂱; else icon=󰂯; fi
    sketchybar --add item "bt.dev.$i" popup.$PARENT \
      --set "bt.dev.$i" icon="$icon" label="$name" \
        click_script="$PLUGIN_DIR/bluetooth.sh device $addr"
  done < <(blueutil --paired --format json 2>/dev/null |
    jq -r '.[] | [.address, (.connected | tostring), .name] | @tsv')
  [ "$i" -gt 0 ] && sketchybar --move bt.settings after "bt.dev.$i"
}

case "${1:-$SENDER}" in
  toggle) blueutil --power toggle; sleep 1; update; devices ;;
  device)
    if [ "$(blueutil --is-connected "$2")" = "1" ]; then blueutil --disconnect "$2"; else blueutil --connect "$2"; fi
    update; devices ;;
  mouse.clicked) update; devices; sketchybar --set $PARENT popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off ;;
  *) update ;;
esac
