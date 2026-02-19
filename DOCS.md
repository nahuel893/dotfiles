# Dotfiles - Documentación técnica

Documentación completa del sistema Arch Linux + Hyprland de nahuel.
Hardware: Desktop con monitor LG 24GL600F (1920x1080@60Hz) via HDMI.

---

## Estructura del repositorio

```
~/dotfiles/
├── .config/
│   ├── alacritty/alacritty.toml    # Terminal (fallback)
│   ├── fontconfig/fonts.conf        # Renderizado de fuentes
│   ├── hypr/
│   │   ├── hyprland.conf            # Window manager
│   │   ├── hyprlock.conf            # Lock screen
│   │   └── hyprpaper.conf           # Wallpaper (autogenerado)
│   ├── kitty/kitty.conf             # Terminal (principal)
│   ├── matugen/
│   │   ├── config.toml              # Configuración de matugen
│   │   └── templates/               # Templates para generar colores
│   │       ├── kitty-colors.conf
│   │       ├── waybar-colors.css
│   │       ├── rofi-colors.rasi
│   │       ├── hyprland-colors.conf
│   │       ├── hyprlock-colors.conf
│   │       └── alacritty-colors.toml
│   ├── nvim/lua/                    # AstroNvim configs
│   │   ├── community.lua            # Plugins de la comunidad
│   │   ├── lazy_setup.lua           # Bootstrap de Lazy.nvim
│   │   ├── polish.lua               # Config final (transparencia)
│   │   └── plugins/                 # Configs de plugins
│   │       ├── astrocore.lua        # Core de AstroNvim
│   │       ├── astrolsp.lua         # LSP config
│   │       ├── astroui.lua          # UI config
│   │       ├── mason.lua            # Gestor de LSPs/formatters
│   │       ├── none-ls.lua          # Formateo/linting externo
│   │       ├── treesitter.lua       # Syntax highlighting
│   │       └── user.lua             # Plugins custom del usuario
│   ├── rofi/config.rasi             # Launcher de apps
│   ├── starship.toml                # Prompt del shell
│   └── waybar/
│       ├── config.jsonc             # Barra de estado (datos)
│       └── style.css                # Barra de estado (estilo)
├── scripts/
│   └── random-wallpaper.sh          # Wallpaper + colores al inicio
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

## Paleta de colores: Material You dinámico (matugen)

La paleta de colores de todo el entorno se **genera automáticamente** a partir del wallpaper actual usando **matugen** (Material Design 3 de Google). Cada vez que cambia el wallpaper, los colores de kitty, waybar, rofi, hyprland, hyprlock y alacritty se actualizan.

### Cómo funciona

```
Wallpaper cambia (manual o al iniciar sesión)
  ↓
random-wallpaper.sh selecciona imagen aleatoria
  ↓
matugen image $wallpaper -m dark
  ↓ Extrae el color dominante del wallpaper
  ↓ Genera ~50 roles de color Material You (primary, secondary, surface, error, etc.)
  ↓ Procesa los 6 templates y escribe archivos de colores:
  │   → ~/.config/kitty/matugen.conf
  │   → ~/.config/waybar/colors.css
  │   → ~/.config/rofi/colors.rasi
  │   → ~/.config/hypr/colors.conf
  │   → ~/.config/hypr/hyprlock-colors.conf
  │   → ~/.config/alacritty/matugen.toml
  ↓ Ejecuta post_hooks (recarga waybar con SIGUSR2)
  ↓
