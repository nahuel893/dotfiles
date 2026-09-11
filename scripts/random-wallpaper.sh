#!/usr/bin/env bash
# Pick a random wallpaper from WALLPAPER_DIR and hand it to set-wallpaper.sh.
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source dotfiles env if WALLPAPER_DIR is not set
[ -z "${WALLPAPER_DIR:-}" ] && [ -f "$HOME/dotfiles/.env" ] && source "$HOME/dotfiles/.env"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

# `find` on purpose: these dotfiles bootstrap bare Debian/Arch/Manjaro boxes
# where fd may be absent (and is named fdfind on Debian).
wall=$(find "$WALLPAPER_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    | shuf -n 1)

if [ -z "$wall" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

exec "$SCRIPTS_DIR/set-wallpaper.sh" "$wall"
