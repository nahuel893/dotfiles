# Dotfiles - Guía de uso

## Estructura

```
~/dotfiles/
├── .config/
│   ├── alacritty/alacritty.toml
│   └── hypr/hyprland.conf
├── .gitignore
├── install.sh
└── USAGE.md
```

## ¿Cómo funciona?

`install.sh` crea **symlinks** (enlaces simbólicos) desde `~/.config/` hacia `~/dotfiles/.config/`.

```
~/.config/alacritty/alacritty.toml  →  ~/dotfiles/.config/alacritty/alacritty.toml
~/.config/hypr/hyprland.conf        →  ~/dotfiles/.config/hypr/hyprland.conf
```

Hyprland y Alacritty leen desde `~/.config/` como siempre, pero el archivo real vive en `~/dotfiles/`. Así cuando editás tu config, el cambio ya está dentro del repo git listo para commitear.

Si ya existe un archivo en `~/.config/`, lo renombra a `.bak` antes de reemplazarlo para no perder nada.

## Flujo día a día

1. Editás un config normalmente:
   ```bash
   vim ~/.config/hypr/hyprland.conf
   ```
2. Como es un symlink, el cambio ya está en `~/dotfiles/`.
3. Guardás el cambio:
   ```bash
   cd ~/dotfiles
   git add -A
   git commit -m "lo que cambiaste"
   git push
   ```

## Instalación en un Arch nuevo

1. Clonar el repo:
   ```bash
   git clone https://github.com/nahuel893/dotfiles ~/dotfiles
   ```
2. Correr el instalador:
   ```bash
   bash ~/dotfiles/install.sh
   ```
3. Todas las configs vuelven al lugar correcto.

## Sincronizar entre múltiples PCs

**En el otro PC (primera vez):**
```bash
git clone https://github.com/nahuel893/dotfiles ~/dotfiles
bash ~/dotfiles/install.sh
```

**Regla importante:** siempre `git pull` antes de editar, siempre `git push` después de commitear.

```bash
cd ~/dotfiles
git pull                          # traer cambios del otro PC
# ... editás tus configs ...
git add -A
git commit -m "lo que cambiaste"
git push                          # subir cambios
```

Como las configs son symlinks, al hacer `git pull` se actualizan automáticamente.

## Agregar un nuevo dotfile

1. Copiar el archivo al repo manteniendo la estructura:
   ```bash
   mkdir -p ~/dotfiles/.config/waybar
   cp ~/.config/waybar/config ~/dotfiles/.config/waybar/
   ```
2. Agregar la línea en `install.sh`:
   ```bash
   link .config/waybar/config
   ```
3. Correr `bash ~/dotfiles/install.sh` para crear el symlink.
4. Commitear el cambio.
