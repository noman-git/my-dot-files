#!/usr/bin/env bash
# Colours as 0xAARRGGBB.
#
# The bar has no background. Its items sit in glass capsules that glassbar
# draws with real macOS Liquid Glass (helpers/glassbar). The active
# workspace is a white pill with dark text, like an active Control Center
# toggle. White text with a soft shadow. The menus use SketchyBar's own
# blur with these colours. Fixed, so it looks the same on every wallpaper.
export GLASS_EDGE=0x59ffffff        # 1-point bright edge of the menus
export ACTIVE_COLOR=0xf2ffffff      # active workspace pill
export ACTIVE_TEXT=0xff1c1c1e       # text on the active workspace pill
export POPUP_COLOR=0x80101012       # menus: same glass, a little darker
export ICON_COLOR=0xf2ffffff
export LABEL_COLOR=0xf2ffffff
export MUTED_COLOR=0x8cffffff       # empty workspaces, slider track
export TEXT_SHADOW=0x66000000       # keeps white text readable on light wallpapers

# Accent for the music bars and the volume slider. Fixed too: wallust
# accents from dark wallpapers were too dark to see on the glass.
export ACCENT_COLOR=0xff8fb8ff
