#!/usr/bin/env bash
# Set up a Mac from this repo.
#
#   ./install_mac.sh [--no-brew] [--no-defaults]
#
# Order: Homebrew, packages from pkgs/Brewfile, wallust, submodules, stow,
# macOS defaults, first wallust colours, then start the desktop apps.
# Re-runnable: brew bundle skips installed packages, cargo skips an installed
# wallust, and stow uses -R.
#
# After the first run, give OmniWM Accessibility and Input Monitoring in
# System Settings > Privacy & Security, give Hammerspoon Accessibility, and
# allow the Karabiner driver extension when Karabiner asks.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd -P)"
cd "$REPO"

DO_BREW=1
DO_DEFAULTS=1
STOW_PACKAGES=(git zsh tmux tmux-powerline kitty nvim btop fastfetch mac-desktop)

log() { printf '\n== %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "this script is for macOS"
[ "$REPO" = "$HOME/my-dot-files" ] || die "clone the repo to ~/my-dot-files; stow links into the parent directory"

for a in "$@"; do
  case "$a" in
    --no-brew) DO_BREW=0 ;;
    --no-defaults) DO_DEFAULTS=0 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $a" ;;
  esac
done

install_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    [ -x /opt/homebrew/bin/brew ] || {
      log "installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    }
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  log "installing packages from pkgs/Brewfile"
  brew bundle --file "$REPO/pkgs/Brewfile"
  log "installing wallust"
  command -v wallust >/dev/null 2>&1 || [ -x "$HOME/.cargo/bin/wallust" ] || cargo install wallust
}

stow_packages() {
  log "stowing ${STOW_PACKAGES[*]}"
  # Pre-create the dirs so stow links the files inside them and not the
  # whole dir. Programs then write their own state next to the links.
  # ~/.config/karabiner is left out on purpose: Karabiner replaces
  # karabiner.json on save, which breaks a file link, so stow links the dir.
  mkdir -p "$HOME/.config/omniwm" "$HOME/.config/hammerspoon" "$HOME/.config/kitty" \
    "$HOME/.config/sketchybar" "$HOME/.config/wallust" "$HOME/.config/cava" "$HOME/.local/bin"
  local p
  for p in "${STOW_PACKAGES[@]}"; do
    if ! stow -R -v "$p"; then
      die "stow $p failed. A real file is in the way; move it aside (do not use --adopt) and rerun."
    fi
  done
}

set_defaults() {
  log "setting macOS defaults"
  defaults write org.hammerspoon.Hammerspoon MJConfigFile "$HOME/.config/hammerspoon/init.lua"
  # OmniWM needs a separate Space for each display.
  defaults write com.apple.spaces spans-displays -bool false
  # Do not reorder Spaces by recent use; OmniWM keeps its own order.
  defaults write com.apple.dock mru-spaces -bool false
  defaults write com.apple.dock autohide -bool true
  # Fast key repeat for vim motions.
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  # Turn off the drag-to-edge window tiling of macOS 15 and later; it fights OmniWM.
  defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
  defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
  # Hide the menu bar; SketchyBar takes its place. Apps pick this up on relaunch.
  defaults write NSGlobalDomain _HIHideMenuBar -bool true
  # Show Notification Center on Hyper+N (symbolic hotkey 163, off by default).
  # The bar's bell sends it through Hammerspoon; macOS has no command for it.
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 163 \
    '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>110</integer><integer>45</integer><integer>1966080</integer></array><key>type</key><string>standard</string></dict></dict>'
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
  killall Dock 2>/dev/null || true
}

build_glassbar() {
  log "building glassbar (real Liquid Glass behind the SketchyBar capsules)"
  mkdir -p "$HOME/.local/bin"
  # Remove first: macOS can kill a signed binary that was overwritten in
  # place (it caches the old signature).
  rm -f "$HOME/.local/bin/glassbar"
  swiftc -O "$REPO/mac-desktop/.config/sketchybar/helpers/glassbar/main.swift" \
    -o "$HOME/.local/bin/glassbar" || log "glassbar did not build; the bar works without glass"
}

seed_colours() {
  [ -f "$HOME/.cache/.current_wallpaper" ] && return
  log "first wallust colours from seed/wallpaper.jpg"
  "$HOME/.local/bin/mac-wallpaper" "$REPO/seed/wallpaper.jpg" || true
}

start_apps() {
  log "starting OmniWM, SketchyBar, Hammerspoon and Karabiner"
  open -a OmniWM || true
  brew services start sketchybar || true
  open -a Hammerspoon || true
  open -a Karabiner-Elements || true
}

main() {
  [ "$DO_BREW" = 1 ] && install_brew
  log "updating submodules"
  git submodule update --init --recursive
  stow_packages
  [ "$DO_DEFAULTS" = 1 ] && set_defaults
  build_glassbar
  seed_colours
  start_apps
  log "done. Grant the permissions listed at the top of this script, then log out and in once."
}

main
