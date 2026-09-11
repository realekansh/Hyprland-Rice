# Hyprland Lua Architecture

Hyprland version 0.55+ supports native Lua configuration. This setup replaces traditional monolithic configuration files with an isolated, modular Lua architecture.

---

## Modular File Layout

The Hyprland configuration directory is arranged so that every functional area is managed in a single, dedicated file:

```text
hypr/
├── hyprland.lua            # Entry point: loads all submodules
└── hyprland/
    ├── cursor.lua          # Cursor theme and XCursor synchronization
    ├── environment.lua     # Session environment variables
    ├── monitors.lua        # Display outputs, resolutions, and scaling
    ├── appearance.lua      # Layout, gaps, borders, shadows, and blur
    ├── animations.lua      # Custom bezier curves and spring physics
    ├── input.lua           # Touchpad gestures, repeat rates, and focus
    ├── keybinds.lua        # Keyboard and mouse dispatchers
    ├── rules.lua           # Window rules and layer shell blur rules
    └── startup.lua         # D-Bus session export and autostarted daemons
```

---

## Loading Order & Dependencies

The main entry point `hypr/hyprland.lua` requires modules in a deliberate sequence:

```lua
require("hyprland.cursor")
require("hyprland.environment")
require("hyprland.monitors")
require("hyprland.appearance")
require("hyprland.animations")
require("hyprland.input")
require("hyprland.keybinds")
require("hyprland.rules")
require("hyprland.startup")
```

### Why Order Matters
1. **`cursor` & `environment`**: Export environment variables (`XCURSOR_SIZE`, `HYPRCURSOR_THEME`, `QT_QPA_PLATFORM`) early so child processes inherit them cleanly.
2. **`monitors`**: Establishes display geometry and HiDPI scaling before any window or surface is rendered.
3. **`appearance` & `animations`**: Defines layout primitives, window rounding, blur passes, and bezier physics models.
4. **`input` & `keybinds`**: Configures keyboard autorepeat, natural touchpad scrolling, and hotkey dispatchers.
5. **`rules`**: Registers window behavior overrides, center rules, and layer shell blur.
6. **`startup`**: Runs last, once the compositor runtime is fully configured, to spawn background daemons.

---

## Lua API Patterns Used

Hyprland exposes the `hl` global table to Lua configuration files:

### 1. Declarative Configuration (`hl.config`)
Used for table-based settings like input, layout, and decoration:
```lua
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        layout   = "dwindle",
    },
})
```

### 2. Keybinding Dispatchers (`hl.bind`)
Binds hotkeys to compositor dispatchers or external commands:
```lua
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + Return", hl.dsp.exec_cmd("/usr/bin/kitty"))
```

### 3. Window & Layer Rules (`hl.window_rule`, `hl.layer_rule`)
Target window classes or layer shell namespaces:
```lua
hl.layer_rule({
    name         = "waybar-blur",
    match        = { namespace = "waybar" },
    blur         = true,
    ignore_alpha = 0.2,
})
```

### 4. Conditional Binary Detection
In `hypr/hyprland/keybinds.lua`, application shortcuts are guarded by an executable existence helper:
```lua
local function executable(path)
    local f = io.open(path, "r")
    if not f then return nil end
    f:close()
    return path
end
```
If an application (such as `/usr/bin/chromium`) is not installed, the binding is silently omitted rather than registering a dead shortcut or throwing runtime errors.

---

## Related Documents

* [Hyprland Component Reference](../components/hyprland.md) — Window rules, gaps, and blur settings.
* [Keybindings Reference](../workflow/keybindings.md) — Complete list of all configured shortcuts.
* [Monitors Customization](../customization/monitors.md) — Configuring display outputs.
