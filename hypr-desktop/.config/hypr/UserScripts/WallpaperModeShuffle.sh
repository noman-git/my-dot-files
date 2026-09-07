#!/usr/bin/env bash
# /* ---- 💫 based on JaKooLit WallpaperAutoChange (user modified) 💫 ---- */ ##
# Wallpaper auto-shuffle. Cycles a random wallpaper from a chosen pool every
# INTERVAL seconds. The chosen pool is remembered so it can resume at login.
#
# Launch detached so it forms its own process group, e.g.:
#     setsid WallpaperModeShuffle.sh Dark &
#
#   Usage: WallpaperModeShuffle.sh <Dark|Light|All> [interval_seconds]
#     Dark  -> ~/Pictures/wallpapers/Dynamic-Wallpapers/Dark
#     Light -> ~/Pictures/wallpapers/Dynamic-Wallpapers/Light
#     All   -> ~/Pictures/wallpapers  (everything, recursively)

MODE="${1:-All}"
INTERVAL="${2:-1800}"

base="$HOME/Pictures/wallpapers"
dynamic="$base/Dynamic-Wallpapers"
mode_file="$HOME/.cache/.wallpaper_shuffle_mode"
pid_file="$HOME/.cache/.wallpaper_shuffle.pid"
notif="$HOME/.config/swaync/images/bell.png"
wallust_swww="$HOME/.config/hypr/scripts/WallustSwww.sh"
wallust_refresh="$HOME/.config/hypr/scripts/RefreshNoWaybar.sh"

export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_TYPE=simple

case "$MODE" in
  Dark)  dir="$dynamic/Dark"  ;;
  Light) dir="$dynamic/Light" ;;
  All)   dir="$base"          ;;
  *) echo "Usage: $0 <Dark|Light|All> [interval_seconds]"; exit 1 ;;
esac

# Stop any previously running shuffler. Kill its whole process group (negative
# PID) so the child `sleep` dies too; fall back to a plain kill. Precise: only
# the recorded PID is targeted, never a broad pgrep.
if [ -f "$pid_file" ]; then
  old="$(cat "$pid_file" 2>/dev/null)"
  if [ -n "$old" ] && [ "$old" != "$$" ]; then
    kill -- -"$old" 2>/dev/null || kill "$old" 2>/dev/null
  fi
fi

echo "$$"    > "$pid_file"
echo "$MODE" > "$mode_file"
# Remove the PID file on exit, but only if it still points at us (a newer
# instance may have already claimed it).
trap '[ "$(cat "$pid_file" 2>/dev/null)" = "$$" ] && rm -f "$pid_file"' EXIT

command -v notify-send >/dev/null 2>&1 && \
  notify-send -u low -i "$notif" "Wallpaper shuffle" "ON — $MODE, every $((INTERVAL/60)) min"

while true; do
  mapfile -t imgs < <(find -L "$dir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.gif' -o -iname '*.webp' \) | shuf)

  # Pool empty (e.g. no images in that folder yet) — wait and re-check.
  if [ "${#imgs[@]}" -eq 0 ]; then
    sleep 60
    continue
  fi

  for img in "${imgs[@]}"; do
    swww img "$img"
    "$wallust_swww" "$img" 2>/dev/null
    "$wallust_refresh" 2>/dev/null
    sleep "$INTERVAL"
  done
done
