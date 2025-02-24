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
  yay -S --needed --noconfirm \
    nerd-fonts-jetbrains-mono lsix vv
}

# Set up Git
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

# Set up Zsh
setup_zsh() {
  echo "Setting up zsh..."

  if ! grep -q "$(which zsh)" /etc/shells; then
    echo "$(which zsh)" | sudo tee -a /etc/shells
  fi

  if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s "$(which zsh)"
    echo "Default shell changed to Zsh. Restart your terminal."
  fi
}

# Main function
main() {
  install_yay
  install_packages
  # setup_git  # Uncomment if needed
  stow git
  stow zsh
  setup_zsh
  sudo pacman -S nodejs npm

  echo "Installation completed! Restart your terminal to apply changes."
}

main
