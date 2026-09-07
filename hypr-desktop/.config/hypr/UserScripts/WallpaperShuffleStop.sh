#!/usr/bin/env bash
# /* ---- 💫 user script 💫 ---- */ ##
# Turn the wallpaper auto-shuffle OFF. Called whenever a wallpaper is chosen
# manually (WallpaperSelect / WallpaperRandom) so the pick is not overwritten
# at the next shuffle tick. Records "off" so login does not resume shuffling.

pid_file="$HOME/.cache/.wallpaper_shuffle.pid"
mode_file="$HOME/.cache/.wallpaper_shuffle_mode"

if [ -f "$pid_file" ]; then
  pid="$(cat "$pid_file" 2>/dev/null)"
  if [ -n "$pid" ]; then
    # Kill the whole process group so the child `sleep` dies too.
    kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null
  fi
fi
rm -f "$pid_file"
echo "off" > "$mode_file"
