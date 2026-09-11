-- Monitor configuration.
--
-- Dedicated configuration for the internal panel, plus a safe preferred-mode
-- fallback for hotplugged external displays.
--
-- Reference: https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Internal laptop display
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60.05600",
    position = "auto",
    scale    = "1.25",
})

-- Fallback rule for any connected external monitor
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Prevent blurry XWayland applications under fractional scaling (1.25x)
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
