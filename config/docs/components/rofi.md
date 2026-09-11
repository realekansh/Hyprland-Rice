# Rofi

Rofi serves as both the desktop application launcher and the engine behind an interactive suite of system applets.

---

## Configuration Files

* `rofi/config.rasi` — Global Rofi configuration.
* `rofi/launchers/type-1/` — Primary application launcher (10 selectable styles).
* `rofi/launchers/type-2/` — Alternative application launcher with banner graphics.
* `rofi/battery/battery.sh` — Battery diagnostics and CPU power profile manager.
* `rofi/bluetooth/bluetooth.sh` — Bluetooth device management applet.
* `rofi/wifi/wifi.sh` — Wireless network scanner and connection applet.
* `rofi/ethernet/ethernet.sh` — Wired network interface status.
* `rofi/network/network.sh` — Unified network hub.
* `rofi/vpn/vpn.sh` — VPN connection manager.
* `rofi/powermenu/powermenu.sh` — System power menu.

---

## Global Settings (`rofi/config.rasi`)

* **Modes**: `drun,run,filebrowser,window`.
* **Font**: `Mono 12`.
* **Icon Theme**: `Papirus`.
* **Matching**: Normal tokenized matching, case-insensitive.
* **History**: Enabled, retaining up to 25 entries.

---

## Application Launchers

* **Type-1 Launcher** (`rofi/launchers/type-1/launcher.sh`): Triggered by `Super + Space`. Renders application icons and names in a clean grid.
* **Type-2 Launcher** (`rofi/launchers/type-2/launcher.sh`): Features sidebar image cards backed by graphics in `rofi/images/`.

Each launcher includes styles `style-1.rasi` through `style-10.rasi`.

---

## Custom Applet Suite

### 1. Battery & Power Profiles (`rofi/battery/battery.sh`)
An interactive power manager:
* **Power Modes**:
  * `Performance` — Sets CPU energy-performance preference (EPP) to `performance` and governor to `performance`.
  * `Balanced` — Sets EPP to `balance_performance` and governor to `powersave`.
  * `Power Saver` — Sets EPP to `balance_power` and governor to `powersave`.
  * `Ultra Eco` — Sets EPP to `power` and governor to `powersave`.
* **Telemetry Info Card**: Displays real-time battery percentage, charging state, health, power draw (in Watts), voltage, and estimated time remaining.
* **Diagnostics Submenu**: Parses raw `upower -i` output into an interactive menu.
* **Hardware Specs Submenu**: Parses `/sys/class/power_supply/BAT*/uevent` attributes.

### 2. Bluetooth Applet (`rofi/bluetooth/bluetooth.sh`)
Manages Bluetooth devices via `bluetoothctl`:
* Toggles Bluetooth controller power.
* Scans for nearby discoverable devices.
* Connects, disconnects, pairs, trusts, and removes devices.

### 3. Wi-Fi Applet (`rofi/wifi/wifi.sh`)
Manages wireless connections via `nmcli`:
* Scans available SSIDs and displays signal strength indicators.
* Prompts for passwords securely via Rofi dmenu.
* Connects to saved networks and toggles Wi-Fi radio on/off.

### 4. Power Menu (`rofi/powermenu/powermenu.sh`)
Provides quick session controls: Lock (`hyprlock`), Suspend, Logout, Reboot, and Shutdown.

---

## Related Documents

* [System Controls](../workflow/system-controls.md)
* [Keybindings Reference](../workflow/keybindings.md)
