# Appearance Customization

Window layout, gaps, border widths, corner rounding, shadows, and compositor blur are defined in `hypr/hyprland/appearance.lua`.

---

## Configuration File

* `hypr/hyprland/appearance.lua`

---

## Gaps & Window Layout

```lua
hl.config({
    general = {
        gaps_in  = 5,     -- Gap between adjacent tiled windows (px)
        gaps_out = 10,    -- Gap between windows and monitor edge (px)
        border_size = 2,  -- Border thickness (px)
        layout = "dwindle",
    },
})
```

* To disable gaps entirely, set `gaps_in = 0` and `gaps_out = 0`.
* To increase screen border margin, increase `gaps_out`.

---

## Active & Inactive Border Colors

Borders are configured using color strings or gradient tables:

```lua
col = {
    active_border = {
        colors = {
            "rgba(cdd6f4ff)",
            "rgba(c7bdd3ff)",
            "rgba(676a80ff)",
        },
        angle = 45,
    },
    inactive_border = "rgb(333333)",
}
```

* `angle`: Controls gradient angle across window perimeters.
* `inactive_border`: Solid color used for unfocused windows.

---

## Rounding, Blur & Shadows

Configured under the `decoration` block:

```lua
decoration = {
    rounding       = 8,   -- Corner radius in pixels
    rounding_power = 2,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    shadow = {
        enabled      = true,
        range        = 6,
        render_power = 3,
        color        = 0xee1a1a1a,
    },

    blur = {
        enabled  = true,
        size     = 3,
        passes   = 3,
        vibrancy = 0.1696,
    },
}
```

* **Corner Radius**: Adjust `rounding` (e.g. `0` for sharp rectangular windows, `12` for softer curves).
* **Blur Passes**: Increase `passes` for smoother, deeper blur (increases GPU utilization). Set `enabled = false` on low-power devices.

After editing, reload with `hyprctl reload`.

---

## Related Documents

* [Theming System](theming.md)
* [Hyprland Component Reference](../components/hyprland.md)
