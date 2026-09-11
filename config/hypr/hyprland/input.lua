-- Input device defaults.
--
-- These values deliberately avoid opinionated profiles (no custom accel
-- curves, no exotic scroll methods) and aim for a comfortable laptop
-- baseline. Per-device overrides belong in a future module via `hl.device`.
--
-- Reference: https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        -- Keyboard: bare US layout, no variant. Change kb_layout per locale.
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        -- 1 = follow mouse focus (the conventional default). 0/2/3 exist but
        -- are more opinionated; keep the neutral choice.
        follow_mouse = 1,

        -- 0 = no sensitivity modification. Range is -1.0..1.0.
        sensitivity = 0,

        -- Reasonable autorepeat; tuned to feel responsive without key bounce.
        repeat_rate  = 50,
        repeat_delay = 300,

        touchpad = {
            tap_to_click            = true,    -- tap-to-click is expected on laptops
            tap_and_drag            = true,    -- drag with a tap followed by movement
            drag_lock               = 1,       -- keep a drag briefly active after lifting
            natural_scroll          = true,    -- trackpad "natural" direction is now standard
            disable_while_typing    = true,    -- avoids accidental cursor jumps while typing
            clickfinger_behavior    = true,    -- two-finger tap/click acts as right click
            middle_button_emulation = false,   -- keep two-button middle-click emulation off
            scroll_factor           = 1.0,     -- normal two-finger scroll speed
        },
    },

    gestures = {
        -- Make slow swipes easier to complete without removing the native
        -- 1:1 finger-following interaction.
        workspace_swipe_distance = 180,
        workspace_swipe_cancel_ratio = 0.35,
        workspace_swipe_min_speed_to_force = 0,
        workspace_swipe_direction_lock = true,
        workspace_swipe_forever = true,
        workspace_swipe_create_new = false,
    },
})

-- Mouse ---------------------------------------------------------------------

-- Scroll through open workspaces only, wrapping at either end.
hl.config({
    binds = {
        allow_workspace_cycles = true,
    },
})

-- Keep the native 1:1 gesture so the workspace follows the fingers.
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
