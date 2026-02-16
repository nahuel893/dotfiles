# Dotfiles - Guía de uso

## Estructura

```
~/dotfiles/
├── .config/
│   ├── alacritty/alacritty.toml
│   ├── hypr/hyprland.conf
│   └── starship.toml
├── .zshrc
├── arch-post-install.sh
├── install.sh
├── USAGE.md
└── .gitignore
```

## ¿Cómo funciona?

`install.sh` crea **symlinks** (enlaces simbólicos) desde tu home hacia `~/dotfiles/`.

```
~/.config/alacritty/alacritty.toml  →  ~/dotfiles/.config/alacritty/alacritty.toml
~/.config/hypr/hyprland.conf        →  ~/dotfiles/.config/hypr/hyprland.conf
~/.config/starship.toml             →  ~/dotfiles/.config/starship.toml
~/.zshrc                            →  ~/dotfiles/.zshrc
```

Hyprland, Alacritty, Starship y Zsh leen desde sus rutas habituales, pero el archivo real vive en `~/dotfiles/`. Así cuando editás tu config, el cambio ya está dentro del repo git listo para commitear.

Si ya existe un archivo en el destino, lo renombra a `.bak` antes de reemplazarlo para no perder nada.

## Shell: Zsh + Oh-My-Zsh + Starship

El setup de shell tiene tres partes:

- **Zsh** — el shell (reemplazo de bash)
- **Oh-My-Zsh** — framework con plugins:
  - `git` — aliases útiles (`gst`, `gco`, `gp`, etc.)
  - `zsh-autosuggestions` — sugiere comandos mientras escribís
  - `zsh-syntax-highlighting` — colorea comandos válidos/inválidos
- **Starship** — prompt rápido y minimalista (reemplaza el tema de Oh-My-Zsh)

La instalación de Oh-My-Zsh y plugins se hace desde `arch-post-install.sh`. Las configs (`.zshrc` y `starship.toml`) se restauran con `install.sh`.

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
2. Correr el post-install (instala paquetes, Oh-My-Zsh, plugins, yay):
   ```bash
   bash ~/dotfiles/arch-post-install.sh
   ```
3. Correr el instalador de symlinks:
   ```bash
   bash ~/dotfiles/install.sh
   ```
4. Todas las configs vuelven al lugar correcto.

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
