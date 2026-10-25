# themes.sh — the openskin presets as theme-switch.sh knows them.
# Sourced by theme-switch.sh, not executed. This is the ONE place the presets live:
# every tool theme-switch.sh writes (kitty, ghostty, sway, waybar, mako, nvim, openskin)
# reads its colors from here.
#
# The seven openskin colors and the Claude Code theme mirror PRESETS in
# extras-claude-code/plugins/openskin/hooks/skin.tsx; keep them in sync with it.
# `panelBackground` is deliberately absent: presets leave it as the person set it.
#
# One preset per line, fields separated by '|':
#   name     preset name (as `/skin <name>` takes it)
#   system   the themes/<name>.sh palette that themes the desktop for this preset:
#              empty    -> the desktop palette is generated from this row
#              current  -> the desktop keeps the theme it has (only `default`)
#              <name>   -> that existing palette; <name> is accepted as an alias
#   kitty    `kitten themes` name whose official palette goes into kitty
#   nvim     installed nvim colorscheme, empty to leave nvim as it is
#   cc       Claude Code theme (dark|light)
#   accent surface toolBar error muted command background   openskin colors
#   fg       official foreground, used when the kitty palette is unavailable
#
# shellcheck shell=bash disable=SC2034
OPENSKIN_PRESETS=(
    "default|current|||dark|#f0a6ec|#24242c|#55555f|#ff6b5b|#7f7f8a|bashBorder|#1c1c22|"
    "tokyonight||Tokyo Night||dark|#bb9af7|#1f2335|#414868|#f7768e|#737aa2|#7dcfff|#16161e|#c0caf5"
    "catppuccin-mocha||Catppuccin-Mocha|catppuccin-mocha|dark|#cba6f7|#313244|#585b70|#f38ba8|#9399b2|#94e2d5|#181825|#cdd6f4"
    "catppuccin-latte|latte|Catppuccin-Latte|catppuccin-latte|light|#8839ef|#ccd0da|#acb0be|#d20f39|#5c5f77|#179299|#e6e9ef|#4c4f69"
    "gruvbox-dark|gruvbox|Gruvbox Dark|gruvbox|dark|#fabd2f|#3c3836|#665c54|#fb4934|#a89984|#8ec07c|#1d2021|#ebdbb2"
    "nord|nord|Nord|nord|dark|#88c0d0|#3b4252|#4c566a|#bf616a|#81a1c1|#a3be8c|#2e3440|#d8dee9"
    "rose-pine||Rosé Pine||dark|#c4a7e7|#26233a|#403d52|#eb6f92|#908caa|#9ccfd8|#191724|#e0def4"
    "rose-pine-dawn||Rosé Pine Dawn||light|#907aa9|#f2e9e1|#cecacd|#b4637a|#797593|#56949f|#faf4ed|#575279"
    "kanagawa-wave||Kanagawa||dark|#d27e99|#2a2a37|#54546d|#e46876|#938aa9|#7fb4ca|#16161d|#dcd7ba"
    "everforest||Everforest Dark Medium||dark|#a7c080|#343f44|#475258|#e67e80|#9da9a0|#83c092|#232a2e|#d3c6aa"
    "one-dark||One Dark||dark|#61afef|#2c313c|#3e4451|#e06c75|#828997|#56b6c2|#21252b|#abb2bf"
)

# preset_row <name> — prints the preset row whose name, or whose system palette, is <name>.
# Returns 1 when no preset matches.
preset_row() {
    local row name system
    for row in "${OPENSKIN_PRESETS[@]}"; do
        IFS='|' read -r name system _ <<<"$row"
        if [ "$name" = "$1" ] || { [ "$system" = "$1" ] && [ "$system" != current ]; }; then
            printf '%s\n' "$row"
            return 0
        fi
    done
    return 1
}
