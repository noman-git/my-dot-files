#!/usr/bin/env bash
# Volume icon and level. A click opens a menu with a slider, mute and the
# audio outputs (switchaudio-osx) in the slots volume.out.1-6 from sketchybarrc.
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
  command -v SwitchAudioSource >/dev/null 2>&1 || return
  local current i=0 name icon args=()
  current="$(SwitchAudioSource -c -t output)"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    i=$((i + 1))
    [ "$i" -le 6 ] || break
    if [ "$name" = "$current" ]; then icon=󰄬; else icon=󰓃; fi
    args+=(--set "volume.out.$i" drawing=on icon="$icon" label="$name"
      click_script="$PLUGIN_DIR/volume.sh output \"$name\"")
  done < <(SwitchAudioSource -a -t output)
  while [ "$i" -lt 6 ]; do
    i=$((i + 1))
    args+=(--set "volume.out.$i" drawing=off)
  done
  sketchybar "${args[@]}"
}

case "${1:-$SENDER}" in
  mute) osascript -e 'set volume output muted not (output muted of (get volume settings))'; update ;;
  output) SwitchAudioSource -t output -s "$2" >/dev/null; outputs ;;
  volume_change) update "$INFO" ;;
  mouse.clicked)
    [ "$(sketchybar --query $PARENT | jq -r .popup.drawing)" = "off" ] && { update; outputs; }
    sketchybar --set $PARENT popup.drawing=toggle ;;
  mouse.exited.global) sketchybar --set $PARENT popup.drawing=off ;;
  *) update ;;
esac
