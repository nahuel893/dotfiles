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
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

# Claude Code
export CLAUDE_AGENT_TEAMS=1

# Wallpaper directory
export WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Aliases
alias ls="exa --icons"
alias ll="exa --icons -la"
alias la="exa --icons -a"
alias lt="exa --icons --tree --level=2"
alias ..="cd .."
alias ...="cd ../.."
alias chss="cd ~/projects/work/chesserp-py-sdk/"
alias dm="cd ~/projects/work/sales-dashboard/"
alias etl="~/projects/work/medallion-etl/"
# Terminal title (muestra carpeta actual y comando en ejecución)
function precmd() {
    print -Pn "\e]2;%~\a"
}
function preexec() {
    print -Pn "\e]2;$1\a"
}

# Starship prompt
eval "$(starship init zsh)"

# Override alias gga → Gentleman Guardian Angel
unalias gga 2>/dev/null
alias gga="$HOME/.local/bin/gga"

export QT_QPA_PLATFORM=xcb
export QT_SCALE_FACTOR=1
export PATH=~/.npm-global/bin:$PATH
