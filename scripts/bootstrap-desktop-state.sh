#!/usr/bin/env bash
# Seed the gitignored desktop state on a fresh machine, so the first Hyprland
# login has a wallpaper, wallust colours, and a waybar layout and style.
# Run after `stow hypr-desktop`. Idempotent: anything that exists is kept.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
H="$HOME/.config/hypr"
W="$HOME/.config/waybar"
R="$HOME/.config/rofi"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"

[ -d "$H" ] || { echo "error: $H not found, run stow hypr-desktop first" >&2; exit 1; }

mkdir -p "$H/wallpaper_effects" "$H/wallust" "$W/wallust" "$R/wallust" "$CACHE" \
         "$HOME/Pictures/wallpapers/Dynamic-Wallpapers/Dark" \
         "$HOME/Pictures/wallpapers/Dynamic-Wallpapers/Light"

seed() { # description, test, command...
  local what="$1"; shift
  if eval "$1"; then echo "  present   $what"; else shift; echo "  create    $what"; "$@"; fi
}

current="$H/wallpaper_effects/.wallpaper_current"
seed "current wallpaper" "[ -f '$current' ]" cp "$REPO/seed/wallpaper.jpg" "$current"
seed "rofi/.current_wallpaper" "[ -e '$R/.current_wallpaper' ]" ln -s "$current" "$R/.current_wallpaper"
seed "waybar/config" "[ -e '$W/config' ]" ln -s "$HOME/.config/waybar/configs/[TOP] Default Laptop" "$W/config"
seed "waybar/style.css" "[ -e '$W/style.css' ]" ln -s "$HOME/.config/waybar/style/[Colored] Translucent.css" "$W/style.css"
seed "~/.cache/.theme_mode" "[ -f '$CACHE/.theme_mode' ]" sh -c "echo Dark > '$CACHE/.theme_mode'"
seed "~/.cache/.wallpaper_shuffle_mode" "[ -f '$CACHE/.wallpaper_shuffle_mode' ]" sh -c "echo off > '$CACHE/.wallpaper_shuffle_mode'"

if command -v wallust >/dev/null 2>&1; then
  seed "wallust colours" "[ -f '$H/wallust/wallust-hyprland.conf' ]" wallust run -s "$current"
else
  echo "  wallust not installed, colour templates not generated"
fi

if [ ! -d "$HOME/Pictures/wallpapers/Dynamic-Wallpapers/Dark" ] || [ -z "$(ls -A "$HOME/Pictures/wallpapers/Dynamic-Wallpapers/Dark")" ]; then
  echo
  echo "Wallpapers are not in git. Copy your sets into:"
  echo "  $HOME/Pictures/wallpapers/Dynamic-Wallpapers/Dark"
  echo "  $HOME/Pictures/wallpapers/Dynamic-Wallpapers/Light"
fi
