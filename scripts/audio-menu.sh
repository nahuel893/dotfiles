#!/usr/bin/env bash
# Audio device switcher (outputs + inputs) for PipeWire/PulseAudio via fuzzel.
# Picks a sink or source, makes it the default, and moves existing streams to it.
set -euo pipefail

SPK=$''   # speaker icon
MIC=$''   # microphone icon

declare -A MAP
options=""

# Outputs (sinks)
while IFS=$'\t' read -r name desc; do
    [ -n "$name" ] || continue
    label="${SPK}  ${desc}"
    MAP["$label"]="sink:${name}"
    options+="${label}"$'\n'
done < <(pactl list sinks | awk '
    /^[[:space:]]*Name:/       { sub(/^[^:]*:[[:space:]]*/, ""); n=$0 }
    /^[[:space:]]*Description:/ { sub(/^[^:]*:[[:space:]]*/, ""); print n "\t" $0 }')

# Inputs (sources, skipping .monitor loopbacks)
while IFS=$'\t' read -r name desc; do
    [ -n "$name" ] || continue
    case "$name" in *.monitor) continue ;; esac
    label="${MIC}  ${desc}"
    MAP["$label"]="source:${name}"
    options+="${label}"$'\n'
done < <(pactl list sources | awk '
    /^[[:space:]]*Name:/       { sub(/^[^:]*:[[:space:]]*/, ""); n=$0 }
    /^[[:space:]]*Description:/ { sub(/^[^:]*:[[:space:]]*/, ""); print n "\t" $0 }')

choice=$(printf '%s' "$options" | fuzzel --dmenu --prompt "audio ❯ " --lines 12 --width 48) || exit 0
[ -n "${choice:-}" ] || exit 0

sel="${MAP[$choice]:-}"
[ -n "$sel" ] || exit 0
kind="${sel%%:*}"; dev="${sel#*:}"

if [ "$kind" = "sink" ]; then
    pactl set-default-sink "$dev"
    pactl list short sink-inputs | while read -r id _rest; do
        pactl move-sink-input "$id" "$dev" 2>/dev/null || true
    done
else
    pactl set-default-source "$dev"
    pactl list short source-outputs | while read -r id _rest; do
        pactl move-source-output "$id" "$dev" 2>/dev/null || true
    done
fi

command -v notify-send >/dev/null 2>&1 && notify-send -t 2000 -a audio "Audio" "$choice" || true
