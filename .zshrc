# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Oh My Zsh theme (deshabilitado, usa Starship)
ZSH_THEME=""

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ls="ls --color=auto"
alias ll="ls -la"
alias la="ls -a"
alias ..="cd .."
alias ...="cd ../.."

# Starship prompt
eval "$(starship init zsh)"
