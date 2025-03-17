#!/bin/bash

# Function to detect the OS (ensure it's Ubuntu)
detect_os() {
  if [[ -f "/etc/os-release" ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
      echo "ubuntu"
      return
    fi
  fi
  echo "unsupported"
}

# Ensure the script is running on Ubuntu
OS=$(detect_os)
if [[ "$OS" != "ubuntu" ]]; then
  echo "This script is only for Ubuntu!"
  exit 1
fi

# Update package lists and install essential packages
install_packages() {
  echo "Updating package lists..."
  sudo apt update
  echo "Installing packages..."
  sudo apt install -y \
    zsh neovim tmux stow yarn fzf ripgrep bat zoxide imagemagick git
}

# Optionally, install Nerd Fonts JetBrains Mono manually
install_nerd_font() {
  echo "Installing Nerd Fonts JetBrains Mono..."
  # Example URL for JetBrainsMono Nerd Font (version might change; check the repo for updates)
  FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip"
  TEMP_DIR=$(mktemp -d)
  wget -O "$TEMP_DIR/JetBrainsMono.zip" "$FONT_URL"
  unzip "$TEMP_DIR/JetBrainsMono.zip" -d "$TEMP_DIR/JetBrainsMono"
  mkdir -p ~/.local/share/fonts/JetBrainsMono
  cp "$TEMP_DIR/JetBrainsMono"/* ~/.local/share/fonts/JetBrainsMono/
  fc-cache -fv
  rm -rf "$TEMP_DIR"
}

# Set up Git (optional)
setup_git() {
  echo "Setting up git..."
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
  # Assumes your dotfiles repo is organized in subdirectories (e.g., git, zsh, kitty, tmux-powerline)
  stow git
  stow zsh
  stow kitty
  stow tmux-powerline
}

# Main function
main() {
  install_packages
  # Uncomment the next line if you want to install Nerd Fonts JetBrains Mono.
  # install_nerd_font
  # Uncomment the next line if you want to set up git interactively.
  # setup_git
  stow_dotfiles
}

main

