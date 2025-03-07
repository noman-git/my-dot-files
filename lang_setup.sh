#!/bin/bash

# Function to install pyenv and Python 3.10 using pyenv
setup_pyenv_and_python() {
  echo "Setting up pyenv and Python 3.10..."

  # Install pyenv using nix
  if command -v nix-env &> /dev/null; then
    nix-env -iA nixpkgs.pyenv
  else
    echo "Error: nix not found. Exiting."
    exit 1
  fi

  # Initialize pyenv
  export PATH="$HOME/.nix-profile/bin:$PATH"
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

  # Set up pyenv environment in the shell
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"

  # Install Python 3.10 using pyenv
  pyenv install 3.10.0
  pyenv global 3.10.0

  # Verify installation
  if pyenv versions | grep "3.10"; then
    echo "Python 3.10 installed successfully!"
  else
    echo "Failed to install Python 3.10"
  fi
}

# Function to install Lua 5.1 using nix
setup_lua() {
  echo "Setting up Lua 5.1..."

  # Use nix to install Lua
  if command -v nix-env &> /dev/null; then
    nix-env -iA nixpkgs.lua
  else
    echo "Error: nix not found. Exiting."
    exit 1
  fi
}


# Run all setup functions
setup_pyenv_and_python
setup_lua

