#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Make sure the wallpaper directory exists
mkdir -p "$WALLPAPER_DIR"

# Pick a random supported wallpaper
WALLPAPER="$(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | shuf -n 1
)"

if [[ -z "$WALLPAPER" ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Apply wallpaper through Hyprpaper
hyprctl hyprpaper wallpaper ", $WALLPAPER"
