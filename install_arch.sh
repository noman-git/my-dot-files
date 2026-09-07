#!/bin/bash

# Function to detect the OS (ensure it's Arch)
detect_os() {
  if [[ -f "/etc/arch-release" ]]; then
    echo "arch"
  else
    echo "unsupported"
  fi
}

# Ensure the script is running on Arch Linux
OS=$(detect_os)
if [[ "$OS" != "arch" ]]; then
  echo "This script is only for Arch Linux!"
  exit 1
fi

# Install yay if not installed
install_yay() {
  if ! command -v yay &>/dev/null; then
    echo "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit
    makepkg -si --noconfirm
    cd - || exit
    rm -rf /tmp/yay
  fi
}

# Install essential packages
install_packages() {
  echo "Installing packages..."
  sudo pacman -S --needed --noconfirm \
    zsh neovim tmux stow yarn fzf ripgrep bat zoxide imagemagick

  # Install additional tools from AUR
  yay -S --needed --noconfirm nerd-fonts-jetbrains-mono
}

# Stow dotfiles packages
stow_dotfiles() {
  echo "Stowing dotfiles..."

  # These stow commands assume your dotfiles repo is organized by package:
  # e.g., a folder named "git" for git configs,
  #       "zsh" for zsh configs,
  #       "kitty" for kitty configs, and
  #       "tmux-powerline" for tmux-powerline configs.
  stow git
  stow zsh
  stow tmux
  stow kitty
  stow tmux-powerline
}

# Main function
main() {
  install_yay
  install_packages
  stow_dotfiles
}

main

