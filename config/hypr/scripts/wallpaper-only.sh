#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Wallpaper-Only Shuffle Script
#
# Randomly selects and applies a wallpaper from ~/.config/hypr/hyprpaper/
# while leaving the Waybar stylesheet and theme completely untouched.
#
# Features:
#   - Syncs ~/.config/hypr/hyprpaper.conf and ~/.config/hypr/hyprlock.conf
#     for persistent desktop and lock screen backgrounds across reboots.
#   - Smoothly applies wallpaper live using Hyprpaper Wayland IPC.
#   - Avoids picking the currently active wallpaper when alternatives exist.
#   - Accepts an optional image file path as $1 for direct wallpaper setting.
#   - Sends a desktop notification with wallpaper thumbnail.
#
# Triggered via: SUPER + ALT + W
# -----------------------------------------------------------------------------

set -euo pipefail

WALLPAPER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper"
HYPRPAPER_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf"
HYPRLOCK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"

# 1. Determine target wallpaper
if [[ -n "${1:-}" && -f "$1" ]]; then
    WALLPAPER="$(realpath "$1")"
else
    # Detect currently active wallpaper to avoid picking the same one
    CURRENT_WALLPAPER=""
    if [[ -f "$HYPRPAPER_CONF" ]]; then
        CURRENT_WALLPAPER="$(grep -E '^[[:space:]]*path[[:space:]]*=' "$HYPRPAPER_CONF" | head -n1 | sed -E 's/.*=[[:space:]]*//')"
    fi

    # Find all eligible wallpapers
    mapfile -t ALL_WALLPAPERS < <(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
    )

    if [[ ${#ALL_WALLPAPERS[@]} -eq 0 ]]; then
        notify-send -u critical -a "Wallpaper" "Wallpaper Error" "No valid image files found in $WALLPAPER_DIR"
        echo "Error: No wallpapers found in $WALLPAPER_DIR" >&2
        exit 1
    fi

    # Filter out current wallpaper if more than 1 image is available
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
echo "Applying wallpaper: $WALLPAPER_NAME"

# 2. Persist to hyprpaper.conf
if [[ -f "$HYPRPAPER_CONF" ]]; then
    SAFE_WP="${WALLPAPER//\\/\\\\}"
    SAFE_WP="${SAFE_WP//&/\\&}"
    sed -i -E "s|^([[:space:]]*preload[[:space:]]*=).*|\1 $SAFE_WP|g; s|^([[:space:]]*wallpaper[[:space:]]*=).*|\1 ,$SAFE_WP|g" "$HYPRPAPER_CONF"
fi

# 3. Persist to hyprlock.conf for lockscreen sync (only the background path)
if [[ -f "$HYPRLOCK_CONF" ]]; then
    SAFE_WP="${WALLPAPER//\\/\\\\}"
    SAFE_WP="${SAFE_WP//&/\\&}"
    awk -v wp="$SAFE_WP" '
        /^[[:space:]]*background[[:space:]]*\{/ { in_bg=1 }
        in_bg && /^[[:space:]]*path[[:space:]]*=/ { sub(/=.*/, "= " wp); in_bg=0 }
        { print }
    ' "$HYPRLOCK_CONF" > "${HYPRLOCK_CONF}.tmp" && mv "${HYPRLOCK_CONF}.tmp" "$HYPRLOCK_CONF"
fi

# 4. Live reload hyprpaper
if pgrep -x hyprpaper >/dev/null; then
    hyprctl hyprpaper wallpaper ",$WALLPAPER" >/dev/null 2>&1
else
    hyprpaper >/dev/null 2>&1 &
fi

# 5. Notify user
notify-send -a "Wallpaper" \
    -i "$WALLPAPER" \
    "Wallpaper Updated" \
    "$WALLPAPER_NAME"

echo "Done! Wallpaper updated without modifying Waybar theme."
