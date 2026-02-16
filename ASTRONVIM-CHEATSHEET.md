# AstroNvim - Guía de atajos de teclado

**Leader key: `Space`**

## General
| Tecla | Acción |
|-------|--------|
| `Ctrl + s` | Guardar |
| `Ctrl + q` | Salir |
| `Leader + n` | Nuevo archivo |
| `Leader + R` | Renombrar archivo actual |
| `Leader + c` | Cerrar buffer |
| `jj` o `jk` | Escape (modo insert) |
| `Leader + /` | Comentar/descomentar línea |

## Navegación entre ventanas
| Tecla | Acción |
|-------|--------|
| `Ctrl + h` | Ventana izquierda |
| `Ctrl + j` | Ventana abajo |
| `Ctrl + k` | Ventana arriba |
| `Ctrl + l` | Ventana derecha |
| `\` | Split horizontal |
| `\|` | Split vertical |
| `Ctrl + Up/Down/Left/Right` | Redimensionar ventana |

## Buffers
| Tecla | Acción |
|-------|--------|
| `]b` | Siguiente buffer |
| `[b` | Buffer anterior |
| `>b` | Mover buffer a la derecha |
| `<b` | Mover buffer a la izquierda |
| `Leader + bb` | Picker de buffers |
| `Leader + bc` | Cerrar todos menos el actual |
| `Leader + bC` | Cerrar todos |
| `Leader + bd` | Picker para borrar buffer |

## Explorador de archivos (Neo-Tree)
| Tecla | Acción |
|-------|--------|
| `Leader + e` | Toggle explorador |
| `Leader + o` | Focus en explorador |

## Búsqueda (Picker/Telescope)
| Tecla | Acción |
|-------|--------|
| `Leader + ff` | Buscar archivos |
| `Leader + fF` | Buscar archivos (incluir ocultos) |
| `Leader + fw` | Buscar texto (live grep) |
| `Leader + fW` | Buscar texto (incluir ocultos) |
| `Leader + fb` | Buscar en buffers abiertos |
| `Leader + fc` | Buscar palabra bajo cursor |
| `Leader + fo` | Archivos recientes |
| `Leader + fh` | Buscar en help tags |
| `Leader + fk` | Buscar keymaps |
| `Leader + ft` | Buscar colorschemes |
| `Leader + fr` | Buscar en registros |
| `Leader + fs` | Smart search |
| `Leader + f + Enter` | Reanudar búsqueda anterior |

## LSP (Autocompletado e inteligencia)
| Tecla | Acción |
|-------|--------|
| `K` | Hover documentación |
| `gd` | Ir a definición |
| `gD` | Ir a declaración |
| `gy` | Ir a type definition |
| `grr` | Buscar referencias |
| `grn` | Renombrar símbolo |
| `gra` | Code actions |
| `gl` | Diagnósticos de línea |
| `Leader + lf` | Formatear documento |
| `Leader + ld` | Diagnósticos de línea |
| `Leader + lD` | Todos los diagnósticos |
| `Leader + ls` | Símbolos del documento |
| `Leader + lh` | Signature help |
| `Leader + li` | Info LSP |
| `Leader + lR` | Buscar referencias |
| `Leader + lS` | Outline de símbolos |
| `]d` / `[d` | Siguiente/anterior diagnóstico |
| `]e` / `[e` | Siguiente/anterior error |
| `]w` / `[w` | Siguiente/anterior warning |

## Completado (en modo insert)
| Tecla | Acción |
|-------|--------|
| `Ctrl + Space` | Abrir menú de completado |
| `Enter` | Seleccionar completado |
| `Tab` / `Shift + Tab` | Siguiente/anterior opción |
| `Ctrl + e` | Cancelar completado |
| `Ctrl + u` / `Ctrl + d` | Scroll docs arriba/abajo |

## Git
| Tecla | Acción |
|-------|--------|
| `Leader + gb` | Ramas |
| `Leader + gc` | Commits del repo |
| `Leader + gC` | Commits del archivo |
| `Leader + gt` | Git status |
| `Leader + go` | Abrir en browser |

## Terminal
| Tecla | Acción |
|-------|--------|
| `Leader + tf` | Terminal flotante |
| `Leader + th` | Terminal horizontal |
| `Leader + tv` | Terminal vertical |
| `Leader + tl` | Toggle lazygit |
| `Leader + tn` | Toggle Node REPL |
| `Leader + tp` | Toggle Python REPL |
| `Leader + tt` | Toggle btm (monitor) |
| `F7` o `Ctrl + '` | Toggle terminal actual |

## Debugger (DAP)
| Tecla | Acción |
|-------|--------|
| `Leader + dc` o `F5` | Iniciar/continuar |
| `Leader + dp` o `F6` | Pausar |
| `Leader + db` o `F9` | Toggle breakpoint |
| `Leader + dC` o `Shift + F9` | Breakpoint condicional |
| `Leader + do` o `F10` | Step over |
| `Leader + di` o `F11` | Step into |
| `Leader + dO` o `Shift + F11` | Step out |
| `Leader + dq` | Cerrar sesión |
| `Leader + du` | Toggle UI del debugger |
| `Leader + dE` | Evaluar expresión |

## Sesiones
| Tecla | Acción |
|-------|--------|
| `Leader + Ss` | Guardar sesión |
| `Leader + Sl` | Cargar última sesión |
| `Leader + Sf` | Buscar sesiones |
| `Leader + Sd` | Borrar sesión |
| `Leader + S.` | Cargar sesión del directorio actual |

## Paquetes
| Tecla | Acción |
|-------|--------|
| `Leader + pa` | Actualizar Lazy + Mason |
| `Leader + pi` | Instalar plugins |
| `Leader + pm` | Abrir Mason |
| `Leader + pu` | Buscar actualizaciones |
| `Leader + pU` | Actualizar plugins |

## Tabs
| Tecla | Acción |
|-------|--------|
| `]t` | Siguiente tab |
| `[t` | Tab anterior |

## Dashboard
| Tecla | Acción |
|-------|--------|
| `Leader + h` | Abrir dashboard |
