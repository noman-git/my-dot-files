#!/usr/bin/env bash
# Colours as 0xAARRGGBB. wallust writes wallust-colors.sh on every wallpaper
# change (not in git); these defaults are the Hyprland fallback colours.

export BAR_COLOR=0xcc17181c
export ICON_COLOR=0xffe4ecf2
export LABEL_COLOR=0xffe4ecf2
export ACCENT_COLOR=0xff6582ab
export MUTED_COLOR=0xff3e3f43

[ -f "$HOME/.config/sketchybar/wallust-colors.sh" ] && source "$HOME/.config/sketchybar/wallust-colors.sh"
