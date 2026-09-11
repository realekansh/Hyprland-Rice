#!/usr/bin/env bash

# Shared state and small helpers. The orchestration file owns shell options.

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$INSTALL_DIR/../.." && pwd)"
CONFIG_SOURCE="$REPO_ROOT/config"
PACKAGE_SOURCE="$REPO_ROOT/packages"
ASSET_SOURCE="$REPO_ROOT/assets"

INSTALL_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-rice"
BACKUP_ROOT="$STATE_ROOT/backups/$INSTALL_TIMESTAMP"
LOG_DIR="$REPO_ROOT/logs"
LOG_FILE="$LOG_DIR/install-$INSTALL_TIMESTAMP.log"

DRY_RUN=0
NONINTERACTIVE=0
AUTO_ACCEPT=0
NO_COLOR=0
CONFIG_MODE="skip"
BACKUP_EXISTING=0
INSTALL_RECOMMENDED=1
INSTALL_OPTIONAL=0
INSTALL_WALLPAPERS=1
INSTALL_FONTS=1
INSTALL_GTK_THEME=1
INSTALL_CURSOR_THEME=0
INSTALL_ICON_THEME=1
INSTALL_SERVICES=1
START_SERVICES=0
INSTALL_DEV_TOOLS=0
INSTALL_MEDIA_UTILITIES=1
INSTALL_OPTIONAL_DEPS=0

BACKUP_RECORDS=()
CREATED_TARGETS=()
TEMP_PATHS=()

if [[ -t 1 ]] && (( ! NO_COLOR )); then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    BLUE=$'\033[34m'
    RESET=$'\033[0m'
else
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

log() {
    printf '%s[%s]%s %s\n' "$BLUE" "$(date +%H:%M:%S)" "$RESET" "$*"
}

ok() {
    printf '%s[ OK ]%s %s\n' "$GREEN" "$RESET" "$*"
}

warn() {
    printf '%s[ WARN ]%s %s\n' "$YELLOW" "$RESET" "$*" >&2
}

die() {
    printf '%s[ ERROR ]%s %s\n' "$RED" "$RESET" "$*" >&2
    return 1
}

run_cmd() {
    if (( DRY_RUN )); then
        log "dry-run: $*"
        return 0
    fi
    "$@"
}

path_exists() {
    [[ -e "$1" || -L "$1" ]]
}

register_created_target() {
    CREATED_TARGETS+=("$1")
}

register_backup() {
    BACKUP_RECORDS+=("$1|$2")
}

parse_args() {
    while (($#)); do
        case "$1" in
            --dry-run) DRY_RUN=1 ;;
            --non-interactive) NONINTERACTIVE=1 ;;
            --yes) NONINTERACTIVE=1; AUTO_ACCEPT=1 ;;
            --no-color) NO_COLOR=1; disable_colors ;;
            --help|-h)
                cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --dry-run          inspect and log actions without changing the system
  --non-interactive  use safe defaults without prompts
  --yes              accept all feature prompts, including optional features
  --no-color         disable ANSI colors
  --help             show this help
USAGE
                exit 0
                ;;
            *) die "Unknown option: $1"; return 2 ;;
        esac
        shift
    done
}

setup_logging() {
    run_cmd mkdir -p "$LOG_DIR"
    if (( ! DRY_RUN )); then
        exec > >(tee -a "$LOG_FILE") 2>&1
    fi
    log "Log file: $LOG_FILE"
}

begin_transaction() {
    if (( ! DRY_RUN )); then
        mkdir -p "$BACKUP_ROOT"
    fi
    log "Transaction workspace: $BACKUP_ROOT"
}

rollback_installation() {
    local record backup target
    warn "Rolling back files changed by this installation."

    if (( ${#CREATED_TARGETS[@]} )); then
        for target in "${CREATED_TARGETS[@]}"; do
            if path_exists "$target"; then
                rm -rf -- "$target"
            fi
        done
    fi

    if (( ${#BACKUP_RECORDS[@]} )); then
        for record in "${BACKUP_RECORDS[@]}"; do
            backup="${record%%|*}"
            target="${record#*|}"
            if path_exists "$backup"; then
                rm -rf -- "$target"
                mkdir -p -- "$(dirname -- "$target")"
                cp -a -- "$backup" "$target"
                log "Restored $target"
            fi
        done
    fi
}

cleanup_paths() {
    local path
    for path in "${TEMP_PATHS[@]}"; do
        [[ -n "$path" && -e "$path" ]] && rm -rf -- "$path"
    done
}

on_error() {
    local line="$1"
    set +e
    printf '%s[ FAILED ]%s Installation stopped at line %s.\n' "$RED" "$RESET" "$line" >&2
    rollback_installation
    cleanup_paths
    printf 'Backups remain available at: %s\n' "$BACKUP_ROOT" >&2
    exit 1
}

disable_colors() {
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
}
