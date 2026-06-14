#!/usr/bin/env bash
# Wi-Fi network switcher via NetworkManager (nmcli) + fuzzel.
# Rescans, lists networks (signal + lock + SSID), connects (prompts password if needed).
set -euo pipefail

LOCK=$''   # padlock icon
DOT=$''    # filled dot (currently connected)

declare -A SSID_OF
declare -A seen
options=""

while IFS=':' read -r inuse signal security ssid; do
    [ -n "${ssid:-}" ] || continue
    [ -n "${seen[$ssid]:-}" ] && continue
    seen[$ssid]=1
    mark="  "; [ "$inuse" = "*" ] && mark="${DOT} "
    lk=" "; { [ -n "$security" ] && [ "$security" != "--" ]; } && lk="$LOCK"
    label="${mark}${signal}%  ${lk}  ${ssid}"
    SSID_OF["$label"]="$ssid"
    options+="${label}"$'\n'
done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan auto)

[ -n "$options" ] || { notify-send -a wifi "Wi-Fi" "No networks found" 2>/dev/null; exit 0; }

choice=$(printf '%s' "$options" | fuzzel --dmenu --prompt "wifi ❯ " --lines 14 --width 50) || exit 0
[ -n "${choice:-}" ] || exit 0
ssid="${SSID_OF[$choice]:-}"
[ -n "$ssid" ] || exit 0

# Try a known/open connection first; only prompt for a password if that fails.
if nmcli -w 20 device wifi connect "$ssid" >/dev/null 2>&1; then
    notify-send -a wifi "Wi-Fi" "Connected: $ssid" 2>/dev/null || true
else
    pass=$(printf '' | fuzzel --dmenu --password --prompt "pass ❯ ") || exit 0
    [ -n "${pass:-}" ] || exit 0
    if nmcli -w 20 device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify-send -a wifi "Wi-Fi" "Connected: $ssid" 2>/dev/null || true
    else
        notify-send -a wifi -u critical "Wi-Fi" "Failed: $ssid" 2>/dev/null || true
    fi
fi
