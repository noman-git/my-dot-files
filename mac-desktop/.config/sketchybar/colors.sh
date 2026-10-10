#!/usr/bin/env bash
# Colours as 0xAARRGGBB.
#
# Glass style, like macOS Liquid Glass: a light frosted tint with a strong
# blur (blur_radius in sketchybarrc), a thin bright edge and white text.
# These stay fixed so the bar looks the same on every wallpaper.
export GLASS_COLOR=0x26ffffff       # bar tint
export GLASS_EDGE=0x47ffffff        # 1-point edge of the bar, menus, active pill
export GLASS_ACTIVE=0x38ffffff      # active workspace pill
export POPUP_COLOR=0x991c1c1e       # menus: darker glass for readable text
export ICON_COLOR=0xf2ffffff
export LABEL_COLOR=0xf2ffffff
export MUTED_COLOR=0x8cffffff       # empty workspaces, slider track

# Accent for the music bars and the volume slider. Fixed too: wallust
# accents from dark wallpapers were too dark to see on the glass.
export ACCENT_COLOR=0xff8fb8ff
