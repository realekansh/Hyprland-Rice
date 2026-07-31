-- Keyboard and mouse bindings.
--
-- SUPER is the primary (and only) modifier for application launches and window
-- actions. Keeping a single modifier avoids collisions with app-internal
-- shortcuts (Ctrl/Alt) and leaves SUPER+SHIFT and SUPER+CTRL as room to grow.
--
-- Hardware function keys (volume, brightness, media) are bound *without* a
-- modifier and with `locked = true` so they keep working under a screen-lock
-- surface. They are repeated (`repeating = true`) so holding a key sweeps the
-- value rather than firing once per physical press.
--
-- Reference: https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"

-- Applications launched directly, no shell wrapper. Each is gated on the
-- executable existing so the config still loads cleanly when an app is absent
-- and the absence is discoverable from the Hyprland log instead of a silent
-- dead key.
local function executable(path)
    local f = io.open(path, "r")
    if not f then return nil end
    f:close()
    return path
end

local terminal    = executable("/usr/bin/kitty")
local fileManager = executable("/usr/bin/nautilus")
local browser     = executable("/usr/bin/firefox")
local hyprpicker = executable("/usr/bin/hyprpicker")
local launcher    = "rofi -show drun"

-- Window lifecycle ----------------------------------------------------------

-- Launch a terminal.
if terminal then
    hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
end

-- Close the focused window.
hl.bind(mainMod .. " + W", hl.dsp.window.close())

-- Lock Hyprland 
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Exit Hyprland.
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- Toggle floating on the focused window. (Avoids SUPER+V, which clashes with
-- "paste" muscle memory; "F" reads as "float" anyway.)
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

-- Fullscreen the focused window. SUPER+Space was previously fullscreen but is
-- now the launcher; fullscreen moves to a single dedicated "Print Screen"-free
-- key that does not clash with the Phase 1.1 application set.
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Applications ---------------------------------------------------------------

-- File manager.
if fileManager then
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
end

-- Application launcher.
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(launcher))

-- Launch the browser.
if browser then
    hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
end

-- Screenshots ---------------------------------------------------------------
--
-- SUPER + SHIFT + S enters region selection mode. The selected area is copied
-- directly to the Wayland clipboard without creating a screenshot file.

local hyprshot = executable("/usr/bin/hyprshot")

if hyprshot then
    hl.bind(
        mainMod .. " + SHIFT + S",
        hl.dsp.exec_cmd(hyprshot .. " -m region --clipboard-only")
    )
end

-- Clipboard -----------------------------------------------------------------

hl.bind(
    mainMod .. " + V",
    hl.dsp.exec_cmd("vicinae vicinae://launch/clipboard/history")
)

-- Color picker --------------------------------------------------------------
--
-- Pick a color from the screen and copy its HEX value directly to the
-- Wayland clipboard.

if hyprpicker then
    hl.bind(
        mainMod .. " + SHIFT + C",
        hl.dsp.exec_cmd(hyprpicker .. " -a")
    )
end

-- Wallpaper Shuffle ---------------------------------------------------------
--
-- Use this command to reload and apply new wallpaper from ~/Pictures/wallpapers/
-- directory to apply a random wallpaper

hl.bind(
    mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/wallpaper.sh"),
    { desc = "Shuffle wallpaper" }
)

-- Waybar Reload---------------------------------------------------------
--
-- Use this command to reload waybar and apply new configuration 

hl.bind(
    mainMod .. " + SHIFT + R",
    hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/waybar-reload.sh"),
    { desc = "Reload Waybar" }
)

-- Add more application bindings by defining an executable above and binding
-- it in this section, for example:
-- local editor = executable("/usr/bin/codium")
-- if editor then hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(editor)) end

-- Directional focus movement. Arrow keys are paired with Vim-style hjkl so the
-- scheme is usable on laptops without dedicated arrows and friendly to keyboard
-- users. Define the two sets once.
local focus_dirs = {
    { "left",  "left"  },
    { "right", "right" },
    { "up",    "up"    },
    { "down",  "down"  },
    { "left",  "h"     },
    { "right", "l"     },
    { "up",    "k"     },
    { "down",  "j"     },
}
for _, d in ipairs(focus_dirs) do
    hl.bind(mainMod .. " + " .. d[2], hl.dsp.focus({ direction = d[1] }))
end

-- Workspaces 1-10 -----------------------------------------------------------
--
-- Hyprland uses 1..10 as workspace IDs but maps workspace 10 onto the "0" key
-- on the keyboard, so the key index is `i % 10`.
for i = 1, 10 do
    local key = i % 10
    -- Switch to workspace.
    hl.bind(mainMod .. " + " .. key,                 hl.dsp.focus({ workspace = i }))
    -- Move the focused window to that workspace.
    hl.bind(mainMod .. " + SHIFT + " .. key,         hl.dsp.window.move({ workspace = i }))
end

-- Mouse ---------------------------------------------------------------------

-- Move a window by dragging with SUPER + left mouse button.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })

-- Resize a window by dragging with SUPER + right mouse button.
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Cycle workspaces with the scroll wheel while holding SUPER.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Hardware keys -------------------------------------------------------------
--
-- `locked = true` makes a binding fire even while a session lock surface is up,
-- which is the expected behavior for volume/brightness/media keys. `repeating
-- = true` lets the dispatcher fire on each key repeat so holding the key ramps
-- the value in the configured step instead of stepping once.
--
-- PipeWire's `wpctl` is talked to directly so the controls are independent of
-- any bar/OSD. `-l 1` clamps output volume to 100% so a held key cannot drive
-- the sink into software amplification (clipping). The mic binding has no cap:
-- boosting a source above unity is rarely desirable and there is no clean
-- convention, so we leave it. PipeWire's `@DEFAULT_AUDIO_SINK@` /
-- `@DEFAULT_AUDIO_SOURCE@` selectors track the user's configured default
-- device, so these bindings follow the active output/input automatically.
local hw_opts = { locked = true, repeating = true }
local hw_opts_no_repeat = { locked = true }

-- wpctl/brightnessctl/playerctl are used by the bindings below. Hyprland does
-- not gate executables on `command -v`, so a missing binary would just log a
-- spawn error on key press; all three were verified present on this system
-- during Phase 1.1 inspection.

-- Volume, output mute, mic mute ---------------------------------------------

-- Function keys produce the XF86Audio* symbols.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), hw_opts)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),     hw_opts)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   hw_opts_no_repeat)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), hw_opts_no_repeat)

-- Brightness ---------------------------------------------------------------
--
-- `brightnessctl` reads from the `/sys/class/backlight` default device and
-- does not require root on systems where the udev `backlight` rule grants the
-- logged-in user write access (the conventional Arch setup). 5% steps match
-- the volume controls to keep the behavior predictable.

-- Function keys produce the XF86MonBrightness* symbols.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), hw_opts)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), hw_opts)

-- Media playback ---------------------------------------------------------
--
-- `playerctl` talks MPRIS, so the same keys drive whichever player exposes an
-- MPRIS2 interface (firefox, spotify, mpv, …) without per-app wiring.
-- `play-pause` toggles; the dedicated XF86AudioPlay and XF86AudioPause symbols
-- are the same MPRIS call on most keyboards but both are bound so a keyboard
-- that emits either one works. `XF86AudioStop` is distinct on real keyboards
-- and does a hard stop; it is bound unconditionally but is a no-op when no
-- player implements Stop.

-- Function keys produce the XF86Audio* symbols.
hl.bind("XF86AudioPlay",   hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",   hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",   hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioStop",   hl.dsp.exec_cmd("playerctl stop"),       { locked = true })
