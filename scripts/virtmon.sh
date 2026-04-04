#!/usr/bin/sh

# VirtMon - Virtual Monitor via VNC
# Adapted from https://github.com/LinuxRenaissance/VirtMon

# ── CONFIG ──
VIRTUAL_WORKSPACE=10
REAL_MONITOR="HDMI-A-1"
BIND_IP="192.168.1.1"
VNC_PORT=5900

# ── Remove existing headless monitors ──
for MON in $(hyprctl monitors | grep HEADLESS | awk '{print $2}'); do
  echo "[virtmon] Removing $MON..."
  hyprctl output remove "$MON"
done

# ── Cleanup on exit ──
cleanup() {
  echo "\n[virtmon] Cleaning up..."
  hyprctl dispatch moveworkspacetomonitor $VIRTUAL_WORKSPACE $REAL_MONITOR
  hyprctl dispatch focusmonitor "$REAL_MONITOR"
  pkill wayvnc
  hyprctl output remove "$VIRTUAL_MONITOR"
  echo "[virtmon] Done."
  exit 0
}

trap cleanup INT TERM EXIT

# ── Create virtual monitor and detect its name ──
echo "[virtmon] Creating headless monitor..."
hyprctl output create headless
sleep 0.5

VIRTUAL_MONITOR=$(hyprctl monitors | grep HEADLESS | awk '{print $2}')
if [ -z "$VIRTUAL_MONITOR" ]; then
  echo "[virtmon] ERROR: No headless monitor found"
  exit 1
fi
echo "[virtmon] Detected: $VIRTUAL_MONITOR"

# ── Position monitor to the left ──
hyprctl keyword monitor "$VIRTUAL_MONITOR,1920x1080@60,1920x0,1.0"
sleep 0.3

# ── Assign workspace to virtual monitor ──
echo "[virtmon] Binding workspace $VIRTUAL_WORKSPACE to $VIRTUAL_MONITOR..."
hyprctl keyword workspace "$VIRTUAL_WORKSPACE,monitor:$VIRTUAL_MONITOR,default:true"
sleep 0.2
hyprctl dispatch moveworkspacetomonitor $VIRTUAL_WORKSPACE $VIRTUAL_MONITOR
sleep 0.2
hyprctl dispatch workspace $VIRTUAL_WORKSPACE
sleep 0.2

# ── Return focus to real monitor ──
hyprctl dispatch focusmonitor "$REAL_MONITOR"

# ── Start VNC server ──
echo "[virtmon] Starting WayVNC on $BIND_IP:$VNC_PORT (-o $VIRTUAL_MONITOR)..."
wayvnc -o "$VIRTUAL_MONITOR" "$BIND_IP" "$VNC_PORT"
