#!/usr/bin/env bash
#
# theme-switch.sh — single source of truth theme switcher for the sway rice.
# Reads one palette (themes/<name>.sh, or an openskin preset from scripts/themes.sh)
# and regenerates the color files that each app's config consumes, then
# live-reloads everything. Choices that match an openskin preset also theme
# Claude Code (openskin colors + Claude Code's dark/light theme in
# ~/.claude/settings.json).
#
# Usage:
#   theme-switch.sh nord|gruvbox|latte|tokyonight|...   # set a specific theme
#   theme-switch.sh default    # openskin's own look; the desktop keeps its theme
#   theme-switch.sh next       # cycle to the next theme
#   theme-switch.sh            # re-apply the current theme
#
# Aliases: gruvbox-dark = gruvbox, catppuccin-latte = latte (the desktop keeps
# its hand-made palette and openskin gets the matching preset).
#
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
THEMES_DIR="$DOTFILES/themes"
SCRIPTS_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
STATE_FILE="$HOME/.config/sway/.current-theme"
CYCLE=(nord gruvbox classic latte sunset purplerange pinksky
       tokyonight catppuccin-mocha rose-pine rose-pine-dawn kanagawa-wave everforest one-dark)

# shellcheck source-path=SCRIPTDIR source=themes.sh
source "$SCRIPTS_DIR/themes.sh"

