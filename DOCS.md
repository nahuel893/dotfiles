# Dotfiles - Documentación técnica

Documentación completa del sistema Arch Linux + Hyprland de nahuel.
Hardware: Desktop con monitor LG 24GL600F (1920x1080@60Hz) via HDMI.

---

## Estructura del repositorio

```
~/dotfiles/
├── .config/
│   ├── alacritty/alacritty.toml    # Terminal
│   ├── fontconfig/fonts.conf        # Renderizado de fuentes
│   ├── hypr/
│   │   ├── hyprland.conf            # Window manager
│   │   └── hyprpaper.conf           # Wallpaper (autogenerado)
│   ├── rofi/config.rasi             # Launcher de apps
│   ├── starship.toml                # Prompt del shell
│   └── waybar/
│       ├── config.jsonc             # Barra de estado (datos)
│       └── style.css                # Barra de estado (estilo)
├── scripts/
│   └── random-wallpaper.sh          # Wallpaper aleatorio al inicio
├── .zshrc                           # Configuración del shell
├── arch-post-install.sh             # Script de instalación completa
├── install.sh                       # Instalador de symlinks
├── USAGE.md                         # Guía de uso rápido
├── DOCS.md                          # Esta documentación
├── ZSH-CHEATSHEET.md               # Atajos de Zsh/Oh-My-Zsh
├── ASTRONVIM-CHEATSHEET.md          # Atajos de AstroNvim
└── .gitignore
```

---

## Paleta de colores: Rosé Pine

Paleta unificada en alacritty, waybar y rofi.

| Nombre | Hex | Uso |
|--------|-----|-----|
| Base | `#181818` | Fondo principal |
| Surface | `#1a1a2e` | Fondo elevado (inputbar rofi, selección waybar) |
| Text | `#d8d8d8` | Texto principal |
| Subtle | `#585858` | Texto secundario, elementos inactivos |
| Muted text | `#e0def4` | Texto destacado (reloj) |
| Violeta | `#c4a7e7` | Acento principal: cursor, selección, workspace activo, RAM |
| Cyan | `#9ccfd8` | CPU, red |
| Dorado | `#f6c177` | Temperatura |
| Rosa | `#ebbcba` | Audio |
| Rojo | `#eb6f92` | Errores, urgente, desconectado |
| Azul | `#31748f` | Color blue del terminal |
| Píldoras waybar | `rgba(60, 60, 70, 0.65)` | Fondo semitransparente de módulos |

---

## Archivos de configuración

### `.config/alacritty/alacritty.toml` — Terminal

**Alacritty** es un emulador de terminal GPU-accelerated para Wayland.

| Sección | Qué hace |
|---------|----------|
| `[terminal.shell]` | Fuerza zsh como shell. Necesario porque alacritty no siempre respeta el shell default del usuario |
| `[font]` | JetBrains Mono Bold a 11.3pt. Bold mejora legibilidad en tamaños chicos |
| `[window]` | `opacity = 0.70` habilita transparencia. El blur lo aplica Hyprland, no alacritty |
| `[colors.primary]` | Fondo `#181818` y texto `#d8d8d8` (base Rosé Pine) |
| `[colors.cursor]` | Cursor violeta (`#c4a7e7`) sobre fondo oscuro para máximo contraste |
| `[colors.selection]` | Selección violeta para consistencia visual con el cursor |
| `[colors.normal]` | Los 8 colores base del terminal (black, red, green, yellow, blue, magenta, cyan, white) mapeados a la paleta Rosé Pine |
| `[colors.bright]` | Variantes bright de los mismos colores. `bright.black` es el gris (`#585858`), `bright.white` es el blanco más claro (`#e0def4`) |
| `[keyboard]` | `Ctrl+Shift+Enter` abre una nueva instancia de alacritty |

### `.config/hypr/hyprland.conf` — Window Manager

**Hyprland** es un compositor Wayland tiling con animaciones.

| Sección | Qué hace |
|---------|----------|
| **Monitors** | `monitor=,preferred,auto,auto` detecta el monitor automáticamente (LG 24GL600F 1080p) |
| **Programs** | `$terminal = alacritty`, `$menu = rofi -show drun -show-icons -theme ...` Define las apps principales |
| **Autostart** | Lanza `random-wallpaper.sh` (wallpaper + hyprpaper), `swaync` (notificaciones) y `waybar` al iniciar sesión |
| **General** | `gaps_in = 5`, `gaps_out = 20` separa las ventanas entre sí y del borde. `layout = dwindle` usa tiling dinámico |
| **Decoration** | `rounding = 10` redondea esquinas de ventanas. `blur: size=8, passes=3` crea blur difuminado detrás de ventanas transparentes |
| **Animations** | Curvas bezier personalizadas para transiciones suaves de ventanas, fade y workspaces |
| **Input** | Layout US, `follow_mouse = 1` (focus sigue al mouse) |
| **Keybinds** | `Super+Q` terminal, `Super+C` cerrar, `Super+R` rofi, `Super+1-0` workspaces, `Super+Shift+1-0` mover ventana a workspace |

