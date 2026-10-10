#!/usr/bin/env bash
# Set up a Mac from this repo.
#
#   ./install_mac.sh [--no-brew] [--no-defaults]
#
# Order: Homebrew, packages from pkgs/Brewfile, submodules, stow, Hammerspoon
# config path, macOS defaults, then start OmniWM and Hammerspoon. Re-runnable:
# brew bundle skips installed packages and stow uses -R.
#
# After the first run, give OmniWM Accessibility and Input Monitoring in
# System Settings > Privacy & Security, and give Hammerspoon Accessibility.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd -P)"
cd "$REPO"

DO_BREW=1
DO_DEFAULTS=1
STOW_PACKAGES=(git zsh tmux tmux-powerline kitty nvim mac-desktop)

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
}

stow_packages() {
  log "stowing ${STOW_PACKAGES[*]}"
  # Pre-create the dirs so stow links the files inside them and not the
  # whole dir. Programs then write their own state next to the links.
  mkdir -p "$HOME/.config/omniwm" "$HOME/.config/hammerspoon" "$HOME/.config/kitty"
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
  killall Dock 2>/dev/null || true
}

start_apps() {
  log "starting OmniWM and Hammerspoon"
  open -a OmniWM || true
  open -a Hammerspoon || true
}

main() {
  [ "$DO_BREW" = 1 ] && install_brew
  log "updating submodules"
  git submodule update --init --recursive
  stow_packages
  [ "$DO_DEFAULTS" = 1 ] && set_defaults
  start_apps
  log "done. Grant the permissions listed at the top of this script, then log out and in once."
}

main
