#!/usr/bin/env bash
# Selecciona un wallpaper aleatorio, genera colores con matugen, y lanza hyprpaper

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Matar instancias previas de hyprpaper
pkill -x hyprpaper 2>/dev/null
sleep 1

# Buscar imágenes
wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)

if [[ -z "$wallpaper" ]]; then
    echo "No se encontraron wallpapers en $WALLPAPER_DIR"
    exit 1
fi

# Generar paleta Material You desde el wallpaper
matugen image "$wallpaper" -m dark 2>/dev/null

# Obtener nombre del monitor
monitor=$(hyprctl monitors -j | grep -o '"name": "[^"]*"' | head -1 | cut -d'"' -f4)
monitor=${monitor:-HDMI-A-1}

# Generar hyprpaper.conf (formato 0.8.x con bloques)
cat > "$HYPRPAPER_CONF" << EOF
wallpaper {
    monitor = ${monitor}
    path = ${wallpaper}
    fit_mode = cover
}
EOF

# Esperar a que el archivo esté listo y lanzar hyprpaper
sync
exec hyprpaper
