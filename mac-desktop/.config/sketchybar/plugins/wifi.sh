#!/usr/bin/env bash
# Wi-Fi on/off and the IP address. macOS hides the network name (SSID) from
# programs without Location access, so it is not shown.

if [ "$(networksetup -getairportpower en0 | awk '{print $NF}')" != "On" ]; then
  sketchybar --set "$NAME" icon=󰖪 label="off"
  exit 0
fi

ip="$(ipconfig getifaddr en0)"
if [ -n "$ip" ]; then
  sketchybar --set "$NAME" icon=󰖩 label="$ip"
else
  sketchybar --set "$NAME" icon=󰖪 label="no network"
fi
