# Fastfetch

Fastfetch displays system branding and hardware metrics in terminal windows.

---

## Configuration Files

* `fastfetch/config.jsonc` — Default configuration.
* `fastfetch/ascii/` — Custom ASCII logo templates (`arch.txt`, `rose.txt`, `triangle.txt`).
* `fastfetch/presets/` — Alternate preset configurations (`ascii-art.jsonc`, `full-info.jsonc`, `groups.jsonc`, `hypr.jsonc`, `minimal.jsonc`, `nyarch.jsonc`, `os.jsonc`).

---

## Display Modules

The default configuration in `fastfetch/config.jsonc` renders:
* **Logo**: Custom ASCII art sourced from `~/.config/fastfetch/ascii/arch.txt`.
* **OS**: Linux distribution with icon ``.
* **Kernel**: Kernel version with icon ``.
* **Packages**: Pacman package count with icon ``.
* **Shell**: Active user shell with icon ``.
* **Terminal**: Active terminal emulator with icon ``.
* **WM**: Compositor name (`Hyprland`) with icon ``.
* **Uptime**: System uptime with icon ``.

---

## Related Documents

* [Theming System](../customization/theming.md)
