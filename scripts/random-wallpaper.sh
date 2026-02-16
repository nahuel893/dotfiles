#!/usr/bin/env bash
# Selecciona un wallpaper aleatorio y lanza hyprpaper

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Buscar imágenes
wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)

if [[ -z "$wallpaper" ]]; then
    echo "No se encontraron wallpapers en $WALLPAPER_DIR"
    exit 1
fi

# Generar hyprpaper.conf con el wallpaper elegido
cat > "$HYPRPAPER_CONF" << EOF
preload = $wallpaper
wallpaper = ,${wallpaper}
splash = false
EOF

# Lanzar hyprpaper
exec hyprpaper
