#!/usr/bin/env bash
#
# Arch Linux + Hyprland - Post Install Script
# Basado en el historial de instalación de nahuel
# Fecha de referencia: 2026-02-14
#

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }

if [[ $EUID -eq 0 ]]; then
    err "No ejecutes este script como root. Usa tu usuario normal."
    exit 1
fi

# ─────────────────────────────────────────────
# 1. Actualizar sistema
# ─────────────────────────────────────────────
log "Actualizando sistema..."
sudo pacman -Syu --noconfirm

# ─────────────────────────────────────────────
# 2. Paquetes base del sistema
# ─────────────────────────────────────────────
log "Instalando paquetes base..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    linux-headers \
    git \
    curl \
    wget \
    nano \
    vim \
    fastfetch

# ─────────────────────────────────────────────
# 3. Boot & Red
# ─────────────────────────────────────────────
log "Instalando boot y red..."
sudo pacman -S --needed --noconfirm \
    grub \
    efibootmgr \
    dosfstools \
    mtools \
    os-prober \
    networkmanager

sudo systemctl enable --now NetworkManager

# ─────────────────────────────────────────────
# 4. Hyprland + ecosistema Wayland
# ─────────────────────────────────────────────
log "Instalando Hyprland y ecosistema Wayland..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    hyprpaper \
    hyprpolkitagent \
    xdg-desktop-portal-hyprland \
    waybar \
    rofi-wayland \
    dunst \
    wl-clipboard

# ─────────────────────────────────────────────
# 5. Audio (PipeWire)
# ─────────────────────────────────────────────
log "Instalando PipeWire y componentes de audio..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# ─────────────────────────────────────────────
# 6. Display Manager
# ─────────────────────────────────────────────
log "Instalando SDDM..."
sudo pacman -S --needed --noconfirm sddm
sudo systemctl enable sddm

# ─────────────────────────────────────────────
# 7. Terminal + fuentes
# ─────────────────────────────────────────────
log "Instalando terminal y fuentes..."
sudo pacman -S --needed --noconfirm \
    alacritty \
    ttf-jetbrains-mono \
    ttf-jetbrains-mono-nerd \
    otf-font-awesome \
    noto-fonts \
    noto-fonts-emoji

# ─────────────────────────────────────────────
# 8. Apps de usuario
# ─────────────────────────────────────────────
log "Instalando aplicaciones..."
sudo pacman -S --needed --noconfirm \
    firefox \
    ranger \
    thunar \
    grim \
    slurp

# ─────────────────────────────────────────────
# 9. Utilidades extras recomendadas
# ─────────────────────────────────────────────
log "Instalando utilidades..."
sudo pacman -S --needed --noconfirm \
    brightnessctl \
    playerctl \
    polkit-gnome \
    unzip \
    p7zip

# ─────────────────────────────────────────────
# 10. Configs iniciales
# ─────────────────────────────────────────────
log "Configurando Alacritty..."
mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.toml << 'ALACRITTY'
[font]
size = 14.0

[font.normal]
family = "JetBrains Mono"
style = "Medium"

[window]
opacity = 1.0
padding = { x = 6, y = 6 }

[colors.primary]
background = "#181818"
foreground = "#d8d8d8"

[keyboard]
bindings = [
  { key = "Return", mods = "Control|Shift", action = "SpawnNewInstance" },
]
ALACRITTY

# ─────────────────────────────────────────────
# 11. Instalar yay (AUR helper)
# ─────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    log "Instalando yay (AUR helper)..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
else
    warn "yay ya está instalado, salteando."
fi

# ─────────────────────────────────────────────
# Resumen
# ─────────────────────────────────────────────
echo ""
log "===== Instalación completada ====="
echo ""
echo "  Paquetes instalados que ya tenías:"
echo "    hyprland, waybar, hyprpaper, sddm, firefox,"
echo "    alacritty, ranger, rofi, dunst, pipewire,"
echo "    wl-clipboard, ttf-jetbrains-mono, fastfetch"
echo ""
echo "  Paquetes nuevos agregados:"
echo "    pipewire-pulse, pipewire-alsa, wireplumber  (audio completo)"
echo "    rofi-wayland          (rofi nativo para Wayland)"
echo "    noto-fonts, noto-fonts-emoji  (soporte Unicode)"
echo "    thunar                (file manager gráfico)"
echo "    grim, slurp           (screenshots en Wayland)"
echo "    brightnessctl         (control de brillo)"
echo "    playerctl             (control de media)"
echo "    polkit-gnome          (autenticación gráfica)"
echo "    yay                   (AUR helper)"
echo ""
warn "Reiniciá para que SDDM y todo quede activo."
