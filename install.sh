#!/bin/bash

# Function to detect the OS
detect_os() {
  OS="unknown"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  fi
  echo "$OS"
}

# Install Nix
install_nix() {
  OS=$(detect_os)
  if [[ "$OS" == "linux" ]]; then
    sh <(curl -L https://nixos.org/nix/install) --daemon
  elif [[ "$OS" == "macos" ]]; then
    sh <(curl -L https://nixos.org/nix/install)
  else
    echo "Unsupported OS: $OS"
    exit 1
  fi
}


setup_git() {
  echo "Setting up git..."

  # Check if git is installed
  if ! command -v git &>/dev/null; then
    echo "Git is not installed. Exiting."
    exit 1
  fi

  # Prompt the user for Git username and email
  read -p "Enter your Git username: " git_username
  read -p "Enter your Git email: " git_email

  # Configure git
  git config --global user.name "$git_username"
  git config --global user.email "$git_email"
  git config --global init.defaultBranch main

  echo "Git configured successfully!"
}

# Set up zsh
setup_zsh() {
    echo "Setting up zsh..."

  # Add zsh to valid shells if not present
  if ! grep -q "$(which zsh)" /etc/shells; then
      echo "$(which zsh)" | sudo tee -a /etc/shells
  fi

  # Set zsh as the default shell
  if [[ "$SHELL" != "$(which zsh)" ]]; then
      chsh -s "$(which zsh)"
  fi
}

# lnstall necessary packages using Nix
install_packages() {
  nix-env -iA \
    nixpkgs.zsh \
    nixpkgs.neovim \
    nixpkgs.tmux \
    nixpkgs.stow \
    nixpkgs.yarn \
    nixpkgs.fzf \
    nixpkgs.ripgrep \
    nixpkgs.bat \
    nixpkgs.zoxide \
    nixpkgs.imagemagick
}

# Main function
main() {
  install_nix
#  setup_git
  install_packages
  stow git
  stow zsh
  setup_zsh

  echo "Installation completed. Please restart your terminal."
}

main

