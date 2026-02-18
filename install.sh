#!/usr/bin/env bash
# Crea symlinks de los dotfiles a ~/.config
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

link() {
    local src="$DOTFILES_DIR/$1"
    local dest="$HOME/$1"
    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        echo "[!] Backup: $dest -> ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi
    ln -sf "$src" "$dest"
    echo "[+] $dest -> $src"
}

link .config/alacritty/alacritty.toml
link .config/kitty/kitty.conf
link .config/hypr/hyprland.conf
link .config/hypr/hyprlock.conf
link .config/starship.toml
link .config/fontconfig/fonts.conf
link .config/nvim/lua/community.lua
link .config/nvim/lua/lazy_setup.lua
link .config/nvim/lua/polish.lua
link .config/nvim/lua/plugins/astrocore.lua
link .config/nvim/lua/plugins/astrolsp.lua
link .config/nvim/lua/plugins/astroui.lua
link .config/nvim/lua/plugins/mason.lua
link .config/nvim/lua/plugins/none-ls.lua
link .config/nvim/lua/plugins/treesitter.lua
link .config/nvim/lua/plugins/user.lua
link .config/rofi/config.rasi
link .config/waybar/config.jsonc
link .config/waybar/style.css
link .zshrc
