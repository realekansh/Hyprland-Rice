# Scripts & Automation

This document provides a technical reference for custom shell scripts in the repository.

---

## 1. Wallpaper Shuffler (`hypr/scripts/wallpaper.sh`)

* **Path**: `~/.config/hypr/scripts/wallpaper.sh`
* **Triggered by**: `Super + Shift + W`
* **Purpose**: Selects a random wallpaper from `hypr/hyprpaper/` and synchronizes configuration across daemons.
* **Execution Flow**:
  1. Finds all `.jpg`, `.jpeg`, `.png`, and `.webp` images in `~/.config/hypr/hyprpaper/` and picks one using `shuf -n 1`.
  2. Finds all `.css` files in `~/.config/waybar/themes/` and picks one randomly.
  3. Uses `sed -i` to update the active `path = ...` in `hypr/hyprpaper.conf`.
  4. Uses `sed -i` to update the active `path = ...` in `hypr/hyprlock.conf`.
  5. Updates the `@import url("themes/...")` directive in `waybar/style.css`.
  6. Restarts `hyprpaper` (`killall hyprpaper && hyprpaper &`).
  7. Sends `SIGUSR2` to Waybar (`killall -SIGUSR2 waybar`) to hot-reload CSS without killing the process.

---

## 2. Night Light Toggle (`hypr/scripts/hyprsunset-toggle.sh`)

* **Path**: `~/.config/hypr/scripts/hyprsunset-toggle.sh`
* **Arguments**: Optional color temperature (default: `4000`).
* **Purpose**: Toggles display warmth between neutral daylight and warm night mode.
* **Execution Flow**:
  1. Checks if `hyprsunset` is running; launches it if absent.
  2. Reads state from `${XDG_RUNTIME_DIR:-/tmp}/hyprsunset_state`.
  3. If currently `on`: runs `hyprctl hyprsunset identity` and sets state to `off`.
  4. If currently `off`: runs `hyprctl hyprsunset temperature "$TEMP"` and sets state to `on`.

---

## 3. System Maintenance (`hypr/scripts/sysmaintenance.sh`)

* **Path**: `~/.config/hypr/scripts/sysmaintenance.sh`
* **Arguments**: Optional `--upgrade` (`-u`) to include a full system upgrade.
* **Purpose**: Interactive, abort-safe housekeeping for Arch Linux systems.
* **Execution Flow**:
  1. Detects whether `paru` or `yay` is installed.
  2. Creates timestamped log in `~/.local/var/log/spring-clean-YYYY-MM-DD_HH-MM-SS.log`.
  3. (Optional) Executes `$AUR -Syu --ask 4`.
  4. Trims pacman package cache with `sudo paccache -vrk2` (keeps 2 versions) and `sudo paccache -ruk0` (purges uninstalled packages).
  5. Detects orphaned packages with `$AUR -Qtdq` and prompts for removal via `sudo pacman -Rns`.
  6. Prunes empty folders and files older than 30 days in `~/.cache`.
  7. Vacuums systemd journald logs older than 7 days (`sudo journalctl --vacuum-time=7d`).
  8. Scans for failed systemd units using `systemctl --failed`.

---

## 4. Waybar Reload (`hypr/scripts/waybar-reload.sh`)

* **Path**: `~/.config/hypr/scripts/waybar-reload.sh`
* **Triggered by**: `Super + Shift + R`
* **Purpose**: Cleanly terminates and relaunches the Waybar process.
* **Execution Flow**:
  1. Executes `pkill -x waybar`.
  2. Loops with `sleep 0.1` until `pgrep -x waybar` confirms termination.
  3. Spawns a fresh `waybar` instance in the background.

---

## 5. Lockscreen Status Scripts (`hypr/hyprlock/scripts/`)

* **`status.sh`**: Queries `/sys/class/power_supply/*BAT*/` to output remaining battery capacity (`N%`) and charging indicator (`(+)`).
* **`check-capslock.sh`**: Queries `hyprctl devices` to output `"Caps Lock is Active"` if the primary keyboard has Caps Lock turned on.
* **`notifications.sh`**: Queries `swaync-client -c` to output `• N notifications` if unread notifications exist.

---

## Related Documents

* [Wallpaper Workflow](wallpapers.md)
* [System Controls](system-controls.md)
* [Hyprlock](../components/hyprlock.md)
