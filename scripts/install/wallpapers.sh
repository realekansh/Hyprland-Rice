#!/usr/bin/env bash

install_wallpapers() {
    (( INSTALL_WALLPAPERS )) || { log "Skipping wallpapers."; return 0; }
    local source="$ASSET_SOURCE/wallpapers" target="$HOME/Pictures/wallpapers" file
    [[ -d "$source" ]] || { warn "Bundled wallpaper directory is missing: $source"; return 0; }
    if ! path_exists "$target"; then
        register_created_target "$target"
    fi
    run_cmd mkdir -p -- "$target"
    while IFS= read -r -d '' file; do
        if [[ -e "$target/$(basename -- "$file")" ]]; then
            log "Keeping existing wallpaper: $target/$(basename -- "$file")"
        else
            run_cmd cp -a -- "$file" "$target/"
        fi
    done < <(find "$source" -maxdepth 1 -type f -iregex '.*\.(jpg\|jpeg\|png\|webp)$' -print0)
    ok "Wallpapers installed into $target."
}
