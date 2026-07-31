-- Cursor theme configuration.
--
-- Hyprcursor-aware applications use HYPRCURSOR_THEME, while legacy
-- XCursor/XWayland applications use XCURSOR_THEME. Keeping both values in
-- sync ensures the installed Moga-Black theme is used consistently.
--
-- The theme itself is installed separately under ~/.icons/Moga-Black.

hl.env("HYPRCURSOR_THEME", "Moga-Black")
hl.env("XCURSOR_THEME", "Moga-Black")

-- Moga-Black is a legacy XCursor theme; it does not contain a Hyprcursor
-- manifest. Disable Hyprcursor so Hyprland loads the XCursor theme instead of
-- trying to resolve Moga-Black as a Hyprcursor theme.
hl.config({
    cursor = {
        enable_hyprcursor = false,
        sync_gsettings_theme = true,
    },
})
