# Hyprpaper

Hyprpaper is the official wallpaper daemon for Hyprland. It renders wallpapers across all detected monitors with cover-fit scaling and low resource consumption.

---

## Configuration Files

* `hypr/hyprpaper.conf` — Main daemon configuration.
* `hypr/hyprpaper/` — Directory of curated wallpaper images.

---

## Configuration Settings

```text
ipc = on
splash = false

wallpaper {
    monitor =
    path = /home/notrealekansh/.config/hypr/hyprpaper/flowering-rain.png
    fit_mode = cover
}
```

* **IPC**: `ipc = on` allows external scripts to send runtime wallpaper reload commands.
* **Splash**: Disabled.
* **Fit Mode**: `cover` scales the image proportionally to fill the display area without letterboxing.

---

## Integration with Wallpaper Shuffler

When `Super + Shift + W` is pressed, `hypr/scripts/wallpaper.sh` updates the `path` line in `hyprpaper.conf` and restarts the daemon:

```bash
sed -i -E "s|path = .*|path = $WALLPAPER|g" "$HYPRPAPER_CONF"
killall hyprpaper
hyprpaper >/dev/null 2>&1 &
```

---

## Related Documents

* [Wallpaper Workflow](../workflow/wallpapers.md)
* [Hyprlock](../components/hyprlock.md)
