#!/usr/bin/env bash
# Wi-Fi icon. A click opens a menu with an on/off switch and the settings.
#   wifi.sh toggle   turn Wi-Fi on or off (from the menu)

PARENT=wifi
power() { networksetup -getairportpower en0 | awk '{print $NF}'; }

update() {
  if [ "$(power)" != "On" ]; then
    sketchybar --set $PARENT icon=󰖪 --set wifi.toggle label="Turn Wi-Fi On"
  elif [ -n "$(ipconfig getifaddr en0)" ]; then
    sketchybar --set $PARENT icon=󰖩 --set wifi.toggle label="Turn Wi-Fi Off"
  else
    sketchybar --set $PARENT icon=󰤮 --set wifi.toggle label="Turn Wi-Fi Off"
  fi
}

case "${1:-$SENDER}" in
  toggle)
    if [ "$(power)" = "On" ]; then networksetup -setairportpower en0 off; else networksetup -setairportpower en0 on; fi
    sleep 1; update ;;
  mouse.clicked) update; sketchybar --set $PARENT popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off ;;
  *) update ;;
esac
