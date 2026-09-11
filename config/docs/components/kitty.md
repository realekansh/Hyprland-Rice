# Kitty

Kitty is the primary GPU-accelerated terminal emulator configured for daily command-line work.

---

## Configuration File

* `kitty/kitty.conf` — Terminal visual and performance settings.

---

## Visual Settings

* **Font**: `JetBrainsMono Nerd Font`, size `11.5`.
* **Cursor**: Beam shape (`cursor_shape beam`), non-blinking (`cursor_blink_interval 0`).
* **Padding**: `12px` inner window padding.
* **Opacity & Blur**: `background_opacity 0.4`, `background_blur 32`.
* **Color Palette**: Catppuccin Mocha-inspired tones (`background #0e0e12`, `foreground #cdd6f4`, `selection_background #313244`).

---

## Performance Settings

* **Repaint Delay**: `10ms`.
* **Input Delay**: `3ms`.
* **Audio Bell**: Disabled (`enable_audio_bell no`).

---

## Compositor Rule Interaction

To prevent compounded transparency levels when Hyprland applies window opacity, `hypr/hyprland/rules.lua` enforces an override rule specifically for Kitty:

```lua
hl.window_rule({
  name    = "kitty-blur-and-opacity",
  match   = { class = "^(kitty)$" },
  opacity = "1.0 override 1.0 override",
})
```

This guarantees Kitty maintains its exact `0.4` alpha transparency while inheriting 32-pass compositor background blur.

---

## Related Documents

* [Typography & Fonts](../customization/fonts.md)
* [Appearance Customization](../customization/appearance.md)
