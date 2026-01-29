#!/usr/bin/env bash
set -euo pipefail

PYTHON_VERSION="3.12.2"
VENV_DIR="$HOME/.virtualenvs/neovim"

echo "==> Starting environment setup..."

# -------------------------------
# PYENV + PYTHON
# -------------------------------
setup_pyenv_and_python() {
  echo "==> Installing pyenv..."

  sudo pacman -S --needed --noconfirm \
    pyenv \
    base-devel \
    openssl \
    zlib \
    xz \
    tk

  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"

  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"

  if ! pyenv versions --bare | grep -qx "$PYTHON_VERSION"; then
    echo "==> Installing Python $PYTHON_VERSION..."
    pyenv install "$PYTHON_VERSION"
  fi

  pyenv global "$PYTHON_VERSION"

  echo "==> Creating Neovim virtualenv..."
  mkdir -p "$(dirname "$VENV_DIR")"

  if [[ ! -d "$VENV_DIR" ]]; then
    python -m venv "$VENV_DIR"
  fi

  # Activate venv
  source "$VENV_DIR/bin/activate"

  echo "==> Installing Python packages..."
  pip install --upgrade pip
  pip install \
    pynvim \
    jupyter-client \
    cairosvg \
    pnglatex \
    plotly \
    kaleido \
    pyperclip \
    pillow

  echo "==> Python setup complete"
}

# -------------------------------
# LUA 5.4
# -------------------------------
setup_lua() {
  echo "==> Installing Lua 5.4..."

  if ! command -v yay &>/dev/null; then
    echo "==> Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    pushd /tmp/yay
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/yay
  fi

  yay -S --needed --noconfirm lua54

  lua -v
}

# -------------------------------
# NODE.JS
# -------------------------------
setup_node() {
  echo "==> Installing Node.js..."
  sudo pacman -S --needed --noconfirm nodejs npm
}

# -------------------------------
# MAIN
# -------------------------------
main() {
  setup_pyenv_and_python
  setup_lua
  setup_node
  echo "==> All done."
}

main

