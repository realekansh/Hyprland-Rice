# Wallpaper Workflow

This document explains how wallpaper storage, selection, synchronization, and reload daemons are organized.

---

## Architecture Flow

```text
[ User presses Super + Shift + W ]     [ User presses Super + Alt + W ]
              │                                        │
              ▼                                        ▼
   [ wallpaper-theme.sh ]                    [ wallpaper-only.sh ]
   (Wallpaper + Waybar Theme)                (Wallpaper Only)
              │                                        │
     ┌────────┴────────┬──────────────┐       ┌────────┴────────┐
     ▼                 ▼              ▼       ▼                 ▼
[hyprpaper.conf] [hyprlock.conf]  [style.css] [hyprpaper.conf] [hyprlock.conf]
     │                 │              │       │                 │
     ▼                 ▼              ▼       ▼                 ▼
  hyprctl           hyprlock       killall hyprctl           hyprlock
 hyprpaper            lock         -SIGUSR2 hyprpaper          lock
   reload            screen         waybar    reload          screen
```

---

## Wallpaper Scripts & Modes

The system provides two dedicated shuffle scripts located in `~/.config/hypr/scripts/`:

1. **`wallpaper-theme.sh` (`Super + Shift + W`)**:
   - Randomly picks a wallpaper from `~/.config/hypr/hyprpaper/`.
   - Randomly picks a matching Waybar theme from `~/.config/waybar/themes/`.
   - Updates `hyprpaper.conf`, `hyprlock.conf`, and `~/.config/waybar/style.css`.
   - Live reloads Hyprpaper and sends `SIGUSR2` to Waybar for an instantaneous, flicker-free stylesheet transition.
   - Dispatches a desktop notification with thumbnail and theme name.

2. **`wallpaper-only.sh` (`Super + Alt + W`)**:
   - Randomly picks and applies a wallpaper from `~/.config/hypr/hyprpaper/`.
   - Updates `hyprpaper.conf` and `hyprlock.conf` for persistent desktop and lockscreen sync.
   - **Leaves Waybar theme and CSS completely untouched**.
   - Ideal for users who found their preferred Waybar theme and only want to randomize backgrounds.

3. **`wallpaper.sh` (CLI Dispatcher)**:
   - Unified entrypoint:
     ```bash
     wallpaper.sh --only    # Shuffle wallpaper only
     wallpaper.sh --theme   # Shuffle both wallpaper and Waybar theme
     wallpaper.sh /path/to/img.png  # Set specific wallpaper
     ```

---

## Wallpaper Storage

* All wallpaper assets live in `~/.config/hypr/hyprpaper/`.
* Supported image formats include `.png`, `.jpg`, `.jpeg`, and `.webp`.
* Wallpapers are rendered using `fit_mode = cover` so aspect ratios fill display outputs cleanly.

---

## Multi-Daemon Synchronization

A common issue in Wayland desktop environments is visual desynchronization between the desktop wallpaper and the lockscreen wallpaper. Both shuffler scripts resolve this by updating both configuration files simultaneously:

1. Selects an image from `~/.config/hypr/hyprpaper/`.
2. Updates `hypr/hyprpaper.conf`:
   ```bash
   sed -i -E "s|path = .*|path = $WALLPAPER|g" "$HYPRPAPER_CONF"
   ```
3. Updates `hypr/hyprlock.conf`:
   ```bash
   sed -i -E "s|path = .*|path = $WALLPAPER|g" "$HYPRLOCK_CONF"
   ```
4. Reloads `hyprpaper` dynamically via Wayland IPC:
   ```bash
   hyprctl hyprpaper wallpaper ",$WALLPAPER"
   ```

Because `hyprlock.conf` now references the same image path, activating the screen lock (`Super + L`) displays the exact same wallpaper with Gaussian blur applied.

---

## Adding Custom Wallpapers

To add your own wallpapers to the rotation:
1. Copy image files into `~/.config/hypr/hyprpaper/`.
2. Press `Super + Alt + W` (wallpaper only) or `Super + Shift + W` (wallpaper + theme).

---

## Related Documents

* [Hyprpaper Component Reference](../components/hyprpaper.md)
* [Hyprlock Component Reference](../components/hyprlock.md)
* [Keybindings Reference](keybindings.md)
