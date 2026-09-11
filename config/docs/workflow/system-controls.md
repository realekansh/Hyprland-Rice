# System Controls

This document details how hardware keys, applets, and system interfaces interact to control audio, display brightness, battery profiles, and networking.

---

## Audio & Volume Controls

Audio is managed directly via PipeWire's `wpctl` utility, bypassing the need for an active status bar:

```text
[ Volume Up Key ] ──> wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
[ Volume Down Key ] ──> wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
[ Audio Mute Key ]  ──> wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
[ Mic Mute Key ]    ──> wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
```

* **Clamping**: Volume increases use `-l 1` to clamp output to 100%, preventing software audio clipping.
* **Tracking**: The `@DEFAULT_AUDIO_SINK@` and `@DEFAULT_AUDIO_SOURCE@` aliases automatically track whichever audio device is active (e.g. switching between internal speakers and Bluetooth headphones).

---

## Backlight & Brightness Controls

Display brightness is managed using `brightnessctl`:

```text
[ Brightness Up Key ]   ──> brightnessctl set 5%+
[ Brightness Down Key ] ──> brightnessctl set 5%-
```

* Steps are fixed at 5% to keep adjustments smooth and predictable.
* During idle states, `hypridle` saves and dims brightness to `50` via `brightnessctl -s set 50`, restoring it on activity with `brightnessctl -r`.

---

## CPU Power Profiles

Configured via the custom Rofi applet `rofi/battery/battery.sh`:

```text
[ Rofi Battery Applet ]
           │
     Select Mode
           │
 ┌─────────┼─────────────────────────┐
 ▼         ▼                         ▼
Performance Balanced             Power Saver / Ultra Eco
(performance) (balance_performance)  (balance_power / power)
```

The script writes directly to kernel sysfs nodes:
* **Energy Performance Preference**: `/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference`
* **Scaling Governor**: `/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`
* **Persistence**: Writes selected profile to `rofi/battery/current_profile`.

---

## Network & Connectivity

* **Wi-Fi**: Managed via `rofi/wifi/wifi.sh` using `nmcli device wifi`. Supports scanning, signal strength bars, and password entry.
* **Bluetooth**: Managed via `rofi/bluetooth/bluetooth.sh` using `bluetoothctl`. Supports pairing, connecting, trusting, and power toggles.
* **Ethernet**: Status monitored via `rofi/ethernet/ethernet.sh`.
* **VPN**: Managed via `rofi/vpn/vpn.sh` using `nmcli connection up/down`.

---

## Media Playback

Media keys are bound to `playerctl` in `hypr/hyprland/keybinds.lua`:
* `XF86AudioPlay` / `Pause` — `playerctl play-pause`
* `XF86AudioNext` — `playerctl next`
* `XF86AudioPrev` — `playerctl previous`
* `XF86AudioStop` — `playerctl stop`

These communicate over the standard MPRIS D-Bus interface with Spotify, Chromium, Firefox, and VLC.

---

## Related Documents

* [Keybindings Reference](keybindings.md)
* [Rofi Component Reference](../components/rofi.md)
* [AGS Component Reference](../components/ags.md)
