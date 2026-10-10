#!/usr/bin/env bash
# Colours as 0xAARRGGBB. wallust writes wallust-colors.sh on every wallpaper
# change (not in git); these defaults are the Hyprland fallback colours.

# Bar background: 0x40 alpha plus blur in sketchybarrc makes it translucent.
export BAR_COLOR=0x4017181c
export ICON_COLOR=0xffe4ecf2
export LABEL_COLOR=0xffe4ecf2
export ACCENT_COLOR=0xff6582ab
export MUTED_COLOR=0xff6b6e75
export POPUP_COLOR=0xd017181c

[ -f "$HOME/.config/sketchybar/wallust-colors.sh" ] && source "$HOME/.config/sketchybar/wallust-colors.sh"
