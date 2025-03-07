#!/bin/bash
# zsh-setup.sh - Set up Zsh as your default shell

echo "Setting up Zsh..."

# Add zsh to /etc/shells if not already present
if ! grep -q "$(which zsh)" /etc/shells; then
  echo "Adding $(which zsh) to /etc/shells..."
  echo "$(which zsh)" | sudo tee -a /etc/shells
fi

# Change default shell to zsh if not already set
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "Changing default shell to zsh..."
  chsh -s "$(which zsh)"
  echo "Default shell changed to Zsh. Please restart your terminal for this change to take effect."
else
  echo "Default shell is already Zsh."
fi

