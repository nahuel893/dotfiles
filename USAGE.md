# Dotfiles - Guía de uso

## Estructura

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
│   ├── nvim/lua/                    # AstroNvim configs
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
└── .gitignore
```

## ¿Cómo funciona?

`install.sh` crea **symlinks** (enlaces simbólicos) desde tu home hacia `~/dotfiles/`.

```
~/.config/kitty/kitty.conf          →  ~/dotfiles/.config/kitty/kitty.conf
~/.config/hypr/hyprland.conf        →  ~/dotfiles/.config/hypr/hyprland.conf
~/.config/hypr/hyprlock.conf        →  ~/dotfiles/.config/hypr/hyprlock.conf
~/.config/waybar/style.css          →  ~/dotfiles/.config/waybar/style.css
~/.config/rofi/config.rasi          →  ~/dotfiles/.config/rofi/config.rasi
~/.config/matugen/config.toml       →  ~/dotfiles/.config/matugen/config.toml
~/.config/matugen/templates/*       →  ~/dotfiles/.config/matugen/templates/*
~/.config/nvim/lua/*                →  ~/dotfiles/.config/nvim/lua/*
~/.zshrc                            →  ~/dotfiles/.zshrc
(... y más)
```

Las apps leen desde sus rutas habituales, pero el archivo real vive en `~/dotfiles/`. Así cuando editás tu config, el cambio ya está dentro del repo git listo para commitear.

Si ya existe un archivo en el destino, lo renombra a `.bak` antes de reemplazarlo.

## Colores dinámicos (matugen)

Los colores de todo el entorno (kitty, waybar, rofi, hyprland, hyprlock, alacritty) se generan automáticamente a partir del wallpaper usando **matugen** (Material Design 3 de Google).

Cada config importa un archivo de colores generado:
- `kitty.conf` → `include matugen.conf`
- `style.css` → `@import "colors.css"`
- `config.rasi` → `@import "colors.rasi"`
- `hyprland.conf` → `source = colors.conf`
- `hyprlock.conf` → `source = hyprlock-colors.conf`
- `alacritty.toml` → `import = ["matugen.toml"]`

Para regenerar colores manualmente:
```bash
matugen image ~/Pictures/wallpapers/foto.jpg -m dark
```

O cambiar wallpaper + colores con `Super+W`.

## Keybinds principales

| Tecla | Acción |
|-------|--------|
| `Super + Q` | Abrir terminal (kitty) |
| `Super + C` | Cerrar ventana |
| `Super + R` | Abrir rofi (launcher) |
| `Super + L` | Lock screen (hyprlock) |
| `Super + Shift + L` | Hibernar (suspend to disk) |
| `Super + W` | Cambiar wallpaper + regenerar colores |
| `Super + V` | Toggle floating |
| `Super + 1-0` | Cambiar workspace |
| `Super + Shift + 1-0` | Mover ventana a workspace |
| `Print` | Screenshot pantalla completa |
| `Super + Print` | Screenshot de región |
| `Super + Shift + Print` | Screenshot región → clipboard |

## Shell: Zsh + Oh-My-Zsh + Starship

- **Zsh** — el shell (reemplazo de bash)
- **Oh-My-Zsh** — framework con plugins:
  - `git` — aliases útiles (`gst`, `gco`, `gp`, etc.)
  - `zsh-autosuggestions` — sugiere comandos mientras escribís
  - `zsh-syntax-highlighting` — colorea comandos válidos/inválidos
- **Starship** — prompt rápido y minimalista

Aliases custom:
| Alias | Comando |
|-------|---------|
| `ls` | `exa --icons` |
| `ll` | `exa --icons -la` |
| `la` | `exa --icons -a` |
| `lt` | `exa --icons --tree --level=2` |

## Flujo día a día

1. Editás un config normalmente:
   ```bash
   nvim ~/.config/hypr/hyprland.conf
   ```
2. Como es un symlink, el cambio ya está en `~/dotfiles/`.
3. Guardás el cambio:
   ```bash
   cd ~/dotfiles
   gaa          # git add --all
   gcm "mensaje"  # git commit -m
   gp           # git push
   ```

## Instalación en un Arch nuevo

```bash
# 1. Clonar dotfiles
git clone https://github.com/nahuel893/dotfiles ~/dotfiles

# 2. Instalar paquetes, Oh-My-Zsh, plugins, yay
bash ~/dotfiles/arch-post-install.sh

# 3. Crear symlinks
bash ~/dotfiles/install.sh

# 4. Agregar wallpapers
mkdir -p ~/Pictures/wallpapers
# Copiar imágenes a ~/Pictures/wallpapers/

# 5. Generar colores iniciales
matugen image ~/Pictures/wallpapers/alguna-imagen.jpg -m dark

# 6. Reiniciar
sudo reboot
```

## Sincronizar entre múltiples PCs

**En el otro PC (primera vez):**
```bash
git clone https://github.com/nahuel893/dotfiles ~/dotfiles
bash ~/dotfiles/arch-post-install.sh
bash ~/dotfiles/install.sh
```

**Regla importante:** siempre `git pull` antes de editar, siempre `git push` después de commitear.

```bash
cd ~/dotfiles
git pull                          # traer cambios del otro PC
# ... editás tus configs ...
gaa && gcm "lo que cambiaste" && gp
```

Como las configs son symlinks, al hacer `git pull` se actualizan automáticamente.

## Agregar un nuevo dotfile

1. Copiar el archivo al repo manteniendo la estructura:
   ```bash
   mkdir -p ~/dotfiles/.config/app
   cp ~/.config/app/config ~/dotfiles/.config/app/
   ```
2. Agregar la línea en `install.sh`:
   ```bash
   link .config/app/config
   ```
3. Correr `bash ~/dotfiles/install.sh` para crear el symlink.
4. Commitear el cambio.
