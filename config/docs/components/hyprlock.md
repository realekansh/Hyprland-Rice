# Hyprlock

Hyprlock is the fast, GPU-accelerated screen locker for Hyprland. It provides a blurred lockscreen surface with real-time status tickers.

---

## Configuration Files

* `hypr/hyprlock.conf` — Visual definitions, widgets, and layout.
* `hypr/hyprlock/colors.conf` — Color definitions sourced into hyprlock.
* `hypr/hyprlock/fonts/` — Bundled fonts (SF Pro Display, JetBrains Mono Nerd Font).
* `hypr/hyprlock/scripts/` — Status ticker shell scripts.

---

## Visual Design

* **Background**: Uses the active wallpaper with multi-pass Gaussian blur (`blur_passes = 3`, `blur_size = 7`, `noise = 0.0117`, `contrast = 0.8916`).
* **Clock**: Rendered at `128pt` using SF Pro Display Bold (`valign = center`, `position = 0, 320`).
* **Date**: Rendered at `20pt` via `date +"%A, %B %d"` (`position = 0, 200`).
* **Input Field**: Rounded password entry box (`rounding = 16`, `size = 260, 48`) with failed authentication feedback.

---

## Status Scripts

Hyprlock polls three custom scripts to display hardware and notification state:

### 1. Battery Status (`hypr/hyprlock/scripts/status.sh`)
* **Poll Rate**: Every 5000ms.
* **Behavior**: Reads `/sys/class/power_supply/*BAT*/` to display remaining battery percentage and a `(+)` indicator when charging.

### 2. Caps Lock Warning (`hypr/hyprlock/scripts/check-capslock.sh`)
* **Poll Rate**: Every 250ms.
* **Behavior**: Queries `hyprctl devices` for the main keyboard's `capsLock` state. Prints `"Caps Lock is Active"` when enabled, or empty string when off.

### 3. SwayNC Notifications (`hypr/hyprlock/scripts/notifications.sh`)
* **Poll Rate**: Every 1000ms.
* **Behavior**: Runs `swaync-client -c` to query unread notification counts and prints `• N notifications`.

---

## Related Documents

* [Wallpaper Workflow](../workflow/wallpapers.md)
* [Hypridle](../components/hypridle.md)
* [SwayNC](../components/swaync.md)
