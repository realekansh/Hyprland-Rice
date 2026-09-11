# Architecture Overview

This document describes the high-level architecture of the desktop environment: how software layers interact, how environment variables propagate, and how inter-process communication coordinates system state.

---

## System Layers

The desktop is organized into four operational tiers:

```text
+-----------------------------------------------------------------------+
| User Interface Overlays                                               |
|  - Rofi (Launchers & Applets)       - AGS (Media & Telemetry Popups)  |
|  - SwayNC (Notification Center)     - Wlogout (Session Menu)          |
+-----------------------------------------------------------------------+
                                    |
+-----------------------------------------------------------------------+
| Wayland Compositor Core                                               |
|  - Hyprland (0.55+ Lua Runtime)                                       |
|  - Layer Shell Blur & Window Rules                                    |
|  - Input Dispatcher & Animation Physics                               |
+-----------------------------------------------------------------------+
                                    |
+-----------------------------------------------------------------------+
| Background Daemons & Services                                         |
|  - Hypridle (Idle & Sleep Monitor)  - Hyprpaper (Wallpaper Daemon)    |
|  - Hyprsunset (Gamma Daemon)        - PipeWire / WirePlumber (Audio)  |
|  - NetworkManager (Networking)      - BlueZ (Bluetooth)               |
+-----------------------------------------------------------------------+
                                    |
+-----------------------------------------------------------------------+
| Linux Kernel & Hardware Interfaces                                    |
|  - /sys/class/power_supply (Battery) - /sys/class/backlight (Display) |
|  - /sys/devices/system/cpu (EPP)     - /proc/stat, /proc/meminfo      |
+-----------------------------------------------------------------------+
```

---

## Inter-Process Communication (IPC)

Components communicate through standard Wayland protocols, D-Bus interfaces, and Linux kernel sysfs nodes:

```text
[ Hardware Function Keys ]
         │
         ▼
[ Hyprland Keybind Dispatcher ]
         │
    ┌────┼───────────────────────────┐
    │    │                           │
    ▼    ▼                           ▼
 wpctl brightnessctl         playerctl (MPRIS)
 (Audio) (Backlight)                 │
    │        │                       ▼
    ▼        ▼                 [ AGS Media Widget ]
 PipeWire /sys/class/backlight
```

### 1. D-Bus & Systemd Session Synchronization
During compositor startup in `hypr/hyprland/startup.lua`, Hyprland synchronizes its Wayland display environment with the user D-Bus and systemd session:
* `dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP`
* `systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_CURRENT_SESSION`

This ensures that desktop portals (e.g. `xdg-desktop-portal-hyprland`), file dialogs, and background user services inherit proper Wayland socket access.

### 2. Compositor IPC (`hyprctl`)
Shell scripts and widget daemons control Hyprland dynamically using the `hyprctl` socket:
* `hyprctl dispatch exit 0` — Session logout triggered by Wlogout.
* `hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'` — Display wake triggered by Hypridle.
* `hyprctl hyprsunset temperature <K>` — Dynamic color warmth adjustments.
* `hyprctl devices` — Caps Lock state queries executed by Hyprlock.

### 3. Layer Shell Architecture
Overlays like SwayNC, AGS, and Wlogout run as Wayland Layer Shell clients (`gtk-layer-shell` / `wlr-layer-shell`). Hyprland controls their stacking, exclusive zones, and visual effects through dedicated layer rules declared in `hypr/hyprland/rules.lua`.

---

## Related Documents

* [Hyprland Lua Architecture](hyprland.md) — Modular compositor design and startup sequence.
* [System Controls](../workflow/system-controls.md) — Detailed kernel and hardware control pipeline.
* [Component Overview](../components/hyprland.md) — Compositor configuration and rules.
