# Alacritty

Alacritty is configured as a secondary terminal emulator, providing an alternative environment with bundled color scheme switching.

---

## Configuration Files

* `alacritty/alacritty.toml` — Primary Alacritty configuration.
* `alacritty/themes/` — Curated collection of over 100 color schemes.

---

## Configuration Settings

* **Font**: `JetBrainsMono Nerd Font Semibold`, size `14.0`.
* **Window Opacity**: `0.7` (70% opacity).
* **Padding**: `15px` horizontal and vertical padding.
* **Clipboard**: `save_to_clipboard = true` (copies highlighted text automatically).

---

## Theme Import System

Alacritty imports external theme files using its `general.import` directive in `alacritty.toml`:

```toml
[general]
import = [
    "~/.config/alacritty/themes/themes/aura.toml"
]
```

To switch themes, replace `aura.toml` with any scheme from `alacritty/themes/themes/` (such as `dracula.toml`, `nord.toml`, `gruvbox_dark.toml`, or `catppuccin_mocha.toml`).

---

## Related Documents

* [Theming System](../customization/theming.md)
* [Typography & Fonts](../customization/fonts.md)
