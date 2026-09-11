-- Window and workspace rules.
--
-- Phase 1 establishes the rule *architecture* rather than accumulating
-- application-specific rules. Only rules with a concrete, general purpose
-- are included. App-specific float/pin/workspace assignments belong in later
-- phases where each rule can be justified by an observed behavior.
--
-- Reference: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--            https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Many apps (browsers in particular) emit bogus maximize requests on startup.
-- Suppressing them prevents Hyprland from blowing tiled windows up to
-- fullscreen unexpectedly. The handle is kept local so individual rules could
-- be toggled later, e.g. `suppressMaximizeRule:set_enabled(false)`.
local suppressMaximizeRule = hl.window_rule({
  name           = "suppress-maximize-events",
  match          = { class = ".*" },
  suppress_event = "maximize",
})

-- XWayland transitions sometimes create a tiny, empty, untracked surface (no
-- class, no title) that should not steal focus. This rule keeps those out of
-- the way without affecting real XWayland windows that report a class/title.
hl.window_rule({
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

-- `suppressMaximizeRule` is created and registered; the local variable is
-- retained intentionally for potential runtime toggling as shown above.
_ = suppressMaximizeRule

-- Force blur and maintain precise Kitty window opacity.
-- The "override" flag stops Hyprland from compounding transparency levels.


hl.layer_rule({
  name         = "waybar-blur",
  match        = { namespace = "waybar" },
  blur         = true,
  ignore_alpha = 0.2,
  xray         = false,
})

hl.window_rule({
  name    = "kitty-blur-and-opacity",
  match   = { class = "^(kitty)$" },
  opacity = "1.0 override 1.0 override",
})

-- SwayNC notification center blur layer rules
hl.layer_rule({
  name         = "swaync-control-center-blur",
  match        = { namespace = "swaync-control-center" },
  blur         = true,
  ignore_alpha = 0.2,
})

hl.layer_rule({
  name         = "swaync-notification-window-blur",
  match        = { namespace = "swaync-notification-window" },
  blur         = true,
  ignore_alpha = 0.2,
})

-- Wlogout blur layer rules
hl.layer_rule({
  name         = "wlogout-blur",
  match        = { namespace = "wlogout" },
  blur         = true,
  ignore_alpha = 0.0,
})

hl.layer_rule({
  name         = "wlogout-gtk-blur",
  match        = { namespace = "gtk-layer-shell" },
  blur         = true,
  ignore_alpha = 0.0,
})

-- Center align window rules for certain applications.
-- This ensures that these windows appear in the center
-- of the screen when they are opened, providing a consistent and user-friendly experience.

hl.window_rule({
  name = "center-pavucontrol",
  match = {
    class = ".*pavu.*",
    -- initial_class = ".*pavu.*",
  },
  float = true,
  center = true,
  size = { 900, 600 },

})

hl.window_rule({
  name   = "center-blueman",
  match  = { class = "blueman-manager" },
  float  = true,
  center = true,
})

hl.window_rule({
  name   = "center-nwg-looks",
  match  = { class = "nwg-look" },
  float  = true,
  center = true,
})

-- Picture-in-Picture windows float and stay pinned across workspaces
hl.window_rule({
  name  = "picture-in-picture",
  match = { title = "^(Picture-in-Picture)$" },
  float = true,
  pin   = true,
})

-- Common file picker dialogs float and center
hl.window_rule({
  name  = "file-picker-dialogs",
  match = { title = "^(Open Files?|Save Files?|Confirm to replace files|Choose Files?|File Upload)$" },
  float = true,
  center = true,
})

-- Polkit authentication agents float and center
hl.window_rule({
  name  = "polkit-agent-dialog",
  match = { class = "^(hyprpolkitagent|org.freedesktop.impl.portal.desktop.kde|polkit-gnome-authentication-agent-1)$" },
  float = true,
  center = true,
})

-- Application launcher (Rofi) blur layer rule
hl.layer_rule({
  name         = "rofi-blur",
  match        = { namespace = "rofi" },
  blur         = true,
  ignore_alpha = 0.2,
})
