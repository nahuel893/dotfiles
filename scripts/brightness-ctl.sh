#!/usr/bin/env bash
#
# Brightness control that works WITHOUT root.
#
# Writing to /sys/class/backlight/*/brightness normally needs root (or a udev
# rule granting the 'video' group write access). This wrapper avoids that: it
# uses systemd-logind's SetBrightness D-Bus call, which the kernel authorizes
# for the *active session's* user with no elevated privileges. If the sysfs
# node happens to be writable (udev rule present), it uses brightnessctl
# directly instead.
#
# It also fixes the "brightness resets after the screen powers off" bug: the
# i915 panel re-initializes at a low PWM value on DPMS power-on, so we stash the
# level before power-off (save) and re-apply it on resume (restore).
#
# Usage:
#   brightness-ctl.sh save              stash the current level
#   brightness-ctl.sh restore           re-apply the stashed level (DPMS fix)
#   brightness-ctl.sh set <raw>         set an absolute raw value
#   brightness-ctl.sh up|down [step%]   relative change (default 5%)
#
set -euo pipefail

DEV=intel_backlight
SYS="/sys/class/backlight/$DEV"
STATE="${XDG_RUNTIME_DIR:-/tmp}/brightness.$DEV"

[ -d "$SYS" ] || { echo "no backlight device: $SYS" >&2; exit 1; }

max=$(< "$SYS/max_brightness")
cur=$(< "$SYS/brightness")

apply() {
    local v=$1
    (( v < 1 ))     && v=1        # never fully black
    (( v > max ))   && v=$max
    if [ -w "$SYS/brightness" ]; then
        brightnessctl -d "$DEV" set "$v" >/dev/null
    else
        busctl call org.freedesktop.login1 \
            /org/freedesktop/login1/session/auto \
            org.freedesktop.login1.Session SetBrightness ssu \
            backlight "$DEV" "$v" >/dev/null
    fi
}

step_raw() { echo $(( max * ${1:-5} / 100 )); }

case "${1:-}" in
    save)    echo "$cur" > "$STATE" ;;
    restore) [ -r "$STATE" ] && apply "$(< "$STATE")" || true ;;
    set)     apply "${2:?raw value required}" ;;
    up)      apply $(( cur + $(step_raw "${2:-5}") )) ;;
    down)    apply $(( cur - $(step_raw "${2:-5}") )) ;;
    *) echo "usage: ${0##*/} {save|restore|set <raw>|up|down [step%]}" >&2; exit 1 ;;
esac