usage() {
    echo "Usage: $(basename "$0") [<theme>|next]"
    echo "Available themes:"
    for t in "$THEMES_DIR"/*.sh; do echo "  - $(basename "${t%.sh}")"; done
    echo "Openskin presets (also theme Claude Code):"
    for row in "${OPENSKIN_PRESETS[@]}"; do echo "  - ${row%%|*}"; done
    exit 1
}

choice="${1:-$(cat "$STATE_FILE" 2>/dev/null || echo nord)}"
requested="$choice"

# "next" cycles through the list
if [ "$choice" = "next" ]; then
    current="$(cat "$STATE_FILE" 2>/dev/null || echo "${CYCLE[0]}")"
    idx=0
    for i in "${!CYCLE[@]}"; do [ "${CYCLE[$i]}" = "$current" ] && idx=$i; done
    choice="${CYCLE[$(((idx + 1) % ${#CYCLE[@]}))]}"
    requested="$choice"
fi

# ── which openskin preset (if any) goes with the choice, and which theme the
#    desktop gets. `skin_row` stays empty for themes without a preset (classic,
#    sunset, ...): those leave Claude Code as it is. ──
skin_row="$(preset_row "$choice" || true)"
if [ -n "$skin_row" ]; then
    IFS='|' read -r skin skin_system _ <<<"$skin_row"
    case "$skin_system" in
        "")      choice="$skin" ;;                                           # generated palette
        current) choice="$(cat "$STATE_FILE" 2>/dev/null || echo nord)" ;;   # `default`
        *)       choice="$skin_system" ;;                                    # hand-made palette
    esac
fi

# The preset that describes the desktop theme (empty for classic, sunset, ...).
sys_row="$(preset_row "$choice" || true)"
IFS='|' read -r p_name p_system p_kitty p_nvim p_cc p_accent p_surface p_toolbar \
    p_error p_muted p_command p_background p_fg <<<"$sys_row"

# generate_palette — fills the palette variables themes/<name>.sh would set from the
# preset in p_*: the openskin colors give the UI roles, the official kitty theme
# (KITTY_DUMP) gives the foreground and the 16 ANSI colors. Without a kitty theme
# (offline, no cache) every color comes from the preset's own hexes.
generate_palette() {
    local key value i
    local -A dump=()
    if command -v kitten >/dev/null 2>&1 &&
        KITTY_DUMP="$(timeout 20 kitten themes --dump-theme "$p_kitty" 2>/dev/null)" &&
        [ -n "$KITTY_DUMP" ]; then
        while read -r key value _; do
            case "$key" in foreground | color[0-9] | color1[0-5]) dump[$key]="$value" ;; esac
        done <<<"$KITTY_DUMP"
    else
        KITTY_DUMP=""
        echo "[!] Kitty theme '$p_kitty' unavailable (offline or no cache?): kitty colors built from the $p_name preset's hexes." >&2
    fi

    BG="$p_background"
    BG_ALT="$p_surface"
    BG_BRIGHT="$p_toolbar"
    SURFACE="$BG"
    FG="${dump[foreground]:-$p_fg}"
    FG_ALT="$p_muted"
    ACCENT="$p_accent"
    ON_ACCENT="$BG"
    SECONDARY="$p_command"
    ERROR="$p_error"
    BORDER="$p_toolbar"
    BORDER_INACTIVE="$p_surface"
    IS_LIGHT=0
    [ "$p_cc" = light ] && IS_LIGHT=1

    # ANSI fallback from the preset: black/white swap ends on light themes.
    local -a fb
    if [ "$IS_LIGHT" = 1 ]; then
        fb=("$FG" "$p_error" "$p_command" "$p_accent" "$p_accent" "$p_accent" "$p_command" "$p_toolbar"
            "$p_muted" "$p_error" "$p_command" "$p_accent" "$p_accent" "$p_accent" "$p_command" "$p_surface")
    else
        fb=("$p_surface" "$p_error" "$p_command" "$p_accent" "$p_accent" "$p_accent" "$p_command" "$p_muted"
            "$p_toolbar" "$p_error" "$p_command" "$p_accent" "$p_accent" "$p_accent" "$p_command" "$FG")
    fi
    for i in {0..15}; do
        printf -v "COL$i" '%s' "${dump[color$i]:-${fb[$i]}}"
    done
    TERTIARY="$COL5"
}

# Cleared before sourcing: palettes that declare no wallpaper must not inherit
# one from the environment. KITTY_DUMP holds the official kitty palette of a
# generated preset; hand-made palettes leave it empty.
WALLPAPER=""
KITTY_DUMP=""

PALETTE="$THEMES_DIR/$choice.sh"
if [ -f "$PALETTE" ]; then
    # shellcheck source=/dev/null
    source "$PALETTE"
elif [ -n "$sys_row" ] && [ -z "$p_system" ]; then
    generate_palette
else
    echo "[x] Theme '$choice' not found."
    usage
fi

mkdir -p "$HOME/.config/waybar" "$HOME/.config/rofi" \
         "$HOME/.config/kitty" "$HOME/.config/sway" "$HOME/.config/mako" \
         "$HOME/.config/fuzzel" "$HOME/.config/zellij/themes" "$HOME/.config/ghostty" \
         "$HOME/.config/herdr"

# Break any symlink first so we write real files in ~/.config (never through a
# symlink back into the dotfiles repo, which would dirty git on every switch).
rm -f "$HOME/.config/waybar/colors.css" "$HOME/.config/rofi/colors.rasi" \
      "$HOME/.config/kitty/matugen.conf" "$HOME/.config/sway/colors.conf" \
      "$HOME/.config/mako/config" "$HOME/.config/fuzzel/fuzzel.ini" \
      "$HOME/.config/zellij/themes/rice.kdl" "$HOME/.config/ghostty/theme.conf" \
      "$HOME/.config/herdr/config.toml"

# ── waybar (Material-style vars, matches style.css) ──
cat > "$HOME/.config/waybar/colors.css" <<EOF
/* generated by theme-switch.sh — theme: $choice — do not edit by hand */
@define-color surface           $SURFACE;
@define-color surface_container $BG_ALT;
@define-color surface_bright    $BG_BRIGHT;
@define-color on_surface        $FG;
@define-color primary           $ACCENT;
@define-color on_primary        $ON_ACCENT;
@define-color secondary         $SECONDARY;
@define-color tertiary          $TERTIARY;
@define-color error             $ERROR;
@define-color outline           $FG_ALT;
@define-color outline_variant   $BORDER;
EOF

# ── rofi ──
cat > "$HOME/.config/rofi/colors.rasi" <<EOF
/* generated by theme-switch.sh — theme: $choice — do not edit by hand */
* {
    bg:          $BG;
    bg-alt:      $BG_ALT;
    fg:          $FG;
    fg-alt:      $FG_ALT;
    accent:      $ACCENT;
    border:      $ACCENT;
    transparent: transparent;
}
EOF

# ── kitty (reuses the `include matugen.conf` slot already in kitty.conf;
#    on Debian/sway matugen isn't used, so this file holds the active theme).
#    Generated presets get the official kitty theme verbatim. ──
if [ -n "$KITTY_DUMP" ]; then
    {
        echo "# generated by theme-switch.sh — theme: $choice (kitty theme: $p_kitty) — do not edit by hand"
        printf '%s\n' "$KITTY_DUMP"
    } > "$HOME/.config/kitty/matugen.conf"
else
cat > "$HOME/.config/kitty/matugen.conf" <<EOF
# generated by theme-switch.sh — theme: $choice — do not edit by hand
foreground $FG
background $BG
cursor     $ACCENT
selection_background $BG_BRIGHT
selection_foreground $FG
color0  $COL0
color1  $COL1
color2  $COL2
color3  $COL3
color4  $COL4
color5  $COL5
color6  $COL6
color7  $COL7
color8  $COL8
color9  $COL9
color10 $COL10
color11 $COL11
color12 $COL12
color13 $COL13
color14 $COL14
color15 $COL15
EOF
fi

# ── ghostty (mirrors kitty; ~/.config/ghostty/config pulls this in via
#    `config-file = theme.conf`). Ghostty has no signal reload, so open windows
#    refresh with ctrl+shift+, — new windows pick it up automatically. ──
cat > "$HOME/.config/ghostty/theme.conf" <<EOF
# generated by theme-switch.sh — theme: $choice — do not edit by hand
background = $BG
foreground = $FG
cursor-color = $ACCENT
selection-background = $BG_BRIGHT
selection-foreground = $FG
palette = 0=$COL0
palette = 1=$COL1
palette = 2=$COL2
palette = 3=$COL3
palette = 4=$COL4
palette = 5=$COL5
palette = 6=$COL6
palette = 7=$COL7
palette = 8=$COL8
palette = 9=$COL9
palette = 10=$COL10
palette = 11=$COL11
palette = 12=$COL12
palette = 13=$COL13
palette = 14=$COL14
palette = 15=$COL15
EOF

# ── herdr (AI agent workspace manager). No runtime color CLI, so the whole
#    config.toml is regenerated: theme colors + baked keybinds. ~/.config/herdr/
#    config.toml is normally a symlink into the repo; theme-switch owns the live
#    copy (broken above), so hand edits go in this heredoc, not the live file. ──
cat > "$HOME/.config/herdr/config.toml" <<EOF
onboarding = false
# generated by theme-switch.sh — theme: $choice — do not edit by hand

[theme]
name = "one-dark"

[theme.custom]
panel_bg = "$BG"
accent = "$ACCENT"
green = "$COL2"
blue = "$COL4"
red = "$COL1"
yellow = "$COL3"

[ui]
accent = "$ACCENT"

[keys]
prefix = "ctrl+a"
previous_agent = "prefix+alt+k"
next_agent = "prefix+alt+j"
focus_agent = "prefix+ctrl+1..9"
EOF

# ── sway (included by ~/.config/sway/config) ──
cat > "$HOME/.config/sway/colors.conf" <<EOF
# generated by theme-switch.sh — theme: $choice — do not edit by hand
set \$accent   $ACCENT
set \$bg       $BG
set \$bg_alt   $BG_ALT
set \$fg       $FG
set \$inactive $BORDER_INACTIVE
set \$urgent   $ERROR
EOF

# ── mako (no @import support → regenerate the whole config) ──
cat > "$HOME/.config/mako/config" <<EOF
# generated by theme-switch.sh — theme: $choice — do not edit by hand
font=IosevkaTerm Nerd Font 11
background-color=${BG_ALT}f2
text-color=$FG
border-color=$ACCENT
progress-color=over $BG_BRIGHT
border-size=2
border-radius=8
padding=10
margin=8
default-timeout=5000
max-visible=5
anchor=top-right

[urgency=high]
border-color=$ERROR
default-timeout=0
EOF

# ── fuzzel (native Wayland launcher; colors are RRGGBBAA without '#') ──
cat > "$HOME/.config/fuzzel/fuzzel.ini" <<EOF
# generated by theme-switch.sh — theme: $choice — do not edit by hand
[main]
font=IosevkaTerm Nerd Font:size=12
prompt=">  "
icons-enabled=no
width=35
lines=10
horizontal-pad=22
vertical-pad=14
inner-pad=10

[border]
width=2
radius=10

[colors]
background=${BG#\#}f2
text=${FG#\#}ff
input=${FG#\#}ff
placeholder=${FG_ALT#\#}ff
match=${ACCENT#\#}ff
selection=${BG_BRIGHT#\#}ff
selection-text=${FG#\#}ff
selection-match=${ACCENT#\#}ff
border=${ACCENT#\#}ff
EOF

# ── zellij (auto-loaded from ~/.config/zellij/themes/; config.kdl sets theme "rice").
#    zellij reads the theme at session start: new sessions pick it up immediately,
#    running sessions update only via zellij's own config file-watcher (not guaranteed). ──
cat > "$HOME/.config/zellij/themes/rice.kdl" <<EOF
// generated by theme-switch.sh — theme: $choice — do not edit by hand
themes {
    rice {
        fg "$FG"
        bg "$BG"
        black "$COL0"
        red "$COL1"
        green "$COL2"
        yellow "$COL3"
        blue "$COL4"
        magenta "$COL5"
        cyan "$COL6"
        white "$COL7"
        orange "$COL3"
    }
}
EOF

# ── neovim (live: tell every running instance to switch colorscheme; the
#    colorscheme comes from the preset table, themes without one leave nvim be) ──
nvim_cs="$p_nvim"
if [ -n "$nvim_cs" ] && command -v nvim >/dev/null 2>&1; then
    for sock in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*; do
        [ -S "$sock" ] || continue
        nvim --server "$sock" --remote-expr "execute('colorscheme $nvim_cs')" >/dev/null 2>&1 || true
    done
fi

# ── Claude Code: the preset's openskin colors + Claude Code's theme. settings.json
#    is usually a symlink into the dotfiles repo: write the resolved file (never
#    replace the link), through a temp file in the same directory, keeping every
#    other key (panelBackground included). Never fatal for the desktop switch. ──
apply_openskin() {
    local s_name s_cc s_accent s_surface s_toolbar s_error s_muted s_command s_background
    local link="$HOME/.claude/settings.json" settings tmp
    IFS='|' read -r s_name _ _ _ s_cc s_accent s_surface s_toolbar s_error s_muted \
        s_command s_background _ <<<"$skin_row"

    command -v jq >/dev/null 2>&1 || { echo "[!] jq not found: openskin left as it is." >&2; return 0; }
    [ -f "$link" ] || { echo "[!] $link not found: openskin left as it is." >&2; return 0; }
    settings="$(readlink -f "$link")"
    tmp="$(mktemp "$(dirname "$settings")/.settings.json.XXXXXX")" ||
        { echo "[!] Cannot create a temp file next to $settings: openskin left as it is." >&2; return 0; }

    if jq --arg cc "$s_cc" --arg accent "$s_accent" --arg surface "$s_surface" \
        --arg toolBar "$s_toolbar" --arg error "$s_error" --arg muted "$s_muted" \
        --arg command "$s_command" --arg background "$s_background" '
        .theme = $cc
        | .pluginConfigs["openskin@extras-claude-code"].options += {
            accent: $accent, surface: $surface, toolBar: $toolBar, error: $error,
            muted: $muted, command: $command, background: $background }
        ' "$settings" > "$tmp"; then
        chmod --reference="$settings" "$tmp" 2>/dev/null || true
        mv -f "$tmp" "$settings"
        echo "[+] Claude Code: openskin preset $s_name ($s_cc theme)"
    else
        rm -f "$tmp"
        echo "[!] Could not update $settings: openskin left as it is." >&2
    fi
}
[ -n "$skin_row" ] && apply_openskin

# ── persist + live reload ──
echo "$choice" > "$STATE_FILE"
swaymsg reload          >/dev/null 2>&1 || true

# ── wallpaper (only for palettes generated from one) ──
# Runs after the reload so nothing sway spawns can land on top of it.
if [ -n "${WALLPAPER:-}" ]; then
    [ -z "${WALLPAPER_DIR:-}" ] && [ -f "$DOTFILES/.env" ] && source "$DOTFILES/.env"
    WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
    wall_path="$WALLPAPER_DIR/$WALLPAPER"
    if [ -f "$wall_path" ]; then
        "$DOTFILES/scripts/set-wallpaper.sh" "$wall_path" >/dev/null 2>&1 || true
    else
        echo "[!] Wallpaper for '$choice' not found: $wall_path" >&2
    fi
fi
makoctl reload          >/dev/null 2>&1 || true
pkill -SIGUSR1 -x kitty >/dev/null 2>&1 || true   # kitty live config reload
command -v herdr >/dev/null 2>&1 && herdr server reload-config >/dev/null 2>&1 || true
label="$choice"
[ "$requested" != "$choice" ] && label="$requested ($choice desktop)"
command -v notify-send >/dev/null 2>&1 && notify-send -t 2000 "Theme" "Switched to $label" || true

echo "[+] Theme applied: $label"
