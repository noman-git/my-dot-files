#!/usr/bin/env bash
# VPN on or off: on when the default route goes through a utun interface
# (NordVPN and most other VPNs). NordVPN for macOS has no command-line tool,
# so a click opens the app to connect or disconnect.

PARENT=vpn
iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
if [[ "$iface" == utun* ]]; then
  sketchybar --set $PARENT icon=󰒃 icon.color="$ACCENT_COLOR"
else
  sketchybar --set $PARENT icon=󰦞 icon.color="$MUTED_COLOR"
fi
