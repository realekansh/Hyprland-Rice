-- Window appearance primitives owned by Hyprland.
--
-- This module sets only structural/visual primitives that Hyprland controls
-- directly: gaps, borders, rounding, opacity, blur and shadows. The actual
-- color palette and design system are intentionally NOT defined here; they
-- belong to a later theming phase. Border/active colors below are neutral
-- grays so the setup is presentable without committing to a theme.
--
-- Reference: https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        -- Modest gaps: tight inner gap for grouped windows, roomier outer gap
        -- against the screen edge. Easy to tune later.
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        -- Neutral placeholders. Replace with the real palette in the theming
        -- phase. `col.active_border` accepts a gradient table; a single-color
        -- string is also valid.
        col = {
            active_border   = "rgba(888888ff)",
            inactive_border = "rgba(333333ff)",
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
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
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
