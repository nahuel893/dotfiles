#!/usr/bin/env bash
#
# Arch/Manjaro + sway (Wayland) — Post Install Script
# Mirror of debian-post-install.sh, translated to pacman. Idempotent.
# Target: Arch Linux / Manjaro / EndeavourOS with sway on Wayland.
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

PACMAN_INSTALL=(sudo pacman -S --needed --noconfirm)

# ─────────────────────────────────────────────
# 1. System update
# ─────────────────────────────────────────────
log "Updating system..."
sudo pacman -Syu --noconfirm

# ─────────────────────────────────────────────
# 2. Base packages
# ─────────────────────────────────────────────
log "Installing base packages..."
"${PACMAN_INSTALL[@]}" \
    base-devel linux-headers git curl wget vim neovim \
    unzip p7zip jq imagemagick fastfetch \
    networkmanager
sudo systemctl enable --now NetworkManager 2>/dev/null || true

# ─────────────────────────────────────────────
# 3. sway + Wayland ecosystem
# ─────────────────────────────────────────────
log "Installing sway and the Wayland ecosystem..."
"${PACMAN_INSTALL[@]}" \
    sway swaybg swayidle swaylock xorg-xwayland \
    waybar mako fuzzel rofi-wayland \
    grim slurp wl-clipboard \
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    polkit-gnome \
    brightnessctl playerctl

# ─────────────────────────────────────────────
# 4. Audio (PipeWire)
# ─────────────────────────────────────────────
log "Installing PipeWire and audio components..."
"${PACMAN_INSTALL[@]}" \
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# ─────────────────────────────────────────────
# 5. Terminal + fonts
# ─────────────────────────────────────────────
log "Installing terminal and fonts..."
"${PACMAN_INSTALL[@]}" \
    kitty alacritty \
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    otf-font-awesome noto-fonts noto-fonts-emoji

install_nerd_font() {
    if fc-list 2>/dev/null | rg -qi "IosevkaTerm Nerd"; then
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
# 6. User apps + CLI utilities
# ─────────────────────────────────────────────
log "Installing applications..."
"${PACMAN_INSTALL[@]}" \
    firefox thunar btop ripgrep fd bat eza

# ─────────────────────────────────────────────
# 7. Display manager (keep SDDM if installed, else install)
# ─────────────────────────────────────────────
if systemctl list-unit-files | rg -q '^sddm\.service'; then
    warn "SDDM already installed, keeping it (it supports sway sessions)."
else
    log "Installing SDDM..."
    "${PACMAN_INSTALL[@]}" sddm
    sudo systemctl enable sddm
fi

# ─────────────────────────────────────────────
# 8. Shell (Zsh + Oh-My-Zsh + Starship)
# ─────────────────────────────────────────────
log "Installing Zsh and Starship..."
"${PACMAN_INSTALL[@]}" zsh starship

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

if [ "$SHELL" != "$(command -v zsh)" ]; then
    log "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)" || warn "Could not change shell (do it manually with chsh -s \$(which zsh))."
fi

# ─────────────────────────────────────────────
# 9. yay (AUR helper)
# ─────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    log "Installing yay (AUR helper)..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
else
    warn "yay already installed, skipping."
fi

# ─────────────────────────────────────────────
# 10. AstroNvim + dependencies
# ─────────────────────────────────────────────
log "Installing AstroNvim dependencies..."
"${PACMAN_INSTALL[@]}" \
    ripgrep lazygit bottom nodejs npm python tree-sitter-cli

if [ ! -d "$HOME/.config/nvim/lua" ]; then
    log "Installing AstroNvim..."
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
# 11. Symlink dotfiles
# ─────────────────────────────────────────────
log "Linking dotfiles..."
bash "$DOTFILES_DIR/install.sh"

# ─────────────────────────────────────────────
# 12. Apply initial theme + wallpaper
# ─────────────────────────────────────────────
if [ -x "$DOTFILES_DIR/scripts/theme-switch.sh" ]; then
    log "Applying initial theme (nord)..."
    bash "$DOTFILES_DIR/scripts/theme-switch.sh" nord || warn "theme-switch will run on first sway login."
else
    warn "scripts/theme-switch.sh not found or not executable. Skipping theme apply."
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
log "===== Installation complete ====="
echo ""
echo "  Window manager : sway (Wayland) + waybar + mako + fuzzel/rofi + swaylock"
echo "  Themes         : nord · gruvbox · latte   (switch: Mod+x, or theme-switch.sh <name>)"
echo "  Wallpaper      : Mod+w  (random from ~/Pictures/wallpapers)"
echo "  Editor         : AstroNvim"
echo "  Shell          : zsh + oh-my-zsh + starship"
echo ""
warn "Log out and pick the 'Sway' session in SDDM."
warn "If IosevkaTerm font looks off, re-run: fc-cache -f"
warn "Hyprland is still installed alongside — uninstall later if sway works for you."
