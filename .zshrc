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

# Dotfiles environment variables
source "$HOME/dotfiles/.env"

# Aliases
alias ls="eza --icons=auto"
alias ll="eza --icons=auto -la"
alias la="eza --icons=auto -a"
alias lt="eza --icons=auto --tree --level=2"
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

# AI CLIs
alias cld="claude --dangerously-skip-permissions"
alias clr="claude --dangerously-skip-permissions --resume"
alias cdr="claude --dangerously-skip-permissions --resume"
alias agp="agy --dangerously-skip-permissions"
alias piu="pi update --extensions"

# Packages
alias pac="sudo pacman -S"
alias yup="yay -Syu"

# Lock the screen (works from shells without the sway display env)
alias lock='WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1} swaylock -f'

# Python / Venv
alias py="python3"
alias venv="source .venv/bin/activate 2>/dev/null || source venv/bin/activate"
export QT_QPA_PLATFORM=xcb
export QT_SCALE_FACTOR=1
export PATH=~/.npm-global/bin:$PATH



# Shells spawned by a multiplexer server started from a tty (before sway) lack
# the display env. Recover it from the live sockets so GUI apps can start.
if [[ -z $WAYLAND_DISPLAY ]]; then
  for _sock in ${XDG_RUNTIME_DIR:-/run/user/$UID}/wayland-<->(N); do
    export WAYLAND_DISPLAY=${_sock:t} XDG_SESSION_TYPE=wayland
    break
  done
  unset _sock
fi
[[ -z $DISPLAY && -S /tmp/.X11-unix/X0 ]] && export DISPLAY=:0
