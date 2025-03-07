#!/bin/bash
set -e

# Function to set up pyenv and install Python 3.12 using pyenv via pacman
setup_pyenv_and_python() {
  echo "Setting up pyenv and Python 3.12..."

  # Install pyenv and pyenv-virtualenv
  sudo pacman -S --needed --noconfirm pyenv pyenv-virtualenv

  # Set up pyenv environment variables
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"

  # Initialize pyenv (should be added to shell profile for persistence)
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  # Install Python 3.12 using pyenv (if not already installed)
  if ! pyenv versions | grep -q "3.12.2"; then
    pyenv install 3.12.2
  fi
  pyenv global 3.12.2

  # Create a virtual environment for Neovim
  if ! pyenv virtualenvs | grep -q "neovim"; then
    pyenv virtualenv 3.12.2 neovim
  fi
  pyenv activate neovim

  # Install pynvim inside the virtual environment
  pip install --upgrade pip
  pip install pynvim jupyter-client cairosvg pnglatex plotly kaleido pyperclip pillow

  # Verify installation
  if pyenv versions | grep "3.12" &>/dev/null; then
    echo "Python 3.12 installed successfully!"
  else
    echo "Failed to install Python 3.12"
  fi
}

# Function to install Lua 5.4 using AUR (yay)
setup_lua() {
  echo "Setting up Lua 5.4..."

  # Ensure yay is installed
  if ! command -v yay &>/dev/null; then
    echo "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit
    makepkg -si --noconfirm
    cd - || exit
    rm -rf /tmp/yay
  fi

  # Install Lua 5.4
  yay -S --needed --noconfirm lua54

  echo "Lua version:"
  lua -v
}

# Function to install Node.js and npm using pacman
setup_node() {
  echo "Setting up Node.js and npm..."
  sudo pacman -S --needed --noconfirm nodejs npm
}

# Main function to run all setups
main() {
  setup_pyenv_and_python
  setup_lua
  setup_node
}

main

