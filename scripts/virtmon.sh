#!/usr/bin/env sh
#
# VirtMon - Virtual Monitor via VNC (sway port)
# Adapted from https://github.com/LinuxRenaissance/VirtMon
#
# Creates a headless output in sway, positions it to the right of the real
# monitors, binds workspace 10 to it, and exposes it over LAN via wayvnc.
# Any VNC client on the network can then use it as a wireless secondary screen.
#
# Trust model: no VNC auth. Only expose on trusted local networks.

# ── CONFIG ──
VIRTUAL_WORKSPACE=10
REAL_MONITOR="HDMI-A-1"
BIND_IP="0.0.0.0"        # listen on all interfaces; restrict via firewall if needed
VNC_PORT=5900
VIRT_MODE="1920x1080@60Hz"
VIRT_POS="3286 0"        # right of HDMI-A-1 (0,0 1920w) + eDP-1 (1920,0 1366w)

# ── Remove existing headless outputs (clean slate) ──
for MON in $(swaymsg -t get_outputs | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name'); do
    echo "[virtmon] Removing existing $MON..."
    swaymsg output "$MON" unplug 2>/dev/null \
        || swaymsg output "$MON" disable 2>/dev/null \
        || true
done

# ── Cleanup on exit ──
cleanup() {
    echo "[virtmon] Cleaning up..."
    pkill -x wayvnc 2>/dev/null || true
    if [ -n "${VIRTUAL_MONITOR:-}" ]; then
        swaymsg output "$VIRTUAL_MONITOR" unplug 2>/dev/null \
            || swaymsg output "$VIRTUAL_MONITOR" disable 2>/dev/null \
            || true
    fi
    swaymsg focus output "$REAL_MONITOR" 2>/dev/null || true
    echo "[virtmon] Done."
    exit 0
}
trap cleanup INT TERM EXIT

# ── Create headless output and detect its name ──
echo "[virtmon] Creating headless output..."
swaymsg create_output >/dev/null
sleep 0.4

VIRTUAL_MONITOR=$(swaymsg -t get_outputs | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name' | head -n1)
if [ -z "$VIRTUAL_MONITOR" ]; then
    echo "[virtmon] ERROR: no headless output found"
    exit 1
fi
echo "[virtmon] Detected: $VIRTUAL_MONITOR"

# ── Position virtual monitor + set mode ──
swaymsg output "$VIRTUAL_MONITOR" mode $VIRT_MODE position $VIRT_POS
sleep 0.2

# ── Bind workspace to the virtual monitor ──
echo "[virtmon] Binding workspace $VIRTUAL_WORKSPACE to $VIRTUAL_MONITOR..."
swaymsg workspace "$VIRTUAL_WORKSPACE" output "$VIRTUAL_MONITOR"
sleep 0.2
swaymsg workspace "$VIRTUAL_WORKSPACE"
sleep 0.2

# ── Return focus to real monitor ──
swaymsg focus output "$REAL_MONITOR" 2>/dev/null || true

# ── Start VNC server bound to the headless output ──
echo "[virtmon] Starting wayvnc on $BIND_IP:$VNC_PORT (-o $VIRTUAL_MONITOR)..."
exec wayvnc -o "$VIRTUAL_MONITOR" "$BIND_IP" "$VNC_PORT"
