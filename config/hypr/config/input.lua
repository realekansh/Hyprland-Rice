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
            tap_to_click          = true,    -- tap-to-click is expected on laptops
            natural_scroll        = true,    -- trackpad "natural" direction is now standard
            disable_while_typing  = true,    -- avoids accidental cursor jumps while typing
            middle_button_emulation = false, -- leave three-finger/middle-click alone
        },
    },
})
