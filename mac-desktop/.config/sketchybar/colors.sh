#!/usr/bin/env bash
# Colours as 0xAARRGGBB.
#
# The bar has no background. Its items sit in glass capsules like the
# macOS Control Center tiles (Liquid Glass): dark see-through tint, blur
# (blur_radius in sketchybarrc), a thin bright edge. The active workspace is
# a white pill with dark text, like an active Control Center toggle. White
# text with a soft shadow. Fixed, so it looks the same on every wallpaper.
export CAPSULE_COLOR=0x59101012     # capsule tint (35% near-black)
export GLASS_EDGE=0x4dffffff        # 1-point bright edge of capsules and menus
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
