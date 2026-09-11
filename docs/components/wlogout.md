# Wlogout

Wlogout provides a full-screen, keyboard-navigable session termination menu.

---

## Configuration Files

* `wlogout/layout` — Button definitions, keyboard shortcuts, and action dispatchers.
* `wlogout/style.css` — Overlay stylesheet, button sizing, and hover animations.
* `wlogout/icons/` — Local session icons (lock, suspend, hibernate, shutdown, reboot, logout).

---

## Actions & Keybindings

| Button | Key | Action Command |
| :--- | :--- | :--- |
| **Lock** | `l` | `hyprlock` |
| **Hibernate** | `h` | `systemctl hibernate` |
| **Logout** | `e` | `hyprctl dispatch exit 0` |
| **Shutdown** | `s` | `systemctl poweroff` |
| **Suspend** | `u` | `hyprlock & sleep 0.5 && systemctl suspend` |
| **Reboot** | `r` | `systemctl reboot` |

---

## Styling & Visual Behavior

* **Backdrop**: Translucent Catppuccin Mocha background (`rgba(30, 30, 46, 0.40)`).
* **Hover Animation**: Buttons expand smoothly on hover (`background-size` scales from 22% to 28% using a bezier curve) and corners round from 0 to `16px`.
* **Compositor Blur**: Hyprland applies layer blur rules (`wlogout-blur` and `wlogout-gtk-blur`) to ensure the desktop behind Wlogout is blurred.

---

## Related Documents

* [Hyprland Window Rules](../components/hyprland.md)
* [Keybindings Reference](../workflow/keybindings.md)
