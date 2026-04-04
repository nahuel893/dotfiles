#!/usr/bin/sh

# Toggle VirtMon on/off
PIDFILE="/tmp/virtmon.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  kill "$(cat "$PIDFILE")"
  rm -f "$PIDFILE"
  notify-send "VirtMon" "Monitor virtual desactivado"
else
  ~/dotfiles/scripts/virtmon.sh &
  echo $! > "$PIDFILE"
  notify-send "VirtMon" "Monitor virtual activado"
fi
