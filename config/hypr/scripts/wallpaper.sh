#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Wallpaper & Theme Management Master Script
#
# Unified entrypoint providing two dedicated operational modes:
#   1. Wallpaper Only  (--only  | -o): Randomizes/sets wallpaper only, keeping
#                                      the active Waybar theme unchanged.
#   2. Full Shuffle    (--theme | -t): Randomizes both the wallpaper and the
#                                      Waybar color palette simultaneously.
#
# Default (no flags): Executes full shuffle (--theme).
#
# Keybindings:
#   SUPER + SHIFT + W  ->  Shuffle Wallpaper & Waybar Theme (wallpaper-theme.sh)
#   SUPER + ALT + W    ->  Shuffle Wallpaper Only (wallpaper-only.sh)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat <<HELP
Usage: $(basename "$0") [OPTIONS] [IMAGE_PATH] [THEME_NAME]

Options:
  -o, --only         Change wallpaper ONLY (preserve current Waybar theme)
  -t, --theme, -b    Change BOTH wallpaper and Waybar theme (default)
  -h, --help         Show this help message

Examples:
  $(basename "$0")                      # Shuffle both wallpaper and Waybar theme
  $(basename "$0") --only               # Shuffle wallpaper only
  $(basename "$0") --theme              # Shuffle both wallpaper and theme
  $(basename "$0") -o ~/Pictures/bg.png # Set specific wallpaper without changing theme
  $(basename "$0") -t ~/Pictures/bg.png catppuccin-mocha.css
HELP
}

case "${1:-}" in
    -o|--only)
        shift
        exec "$SCRIPT_DIR/wallpaper-only.sh" "$@"
        ;;
    -t|--theme|-b|--both)
        shift
        exec "$SCRIPT_DIR/wallpaper-theme.sh" "$@"
        ;;
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        exec "$SCRIPT_DIR/wallpaper-theme.sh" "$@"
        ;;
esac
