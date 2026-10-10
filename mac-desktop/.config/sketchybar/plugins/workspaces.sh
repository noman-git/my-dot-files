#!/usr/bin/env bash
# Draw all 9 workspaces: the number, then one icon per app on it
# (sketchybar-app-font). The current workspace is a white pill with dark text,
# empty ones are dimmed. Current, not focused: an empty workspace has no
# focused window, so OmniWM reports isFocused=false for it. One sketchybar
# call for all items.

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"
MAX_ICONS=2

current="$(omniwmctl query workspaces --format json 2>/dev/null |
  jq -r '.result.payload.workspaces[] | select(.isCurrent) | .number')"

# One line per workspace with windows: "<number><TAB><app>|<app>|...",
# each app once, in window order.
apps_by_ws="$(omniwmctl query windows --format json 2>/dev/null |
  jq -r '[.result.payload.windows[] | select(.workspace.number != null)
          | {n: .workspace.number, a: .app.name}]
         | group_by(.n)[]
         | "\(.[0].n)\t\(reduce .[].a as $a ([]; if index($a) then . else . + [$a] end) | join("|"))"')"

args=()
for n in 1 2 3 4 5 6 7 8 9; do
  icons=""
  line="$(printf '%s\n' "$apps_by_ws" | awk -F'\t' -v n="$n" '$1 == n { print $2 }')"
  if [ -n "$line" ]; then
    IFS='|' read -r -a names <<< "$line"
    # At most MAX_ICONS icons, then "+N": workspaces 6-9 share the space
    # right of the notch with the system items.
    shown=0
    for name in "${names[@]}"; do
      [ "$shown" -lt "$MAX_ICONS" ] || break
      __icon_map "$name"
      icons+="$icon_result "
      shown=$((shown + 1))
    done
    [ "${#names[@]}" -gt "$MAX_ICONS" ] && icons+="+$(( ${#names[@]} - MAX_ICONS )) "
  fi

  if [ "$n" = "$current" ]; then
    args+=(--set "ws.$n" background.drawing=on icon.color="$ACTIVE_TEXT" label.color="$ACTIVE_TEXT"
      icon.shadow.drawing=off label.shadow.drawing=off)
  elif [ -n "$icons" ]; then
    args+=(--set "ws.$n" background.drawing=off icon.color="$ICON_COLOR" label.color="$ICON_COLOR"
      icon.shadow.drawing=on label.shadow.drawing=on)
  else
    args+=(--set "ws.$n" background.drawing=off icon.color="$MUTED_COLOR" label.color="$MUTED_COLOR"
      icon.shadow.drawing=on label.shadow.drawing=on)
  fi

  if [ -n "$icons" ]; then
    args+=(label="${icons% }" label.drawing=on)
  else
    args+=(label="" label.drawing=off)
  fi
done

sketchybar "${args[@]}"
