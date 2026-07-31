-- Animation curves and leaves.
--
-- Curves are defined first (named, reusable), then animation leaves reference
-- them by name. Values are tuned for responsiveness: durations are short and
-- springs are stiff enough that windows settle quickly rather than bouncing.
-- This intentionally avoids full rice-repository presets; only the leaves
-- that materially affect perceived responsiveness are kept here.
--
-- Reference: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

-- Named curves. `points` are the two bezier control points (P1, P2); P0 = (0,0)
-- and P3 = (1,1) are implied.
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- A single reusable spring. Stiff and well-damped so windows snap into place
-- without overshoot oscillation.
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 170, dampening = 20 })

-- Global enable plus the leaves that matter for everyday window management.
-- Speed values are higher than the upstream defaults so transitions finish
-- quickly; tune down if a softer feel is desired.
hl.config({
    animations = {
        enabled = true,
    },
})

hl.animation({ leaf = "global",     enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "windows",    enabled = true, speed = 5,   spring = "snappy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   spring = "snappy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,   bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,   bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 2,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3,   bezier = "easeOutQuint", style = "fade" })
