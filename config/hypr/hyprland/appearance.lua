-- Window appearance primitives and theming.
--
-- This module defines the visual foundation of your desktop: gaps, borders,
-- window rounding, shadows, and blur effects. It seamlessly integrates the
-- Catppuccin Mocha color palette to produce an elegant multi-color border gradient.
--
-- Reference: https://wiki.hypr.land/Configuring/Basics/Variables/

local colors = require('hyprland.themes.catppuccin-mocha')

hl.config({
    general = {
        -- Modest gaps: tight inner gap for grouped windows, roomier outer gap
        -- against the screen edge. Easy to tune later.
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border = {
                colors = {
                    colors.mauve,
                    colors.lavender,
                    colors.sapphire,
                },
                angle = 45,
            },

            inactive_border = colors.surface0,
        },

        -- Resizing from borders/gaps is convenient but can cause accidental
        -- drags; keep it off by default and enable intentionally per user.
        resize_on_border = false,

        -- Tearing requires understanding the trade-offs; leave off.
        allow_tearing = false,

        -- Dwindle is the least surprising default layout. Master/Scrolling
        -- are configurable later via workspace rules.
        layout = "dwindle",
    },

    decoration = {
        -- Gentle rounding; not so large that it clips small windows.
        rounding       = 8,
        rounding_power = 2,

        -- Keep full opacity by default. Dim/transparency are easy to layer on
        -- later but should not surprise the user out of the box.
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
    },
})

-- Dwindle defaults. `preserve_split` keeps the last user-chosen split
-- direction after focus moves away, which matches most users' intuition
-- about how splits should behave.
hl.config({
    dwindle = {
        preserve_split = true,
    },
})
