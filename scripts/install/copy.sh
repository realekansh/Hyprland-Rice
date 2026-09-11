#!/usr/bin/env bash

config_targets() {
    cat <<EOF
Hyprland|$HOME/.config/hypr
Waybar|$HOME/.config/waybar
Rofi|$HOME/.config/rofi
SwayNC|$HOME/.config/swaync
Kitty|$HOME/.config/kitty
Alacritty|$HOME/.config/alacritty
Vicinae|$HOME/.config/vicinae
wlogout|$HOME/.config/wlogout
AGS|$HOME/.config/ags
Btop|$HOME/.config/btop
Fastfetch|$HOME/.config/fastfetch
Yazi|$HOME/.config/yazi
Bash|$HOME/.bashrc
EOF
}

verify_copy() {
    local source="$1" target="$2" file relative
    if [[ -f "$source" ]]; then
        cmp -s "$source" "$target" || { die "Verification failed: $target"; return 1; }
        return 0
    fi
    while IFS= read -r -d '' file; do
        relative="${file#"$source"/}"
        [[ -f "$target/$relative" ]] || { die "Verification missing: $target/$relative"; return 1; }
        cmp -s "$file" "$target/$relative" || { die "Verification failed: $target/$relative"; return 1; }
    done < <(find "$source" -type f -print0)
}

copy_target() {
    local label="$1" source="$2" target="$3"
    [[ -e "$source" ]] || { warn "Skipping missing source: $source"; return 0; }

    if path_exists "$target"; then
        if [[ "$CONFIG_MODE" == skip ]]; then
            log "Skipped existing $label ($target)"
            return 0
        fi
        backup_existing "$target"
        if [[ "$CONFIG_MODE" == replace ]]; then
            (( DRY_RUN )) || rm -rf -- "$target"
        fi
    else
        register_created_target "$target"
    fi

    if [[ -d "$source" ]]; then
        run_cmd mkdir -p -- "$target"
        run_cmd cp -a -- "$source"/. "$target"/
    else
        run_cmd mkdir -p -- "$(dirname -- "$target")"
        run_cmd cp -a -- "$source" "$target"
    fi
    if (( ! DRY_RUN )); then
        verify_copy "$source" "$target"
        if [[ "$label" == wlogout ]]; then
            # The repository owns these icons; do not depend on a system path.
            local icon_path
            icon_path="${target}/icons"
            sed -i "s#/home/[^/]\+/\.config/wlogout/icons#${icon_path}#g; s#/usr/share/wlogout/icons#${icon_path}#g; s#/usr/local/share/wlogout/icons#${icon_path}#g" "$target/style.css"
        fi
    fi
    ok "$label installed"
}

copy_configurations() {
    local label source target
    while IFS='|' read -r label target; do
        case "$label" in
            Hyprland) source="$CONFIG_SOURCE/hypr" ;;
            Waybar) source="$CONFIG_SOURCE/waybar" ;;
            Rofi) source="$CONFIG_SOURCE/rofi" ;;
            SwayNC) source="$CONFIG_SOURCE/swaync" ;;
            Kitty) source="$CONFIG_SOURCE/kitty" ;;
            Alacritty) source="$CONFIG_SOURCE/alacritty" ;;
            Vicinae) source="$CONFIG_SOURCE/vicinae" ;;
            wlogout) source="$CONFIG_SOURCE/wlogout" ;;
            AGS) source="$CONFIG_SOURCE/ags" ;;
            Btop) source="$CONFIG_SOURCE/btop" ;;
            Fastfetch) source="$CONFIG_SOURCE/fastfetch" ;;
            Yazi) source="$CONFIG_SOURCE/yazi" ;;
            Bash) source="$CONFIG_SOURCE/.bashrc" ;;
            *) continue ;;
        esac
        copy_target "$label" "$source" "$target"
    done < <(config_targets)
}
