-- Environment variables exported into the session.
--
-- Only variables that are broadly useful under a Wayland/Hyprland session are
-- set here. Hardware-specific workarounds (NVIDIA/AMD/Intel quirks, GBM
-- backend selection, etc.) are intentionally absent and belong in a later,
-- evidence-driven hardware module. Copying large env blocks from old dotfiles
-- tends to cause subtle breakage on modern Hyprland.
--
-- `hl.env` is the Lua-native equivalent of hyprlang's `env = ...` and is the
-- canonical way to set session environment from the Hyprland config.
-- Reference: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Cursor size is shared by XWayland, Qt and most toolkits via the XCURSOR_*
-- variables; Hyprcursor reads HYPRCURSOR_SIZE. 24 is the upstream default.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Hint toolkits to prefer Wayland with safe fallbacks.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Standard XDG desktop session identifiers
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
