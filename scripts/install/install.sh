#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$INSTALL_DIR/common.sh"
# shellcheck source=ui.sh
source "$INSTALL_DIR/ui.sh"
# shellcheck source=detect.sh
source "$INSTALL_DIR/detect.sh"
# shellcheck source=packages.sh
source "$INSTALL_DIR/packages.sh"
# shellcheck source=backup.sh
source "$INSTALL_DIR/backup.sh"
# shellcheck source=copy.sh
source "$INSTALL_DIR/copy.sh"
# shellcheck source=fonts.sh
source "$INSTALL_DIR/fonts.sh"
# shellcheck source=themes.sh
source "$INSTALL_DIR/themes.sh"
# shellcheck source=wallpapers.sh
source "$INSTALL_DIR/wallpapers.sh"
# shellcheck source=services.sh
source "$INSTALL_DIR/services.sh"
# shellcheck source=postinstall.sh
source "$INSTALL_DIR/postinstall.sh"
# shellcheck source=cleanup.sh
source "$INSTALL_DIR/cleanup.sh"
# shellcheck source=verify.sh
source "$INSTALL_DIR/verify.sh"

main() {
    parse_args "$@"
    setup_logging
    print_banner
    detect_system
    print_system_report
    validate_host
    check_internet
    detect_fonts_and_themes
    detect_existing_state
    configure_choices || { log "Installation cancelled."; return 0; }
    validate_manifests
    begin_transaction

    select_manifests
    install_selected_packages
    copy_configurations
    install_fonts
    install_themes
    install_wallpapers
    configure_services
    postinstall
    verify_installation
    cleanup_installation
    show_completion
}

trap 'on_error "$LINENO"' ERR
main "$@"
