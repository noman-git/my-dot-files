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
bindkey '^[[1;5D' backward-word  # Ctrl-Left for backward word
bindkey '^[[1;5C' forward-word   # Ctrl-Right for forward word
bindkey '^[[1;5A' history-search-backward
bindkey '^[[1;5B' history-search-forward

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
alias pvc='python -m venv venv'
alias pva='source venv/bin/activate'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