hyprpaper carga el wallpaper
```

### Arquitectura: imports en vez de reemplazo

En lugar de que matugen reescriba los configs completos, usa una estrategia de **archivos de colores separados**. Cada config principal importa su archivo de colores generado:

| App | Config principal | Importa | Mecanismo |
|-----|-----------------|---------|-----------|
| kitty | `kitty.conf` | `matugen.conf` | `include matugen.conf` |
| waybar | `style.css` | `colors.css` | `@import "colors.css"` |
| rofi | `config.rasi` | `colors.rasi` | `@import "colors.rasi"` |
| hyprland | `hyprland.conf` | `colors.conf` | `source = ~/.config/hypr/colors.conf` |
| hyprlock | `hyprlock.conf` | `hyprlock-colors.conf` | `source = ~/.config/hypr/hyprlock-colors.conf` |
| alacritty | `alacritty.toml` | `matugen.toml` | `import = ["~/.config/alacritty/matugen.toml"]` |

**Ventaja:** la estructura, layout, font sizes, keybinds, etc. se mantienen intactos en los configs principales. Solo los colores son dinámicos.

### Templates de matugen

Los templates viven en `~/.config/matugen/templates/` y usan la sintaxis `{{ colors.<rol>.<esquema>.<formato> }}`.

#### Roles de color Material You más usados

| Rol | Uso en el entorno |
|-----|-------------------|
| `primary` | Acento principal: cursor, workspace activo, tabs activos, borders |
| `on_primary` | Texto sobre primary (contraste garantizado) |
| `secondary` | Acento secundario: CPU, red, selección |
| `tertiary` | Tercer acento: temperatura, audio |
| `surface` | Fondo principal de la UI |
| `on_surface` | Texto principal sobre surface |
| `surface_container` | Fondo de píldoras/contenedores (waybar, rofi input) |
| `outline` | Texto inactivo, separadores |
| `outline_variant` | Borders inactivos (hyprland) |
| `error` | Errores, urgente, desconectado |
| `error_container` | Red bright del terminal |

#### `kitty-colors.conf`
Genera los 16 colores del terminal + cursor + selection + tabs. Mapeo:
- **color0/8** (black): `surface` / `surface_container_highest`
- **color1/9** (red): `error` / `error_container`
- **color2/10** (green): `secondary_fixed_dim` / `secondary_fixed`
- **color3/11** (yellow): `tertiary_fixed_dim` / `tertiary_fixed`
- **color4/12** (blue): `on_primary_fixed_variant` / `primary`
- **color5/13** (magenta): `on_secondary_fixed_variant` / `secondary`
- **color6/14** (cyan): `on_tertiary_fixed_variant` / `tertiary`
- **color7/15** (white): `on_surface_variant` / `on_surface`

#### `waybar-colors.css`
Genera variables CSS con `@define-color` para todos los ~50 roles. Usa un loop:
```css
<* for name, value in colors *>
@define-color {{ name }} {{ value.dark.hex }};
<* endfor *>
```
En `style.css` se referencian como `@primary`, `@surface`, `@error`, etc.

#### `rofi-colors.rasi`
Genera 8 variables Rofi: `bg`, `bg-alt`, `fg`, `fg-alt`, `accent`, `urgent`, `border`, `transparent`. Usa opacidad (`cc` = 80%, `40` = 25%) para fondos semitransparentes.

#### `hyprland-colors.conf`
Genera variables Hyprland como `$matugen_primary = rgba(...)`. Se usan en `col.active_border` y `col.inactive_border`.

#### `hyprlock-colors.conf`
Genera variables con formato `rgba(r, g, b, alpha)` para los colores del lock screen: acento, superficie, texto, check, fail, warn.

#### `alacritty-colors.toml`
Genera secciones TOML `[colors.primary]`, `[colors.normal]`, `[colors.bright]` con la misma paleta que kitty.

### Configuración: `config.toml`

```toml
[templates.kitty]
input_path = '~/.config/matugen/templates/kitty-colors.conf'
output_path = '~/.config/kitty/matugen.conf'

[templates.waybar]
input_path = '~/.config/matugen/templates/waybar-colors.css'
output_path = '~/.config/waybar/colors.css'
post_hook = 'pkill -SIGUSR2 waybar'     # Recarga waybar sin reiniciar
```

Cada template define: ruta del template de entrada, ruta del archivo generado, y opcionalmente un `post_hook` (comando que se ejecuta después de generar).

### Uso manual

```bash
# Generar colores de cualquier imagen
matugen image ~/Pictures/wallpapers/foto.jpg -m dark

# Ver la paleta generada
matugen image ~/Pictures/wallpapers/foto.jpg -m dark --show-colors

