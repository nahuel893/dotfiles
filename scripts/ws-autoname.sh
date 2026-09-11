#!/usr/bin/env bash
# ws-autoname.sh — rename sway workspaces to "N  <app icons>" from their windows.
# Dependency-free (swaymsg + jq). Started from sway autostart; runs as a daemon
# that reacts to window/workspace events. Icons need a Nerd Font (IosevkaTerm).
set -uo pipefail

# app_id (Wayland) or WM class (XWayland) → Nerd Font glyph.
declare -A ICONS=(
    [firefox]=""            [firefox-esr]=""   [chromium]=""  [google-chrome]=""
    [kitty]=""              [Alacritty]=""     [alacritty]=""
    [thunar]=""             [Thunar]=""        [nautilus]=""
    [code]="󰨞"              [Code]="󰨞"          [code-oss]="󰨞"
    [org.telegram.desktop]="" [discord]=""   [Spotify]=""  [spotify]=""
    [pavucontrol]=""        [org.pwmt.zathura]="󰈙"
    [mpv]=""                [vlc]="󰕼"          [obsidian]=""
    [default]=""
)

icon_for() { echo "${ICONS[$1]:-${ICONS[default]}}"; }

rename_all() {
    # Current name of each workspace, to skip no-op renames (avoids event loops).
    declare -A CUR
    while IFS=$'\t' read -r n nm; do CUR[$n]="$nm"; done \
        < <(swaymsg -t get_workspaces | jq -r '.[] | "\(.num)\t\(.name)"')

    # Process substitution (not a pipe) so this while runs in the function's own
    # shell — a piped `... | while` would run in a subshell where `local` errors.
    local num apps a icons desired oldIFS
    while IFS=$'\t' read -r num apps; do
        icons=""
        if [ -n "$apps" ]; then
            oldIFS="$IFS"; IFS=$'\001'
            for a in $apps; do icons+="$(icon_for "$a") "; done
            IFS="$oldIFS"
            icons="  ${icons% }"
        fi
        desired="${num}${icons}"
        [ "${CUR[$num]:-}" = "$desired" ] || \
            swaymsg "rename workspace number $num to \"$desired\"" >/dev/null 2>&1
    done < <(swaymsg -t get_tree | jq -r '
        .. | objects | select(.type=="workspace" and (.num? // -1) >= 0)
        | .num as $n
        | [ .. | objects
            | select((.app_id // .window_properties.class // "") != "")
            | (.app_id // .window_properties.class) ]
        | "\($n)\t\(join("\u0001"))"')
}

rename_all
swaymsg -t subscribe -m '["window","workspace"]' 2>/dev/null | while read -r _; do
    rename_all
done
