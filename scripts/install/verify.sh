#!/usr/bin/env bash

verify_installation() {
    local required source
    for required in \
        "$CONFIG_SOURCE/hypr/hyprland.lua" \
        "$CONFIG_SOURCE/waybar/config.jsonc" \
        "$CONFIG_SOURCE/rofi/config.rasi" \
        "$CONFIG_SOURCE/hypr/hyprlock.conf" \
        "$CONFIG_SOURCE/hypr/hyprpaper.conf"; do
        [[ -f "$required" ]] || { die "Repository verification failed: missing $required"; return 1; }
    done
    source="$HOME/.config/hypr/hyprland.lua"
    if [[ "$CONFIG_MODE" != skip ]] && (( ! DRY_RUN )); then
        [[ -f "$source" ]] || { die "Installed Hyprland entry point is missing: $source"; return 1; }
    fi
    command -v vicinae >/dev/null 2>&1 || warn "Vicinae is not installed; its config and clipboard binding will remain inactive."
    command -v wlogout >/dev/null 2>&1 || warn "wlogout is not installed; the Waybar power button will remain inactive."
    ok "Installer verification completed."
}
