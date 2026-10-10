#!/usr/bin/env bash
# VPN icon, shown while a VPN is on: the default route goes through a utun
# interface (NordVPN and most other VPNs). NordVPN for macOS has no command-line tool,
# so a click opens the app to connect or disconnect.

PARENT=vpn
iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
# Hidden while off: the dimmed off icon was nearly invisible but kept its
# space in the bar.
if [[ "$iface" == utun* ]]; then
  sketchybar --set $PARENT drawing=on icon=󰒃 icon.color="$ACCENT_COLOR"
else
  sketchybar --set $PARENT drawing=off
fi
