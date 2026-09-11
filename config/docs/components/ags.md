# AGS (Aylur's GTK Shell)

AGS provides desktop widget overlays built on GTK and TypeScript/JavaScript. In this repository, AGS powers two specific interfaces: a floating media player popup and a system telemetry dashboard.

---

## Configuration Files

* `ags/config.js` — AGS entry point and MPRIS media player widget.
* `ags/style.css` — Primary stylesheet for media player surfaces.
* `ags/system_popup.js` — System telemetry dashboard and tray widgets.
* `ags/system_popup.css` — Telemetry panel stylesheet.

---

## Implemented Widgets

### 1. MPRIS Media Player Popup (`MediaWindow`)
Defined in `ags/config.js`:
* **Service**: Imports the AGS `mpris` service to track active media players (Spotify, Chromium, Firefox, etc.).
* **Controls**: Previous track (`btn-prev`), Play/Pause toggle (`btn-play`), Next track (`btn-next`).
* **Telemetry**: Displays track title, artist name, and album artwork (`player.cover_path`).
* **Seekbar**: Interactive slider with live polling of track position and duration formatted as `MM:SS`.
* **Placement**: Anchored to top-left near the status bar. Automatically dismisses when pressing `Escape`.

### 2. System Telemetry Popup (`SystemPopupWindow`)
Defined in `ags/system_popup.js`:
An on-demand hardware status panel showing polled system metrics:
* **CPU Usage**: Polled from `/proc/stat` every 2000ms.
* **RAM Usage**: Polled from `/proc/meminfo` every 2000ms, reporting used and total memory in GB.
* **GPU Utilization**: Polled from `/sys/class/drm/card0/device/gpu_busy_percent` every 2000ms.
* **Root Disk Usage**: Polled from `df -h /` every 10000ms.
* **CPU Temperature**: Polled from `/sys/class/thermal/thermal_zone0/temp` every 2000ms.
* **Network Status**: Bound to `Network.wifi.internet` to report online/offline state.
* **System Updates**: Counts pending Arch updates via `waybar/scripts/getupdates.sh`; clicking triggers `installupdates.sh`.
* **System Tray (`SysTray`)**: Renders active application tray icons with click activation and menu support.

---

## Integration & State Tracking

When `system_popup` is toggled:
1. An event hook writes the visible state (`1` or `0`) to `/tmp/popup_state`.
2. Sends a real-time signal (`pkill -RTMIN+10 -x waybar`) to notify Waybar of the panel state.
3. Clicking anywhere outside the panel or pressing `Escape` closes the window cleanly.

---

## Related Documents

* [System Controls](../workflow/system-controls.md)
* [Hyprland Keybindings](../workflow/keybindings.md)
