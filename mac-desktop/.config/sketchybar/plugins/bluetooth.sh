#!/usr/bin/env bash
# Bluetooth icon with the number of connected devices. A click opens a menu
# with an on/off switch, the paired devices (click to connect or
# disconnect), a search for new devices and the settings. Uses blueutil.
# The menu entries are fixed slots from sketchybarrc: bt.dev.1-8, bt.new.1-8.
#   bluetooth.sh toggle            turn Bluetooth on or off
#   bluetooth.sh device <address>  connect or disconnect one device
#   bluetooth.sh scan              search 6 seconds for new devices
#   bluetooth.sh pair <address>    pair and connect a new device

PARENT=bluetooth
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
SLOTS=8
command -v blueutil >/dev/null 2>&1 || { sketchybar --set $PARENT drawing=off; exit 0; }

update() {
  if [ "$(blueutil --power)" != "1" ]; then
    sketchybar --set $PARENT icon=󰂲 label.drawing=off \
      --set bt.toggle label="Turn Bluetooth On" --set bt.scan drawing=off
    return
  fi
  local count
  count="$(blueutil --connected --format json 2>/dev/null | jq 'length')"
  if [ "${count:-0}" -gt 0 ]; then
    sketchybar --set $PARENT icon=󰂱 label="$count" label.drawing=on
  else
    sketchybar --set $PARENT icon=󰂯 label.drawing=off
  fi
  sketchybar --set bt.toggle label="Turn Bluetooth Off" --set bt.scan drawing=on
}

# fill <prefix> <lines of "address<TAB>icon<TAB>label<TAB>action">
fill() {
  local prefix="$1" i=0 addr icon label action args=()
  while IFS=$'\t' read -r addr icon label action; do
    [ -n "$addr" ] || continue
    i=$((i + 1))
    [ "$i" -le "$SLOTS" ] || break
    args+=(--set "$prefix.$i" drawing=on icon="$icon" label="$label"
      click_script="$PLUGIN_DIR/bluetooth.sh $action $addr")
  done <<< "$2"
  while [ "$i" -lt "$SLOTS" ]; do
    i=$((i + 1))
    args+=(--set "$prefix.$i" drawing=off)
  done
  sketchybar "${args[@]}"
}

devices() {
  local lines=""
  if [ "$(blueutil --power)" = "1" ]; then
    lines="$(blueutil --paired --format json 2>/dev/null |
      jq -r '.[] | [.address, (if .connected then "󰂱" else "󰂯" end), .name, "device"] | @tsv')"
  fi
  fill bt.dev "$lines"
}

scan() {
  sketchybar --set bt.scan label="Searching for 6 seconds…"
  local lines
  lines="$(blueutil --inquiry 6 --format json 2>/dev/null |
    jq -r '.[] | select(.paired | not) | [.address, "󰐕", ("Pair " + (.name // .address)), "pair"] | @tsv')"
  fill bt.new "$lines"
  if [ -z "$lines" ]; then
    sketchybar --set bt.scan label="No device in pairing mode. Search again"
  else
    sketchybar --set bt.scan label="Search again"
  fi
}

case "${1:-$SENDER}" in
  toggle) blueutil --power toggle; sleep 1; update; devices ;;
  device)
    if [ "$(blueutil --is-connected "$2")" = "1" ]; then blueutil --disconnect "$2"; else blueutil --connect "$2"; fi
    update; devices ;;
  scan) scan ;;
  pair)
    sketchybar --set bt.scan label="Pairing…"
    blueutil --pair "$2" && blueutil --connect "$2"
    fill bt.new ""
    update; devices
    sketchybar --set bt.scan label="Search for New Devices" ;;
  mouse.clicked)
    if [ "$(sketchybar --query $PARENT | jq -r .popup.drawing)" = "off" ]; then
      update; devices
      fill bt.new ""
      sketchybar --set bt.scan label="Search for New Devices"
    fi
    sketchybar --set $PARENT popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off ;;
  *) update ;;
esac
