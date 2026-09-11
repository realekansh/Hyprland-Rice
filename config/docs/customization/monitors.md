# Monitors Customization

Display outputs, resolutions, refresh rates, position offsets, and HiDPI scaling are defined in `hypr/hyprland/monitors.lua`.

---

## Configuration File

* `hypr/hyprland/monitors.lua`

---

## Default Configuration

```lua
hl.monitor({
    output   = "",
    mode     = "1920x1080@60.05600",
    position = "auto",
    scale    = "1.25",
})
```

An empty `output = ""` string instructs Hyprland to apply this rule to any detected display, ensuring safe defaults on laptops without hardcoding vendor connector names.

---

## Customizing for Your Machine

To configure specific displays, query your monitor identifiers using `hyprctl monitors` in a terminal:

```bash
hyprctl monitors
```

### 1. Single Display with Custom Refresh Rate
```lua
hl.monitor({
    output   = "eDP-1",
    mode     = "2560x1440@144",
    position = "0x0",
    scale    = "1.0",
})
```

### 2. Dual Monitor Setup
```lua
-- Laptop built-in display
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = "1.0",
})

-- External monitor positioned to the right
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@144",
    position = "1920x0",
    scale    = "1.0",
})
```

### 3. Automatic Preferred Fallback
If you connect to varying projectors or docks, keep an automatic fallback rule at the bottom:
```lua
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
```

After editing, reload Hyprland with `hyprctl reload`.

---

## Related Documents

* [Hyprland Lua Architecture](../architecture/hyprland.md)
* [Hyprland Component Reference](../components/hyprland.md)