### `.config/hypr/hyprpaper.conf` — Wallpaper

**Hyprpaper** es el gestor de wallpapers del ecosistema Hyprland.

Este archivo es **autogenerado** por `scripts/random-wallpaper.sh` en cada inicio de sesión. Contiene la imagen seleccionada aleatoriamente de `~/Pictures/wallpapers/`. No se edita manualmente.

### `.config/rofi/config.rasi` — Launcher de apps

**Rofi** es un launcher de aplicaciones estilo spotlight.

| Sección | Qué hace |
|---------|----------|
| `configuration` | Modo `drun` (muestra apps .desktop con iconos), font JetBrains Mono Nerd Font 13pt |
| `*` (variables) | Define la paleta Rosé Pine como variables reutilizables. `cc` al final del hex = 80% opacidad |
| `window` | 500px de ancho, fondo transparente (`#181818cc`), borde violeta sutil (`#c4a7e740`), bordes redondeados 12px |
| `inputbar` | Barra de búsqueda con fondo surface (`#1a1a2ecc`), prompt violeta, placeholder "Buscar..." |
| `listview` | 7 resultados visibles, altura fija |
| `element` | Items con texto `#d8d8d8`. Al seleccionar: fondo surface + texto violeta |

**Nota:** rofi no lee `config.rasi` automáticamente en esta versión; se pasa con `-theme` desde `hyprland.conf`.

### `.config/waybar/config.jsonc` — Barra de estado (datos)

**Waybar** es una barra de estado para Wayland.

| Campo | Valor | Por qué |
|-------|-------|---------|
| `position` | `top` | Barra arriba de la pantalla |
| `height` | `34` | Altura compacta |
| `margin-top/left/right` | `6/10/10` | Separación del borde, crea efecto flotante |
| **modules-left** | `hyprland/workspaces` | Iconos Nerd Font por workspace (terminal, browser, código, etc.) |
| **modules-center** | `clock` | Reloj. Click alterna entre hora y fecha completa |
| **modules-right** | `tray, temperature, cpu, memory, pulseaudio, network` | Monitoreo del sistema. Sin batería ni wifi (es desktop) |

Cada módulo tiene su `format` con iconos Nerd Font unicode.

### `.config/waybar/style.css` — Barra de estado (estilo)

| Regla | Qué hace |
|-------|----------|
| `window#waybar { background: transparent }` | La barra en sí es invisible |
| Módulos `{ background: rgba(60,60,70,0.65); border-radius: 8px }` | Cada módulo es una píldora semitransparente flotando |
| `button.active { color: #1a1a2e; background: #c4a7e7 }` | Workspace activo: fondo violeta sólido + texto oscuro para contraste |
| Colores por módulo | CPU cyan, RAM violeta, temp dorado, audio rosa, red cyan — cada uno tiene su tono de la paleta |
| `tooltip { background: rgba(24,24,24,0.9) }` | Tooltips oscuros con borde sutil |

### `.config/starship.toml` — Prompt

**Starship** es un prompt cross-shell rápido escrito en Rust. Reemplaza el tema de Oh-My-Zsh.

| Sección | Qué hace |
|---------|----------|
| `format` | Muestra solo: directorio + rama git + estado git + carácter. Minimalista |
| `[directory]` | Trunca a 3 niveles, color cyan bold |
| `[git_branch]` | Icono ` `, color purple bold |
| `[git_status]` | Muestra cambios pendientes en rojo bold |
| `[character]` | `>` verde si el último comando fue exitoso, rojo si falló |

### `.config/fontconfig/fonts.conf` — Renderizado de fuentes

**Fontconfig** controla cómo se renderizan las fuentes en todo el sistema.

| Setting | Valor | Por qué |
|---------|-------|---------|
| `antialias` | `true` | Suaviza bordes de las letras. Sin esto se ven pixeladas |
| `hinting` | `true` + `hintslight` | Ajusta fuentes a la grilla de píxeles. `hintslight` es el mejor balance entre nitidez y fidelidad al diseño original |
| `rgba` | `rgb` | Subpixel rendering: usa los subpíxeles R/G/B del monitor para triplicar resolución horizontal del texto |
| `lcdfilter` | `lcddefault` | Filtro LCD estándar para evitar color fringing del subpixel rendering |
| Alias `monospace` | JetBrains Mono Nerd Font > JetBrains Mono > Noto Sans Mono | Prioridad de fuentes monospace en todo el sistema |
| Alias `sans-serif` | Noto Sans | Fuente default para interfaces gráficas |

