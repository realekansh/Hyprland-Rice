-- Window and workspace rules.
--
-- Phase 1 establishes the rule *architecture* rather than accumulating
-- application-specific rules. Only rules with a concrete, general purpose
-- are included. App-specific float/pin/workspace assignments belong in later
-- phases where each rule can be justified by an observed behavior.
--
-- Reference: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--            https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Many apps (browsers in particular) emit bogus maximize requests on startup.
-- Suppressing them prevents Hyprland from blowing tiled windows up to
-- fullscreen unexpectedly. The handle is kept local so individual rules could
-- be toggled later, e.g. `suppressMaximizeRule:set_enabled(false)`.
local suppressMaximizeRule = hl.window_rule({
    name          = "suppress-maximize-events",
    match         = { class = ".*" },
    suppress_event = "maximize",
})

-- XWayland transitions sometimes create a tiny, empty, untracked surface (no
-- class, no title) that should not steal focus. This rule keeps those out of
-- the way without affecting real XWayland windows that report a class/title.
hl.window_rule({
    name      = "fix-xwayland-drags",
    match     = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- `suppressMaximizeRule` is created and registered; the local variable is
-- retained intentionally for potential runtime toggling as shown above.
_ = suppressMaximizeRule
