#!/usr/bin/env bash
# /* ---- 💫 user script 💫 ---- */ ##
# Restore wallpaper state at login. If the last choice was a shuffle pool,
# resume it; otherwise just repaint the last manually-picked wallpaper.
# Called from Startup_Apps.conf, after swww-daemon is up.

mode_file="$HOME/.cache/.wallpaper_shuffle_mode"
current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
shuffle="$HOME/.config/hypr/UserScripts/WallpaperModeShuffle.sh"

mode="$(cat "$mode_file" 2>/dev/null)"
case "$mode" in
  Dark|Light|All) setsid "$shuffle" "$mode" >/dev/null 2>&1 & ;;
  *) [ -f "$current" ] && swww img "$current" ;;
esac
