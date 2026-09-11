-- Session startup and background services.
--
-- This module centralizes all processes launched on compositor initialization
-- via the `hyprland.start` event.
--
-- Startup Sequence:
--   1. Environment synchronization: updates D-Bus and systemd user environments
--      so portals, screen sharing, and user services inherit WAYLAND_DISPLAY.
--   2. Desktop theme alignment: synchronizes GTK cursor settings with Moga-Black.
--   3. Core daemons: launches status bar (waybar), wallpaper (hyprpaper), idle
--      monitor (hypridle), notification center (swaync), clipboard/runner (vicinae),
--      polkit authentication agent, and terminal emulator (kitty).
--
-- Reference: https://wiki.hypr.land/Configuring/Keywords/#exec-once

hl.on("hyprland.start", function ()
    -- Pull WAYLAND_DISPLAY / XDG_SESSION_TYPE and friends into the user D-Bus and
    -- systemd user session. Order is conventional: D-Bus first, then systemd.
    hl.exec_cmd("command -v dbus-update-activation-environment >/dev/null 2>&1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("command -v systemctl >/dev/null 2>&1 && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")

    -- GTK does not consume XCURSOR_THEME directly. Keep its desktop setting
    -- aligned with the legacy XCursor theme used by Hyprland.
    hl.exec_cmd("command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface cursor-theme 'Moga-Black'")

    -- Start the status bar once Hyprland has exported the Wayland session.
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("kitty")
    hl.exec_cmd("swaync")
    hl.exec_cmd("vicinae server")
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
end)
