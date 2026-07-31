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

-- Hint to Qt applications to prefer the Wayland platform instead of falling
-- back to X11/XWayland. Harmless when no Qt app is running.
hl.env("QT_QPA_PLATFORM", "wayland")
