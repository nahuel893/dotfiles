#!/usr/bin/env bash
# Pick a random wallpaper and set it with swaybg on all outputs (Wayland/sway).
set -euo pipefail

# Source dotfiles env if WALLPAPER_DIR is not set
[ -z "${WALLPAPER_DIR:-}" ] && [ -f "$HOME/dotfiles/.env" ] && source "$HOME/dotfiles/.env"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

wall=$(find "$WALLPAPER_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    | shuf -n 1)

if [ -z "$wall" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Replace any running swaybg
pkill -x swaybg 2>/dev/null || true
sleep 0.3
swaybg -o '*' -i "$wall" -m fill >/dev/null 2>&1 &
disown

echo "Wallpaper: $wall"
