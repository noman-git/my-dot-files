#!/usr/bin/env bash
# Weather from wttr.in: icon and temperature in the bar, a 3-day forecast in
# the menu. The place is ~/.cache/location ("lat,lon", written by
# Hammerspoon from Location Services); without it wttr.in uses the IP
# address, which is the VPN server's city while a VPN is on.

PARENT=weather

case "$SENDER" in
  mouse.clicked) sketchybar --set $PARENT popup.drawing=toggle; exit 0 ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off; exit 0 ;;
esac

place="$(cat "$HOME/.cache/location" 2>/dev/null)"
json="$(curl -fsS -m 15 "https://wttr.in/${place}?format=j1" 2>/dev/null)" || exit 0
[ -n "$json" ] || exit 0

# wttr.in weather codes to Nerd Font icons (day icons).
icon_for() {
  case "$1" in
    113) echo 󰖙 ;;
    116) echo 󰖕 ;;
    119|122) echo 󰖐 ;;
    143|248|260) echo 󰖑 ;;
    176|263|266|293|296|299|302|305|308|311|314|353|356|359) echo 󰖗 ;;
    179|182|185|227|230|317|320|323|326|329|332|335|338|350|362|365|368|371|374|377) echo 󰖘 ;;
    200|386|389|392|395) echo 󰖓 ;;
    *) echo 󰖐 ;;
  esac
}

code="$(echo "$json" | jq -r '.current_condition[0].weatherCode')"
temp="$(echo "$json" | jq -r '.current_condition[0].temp_C')"
feels="$(echo "$json" | jq -r '.current_condition[0].FeelsLikeC')"
desc="$(echo "$json" | jq -r '.current_condition[0].weatherDesc[0].value | gsub("^\\s+|\\s+$"; "")')"
humidity="$(echo "$json" | jq -r '.current_condition[0].humidity')"
area="$(echo "$json" | jq -r '.nearest_area[0].areaName[0].value')"

args=(--set $PARENT icon="$(icon_for "$code")" label="${temp}°"
  --set weather.now label="$area: $desc, feels ${feels}°, humidity ${humidity}%")
i=0
while IFS=$'\t' read -r date max min dcode; do
  i=$((i + 1))
  day="$(date -j -f %Y-%m-%d "$date" +%a 2>/dev/null || echo "$date")"
  args+=(--set "weather.day.$i" icon="$(icon_for "$dcode")" label="$day  ${min}° to ${max}°")
done < <(echo "$json" | jq -r '.weather[] | [.date, .maxtempC, .mintempC, .hourly[4].weatherCode] | @tsv')
sketchybar "${args[@]}"
