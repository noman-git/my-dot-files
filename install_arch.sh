#!/usr/bin/env bash
# Set up an Arch machine from this repo.
#
#   ./install_arch.sh [--nvidia|--no-nvidia] [--dev-services] [--skip-aur] [--no-system]
#
# Order: pacman options, packages by group, yay and AUR packages, submodules,
# stow every package, seed the desktop state, xremap, shell, then the
# system-level files through install_system.sh (sudo). Re-runnable: pacman
# uses --needed, stow uses -R, and every seeding step checks first.
#
# Before running: create your SSH key and add it to GitHub. git/.gitconfig
# rewrites https://github.com/ to ssh, so clones fail without a key.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$REPO"

NVIDIA=auto
DEV_SERVICES=0
SKIP_AUR=0
DO_SYSTEM=1
STOW_PACKAGES=(git zsh tmux tmux-powerline kitty nvim hypr-desktop)

log() { printf '\n== %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ -f /etc/arch-release ] || die "this script is for Arch Linux"

for a in "$@"; do
  case "$a" in
    --nvidia) NVIDIA=yes ;;
    --no-nvidia) NVIDIA=no ;;
    --dev-services) DEV_SERVICES=1 ;;
    --skip-aur) SKIP_AUR=1 ;;
    --no-system) DO_SYSTEM=0 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $a" ;;
  esac
done

detect_nvidia() {
  case "$NVIDIA" in yes) return 0 ;; no) return 1 ;; esac
  local d
  for d in /sys/bus/pci/devices/*; do
    [ -r "$d/vendor" ] && [ -r "$d/class" ] || continue
    [ "$(cat "$d/vendor")" = "0x10de" ] && [[ "$(cat "$d/class")" == 0x03* ]] && return 0
  done
  return 1
}

pkg_list() { grep -hv '^[[:space:]]*#' "$@" | sed 's/[[:space:]]*#.*//' | awk 'NF' | sort -u; }

install_yay() {
  command -v yay >/dev/null 2>&1 && return
  log "installing yay-bin from the AUR"
  local tmp; tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

main() {
  local has_nvidia=0 is_intel=0 groups=()
  detect_nvidia && has_nvidia=1
  grep -q GenuineIntel /proc/cpuinfo && is_intel=1
  echo "repo:   $REPO"
  echo "nvidia: $([ "$has_nvidia" = 1 ] && echo yes || echo no) (mode: $NVIDIA)"
  echo "intel:  $([ "$is_intel" = 1 ] && echo yes || echo no)"
  sudo -v

  log "pacman.conf options"
  sudo ./install_system.sh --pacman-only

  log "packages"
  groups=(pkgs/base.txt pkgs/hyprland.txt pkgs/fonts.txt pkgs/dev.txt pkgs/apps.txt pkgs/tools.txt)
  [ "$is_intel" = 1 ] && groups+=(pkgs/intel.txt)
  [ "$has_nvidia" = 1 ] && groups+=(pkgs/nvidia.txt)
  [ -f pkgs/unsorted.txt ] && groups+=(pkgs/unsorted.txt)
  pkg_list "${groups[@]}" | xargs sudo pacman -S --needed --noconfirm

  if [ "$SKIP_AUR" = 0 ]; then
    log "AUR packages"
    install_yay
    # pyenv shadows /usr/bin/python for makepkg; some AUR builds need the
    # system python-gobject, so pin the system interpreter for the build.
    pkg_list pkgs/aur.txt | xargs PYENV_VERSION=system yay -S --needed --noconfirm
  fi

  log "submodules (nvim)"
  git submodule update --init --remote

  log "stow"
  # Pre-create the dirs that other programs write into, so stow links files
  # into them instead of folding the whole dir into the repo.
  mkdir -p "$HOME/.config/systemd/user" "$HOME/.local/bin" "$HOME/.cache" \
           "$HOME/Pictures/wallpapers/Dynamic-Wallpapers/Dark" \
           "$HOME/Pictures/wallpapers/Dynamic-Wallpapers/Light"
  local p
  for p in "${STOW_PACKAGES[@]}"; do
    if ! stow -R -v "$p"; then
      die "stow $p failed. A real file is in the way; move it aside (do not use --adopt) and rerun."
    fi
  done

  log "desktop state"
  scripts/bootstrap-desktop-state.sh

  log "xremap"
  if [ ! -x "$HOME/.cargo/bin/xremap" ]; then
    cargo install xremap --features hyprland
  fi
  systemctl --user daemon-reload
  systemctl --user enable xremap.service

  log "shell"
  ./setup_shell.sh

  if [ "$DO_SYSTEM" = 1 ]; then
    log "system files (sudo)"
    local flags=()
    [ "$NVIDIA" = yes ] && flags+=(--nvidia)
    [ "$NVIDIA" = no ] && flags+=(--no-nvidia)
    [ "$DEV_SERVICES" = 1 ] && flags+=(--dev-services)
    sudo ./install_system.sh "${flags[@]}"
  fi

  cat <<'NEXT'

Done. Next:
  1. Reboot, pick Hyprland in SDDM.
  2. Run nwg-displays, save, then run hypr-normalize-monitors.
  3. Copy your wallpapers into ~/Pictures/wallpapers/Dynamic-Wallpapers/{Dark,Light}
     and pick one with SUPER+W.
  4. Check `hyprctl configerrors` and `hyprctl devices -j | jq '.mice[].name'`;
     update the touchpad name in ~/.config/hypr/lua/laptop.lua if it differs.
  5. Optional: ./lang_setup.sh for pyenv, the neovim virtualenv and node.
NEXT
}

main "$@"
