# Default Applications Customization

Default desktop application shortcuts and launch commands are defined in `hypr/hyprland/keybinds.lua`.

---

## Configuration File

* `hypr/hyprland/keybinds.lua`

---

## Where Applications Are Defined

At the top of `hypr/hyprland/keybinds.lua`, application paths are declared using the `executable()` helper:

```lua
local terminal    = executable("/usr/bin/kitty")
local fileManager = executable("/usr/bin/nautilus")
local browser     = executable("/usr/bin/chromium")
local hyprpicker  = executable("/usr/bin/hyprpicker")
local launcher    = "~/.config/rofi/launchers/type-1/launcher.sh"
local hyprshot    = executable("/usr/bin/hyprshot")
```

The `executable()` function checks if the binary exists before registering keybindings, preventing dead shortcuts or log errors if an application is uninstalled.

---

## How to Change Default Applications

### 1. Switching Terminal to Alacritty
Change line 27:
```lua
local terminal = executable("/usr/bin/alacritty")
```

### 2. Switching Web Browser to Firefox
Change line 29:
```lua
local browser = executable("/usr/bin/firefox")
```

### 3. Adding a New Application Shortcut
To add a shortcut for a text editor (e.g. `codium` or `neovim` in terminal):
```lua
local editor = executable("/usr/bin/codium")
if editor then
    hl.bind("SUPER + C", hl.dsp.exec_cmd(editor))
end
```

After modifying `keybinds.lua`, apply changes immediately with `hyprctl reload`.

---

## Related Documents

* [Keybindings Reference](../workflow/keybindings.md)
* [Hyprland Lua Architecture](../architecture/hyprland.md)
