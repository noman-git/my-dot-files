#!/usr/bin/env bash
# Colours as 0xAARRGGBB.
#
# The bar has no background. The active workspace pill and the menus use a
# glass style like macOS Liquid Glass: a light tint, blur, a thin bright
# edge. White text with a soft shadow. Fixed, so it looks the same on every
# wallpaper.
export GLASS_EDGE=0x66ffffff        # 1-point bright edge of the menus and active pill
export GLASS_ACTIVE=0x38ffffff      # active workspace pill
export POPUP_COLOR=0x991c1c1e       # menus: darker glass for readable text
export ICON_COLOR=0xf2ffffff
export LABEL_COLOR=0xf2ffffff
export MUTED_COLOR=0x8cffffff       # empty workspaces, slider track
export TEXT_SHADOW=0x80000000       # keeps white text readable on light wallpapers

# Accent for the music bars and the volume slider. Fixed too: wallust
# accents from dark wallpapers were too dark to see on the glass.
export ACCENT_COLOR=0xff8fb8ff
