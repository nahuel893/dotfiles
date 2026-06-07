#!/usr/bin/env bash
#
# Debian-based + sway (Wayland) — Post Install Script
# Mirror of arch-post-install.sh, translated to apt. Idempotent.
# Target: any Debian/Ubuntu-based distro on X11→Wayland with sway.
#
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }

if [ "$EUID" -eq 0 ]; then
    err "Do not run this script as root. Use your normal user."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─────────────────────────────────────────────
# 1. System update
# ─────────────────────────────────────────────
log "Updating system..."
sudo apt-get update
sudo apt-get upgrade -y

# ─────────────────────────────────────────────
# 2. Base packages
# ─────────────────────────────────────────────
log "Installing base packages..."
sudo apt-get install -y \
    build-essential git curl wget vim neovim \
    unzip p7zip-full jq imagemagick fastfetch \
    network-manager

# ─────────────────────────────────────────────
# 3. sway + Wayland ecosystem
# ─────────────────────────────────────────────
log "Installing sway and the Wayland ecosystem..."
sudo apt-get install -y \
    sway swaybg swayidle swaylock \
    waybar mako-notifier rofi \
    grim slurp wl-clipboard \
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    policykit-1-gnome \
    brightnessctl playerctl

# ─────────────────────────────────────────────
# 4. Audio (PipeWire)
# ─────────────────────────────────────────────
log "Installing PipeWire and audio components..."
sudo apt-get install -y \
    pipewire pipewire-pulse pipewire-audio wireplumber pavucontrol
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# ─────────────────────────────────────────────
# 5. Terminal + fonts
# ─────────────────────────────────────────────
log "Installing terminal and fonts..."
sudo apt-get install -y \
    kitty alacritty \
    fonts-jetbrains-mono fonts-font-awesome \
    fonts-noto fonts-noto-color-emoji

install_nerd_font() {
    if fc-list 2>/dev/null | grep -qi "IosevkaTerm Nerd"; then
        warn "IosevkaTerm Nerd Font already installed, skipping."
        return
    fi
    log "Installing IosevkaTerm Nerd Font..."
    local tmp; tmp="$(mktemp -d)"
    curl -fL -o "$tmp/IosevkaTerm.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip"
    mkdir -p "$HOME/.local/share/fonts/IosevkaTerm"
    unzip -o "$tmp/IosevkaTerm.zip" -d "$HOME/.local/share/fonts/IosevkaTerm" >/dev/null
    fc-cache -f >/dev/null
    rm -rf "$tmp"
}
install_nerd_font || warn "Nerd Font download failed (network?). Falling back to JetBrainsMono; continuing."

# ─────────────────────────────────────────────
# 6. User apps
# ─────────────────────────────────────────────
log "Installing applications..."
sudo apt-get install -y firefox-esr thunar btop ripgrep fd-find bat eza 2>/dev/null \
    || sudo apt-get install -y firefox-esr thunar btop ripgrep fd-find bat

# ─────────────────────────────────────────────
# 7. Shell (Zsh + Oh-My-Zsh + Starship)
# ─────────────────────────────────────────────
log "Installing Zsh..."
sudo apt-get install -y zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    warn "Oh-My-Zsh already installed, skipping."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

if ! command -v starship >/dev/null 2>&1; then
    log "Installing Starship..."
    curl -sS https://starship.rs/install/install.sh | sh -s -- -y
else
    warn "Starship already installed, skipping."
fi

if [ "$SHELL" != "$(command -v zsh)" ]; then
    log "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)" || warn "Could not change shell (do it manually with chsh -s \$(which zsh))."
fi

# ─────────────────────────────────────────────
# 8. AstroNvim + dependencies
# ─────────────────────────────────────────────
log "Installing AstroNvim dependencies..."
sudo apt-get install -y ripgrep nodejs npm python3 python3-pip

install_lazygit() {
    command -v lazygit >/dev/null 2>&1 && { warn "lazygit already installed."; return; }
    log "Installing lazygit (from GitHub release)..."
    local ver tmp
    ver="$(curl -s 'https://api.github.com/repos/jesseduffield/lazygit/releases/latest' \
        | grep -Po '"tag_name": *"v\K[^"]*')"
    tmp="$(mktemp -d)"
    curl -fLo "$tmp/lazygit.tar.gz" \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${ver}_Linux_x86_64.tar.gz"
    tar xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    sudo install "$tmp/lazygit" /usr/local/bin
    rm -rf "$tmp"
}
install_lazygit || warn "lazygit install failed (network?); continuing."

command -v tree-sitter >/dev/null 2>&1 || sudo npm install -g tree-sitter-cli 2>/dev/null || \
    warn "Could not install tree-sitter-cli globally (optional)."

if [ ! -d "$HOME/.config/nvim/lua" ]; then
    log "Installing AstroNvim..."
    for d in nvim/.config nvim; do :; done
    mv "$HOME/.config/nvim"        "$HOME/.config/nvim.bak"        2>/dev/null || true
    mv "$HOME/.local/share/nvim"   "$HOME/.local/share/nvim.bak"   2>/dev/null || true
    mv "$HOME/.local/state/nvim"   "$HOME/.local/state/nvim.bak"   2>/dev/null || true
    mv "$HOME/.cache/nvim"         "$HOME/.cache/nvim.bak"         2>/dev/null || true
    git clone --depth 1 https://github.com/AstroNvim/template "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    warn "AstroNvim already installed, skipping clone."
fi

# ─────────────────────────────────────────────
# 9. Symlink dotfiles
# ─────────────────────────────────────────────
log "Linking dotfiles..."
bash "$DOTFILES_DIR/install.sh"

# ─────────────────────────────────────────────
# 10. Apply initial theme + wallpaper
# ─────────────────────────────────────────────
log "Applying initial theme (nord)..."
bash "$DOTFILES_DIR/scripts/theme-switch.sh" nord || warn "theme-switch will run on first sway login."

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
log "===== Installation complete ====="
echo ""
echo "  Window manager : sway (Wayland) + waybar + mako + rofi + swaylock"
echo "  Themes         : nord · gruvbox · latte   (switch: Mod+x, or theme-switch.sh <name>)"
echo "  Wallpaper      : Mod+w  (random from ~/Pictures/wallpapers)"
echo "  Editor         : AstroNvim"
echo "  Shell          : zsh + oh-my-zsh + starship"
echo ""
warn "Log out and pick the 'Sway' session in your display manager (lightdm)."
warn "If IosevkaTerm font looks off, re-run: fc-cache -f"
