#!/usr/bin/env bash

manifest_packages() {
    awk '!/^[[:space:]]*#/ && NF { print $1 }' "$1"
}

validate_manifests() {
    local duplicates
    duplicates="$(for file in "$PACKAGE_SOURCE"/*.txt; do manifest_packages "$file"; done | sort | uniq -d)"
    [[ -z "$duplicates" ]] || { die "Duplicate package names across manifests: $duplicates"; return 1; }
}

add_manifest() {
    local name="$1" file="$PACKAGE_SOURCE/$1.txt"
    [[ -f "$file" ]] || { die "Missing package manifest: $file"; return 1; }
    SELECTED_MANIFESTS+=("$file")
    log "Selected package group: $name"
}

select_manifests() {
    SELECTED_MANIFESTS=()
    if (( INSTALL_RECOMMENDED )); then
        add_manifest core
        add_manifest desktop
        add_manifest hyprland
        add_manifest waybar
        add_manifest rofi
        add_manifest terminal
        add_manifest notifications
    fi
    if (( INSTALL_MEDIA_UTILITIES )); then add_manifest media; fi
    if (( INSTALL_FONTS )); then add_manifest fonts; fi
    if (( INSTALL_GTK_THEME || INSTALL_CURSOR_THEME || INSTALL_ICON_THEME )); then
        add_manifest themes
    fi
    if (( INSTALL_DEV_TOOLS )); then add_manifest development; fi
    if (( INSTALL_OPTIONAL || INSTALL_OPTIONAL_DEPS )); then add_manifest optional; fi
}

install_selected_packages() {
    local file pkg
    local packages=() official=() aur=()
    for file in "${SELECTED_MANIFESTS[@]}"; do
        while read -r pkg; do
            packages+=("$pkg")
        done < <(manifest_packages "$file")
    done
    if ((${#packages[@]} == 0)); then
        warn "No package groups selected."
        return 0
    fi
    log "Preparing ${#packages[@]} packages with pacman."
    if (( DRY_RUN )); then
        printf '  %s\n' "${packages[@]}"
        return 0
    fi
    local aur_helper=""
    if command -v paru >/dev/null 2>&1; then
        aur_helper="paru"
    elif command -v yay >/dev/null 2>&1; then
        aur_helper="yay"
    fi

    for pkg in "${packages[@]}"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            official+=("$pkg")
        elif [[ -n "$aur_helper" ]] && "$aur_helper" -Si "$pkg" >/dev/null 2>&1; then
            aur+=("$pkg")
        else
            if [[ -z "$aur_helper" ]]; then
                die "Package '$pkg' is not in official repositories and no AUR helper (paru or yay) was found."
            else
                die "Package is unavailable from official repositories and AUR helper ($aur_helper): $pkg"
            fi
            return 1
        fi
    done
    if ((${#official[@]})); then
        sudo pacman -Syu --needed --noconfirm "${official[@]}"
    fi
    if ((${#aur[@]})); then
        log "Installing AUR packages with $aur_helper: ${aur[*]}"
        "$aur_helper" -S --needed --noconfirm "${aur[@]}"
    fi
    ok "Package installation completed."
}
