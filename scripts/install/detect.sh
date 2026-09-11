#!/usr/bin/env bash

detect_system() {
    [[ -r /etc/os-release ]] || { die "Cannot read /etc/os-release."; return 1; }
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"

    PACKAGE_MANAGER=""
    if command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
    elif command -v zypper >/dev/null 2>&1; then
        PACKAGE_MANAGER="zypper"
    elif command -v emerge >/dev/null 2>&1; then
        PACKAGE_MANAGER="emerge"
    elif command -v nix-env >/dev/null 2>&1 || command -v nix >/dev/null 2>&1; then
        PACKAGE_MANAGER="nix"
    fi

    if [[ "$DISTRO_ID" == arch || "$DISTRO_LIKE" == *arch* ]] && [[ "$PACKAGE_MANAGER" == pacman ]]; then
        SUPPORTED_SYSTEM=1
    else
        SUPPORTED_SYSTEM=0
    fi

    CPU_MODEL="$(lscpu 2>/dev/null | sed -n 's/^Model name:[[:space:]]*//p' | head -1)"
    CPU_MODEL="${CPU_MODEL:-unknown CPU}"
    GPU_INFO="$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' | sed 's/^[^:]*: //' | paste -sd '; ' -)"
    GPU_INFO="${GPU_INFO:-GPU not detected (lspci unavailable or no PCI display device)}"
    SESSION="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${XDG_SESSION_TYPE:-unknown}}}"
    LOGIN_SHELL="${SHELL:-unknown}"
}

print_system_report() {
    printf '%sSystem detection%s\n' "$BOLD" "$RESET"
    printf '  Distribution: %s\n' "$DISTRO_NAME"
    printf '  Package manager: %s\n' "${PACKAGE_MANAGER:-not found}"
    printf '  GPU: %s\n' "$GPU_INFO"
    printf '  CPU: %s\n' "$CPU_MODEL"
    printf '  Session: %s\n' "$SESSION"
    printf '  Shell: %s\n' "$LOGIN_SHELL"
    printf '  Home: %s\n\n' "$HOME"
}

validate_host() {
    if (( ! SUPPORTED_SYSTEM )); then
        if (( DRY_RUN )); then
            warn "Unsupported system detected; dry-run will continue without package installation."
            return 0
        fi
        die "Unsupported installation target: $DISTRO_NAME. This release currently installs Arch/pacman package names only. Use --dry-run for inventory, or see docs/ for manual porting."
    fi

    if (( EUID == 0 )); then
        die "Do not run this installer as root or with sudo. Dotfiles must be installed as your regular user. The installer will prompt for sudo only when installing packages."
        return 1
    fi
    command -v bash >/dev/null 2>&1 || { die "bash is required."; return 1; }
    command -v sudo >/dev/null 2>&1 || { die "sudo is required for package installation."; return 1; }
    command -v tee >/dev/null 2>&1 || { die "tee is required for installer logging."; return 1; }
    command -v curl >/dev/null 2>&1 || { die "curl is required for the connectivity check."; return 1; }
}

check_internet() {
    if curl -fsSI --max-time 8 https://archlinux.org >/dev/null 2>&1; then
        ok "Internet connectivity detected."
        return 0
    fi
    if (( DRY_RUN )); then
        warn "Internet connectivity check failed; continuing because this is a dry run."
        return 0
    fi
    die "Internet connectivity is required to install packages."
}

detect_existing_state() {
    EXISTING_CONFIGS_FOUND=0
    EXISTING_CONFIGS=""
    local target label
    while IFS='|' read -r label target; do
        if path_exists "$target"; then
            EXISTING_CONFIGS_FOUND=1
            EXISTING_CONFIGS+="  - $label: $target"$'\n'
        fi
    done < <(config_targets)
}

detect_fonts_and_themes() {
    INSTALLED_FONT_COUNT=0
    INSTALLED_THEME_COUNT=0
    if command -v fc-list >/dev/null 2>&1; then
        INSTALLED_FONT_COUNT="$(fc-list 2>/dev/null | wc -l)"
    fi
    if [[ -d /usr/share/themes || -d "$HOME/.themes" ]]; then
        INSTALLED_THEME_COUNT="$(find /usr/share/themes "$HOME/.themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
    fi
    log "Detected fonts: $INSTALLED_FONT_COUNT; GTK themes: $INSTALLED_THEME_COUNT"
}
