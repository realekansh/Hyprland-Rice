#!/usr/bin/env bash

print_banner() {
    printf '%s\n' "${BOLD}Hyprland Rice Installer${RESET}"
    printf '%s\n' "${DIM}Modular desktop setup · logged and reversible${RESET}"
    printf '%s\n\n' "${DIM}Repository: $REPO_ROOT${RESET}"
}

prompt_yes_no() {
    local variable="$1" prompt="$2" default="$3" answer
    if (( AUTO_ACCEPT )); then
        printf -v "$variable" '1'
        return 0
    fi
    if (( NONINTERACTIVE )); then
        printf -v "$variable" '%s' "$default"
        return 0
    fi
    if [[ "$default" == 1 ]]; then
        read -r -p "$prompt [Y/n] " answer
        [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]] && answer=1 || answer=0
    else
        read -r -p "$prompt [y/N] " answer
        [[ "$answer" =~ ^[Yy]$ ]] && answer=1 || answer=0
    fi
    printf -v "$variable" '%s' "$answer"
}

prompt_config_mode() {
    local answer
    if (( ! EXISTING_CONFIGS_FOUND )); then
        CONFIG_MODE="replace"
        return 0
    fi
    if (( AUTO_ACCEPT )); then
        CONFIG_MODE="merge"
        return 0
    fi
    if (( NONINTERACTIVE )); then
        CONFIG_MODE="skip"
        return 0
    fi
    printf '\nExisting configuration targets were found:\n%s\n' "$EXISTING_CONFIGS"
    while :; do
        read -r -p "Choose [m]erge, [r]eplace, or [s]kip existing targets (default: m): " answer
        answer="${answer:-m}"
        case "$answer" in
            m|M) CONFIG_MODE="merge"; break ;;
            r|R) CONFIG_MODE="replace"; break ;;
            s|S) CONFIG_MODE="skip"; break ;;
            *) warn "Please choose m, r, or s." ;;
        esac
    done
}

configure_choices() {
    local consent
    if (( AUTO_ACCEPT )); then
        consent=1
    elif (( NONINTERACTIVE )); then
        consent=1
    else
        printf '%sThis will install selected packages and copy selected files into your home directory.%s\n' "$YELLOW" "$RESET"
        read -r -p "Continue? [y/N] " consent
        [[ "$consent" =~ ^[Yy]$ ]] || return 1
    fi

    prompt_yes_no BACKUP_EXISTING "Back up existing configs" 1
    prompt_yes_no INSTALL_RECOMMENDED "Install recommended packages" 1
    prompt_yes_no INSTALL_OPTIONAL "Install optional package modules" 0
    prompt_yes_no INSTALL_WALLPAPERS "Install bundled wallpapers" 1
    prompt_yes_no INSTALL_FONTS "Install bundled fonts" 1
    prompt_yes_no INSTALL_GTK_THEME "Install and select GTK theme" 1
    prompt_yes_no INSTALL_CURSOR_THEME "Install cursor theme package" 0
    prompt_yes_no INSTALL_ICON_THEME "Install and select icon theme" 1
    prompt_yes_no INSTALL_SERVICES "Enable user services when available" 1
    prompt_yes_no START_SERVICES "Start selected user services now" 0
    prompt_yes_no INSTALL_DEV_TOOLS "Install developer tools" 0
    prompt_yes_no INSTALL_MEDIA_UTILITIES "Install media and hardware utilities" 1
    prompt_yes_no INSTALL_OPTIONAL_DEPS "Install optional script dependencies" 0
    prompt_config_mode
}

show_completion() {
    printf '\n%sInstallation complete.%s\n' "$GREEN$BOLD" "$RESET"
    printf 'Log: %s\n' "$LOG_FILE"
    printf 'Backups: %s\n' "$BACKUP_ROOT"
    printf 'Next: review docs/README.md, then start or reload Hyprland.\n'
}
