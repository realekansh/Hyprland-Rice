# Keybindings Reference

This document provides the complete reference for all keyboard and mouse shortcuts declared in `hypr/hyprland/keybinds.lua`.

`SUPER` (Windows key) is the primary modifier for all desktop actions.

---

## Window Management

| Keybinding | Action | Dispatcher |
| :--- | :--- | :--- |
| `Super + Return` | Launch terminal | `exec /usr/bin/kitty` |
| `Super + W` | Close focused window | `close()` |
| `Super + F` | Toggle floating state | `window.float({ action = "toggle" })` |
| `Super + M` | Toggle fullscreen | `window.fullscreen({ action = "toggle" })` |
| `Super + Shift + Q` | Exit Hyprland session | `exit()` |
| `Super + H` | Move focus left | `focus({ direction = "left" })` |
| `Super + J` | Move focus down | `focus({ direction = "down" })` |
| `Super + K` | Move focus up | `focus({ direction = "up" })` |
| `Super + L` | Lock screen | `exec hyprlock` |
| `Super + Left` | Move focus left | `focus({ direction = "left" })` |
| `Super + Down` | Move focus down | `focus({ direction = "down" })` |
| `Super + Up` | Move focus up | `focus({ direction = "up" })` |
| `Super + Right` | Move focus right | `focus({ direction = "right" })` |

---

## Workspaces (1–10)

| Keybinding | Action |
| :--- | :--- |
| `Super + 1` .. `9` | Switch to workspace 1–9 |
| `Super + 0` | Switch to workspace 10 |
| `Super + Shift + 1` .. `9` | Move focused window to workspace 1–9 |
| `Super + Shift + 0` | Move focused window to workspace 10 |
| `Super + Mouse Scroll Up` | Switch to previous workspace (`e-1`) |
| `Super + Mouse Scroll Down` | Switch to next workspace (`e+1`) |
| `3-Finger Swipe Left / Right` | 1:1 gesture workspace switch |

---

## Applications & Launchers

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| `Super + Space` | Open Rofi launcher | `~/.config/rofi/launchers/type-1/launcher.sh` |
| `Alt + Space` | Toggle Vicinae launcher | `vicinae toggle` |
| `Super + V` | Open clipboard history | `vicinae vicinae://launch/clipboard/history` |
| `Super + E` | Open file manager | `/usr/bin/nautilus` |
| `Super + B` | Open web browser | `/usr/bin/chromium` |
| `Super + Shift + S` | Region screenshot to clipboard | `/usr/bin/hyprshot -m region --clipboard-only` |
| `Super + Shift + C` | Pick screen color to clipboard | `/usr/bin/hyprpicker -a` |

---

## Session & Environment Controls

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| `Super + Shift + W` | Shuffle wallpaper | `bash ~/.config/hypr/scripts/wallpaper.sh` |
| `Super + Shift + R` | Reload Waybar | `bash ~/.config/hypr/scripts/waybar-reload.sh` |
| `Super + Ctrl + I` | Toggle HyprCaffeine | `/usr/bin/hyprcaffeine toggle` |
| `Super + Ctrl + Shift + I` | Open HyprCaffeine menu | `/usr/bin/hyprcaffeine menu` |
| `Super + Ctrl + Shift + D` | Toggle HyprCaffeine lid mode | `/usr/bin/hyprcaffeine lid toggle` |
| `Super + Ctrl + D` | Toggle HyprCaffeine monitor mode | `/usr/bin/hyprcaffeine monitor toggle` |

---

## Hardware Keys (Active Even Under Screen Lock)

These bindings are registered with `locked = true` and `repeating = true` so holding them ramps values continuously:

| Key | Action | Command |
| :--- | :--- | :--- |
| `XF86AudioRaiseVolume` | Volume +5% (max 100%) | `wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+` |
| `XF86AudioLowerVolume` | Volume -5% | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-` |
| `XF86AudioMute` | Toggle audio mute | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` |
| `XF86AudioMicMute` | Toggle microphone mute | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` |
| `XF86MonBrightnessUp` | Screen brightness +5% | `brightnessctl set 5%+` |
| `XF86MonBrightnessDown` | Screen brightness -5% | `brightnessctl set 5%-` |
| `XF86AudioPlay` | Play/pause media | `playerctl play-pause` |
| `XF86AudioPause` | Pause media | `playerctl play-pause` |
| `XF86AudioNext` | Next media track | `playerctl next` |
| `XF86AudioPrev` | Previous media track | `playerctl previous` |
| `XF86AudioStop` | Stop media playback | `playerctl stop` |

---

## Mouse Window Actions

| Binding | Action |
| :--- | :--- |
| `Super + Left Mouse Button` | Drag window to move |
| `Super + Right Mouse Button` | Drag window to resize |

---

## Related Documents

* [Hyprland Lua Architecture](../architecture/hyprland.md)
* [System Controls](system-controls.md)
* [Scripts & Automation](scripts.md)
