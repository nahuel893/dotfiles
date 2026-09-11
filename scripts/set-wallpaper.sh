#!/usr/bin/env bash
# set-wallpaper.sh — single owner of the sway background.
#
# swaybg is the ONLY thing allowed to paint the background. The sway config
# must not carry an `output * background ...` line: sway respawns its own
# swaybg on every `swaymsg reload` (which theme-switch.sh triggers), and that
# second process renders on top of this one, hiding the wallpaper.
#
# Usage: set-wallpaper.sh <image-path>
set -euo pipefail

wall="${1:?usage: set-wallpaper.sh <image-path>}"
[ -f "$wall" ] || { echo "[x] Not a file: $wall" >&2; exit 1; }

# Remember the choice so other tooling can re-apply it without re-picking.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sway"
mkdir -p "$state_dir"
printf '%s\n' "$wall" > "$state_dir/current-wallpaper"

# Start the new swaybg BEFORE killing the old one, so there is no black flash
# while the image decodes.
old_pids="$(pgrep -x swaybg 2>/dev/null || true)"
swaybg -o '*' -i "$wall" -m fill >/dev/null 2>&1 &
disown
sleep 0.3
# shellcheck disable=SC2086  # word splitting is wanted: pgrep can return several PIDs
[ -n "$old_pids" ] && kill $old_pids 2>/dev/null || true

echo "Wallpaper: $wall"
