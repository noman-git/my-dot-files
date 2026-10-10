#!/usr/bin/env bash
# Volume icon and level. A click opens a menu with a slider, mute and the
# audio outputs (switchaudio-osx).
#   volume.sh mute            toggle mute
#   volume.sh output <name>   switch the output device

PARENT=volume
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

update() {
  local vol muted icon
  vol="${1:-$(osascript -e 'output volume of (get volume settings)')}"
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
  sketchybar --set $PARENT icon="$icon" label="${vol}%" \
    --set volume.slider slider.percentage="$vol" \
    --set volume.mute label="$([ "$muted" = "true" ] && echo Unmute || echo Mute)"
}

outputs() {
  sketchybar --remove '/volume\.out\..*/' >/dev/null 2>&1
  command -v SwitchAudioSource >/dev/null 2>&1 || return
  local current i=0 name icon
  current="$(SwitchAudioSource -c -t output)"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    i=$((i + 1))
    if [ "$name" = "$current" ]; then icon=󰄬; else icon=" "; fi
    sketchybar --add item "volume.out.$i" popup.$PARENT \
      --set "volume.out.$i" icon="$icon" label="$name" \
        click_script="$PLUGIN_DIR/volume.sh output \"$name\""
  done < <(SwitchAudioSource -a -t output)
}

case "${1:-$SENDER}" in
  mute) osascript -e 'set volume output muted not (output muted of (get volume settings))'; update ;;
  output) SwitchAudioSource -t output -s "$2" >/dev/null; outputs ;;
  volume_change) update "$INFO" ;;
  mouse.clicked) update; outputs; sketchybar --set $PARENT popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off ;;
  *) update ;;
esac