# Cambiar wallpaper + colores + recargar todo
~/dotfiles/scripts/random-wallpaper.sh && hyprctl reload
```

---

## Archivos de configuración

### `.config/kitty/kitty.conf` — Terminal (principal)

**Kitty** es un emulador de terminal GPU-accelerated con soporte nativo de imágenes. Reemplaza a Alacritty como terminal principal.

| Sección | Qué hace |
|---------|----------|
| `shell` | Fuerza `/usr/bin/zsh` como shell |
| Font | Iosevka Nerd Font a 12pt. Fuente condensada que permite más código por línea |
| `background_opacity` | `0.70` habilita transparencia. El blur lo aplica Hyprland |
| Cursor | Forma beam. Color definido por matugen (primary) |
| `include matugen.conf` | Importa los colores generados dinámicamente por matugen |
| Tab bar | Estilo powerline. Colores dinámicos vía matugen |
| Keybinds | `Ctrl+Shift+Enter` nueva ventana, `Ctrl+Shift+T` nueva tab, `Ctrl+Shift+W` cerrar tab |
| `allow_remote_control` | Permite que herramientas como fastfetch y ranger muestren imágenes en la terminal |

**¿Por qué kitty y no alacritty?** Kitty soporta el protocolo de imágenes nativo, permitiendo mostrar imágenes reales (pixel-perfect) dentro de la terminal. Alacritty no soporta ningún protocolo de imagen. La config de alacritty se mantiene como fallback.

### `.config/alacritty/alacritty.toml` — Terminal (fallback)

**Alacritty** se mantiene como terminal alternativo. Los colores se importan de matugen.

| Sección | Qué hace |
|---------|----------|
| `import` | Importa `matugen.toml` con los colores generados dinámicamente |
| `[terminal.shell]` | Fuerza zsh como shell |
| `[font]` | JetBrains Mono Bold a 11.3pt |
| `[window]` | `opacity = 0.70` habilita transparencia |
| `[keyboard]` | `Ctrl+Shift+Enter` abre una nueva instancia |

### `.config/hypr/hyprland.conf` — Window Manager

**Hyprland** es un compositor Wayland tiling con animaciones.

| Sección | Qué hace |
|---------|----------|
| **Source** | `source = ~/.config/hypr/colors.conf` importa las variables de color generadas por matugen |
| **Monitors** | `monitor=,preferred,auto,auto` detecta el monitor automáticamente (LG 24GL600F 1080p) |
| **Programs** | `$terminal = kitty`, `$menu = rofi -show drun -show-icons -theme ...` Define las apps principales |
| **Autostart** | Lanza `random-wallpaper.sh` (wallpaper + matugen + hyprpaper), `swaync` (notificaciones) y `waybar` al iniciar sesión |
| **General** | `gaps_in = 5`, `gaps_out = 20` separa las ventanas entre sí y del borde. `layout = dwindle` usa tiling dinámico. Borders usan `$matugen_primary` y `$matugen_outline_variant` |
| **Decoration** | `rounding = 10` redondea esquinas de ventanas. `blur: size=8, passes=3` crea blur difuminado detrás de ventanas transparentes |
| **Animations** | Curvas bezier personalizadas para transiciones suaves de ventanas, fade y workspaces |
| **Input** | Layout US, `follow_mouse = 1` (focus sigue al mouse) |

#### Keybinds de Hyprland

| Tecla | Acción |
|-------|--------|
| `Super + Q` | Abrir terminal (kitty) |
| `Super + C` | Cerrar ventana |
| `Super + R` | Abrir rofi (launcher) |
| `Super + E` | File manager |
| `Super + V` | Toggle floating |
| `Super + L` | Lock screen (hyprlock) |
| `Super + Shift + L` | Hibernar (suspend to disk) |
| `Super + W` | Cambiar wallpaper + regenerar colores |
| `Super + 1-0` | Cambiar a workspace 1-10 |
| `Super + Shift + 1-0` | Mover ventana a workspace 1-10 |
| `Super + flechas` | Mover foco entre ventanas |
| `Print` | Screenshot pantalla completa → `~/Pictures/` |
| `Super + Print` | Screenshot de región → `~/Pictures/` |
| `Super + Shift + Print` | Screenshot de región → clipboard |

### `.config/hypr/hyprlock.conf` — Lock Screen

**Hyprlock** es el bloqueador de pantalla del ecosistema Hyprland.

| Sección | Qué hace |
|---------|----------|
| `source` | Importa `hyprlock-colors.conf` con colores dinámicos de matugen |
| `background` | Screenshot con blur (3 passes, size 8), oscurecido al 60% brightness |
| `input-field` | Campo de contraseña centrado, 300x50px, borde redondeado 12px. Colores: borde = primary, fondo = surface, texto = on_surface, error = error, capslock = tertiary |
| `label` (time) | Reloj grande (72px) en Iosevka Nerd Font Bold |
| `label` (date) | Fecha debajo del reloj (18px) con opacidad 80% |

### `.config/hypr/hyprpaper.conf` — Wallpaper

**Hyprpaper** es el gestor de wallpapers del ecosistema Hyprland.

Este archivo es **autogenerado** por `scripts/random-wallpaper.sh` en cada inicio de sesión o al presionar `Super+W`. Usa el formato de bloques de hyprpaper 0.8.x:

```ini
wallpaper {
    monitor = HDMI-A-1
    path = /home/nahuel/Pictures/wallpapers/imagen.jpg
    fit_mode = cover
}
```

**Nota:** `preload` ya no es necesario en hyprpaper 0.8.x. El formato plano (`wallpaper = monitor,path`) está deprecado.

### `.config/nvim/lua/` — AstroNvim

**AstroNvim** es una distribución de Neovim preconfigurada como IDE.

| Archivo | Qué hace |
|---------|----------|
| `lazy_setup.lua` | Bootstrap de Lazy.nvim (gestor de plugins). Configura AstroNvim v5, leader key = Space |
| `community.lua` | Importa plugins de la comunidad AstroNvim (desactivado por defecto) |
| `polish.lua` | Config final que se ejecuta después de todo. Configura **transparencia** removiendo el fondo de Normal, NormalFloat, SignColumn y NeoTree para que el blur de kitty/Hyprland se vea |
| `plugins/astrocore.lua` | Configuración core: keymaps, opciones, autocommands |
| `plugins/astrolsp.lua` | Configuración de LSP: formateo, diagnósticos, keybinds de código |
| `plugins/astroui.lua` | Tema visual y configuración de iconos |
| `plugins/mason.lua` | Lista de LSPs, formatters y linters a instalar automáticamente |
| `plugins/none-ls.lua` | Fuentes externas de formateo/linting (complementa LSP nativo) |
| `plugins/treesitter.lua` | Parsers de syntax highlighting a instalar automáticamente |
| `plugins/user.lua` | Plugins adicionales del usuario |

### `.config/rofi/config.rasi` — Launcher de apps

**Rofi** es un launcher de aplicaciones estilo spotlight.

| Sección | Qué hace |
|---------|----------|
| `configuration` | Modo `drun` (muestra apps .desktop con iconos), font JetBrains Mono Nerd Font 13pt |
| `@import "colors.rasi"` | Importa colores dinámicos generados por matugen |
| `window` | 500px de ancho, fondo transparente (surface + 80% opacidad), borde primary sutil (25% opacidad), bordes redondeados 12px |
| `inputbar` | Barra de búsqueda con fondo surface_container, prompt con color primary, placeholder "Buscar..." |
| `listview` | 7 resultados visibles, altura fija |
| `element` | Items con texto on_surface. Al seleccionar: fondo surface_container + texto primary |

**Nota:** rofi no lee `config.rasi` automáticamente; se pasa con `-theme` desde `hyprland.conf`.

### `.config/waybar/config.jsonc` — Barra de estado (datos)

**Waybar** es una barra de estado para Wayland.

| Campo | Valor | Por qué |
|-------|-------|---------|
| `position` | `top` | Barra arriba de la pantalla |
| `height` | `34` | Altura compacta |
| `margin-top/left/right` | `6/10/10` | Separación del borde, crea efecto flotante |
| **modules-left** | `hyprland/workspaces` | Números 1-10, siempre visibles (persistent workspaces) |
| **modules-center** | `clock` | Reloj. Click alterna entre hora y fecha completa |
| **modules-right** | `tray, temperature, cpu, memory, pulseaudio, network` | Monitoreo del sistema. Sin batería ni wifi (es desktop) |

### `.config/waybar/style.css` — Barra de estado (estilo)

Usa variables CSS importadas de `colors.css` (generado por matugen).

| Regla | Qué hace |
|-------|----------|
| `@import "colors.css"` | Importa todas las variables de color Material You |
| `window#waybar { background: transparent }` | La barra en sí es invisible |
| Módulos `{ background: alpha(@surface_container, 0.65) }` | Cada módulo es una píldora semitransparente flotando |
| `button.active { color: @on_primary; background: @primary }` | Workspace activo: fondo primary + texto con contraste garantizado |
| Colores por módulo | CPU = secondary, RAM = primary, temp = tertiary, audio = tertiary, red = secondary |
| `tooltip { background: alpha(@surface, 0.9) }` | Tooltips oscuros con borde outline_variant |

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

