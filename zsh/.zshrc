alias ..="cd .."
alias c="clear"
alias dc="cd"

# Added by Antigravity CLI installer
export PATH="/Users/sniperzero360/.local/bin:$PATH"

# opencode
export PATH=/Users/sniperzero360/.opencode/bin:$PATH

# History: large, shared live between shells, no duplicates
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS

# Completion (Homebrew's site-functions are on fpath via brew shellenv in .zprofile)
autoload -Uz compinit && compinit

export EDITOR=nvim
export BAT_THEME=ansi

alias ls='eza --group-directories-first'
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'
alias lg=lazygit
alias y=yazi

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
# fzf keys (C-r, C-t, Alt-c). Skipped under `zsh -i -c`, where its option restore warns about zle
[[ -z $ZSH_EXECUTION_STRING ]] && source <(fzf --zsh)

# Plugins: syntax highlighting must be sourced last
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