### `.zshrc` — Shell

**Zsh** con **Oh-My-Zsh** como framework y **Starship** como prompt.

| Línea | Qué hace |
|-------|----------|
| `ZSH_THEME=""` | Deshabilitado porque usamos Starship en su lugar |
| `plugins=(git zsh-autosuggestions zsh-syntax-highlighting)` | **git**: aliases como `gst`, `gp`, `gco`. **autosuggestions**: sugiere comandos del historial en gris. **syntax-highlighting**: colorea comandos válidos (verde) e inválidos (rojo) |
| `export PATH="$HOME/.local/bin:$PATH"` | Agrega `~/.local/bin` al PATH (ahí vive Claude Code y otras herramientas instaladas con pip/npm) |
| Aliases `ls/ll/la/lt` | Reemplazan `ls` por `exa` con iconos Nerd Font. `lt` muestra árbol de 2 niveles |
| `eval "$(starship init zsh)"` | Inicializa Starship como prompt. Debe ir al final del archivo |

---

## Scripts

### `scripts/random-wallpaper.sh` — Wallpaper aleatorio

Se ejecuta al inicio de sesión via `exec-once` en `hyprland.conf`.

1. Busca imágenes (jpg, jpeg, png, webp) en `~/Pictures/wallpapers/`
2. Elige una al azar con `shuf`
3. Genera `~/.config/hypr/hyprpaper.conf` con esa imagen
4. Lanza `hyprpaper` con `exec` (reemplaza el proceso del script)

### `install.sh` — Instalador de symlinks

Crea enlaces simbólicos desde el home hacia el repo de dotfiles.

Función `link()`:
- Recibe una ruta relativa (ej. `.config/alacritty/alacritty.toml`)
- Crea los directorios necesarios con `mkdir -p`
- Si ya existe un archivo real (no symlink), lo renombra a `.bak`
- Crea el symlink con `ln -sf`

Esto permite que las apps lean sus configs desde las rutas habituales, pero los archivos reales vivan en el repo git.

### `arch-post-install.sh` — Post-instalación de Arch

Script idempotente (se puede correr múltiples veces gracias a `--needed`).

| Sección | Paquetes | Por qué |
|---------|----------|---------|
| 1. Sistema | base-devel, linux-headers, git, curl, wget, nano, vim, neovim, fastfetch | Herramientas esenciales de desarrollo y sistema |
| 2. Boot & Red | grub, efibootmgr, dosfstools, mtools, os-prober, networkmanager | Bootloader UEFI + gestión de red. Habilita NetworkManager |
| 3. Hyprland | hyprland, hyprpaper, hyprpolkitagent, xdg-desktop-portal-hyprland, waybar, rofi-wayland, dunst, wl-clipboard | Compositor + barra + launcher + notificaciones + clipboard para Wayland |
| 4. Audio | pipewire, pipewire-pulse, pipewire-alsa, wireplumber | PipeWire reemplaza PulseAudio/ALSA. wireplumber es el session manager. Sin pipewire-pulse las apps que usan PulseAudio no tendrían audio |
| 5. Display Manager | sddm | Pantalla de login gráfica. Se habilita como servicio systemd |
| 6. Terminal + Fuentes | alacritty, ttf-jetbrains-mono, ttf-jetbrains-mono-nerd, otf-font-awesome, noto-fonts, noto-fonts-emoji | Terminal GPU + fuente monospace + variante Nerd Fonts (iconos) + Font Awesome (waybar) + Noto (unicode/emoji) |
| 7. Apps | firefox, ranger, thunar, btop, grim, slurp | Browser + file managers (CLI y GUI) + monitor de sistema + screenshots Wayland |
| 8. Utilidades | brightnessctl, playerctl, polkit-gnome, tailscale, iputils, net-tools, unzip, p7zip | Control de brillo/media + auth gráfica + VPN + herramientas de red + compresión |
| 9. Shell | zsh, starship, oh-my-zsh + plugins | Shell moderno + prompt rápido + framework con autosuggestions y syntax highlighting |
| 10. AUR | yay | Helper para instalar paquetes del AUR. Se compila desde fuente |
| 11. AstroNvim | ripgrep, lazygit, bottom, nodejs, npm, python, tree-sitter-cli | Dependencias de AstroNvim. Clona el template oficial en `~/.config/nvim` |

---

## Flujo de reinstalación

```bash
# 1. Clonar dotfiles
git clone https://github.com/nahuel893/dotfiles ~/dotfiles

# 2. Instalar todo el software
bash ~/dotfiles/arch-post-install.sh

# 3. Crear symlinks de las configs
bash ~/dotfiles/install.sh

# 4. Reiniciar
sudo reboot
```