### `scripts/random-wallpaper.sh` — Wallpaper + colores dinámicos

Se ejecuta al inicio de sesión vía `exec-once` en `hyprland.conf` y manualmente con `Super+W`.

1. Mata instancias previas de hyprpaper con `pkill -x`
2. Busca imágenes (jpg, jpeg, png, webp) en `~/Pictures/wallpapers/`
3. Elige una al azar con `shuf`
4. Ejecuta `matugen image $wallpaper -m dark` para generar colores Material You
5. Detecta el monitor con `hyprctl monitors -j` (fallback: HDMI-A-1)
6. Genera `~/.config/hypr/hyprpaper.conf` con formato de bloques 0.8.x
7. Lanza `hyprpaper` con `exec` (reemplaza el proceso del script)

### `install.sh` — Instalador de symlinks

Crea enlaces simbólicos desde el home hacia el repo de dotfiles.

Función `link()`:
- Recibe una ruta relativa (ej. `.config/kitty/kitty.conf`)
- Crea los directorios necesarios con `mkdir -p`
- Si ya existe un archivo real (no symlink), lo renombra a `.bak`
- Crea el symlink con `ln -sf`

Esto permite que las apps lean sus configs desde las rutas habituales, pero los archivos reales vivan en el repo git. Incluye symlinks para matugen config y todos los templates.

