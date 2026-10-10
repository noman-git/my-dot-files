#!/usr/bin/env bash
# Show the focused workspace and every workspace with windows, in one
# sketchybar call.

source "$HOME/.config/sketchybar/colors.sh"

omniwmctl query workspaces --format json 2>/dev/null |
  jq -r '.result.payload.workspaces[] | "\(.number) \(.isFocused) \(.counts.total)"' | {
    args=()
    while read -r num focused total; do
      [ "$num" -ge 1 ] && [ "$num" -le 9 ] || continue
      if [ "$focused" = "true" ]; then
        args+=(--set "ws.$num" drawing=on background.drawing=on icon.color="$BAR_COLOR")
      elif [ "$total" -gt 0 ]; then
        args+=(--set "ws.$num" drawing=on background.drawing=off icon.color="$ICON_COLOR")
      else
        args+=(--set "ws.$num" drawing=off)
      fi
    done
    [ "${#args[@]}" -gt 0 ] && sketchybar "${args[@]}"
  }
