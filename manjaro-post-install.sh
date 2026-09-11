#!/usr/bin/env bash
#
# Manjaro / Arch + sway (Wayland) — Post Install Script
# Mirror of debian-post-install.sh, translated to pacman. Idempotent.
# Same sway rice as Debian: sway + waybar + mako + fuzzel + swaylock,
# theme-switch.sh (nord/gruvbox/latte), AstroNvim, zsh+omz+starship.
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

# Helper: install repo packages idempotently (--needed skips already-installed).
pac() { sudo pacman -S --needed --noconfirm "$@"; }

# ─────────────────────────────────────────────
# 1. System update
# ─────────────────────────────────────────────
log "Updating system..."
sudo pacman -Syu --noconfirm

# ─────────────────────────────────────────────
# 2. Base packages
# ─────────────────────────────────────────────
log "Installing base packages..."
pac base-devel git curl wget vim neovim \
    unzip p7zip jq imagemagick fastfetch \
    networkmanager
sudo systemctl enable --now NetworkManager 2>/dev/null || true

# ─────────────────────────────────────────────
# 3. sway + Wayland ecosystem
# ─────────────────────────────────────────────
log "Installing sway and the Wayland ecosystem..."
pac sway swaybg swayidle swaylock xorg-xwayland \
    waybar mako fuzzel rofi \
    grim slurp wl-clipboard \
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    polkit-gnome \
    brightnessctl playerctl

# ─────────────────────────────────────────────
# 3b. Backlight permissions (Fn keys + waybar slider via brightnessctl)
# Without the udev rule, /sys/class/backlight/*/brightness isn't writable by
# the 'video' group, so brightnessctl gets PERMISSION DENIED. %k covers any
# device name (intel_backlight, amdgpu_bl0, ...).
# ─────────────────────────────────────────────
log "Setting up backlight permissions..."
sudo usermod -aG video "$USER" || warn "Could not add $USER to 'video' group."
echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' \
    | sudo tee /etc/udev/rules.d/90-backlight.rules >/dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger -c add -s backlight || true
for b in /sys/class/backlight/*/brightness; do
    [ -e "$b" ] && { sudo chgrp video "$b"; sudo chmod g+w "$b"; }
done

# ─────────────────────────────────────────────
# 4. Audio (PipeWire)
# ─────────────────────────────────────────────
log "Installing PipeWire and audio components..."
pac pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# ─────────────────────────────────────────────
# 5. Terminal + fonts
# ─────────────────────────────────────────────
log "Installing terminal and fonts..."
pac kitty alacritty \
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    ttf-iosevkaterm-nerd otf-font-awesome \
    noto-fonts noto-fonts-emoji
fc-cache -f >/dev/null 2>&1 || true

# Fallback if the repo Iosevka package is unavailable for some reason.
if ! fc-list 2>/dev/null | grep -qi "IosevkaTerm Nerd"; then
    warn "IosevkaTerm Nerd Font not found via pacman; downloading from nerd-fonts release..."
    tmp="$(mktemp -d)"
    if curl -fL -o "$tmp/IosevkaTerm.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip"; then
        mkdir -p "$HOME/.local/share/fonts/IosevkaTerm"
        unzip -o "$tmp/IosevkaTerm.zip" -d "$HOME/.local/share/fonts/IosevkaTerm" >/dev/null
        fc-cache -f >/dev/null
    else
        warn "Nerd Font download failed (network?). Falling back to JetBrainsMono; continuing."
    fi
    rm -rf "$tmp"
fi

# ─────────────────────────────────────────────
# 6. User apps
# ─────────────────────────────────────────────
log "Installing applications..."
pac firefox thunar btop ripgrep fd bat eza zellij

# ─────────────────────────────────────────────
# 7. Shell (Zsh + Oh-My-Zsh + Starship)
# ─────────────────────────────────────────────
log "Installing Zsh and Starship..."
pac zsh starship

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
    chsh -s "$(command -v zsh)" || warn "Could not change shell (do it manually: chsh -s \$(which zsh))."
fi

# ─────────────────────────────────────────────
# 8. AUR helper (yay) — optional, only if you later want AUR packages
# ─────────────────────────────────────────────
if ! command -v yay >/dev/null 2>&1; then
    log "Installing yay (AUR helper)..."
    pac yay || warn "yay not in repos; skipping (everything needed is in official repos)."
else
    warn "yay already installed, skipping."
fi

# ─────────────────────────────────────────────
# 9. AstroNvim + dependencies
# ─────────────────────────────────────────────
log "Installing AstroNvim dependencies..."
pac ripgrep lazygit nodejs npm python python-pip tree-sitter-cli

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
# 10. Symlink dotfiles  (must run AFTER AstroNvim clone so the lua/*
#     overrides land on top of the template, not before it)
# ─────────────────────────────────────────────
log "Linking dotfiles..."
bash "$DOTFILES_DIR/install.sh"

# ─────────────────────────────────────────────
# 11. Apply initial theme + wallpaper
# ─────────────────────────────────────────────
log "Applying initial theme (nord)..."
DOTFILES="$DOTFILES_DIR" bash "$DOTFILES_DIR/scripts/theme-switch.sh" nord \
    || warn "theme-switch will run on first sway login."

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
log "===== Installation complete ====="
echo ""
echo "  Window manager : sway (Wayland) + waybar + mako + fuzzel + swaylock"
echo "  Themes         : nord · gruvbox · latte   (switch: Mod+x, or theme-switch.sh <name>)"
echo "  Wallpaper      : Mod+w  (random from ~/Pictures/wallpapers)"
echo "  Editor         : AstroNvim"
echo "  Shell          : zsh + oh-my-zsh + starship"
echo ""
warn "Log out and pick the 'Sway' session in lightdm (gear/session menu on the login screen)."
warn "Add wallpapers to ~/Pictures/wallpapers before using Mod+w."
warn "NOTE: .zshrc aliases 'ls' to 'exa', which Arch replaced with 'eza'."
warn "      Either change the alias to 'eza' or run: sudo ln -s \$(command -v eza) /usr/local/bin/exa"
