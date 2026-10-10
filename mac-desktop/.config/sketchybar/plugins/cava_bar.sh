#!/usr/bin/env bash
# Music bars in SketchyBar, like WaybarCava.sh on Arch: cava writes one line
# per frame ("3;5;0;..." with values 0-7), and each line becomes block
# characters in the cava item. Only bash builtins in the loop, so a frame
# costs one sketchybar call.

blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
last=""
cava -p "$HOME/.config/sketchybar/cava_bar.conf" | while IFS=';' read -r -a values; do
  out=""
  for v in "${values[@]}"; do
    [[ "$v" =~ ^[0-7]$ ]] && out+="${blocks[$v]}"
  done
  # Skip frames that did not change (silence sends the same zero frame).
  if [ -n "$out" ] && [ "$out" != "$last" ]; then
    sketchybar --set cava label="$out"
    last="$out"
  fi
done
