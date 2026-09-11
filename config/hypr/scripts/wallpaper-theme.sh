#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Wallpaper & Waybar Theme Shuffle Script
#
# Simultaneously randomizes the desktop wallpaper from ~/.config/hypr/hyprpaper/
# and the Waybar color palette from ~/.config/waybar/themes/.
#
# Features:
#   - Syncs ~/.config/hypr/hyprpaper.conf and ~/.config/hypr/hyprlock.conf
#     for persistent desktop and lock screen backgrounds across reboots.
#   - Updates ~/.config/waybar/style.css to import the newly selected theme.
#   - Smoothly refreshes the running hyprpaper daemon via Wayland IPC.
#   - Signals Waybar (SIGUSR2) for an instant, flicker-free CSS stylesheet reload.
#   - Accepts optional arguments: $1 for wallpaper path, $2 for theme name/path.
#   - Sends a desktop notification showing the new wallpaper thumbnail and theme name.
#
# Triggered via: SUPER + SHIFT + W
# -----------------------------------------------------------------------------

set -euo pipefail

WALLPAPER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper"
THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/themes"
WAYBAR_STYLE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/style.css"
HYPRPAPER_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf"
HYPRLOCK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"

# 1. Determine target wallpaper
if [[ -n "${1:-}" && -f "$1" ]]; then
    WALLPAPER="$(realpath "$1")"
else
    CURRENT_WALLPAPER=""
    if [[ -f "$HYPRPAPER_CONF" ]]; then
        CURRENT_WALLPAPER="$(grep -E '^[[:space:]]*path[[:space:]]*=' "$HYPRPAPER_CONF" | head -n1 | sed -E 's/.*=[[:space:]]*//')"
    fi

    mapfile -t ALL_WALLPAPERS < <(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
    )

    if [[ ${#ALL_WALLPAPERS[@]} -eq 0 ]]; then
        notify-send -u critical -a "Wallpaper" "Wallpaper Error" "No valid image files found in $WALLPAPER_DIR"
        echo "Error: No wallpapers found in $WALLPAPER_DIR" >&2
        exit 1
    fi

    if [[ ${#ALL_WALLPAPERS[@]} -gt 1 && -n "$CURRENT_WALLPAPER" ]]; then
        ELIGIBLE=()
        for wp in "${ALL_WALLPAPERS[@]}"; do
            [[ "$wp" != "$CURRENT_WALLPAPER" ]] && ELIGIBLE+=("$wp")
        done
        WALLPAPER="${ELIGIBLE[RANDOM % ${#ELIGIBLE[@]}]}"
    else
        WALLPAPER="${ALL_WALLPAPERS[RANDOM % ${#ALL_WALLPAPERS[@]}]}"
    fi
fi

WALLPAPER_NAME="$(basename "$WALLPAPER")"

# 2. Determine target Waybar theme
if [[ -n "${2:-}" ]]; then
    if [[ -f "$2" ]]; then
        THEME_BASENAME="$(basename "$2")"
    elif [[ -f "$THEME_DIR/$2" ]]; then
        THEME_BASENAME="$2"
    elif [[ -f "$THEME_DIR/$2.css" ]]; then
        THEME_BASENAME="$2.css"
    else
        echo "Warning: Specified theme '$2' not found, selecting randomly." >&2
        THEME_BASENAME=""
    fi
else
    THEME_BASENAME=""
fi

if [[ -z "$THEME_BASENAME" ]]; then
    CURRENT_THEME=""
    if [[ -f "$WAYBAR_STYLE" ]]; then
        CURRENT_THEME="$(grep -E '@import url\("themes/' "$WAYBAR_STYLE" | head -n1 | sed -E 's/.*themes\/([^"]+)\.css.*/\1.css/')"
    fi

    mapfile -t ALL_THEMES < <(
        find "$THEME_DIR" -maxdepth 1 -type f -name '*.css'
    )

    if [[ ${#ALL_THEMES[@]} -eq 0 ]]; then
        notify-send -u critical -a "Waybar" "Theme Error" "No theme files found in $THEME_DIR"
        echo "Error: No themes found in $THEME_DIR" >&2
        exit 1
    fi

    if [[ ${#ALL_THEMES[@]} -gt 1 && -n "$CURRENT_THEME" ]]; then
        ELIGIBLE_THEMES=()
        for th in "${ALL_THEMES[@]}"; do
            [[ "$(basename "$th")" != "$CURRENT_THEME" ]] && ELIGIBLE_THEMES+=("$th")
        done
        CHOSEN_THEME="${ELIGIBLE_THEMES[RANDOM % ${#ELIGIBLE_THEMES[@]}]}"
    else
        CHOSEN_THEME="${ALL_THEMES[RANDOM % ${#ALL_THEMES[@]}]}"
    fi
    THEME_BASENAME="$(basename "$CHOSEN_THEME")"
fi

# Format human-friendly theme title
THEME_TITLE="${THEME_BASENAME%.css}"
THEME_TITLE="${THEME_TITLE//-/ }"
THEME_TITLE="$(echo "$THEME_TITLE" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')"

echo "Applying wallpaper:   $WALLPAPER_NAME"
echo "Applying Waybar theme: $THEME_TITLE ($THEME_BASENAME)"

# 3. Persist to hyprpaper.conf
if [[ -f "$HYPRPAPER_CONF" ]]; then
    SAFE_WP="${WALLPAPER//\\/\\\\}"
    SAFE_WP="${SAFE_WP//&/\\&}"
    sed -i -E "s|^([[:space:]]*preload[[:space:]]*=).*|\1 $SAFE_WP|g; s|^([[:space:]]*wallpaper[[:space:]]*=).*|\1 ,$SAFE_WP|g" "$HYPRPAPER_CONF"
fi

# 4. Persist to hyprlock.conf for lockscreen sync (only the background path)
if [[ -f "$HYPRLOCK_CONF" ]]; then
    SAFE_WP="${WALLPAPER//\\/\\\\}"
    SAFE_WP="${SAFE_WP//&/\\&}"
    awk -v wp="$SAFE_WP" '
        /^[[:space:]]*background[[:space:]]*\{/ { in_bg=1 }
        in_bg && /^[[:space:]]*path[[:space:]]*=/ { sub(/=.*/, "= " wp); in_bg=0 }
        { print }
    ' "$HYPRLOCK_CONF" > "${HYPRLOCK_CONF}.tmp" && mv "${HYPRLOCK_CONF}.tmp" "$HYPRLOCK_CONF"
fi

# 5. Persist to Waybar style.css
if [[ -f "$WAYBAR_STYLE" ]]; then
    sed -i -E "s|@import url\(\"themes/[^\"]+\.css\"\);|@import url(\"themes/${THEME_BASENAME}\");|g" "$WAYBAR_STYLE"
fi

# 6. Live reload hyprpaper
if pgrep -x hyprpaper >/dev/null; then
    hyprctl hyprpaper wallpaper ",$WALLPAPER" >/dev/null 2>&1
else
    hyprpaper >/dev/null 2>&1 &
fi

# 7. Live reload Waybar styles
if pgrep -x waybar >/dev/null; then
    killall -SIGUSR2 waybar 2>/dev/null || true
fi

# 8. Notify user
notify-send -a "Theme Shuffle" \
    -i "$WALLPAPER" \
    "Wallpaper & Theme Updated" \
    "Wallpaper: $WALLPAPER_NAME\nTheme: $THEME_TITLE"

echo "Done! Both wallpaper and Waybar theme updated successfully."
