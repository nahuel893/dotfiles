# Wallpapers

Collection from [vyrx-dev/Wallpapers](https://github.com/vyrx-dev/Wallpapers)
(upstream ships no license file; credit to the original authors). Only the
folders that match the palettes in `themes/` are vendored here.

| Folder | Used by theme | Default wallpaper |
|--------|---------------|-------------------|
| `gruvbox/` | `gruvbox` | `gruvbox_forest-4.png` |
| `nord/` | `nord` | `a_mountain_landscape_with_trees_and_a_building_on_top.png` |
| `monochrome/` | `classic` | `dark-mountain.jpg` |
| `calm/` | `latte` | `a_beach_with_trees_on_the_side.jpg` |

The default is the `WALLPAPER` variable inside each `themes/<name>.sh`, relative
to `$WALLPAPER_DIR` (`~/Pictures/wallpapers`). `install.sh` symlinks every entry
of this folder there; `Mod+w` (`scripts/random-wallpaper.sh`) picks randomly from
all of them, subfolders included.
