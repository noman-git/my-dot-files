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

# Set up Git (optional)
setup_git() {
  echo "Setting up git..."
  if ! command -v git &>/dev/null; then
    echo "Git is not installed. Installing..."
    sudo pacman -S --noconfirm git
  fi

  read -p "Enter your Git username: " git_username
  read -p "Enter your Git email: " git_email

  git config --global user.name "$git_username"
  git config --global user.email "$git_email"
  git config --global init.defaultBranch main

  echo "Git configured successfully!"
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
  stow kitty
  stow tmux-powerline
}

# Main function
main() {
  install_yay
  install_packages
  # Uncomment the next line if you want to set up git interactively.
  # setup_git
  stow_dotfiles
}

main

