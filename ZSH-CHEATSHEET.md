# Zsh - Guía de atajos y aliases

## Plugin: git

### Básicos
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `gst` | `git status` | Ver estado del repo |
| `gss` | `git status --short` | Estado compacto |
| `ga` | `git add` | Stagear archivos |
| `gaa` | `git add --all` | Stagear todo |
| `gap` | `git add --patch` | Staging interactivo |

### Commits
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `gc` | `git commit` | Crear commit |
| `gcm` | `git commit -m` | Commit con mensaje |
| `gcam` | `git commit -a -m` | Add all + commit |
| `gc!` | `git commit --amend` | Modificar último commit |
| `gwip` | — | Guardar work in progress |
| `gunwip` | — | Restaurar desde WIP |

### Ramas
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `gco` | `git checkout` | Cambiar rama |
| `gcb` | `git checkout -b` | Crear y cambiar a rama nueva |
| `gb` | `git branch` | Listar ramas |
| `gba` | `git branch -a` | Listar todas (local + remote) |
| `gbd` | `git branch -d` | Borrar rama (seguro) |
| `gbD` | `git branch -D` | Borrar rama (forzado) |
| `gm` | `git merge` | Mergear ramas |

### Diff y log
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `gd` | `git diff` | Ver cambios |
| `gdc` | `git diff --cached` | Ver cambios stageados |
| `glog` | `git log --oneline --graph` | Log compacto con grafo |
| `glo` | `git log --oneline` | Log una línea |

### Push y pull
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `gp` | `git push` | Pushear |
| `gpf` | `git push --force` | Push forzado (cuidado) |
| `gl` | `git pull` | Pullear |
| `glr` | `git pull --rebase` | Pull con rebase |

### Stash
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `gsta` | `git stash` | Guardar cambios temporalmente |
| `gstp` | `git stash pop` | Restaurar stash |
| `gstl` | `git stash list` | Ver stashes |
| `gstd` | `git stash drop` | Borrar un stash |

### Remotes
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `gr` | `git remote` | Gestionar remotes |
| `gra` | `git remote add` | Agregar remote |
| `grv` | `git remote -v` | Ver URLs remotas |
| `gfo` | `git fetch origin` | Fetch desde origin |

### Rebase y reset
| Alias | Comando | Descripción |
|-------|---------|-------------|
| `grb` | `git rebase` | Rebase |
| `grbi` | `git rebase -i` | Rebase interactivo |
| `grh` | `git reset HEAD` | Unstage todo |
| `grhh` | `git reset HEAD --hard` | Hard reset a HEAD |

---

## Plugin: zsh-autosuggestions

Muestra sugerencias en gris mientras escribís, basadas en tu historial.

| Tecla | Acción |
|-------|--------|
| `→` (flecha derecha) | Aceptar sugerencia completa |
| `Ctrl + →` | Aceptar siguiente palabra |
| `Ctrl + E` | Aceptar y ejecutar |
| Seguir escribiendo | Filtrar sugerencia |

---

## Plugin: zsh-syntax-highlighting

Colorea comandos en tiempo real mientras escribís:

| Color | Significado |
|-------|-------------|
| **Verde** | Comando válido / reconocido |
| **Rojo** | Comando inválido / typo |
| **Distinto** | Strings, paths, operadores |
| **Resaltado** | Palabras reservadas (`if`, `for`, `while`) |
| **Coloreado** | Pipes `\|`, redirects `>`, `<` |

Ventaja principal: detectás errores **antes** de presionar Enter.

---

## Aliases custom (.zshrc)

| Alias | Comando | Descripción |
|-------|---------|-------------|
| `ls` | `exa --icons` | Listado con iconos Nerd Font |
| `ll` | `exa --icons -la` | Listado largo con archivos ocultos |
| `la` | `exa --icons -a` | Todos los archivos con iconos |
| `lt` | `exa --icons --tree --level=2` | Árbol de 2 niveles |
| `..` | `cd ..` | Subir un directorio |
| `...` | `cd ../..` | Subir dos directorios |
