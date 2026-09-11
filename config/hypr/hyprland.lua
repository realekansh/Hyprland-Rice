-- 
--  _   _                  _                 _ 
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|                             
-- 
-- Welcome to Hyprland configuration entry point.
--
-- This file is intentionally small: it only loads the modular configuration
-- under ./config/ in a deliberate order. Each module is responsible for one
-- concern. Editing a single aspect of the setup should only require touching
-- one module.
--
-- Hyprland 0.55+ loads $XDG_CONFIG_HOME/hypr/hyprland.lua (typically
-- ~/.config/hypr/hyprland.lua) and configures `package.path` so that
-- `require("config.<module>")` resolves to ./config/<module>.lua relative to
-- this file.

-- Full documentation https://wiki.hypr.land/getting-started/master-tutorial/#in-hyprland-with-the-default-config

-- Order matters:
--   1. environment  -> exports env vars early so subprocesses inherit them.
--   2. monitors      -> establishes the output surface before anything else.
--   3. appearance    -> visual primitives; referenced by animations implicitly.
--   4. animations    -> curves + animation leaves.
--   5. input         -> device behavior.
--   6. keybinds      -> depends on nothing but `hl`.
--   7. rules         -> window/workspace rules; purely additive.
--   8. startup       -> runs last so the session is fully configured first.

-- Files that are imported for Hyprland
require("hyprland.cursor")
require("hyprland.environment")
require("hyprland.monitors")
require("hyprland.appearance")
require("hyprland.animations")
require("hyprland.input")
require("hyprland.keybinds")
require("hyprland.rules")
require("hyprland.permissions")
require("hyprland.startup")