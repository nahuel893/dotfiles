#!/usr/bin/env bash
# Toggle the TV between desktop and gaming display modes.
#
#   desktop : 3840x2160@60Hz  — 85 DPI on a 52" panel, readable text
#   game    : 1920x1080@120Hz — 4x fewer pixels, double the refresh
#
# One panel cannot serve both: the desktop wants pixels, games want frames.
# This GPU is Navi 10 (HDMI 2.0b), so 4K@120 is not an available mode at all.
#
# Usage: tv-mode.sh [desktop|game]   (no argument toggles)

set -euo pipefail

TV_ID="XXX Smart TV Pro 0x00000001"
LAPTOP="eDP-1"

DESKTOP_MODE="3840x2160@60Hz"
GAME_MODE="1920x1080@120Hz"

die() { printf 'tv-mode: %s\n' "$1" >&2; exit 1; }

command -v swaymsg >/dev/null || die "swaymsg not found; is sway running?"
command -v jq >/dev/null      || die "jq not found"

# swaymsg concatenates its arguments into one command string before parsing, so
# shell quoting around an identifier containing spaces is lost and the second
# word is read as a subcommand. The quotes must be inside the string sway parses.
#
# The reply is also checked: sway reports a rejected command as success:false in
# JSON while the message itself is easy to discard. Swallowing it would leave the
# mode silently unchanged, which is the failure this script must not have.
sway_do() {
  local reply
  reply=$(swaymsg "$1") || die "swaymsg failed: $1"
  printf '%s' "$reply" | jq -e 'all(.[]; .success)' >/dev/null \
    || die "sway rejected [$1]: $(printf '%s' "$reply" | jq -r '.[].error // empty' | head -1)"
}

current_width() {
  swaymsg -t get_outputs -r \
    | jq -r --arg id "$TV_ID" \
        'first(.[] | select("\(.make) \(.model) \(.serial)" == $id) | .current_mode.width) // empty'
}

width="$(current_width)"
[ -n "$width" ] || die "TV not found among active outputs (is it connected?)"

case "${1-}" in
  desktop) target=desktop ;;
  game)    target=game ;;
  "")      if [ "$width" -ge 3840 ]; then target=game; else target=desktop; fi ;;
  *)       die "usage: $(basename "$0") [desktop|game]" ;;
esac

if [ "$target" = desktop ]; then
  mode="$DESKTOP_MODE"; laptop_x=3840
else
  mode="$GAME_MODE";    laptop_x=1920
fi

sway_do "output \"$TV_ID\" mode $mode scale 1 position 0 0"

# The laptop panel sits to the right of the TV, so its offset must track the
# TV's logical width or the two overlap. Only touch it when it is connected.
if swaymsg -t get_outputs -r | jq -e --arg n "$LAPTOP" 'any(.[]; .name == $n)' >/dev/null; then
  sway_do "output \"$LAPTOP\" position $laptop_x 0"
fi

printf 'tv-mode: %s -> %s\n' "$target" "$mode"
