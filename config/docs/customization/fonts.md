# Typography & Fonts

Typography is configured across the desktop using consistent font families and weights.

---

## Font Roles & Families

| Role | Font Family | Usage |
| :--- | :--- | :--- |
| **Monospace / Code** | `JetBrainsMono Nerd Font` | Terminals (Kitty, Alacritty), Yazi, SwayNC, Wlogout, Fastfetch |
| **Clock Typography** | `SF Pro Display Bold` | Hyprlock time display (`128pt`) |
| **Date Typography** | `SF Pro Display Regular` | Hyprlock date display (`20pt`) |
| **Applet Font** | `Mono 12` | Rofi launchers and applets |

---

## Where Fonts Are Configured

### 1. Kitty Terminal (`kitty/kitty.conf`)
```text
font_family JetBrainsMono Nerd Font
font_size 11.5
```

### 2. Alacritty Terminal (`alacritty/alacritty.toml`)
```toml
[font]
size = 14.0

[font.normal]
family = "JetBrainsMono  Nerd Font Semibold"
style = "Regular"
```

### 3. Rofi Launcher (`rofi/config.rasi`)
```rasi
font: "Mono 12";
```

### 4. SwayNC (`swaync/style.css`)
```css
* {
  font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font Mono", sans-serif;
  font-size: 13px;
  font-weight: bold;
}
```

### 5. Wlogout (`wlogout/style.css`)
```css
button {
  font-family: "JetBrains Mono Nerd Font", monospace;
  font-size: 13px;
}
```

### 6. Hyprlock (`hypr/hyprlock.conf`)
* Sourced font definitions in `hypr/hyprlock/fonts/SF Pro Display/` and `JetBrains/`.
* Clock: `font_family = $font_family_clock`, `font_size = 128`.

---

## Related Documents

* [Theming System](theming.md)
* [Appearance Customization](appearance.md)
