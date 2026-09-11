# Theming System

The visual environment is unified around the **Catppuccin Mocha** color palette. This document describes how the theme is distributed across desktop components.

---

## Palette Tokens

| Token | Hex Value | Role across the Desktop |
| :--- | :--- | :--- |
| **Base** | `#1e1e2e` | Primary background for SwayNC, Wlogout, and Yazi |
| **Mantle** | `#181825` | Darker container backgrounds and panels |
| **Crust** | `#11111b` | Deep shadow and boundary framing |
| **Surface0** | `#313244` | Selection highlights, inactive buttons, Kitty selection |
| **Text** | `#cdd6f4` | High-contrast foreground typography |
| **Subtext0** | `#a6adc8` | Secondary labels and timestamp typography |
| **Blue** | `#89b4fa` | Primary accent, active workspace markers, fastfetch labels |
| **Mauve** | `#cba6f7` | Secondary accent, active window border gradient |
| **Red** | `#f38ba8` | Critical notifications, poweroff buttons, delete warnings |

---

## Theme Distribution Across Applications

### 1. Hyprland Borders
Defined in `hypr/hyprland/appearance.lua` using a 45° gradient blending `#cdd6f4` (Text), `#c7bdd3`, and `#676a80` (Overlay). Color variables are structured in `hypr/hyprland/theme/catppuccin-mocha.lua`.

### 2. Kitty Terminal
Configured in `kitty/kitty.conf`:
* Background: `#0e0e12` (deep dark slate).
* Foreground: `#cdd6f4`.
* Selection: `#313244` on `#cdd6f4`.

### 3. SwayNC (Notification Center)
Configured in `swaync/themes/catppuccin-mocha.css` and `swaync/style.css`. Cards use `@noti_bg` and `@noti_border_subtle`, with active elements highlighted in `@accent` (`#89b4fa`).

### 4. Wlogout Session Menu
Configured in `wlogout/style.css`:
* Background overlay: `rgba(30, 30, 46, 0.40)`.
* Buttons: `rgba(49, 50, 68, 0.45)` with borders in `rgba(69, 71, 90, 0.60)`.
* Focused button borders: `#CBA6F7` (Mauve).

### 5. Yazi File Manager
Configured in `yazi/theme.toml`:
* Palette matches Catppuccin Mocha tokens for directory names, executable highlights, Git badges, and cursor selections.

### 6. Btop Resource Monitor
Configured in `btop/btop.conf`:
* `color_theme = "catppuccin-mocha"` with `theme_background = false` for terminal transparency.

---

## Related Documents

* [Appearance Customization](appearance.md)
* [Typography & Fonts](fonts.md)
