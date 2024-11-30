# Powerlevel10k Instant Prompt
# Keep this near the top; initialization code needing user input must come before this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Zinit Setup
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Clone Zinit if not already present
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone git@github.com:zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Powerlevel10k and Plugins
zinit ice depth=1; zinit light romkatv/powerlevel10k

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zinit snippet OMZP::command-not-found
zinit snippet OMZP::sudo

autoload -Uz compinit && compinit

zinit cdreplay -q

# Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey '^y' autosuggest-accept
bindkey '^h' backward-word  # Ctrl-Left for backward word
bindkey '^l' forward-word   # Ctrl-Right for forward word
bindkey '^k' history-search-backward
bindkey '^j' history-search-forward

# History Settings
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'
alias pvc='python3 -m venv venv && source venv/bin/activate'
alias pvm='if [[ -n "$VIRTUAL_ENV" ]]; then pip install pynvim jupyter_client ueberzug Pillow cairosvg pnglatex plotly kaleido pyperclip; else echo "Not in a virtual environment. Use pvc to create and activate one."; fi'
alias pva='source venv/bin/activate'



# Session Management Aliases
# Create a new named session
alias tms='tmux new -s'
# Attach to an existing named session
alias tma='tmux attach -t'
# Attach to last session
alias tmal='tmux attach'
# List all tmux sessions
alias tmls='tmux list-sessions'
# Kill a specific session by name
alias tmsk='tmux kill-session -t'
# Kill the current session from within tmux
alias tmskc='tmux kill-session'
# Kill all tmux sessions
alias tmska='tmux kill-server'
# Switch between sessions (opens tmux session switcher menu)
alias tmswitch='tmux command-prompt -p "Switch to session: " "switch-client -t %%"'
# Detach from the current session
alias tmd='tmux detach'
# Window Management Aliases
# Create a new window (not named)
alias tmw='tmux new-window'
# Kill a specific window by number
alias tmwk='tmux kill-window -t'
# Kill the current window
alias tmwkc='tmux kill-window'

# Toggle between the current and the last window
alias tmwt='tmux last-window'

# Next and previous window navigation
alias tmwn='tmux next-window'
alias tmwp='tmux previous-window'


# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