### `arch-post-install.sh` — Post-instalación de Arch

Script idempotente (se puede correr múltiples veces gracias a `--needed`).

| Sección | Paquetes | Por qué |
|---------|----------|---------|
| 1. Sistema | base-devel, linux-headers, git, curl, wget, nano, vim, neovim, fastfetch | Herramientas esenciales de desarrollo y sistema |
| 2. Boot & Red | grub, efibootmgr, dosfstools, mtools, os-prober, networkmanager | Bootloader UEFI + gestión de red. Habilita NetworkManager |
| 3. Hyprland | hyprland, hyprpaper, hyprlock, hyprpolkitagent, xdg-desktop-portal-hyprland, waybar, rofi-wayland, dunst, wl-clipboard, matugen | Compositor + barra + launcher + notificaciones + clipboard + theming dinámico |
| 4. Audio | pipewire, pipewire-pulse, pipewire-alsa, wireplumber | PipeWire reemplaza PulseAudio/ALSA. wireplumber es el session manager. pipewire-pulse es la capa de compatibilidad para apps que usan PulseAudio |
| 5. Display Manager | sddm | Pantalla de login gráfica. Se habilita como servicio systemd |
| 6. Terminal + Fuentes | alacritty, kitty, ttf-jetbrains-mono, ttf-jetbrains-mono-nerd, otf-font-awesome, noto-fonts, noto-fonts-emoji | Terminales GPU (kitty principal, alacritty fallback) + fuentes monospace + Nerd Fonts (iconos) + Font Awesome (waybar) + Noto (unicode/emoji) |
| 7. Apps | firefox, ranger, thunar, btop, grim, slurp | Browser + file managers (CLI y GUI) + monitor de sistema + screenshots Wayland |
| 8. Utilidades | brightnessctl, playerctl, polkit-gnome, tailscale, iputils, net-tools, unzip, p7zip | Control de brillo/media + auth gráfica + VPN + herramientas de red + compresión |
| 9. Shell | zsh, starship, oh-my-zsh + plugins | Shell moderno + prompt rápido + framework con autosuggestions y syntax highlighting |
| 10. AUR | yay | Helper para instalar paquetes del AUR. Se compila desde fuente |
| 11. AstroNvim | ripgrep, lazygit, bottom, nodejs, npm, python, tree-sitter-cli | Dependencias de AstroNvim. Clona el template oficial en `~/.config/nvim` |

---

## Hibernación

El sistema tiene configurada hibernación (suspend to disk) con `Super+Shift+L`.

| Componente | Configuración |
|------------|--------------|
| Swap partition | `/dev/sda8` (8GB, prioridad -2) |
| Swap file | `/swapfile` (8GB, prioridad -3) |
| Total swap | 16GB (suficiente para 14GB RAM) |
| Kernel param | `resume=UUID=8f79067a-5c86-464a-bc40-6ede78b7f1b7` en GRUB |
| Initramfs | Hook `systemd` maneja resume automáticamente |

La hibernación guarda toda la RAM a disco y apaga. Al encender, restaura la sesión exactamente como estaba. Compatible con dual boot (Windows en sda3).

---

## Flujo de reinstalación

```bash
# 1. Clonar dotfiles
git clone https://github.com/nahuel893/dotfiles ~/dotfiles

# 2. Instalar todo el software
bash ~/dotfiles/arch-post-install.sh

# 3. Crear symlinks de las configs
bash ~/dotfiles/install.sh

# 4. Agregar wallpapers
mkdir -p ~/Pictures/wallpapers
# Copiar imágenes a ~/Pictures/wallpapers/

# 5. Generar colores iniciales
matugen image ~/Pictures/wallpapers/alguna-imagen.jpg -m dark

# 6. Reiniciar
sudo reboot
```
