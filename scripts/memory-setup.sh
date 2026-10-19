#!/usr/bin/env bash
# Keep the desktop responsive when RAM runs out, instead of freezing for minutes.
#
#   zram     : compressed swap in RAM, tried before the disk swap
#   earlyoom : kills the biggest process at 5% RAM left, before thrashing starts
#   sysctl   : swappiness/watermarks tuned for zram, Magic SysRq enabled
#   zswap    : turned off, it competes with zram for the same job
#
# The disk swap is left untouched: hibernation still needs it.
# Idempotent; safe to re-run after editing anything under system/.
#
# Usage: memory-setup.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SYS="$DOTFILES_DIR/system"

log()  { printf '\033[0;32m[+]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
die()  { printf '\033[0;31m[x]\033[0m %s\n' "$1" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "Run as your normal user; sudo is called where needed."

if command -v pacman >/dev/null; then
    log "Installing earlyoom + zram-generator (pacman)..."
    sudo pacman -S --needed --noconfirm earlyoom zram-generator
elif command -v apt-get >/dev/null; then
    log "Installing earlyoom + systemd-zram-generator (apt)..."
    sudo apt-get update
    sudo apt-get install -y earlyoom systemd-zram-generator
else
    die "Unsupported distro: neither pacman nor apt-get found."
fi

# Copied, not symlinked: /etc is read by root at boot, possibly before /home is
# mounted, and a root-owned config should not be editable through a user file.
put() {
    sudo install -D -m 644 "$SYS/$1" "/$1"
    log "/$1"
}
put etc/systemd/zram-generator.conf
put etc/sysctl.d/99-memory.conf
put etc/tmpfiles.d/zswap-off.conf
put etc/systemd/system/earlyoom.service.d/override.conf

log "Applying sysctl + zswap off..."
sudo sysctl --system >/dev/null
sudo systemd-tmpfiles --create /etc/tmpfiles.d/zswap-off.conf

log "Starting zram swap..."
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service

log "Enabling earlyoom..."
sudo systemctl enable earlyoom.service
sudo systemctl restart earlyoom.service

echo ""
swapon --show
echo ""
systemctl --no-pager --lines=0 status earlyoom.service | head -3
log "Done. Check kills with: journalctl -u earlyoom"
