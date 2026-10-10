#!/usr/bin/env bash
# Bluetooth icon with the number of connected devices. A click opens a menu
# with an on/off switch and the paired devices; a click on a device connects
# or disconnects it. Uses blueutil.
#   bluetooth.sh toggle            turn Bluetooth on or off
#   bluetooth.sh device <address>  connect or disconnect one device
#   bluetooth.sh scan              search 8 seconds for new devices
#   bluetooth.sh pair <address>    pair and connect a new device

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
  local i=0 addr name connected icon
  if [ "$(blueutil --power)" = "1" ]; then
    while IFS=$'\t' read -r addr connected name; do
      i=$((i + 1))
      if [ "$connected" = "true" ]; then icon=󰂱; else icon=󰂯; fi
      sketchybar --add item "bt.dev.$i" popup.$PARENT \
        --set "bt.dev.$i" icon="$icon" label="$name" \
          click_script="$PLUGIN_DIR/bluetooth.sh device $addr"
    done < <(blueutil --paired --format json 2>/dev/null |
      jq -r '.[] | [.address, (.connected | tostring), .name] | @tsv')
  fi
  # --move does not reorder popup items, so add the last entries again.
  sketchybar --remove bt.scan --remove bt.settings >/dev/null 2>&1
  sketchybar --remove '/bt\.new\..*/' >/dev/null 2>&1
  if [ "$(blueutil --power)" = "1" ]; then
    sketchybar --add item bt.scan popup.$PARENT \
      --set bt.scan icon=󰂰 label="Search for New Devices" \
        click_script="$PLUGIN_DIR/bluetooth.sh scan"
  fi
  sketchybar --add item bt.settings popup.$PARENT \
    --set bt.settings icon=󰒓 label="Bluetooth Settings" \
      click_script="open 'x-apple.systempreferences:com.apple.BluetoothSettings'; sketchybar --set $PARENT popup.drawing=off"
}

scan() {
  sketchybar --set bt.scan label="Searching…" icon=󰂰
  local found i=0 addr name
  found="$(blueutil --inquiry 8 --format json 2>/dev/null)"
  sketchybar --remove '/bt\.new\..*/' >/dev/null 2>&1
  while IFS=$'\t' read -r addr name; do
    i=$((i + 1))
    sketchybar --add item "bt.new.$i" popup.$PARENT \
      --set "bt.new.$i" icon=󰐕 label="Pair ${name:-$addr}" \
        click_script="$PLUGIN_DIR/bluetooth.sh pair $addr"
  done < <(echo "$found" | jq -r '.[] | select(.paired | not) | [.address, (.name // "")] | @tsv')
  if [ "$i" -eq 0 ]; then
    sketchybar --set bt.scan label="No new devices. Search again"
  else
    sketchybar --set bt.scan label="Search again"
  fi
}

case "${1:-$SENDER}" in
  toggle) blueutil --power toggle; sleep 1; update; devices ;;
  scan) scan ;;
  pair)
    sketchybar --set bt.scan label="Pairing…"
    blueutil --pair "$2" && blueutil --connect "$2"
    update; devices ;;
  device)
    if [ "$(blueutil --is-connected "$2")" = "1" ]; then blueutil --disconnect "$2"; else blueutil --connect "$2"; fi
    update; devices ;;
  mouse.clicked) update; devices; sketchybar --set $PARENT popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off ;;
  *) update ;;
esac
