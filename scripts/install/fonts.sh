#!/usr/bin/env bash

install_fonts() {
    (( INSTALL_FONTS )) || { log "Skipping fonts."; return 0; }
    local source="$CONFIG_SOURCE/hypr/hyprlock/fonts" target="$HOME/.local/share/fonts/Hyprland-Rice"
    [[ -d "$source" ]] || { warn "Bundled font directory is missing: $source"; return 0; }
    if path_exists "$target"; then
        backup_existing "$target"
    else
        register_created_target "$target"
    fi
    run_cmd mkdir -p -- "$target"
    run_cmd cp -a -- "$source"/. "$target"/
    if (( ! DRY_RUN )); then
        fc-cache -f "$target"
    fi
    ok "Bundled fonts installed."
}
