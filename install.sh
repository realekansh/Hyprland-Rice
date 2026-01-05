#!/usr/bin/env bash
set -e

# ===============================
# Formatting
# ===============================
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# ===============================
# Splash screen
# ===============================
clear
cat <<'EOF'
██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗
██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝
EOF

echo -e "${BOLD}Hyprland Rice Installer${RESET}"
echo -e "by ${BOLD}notrealekansh${RESET}"
echo

# ===============================
# Warning & consent
# ===============================
echo -e "${YELLOW}${BOLD}⚠️  MUST READ BEFORE INSTALLATION ⚠️${RESET}"
echo
echo "This repository WILL:"
echo " • Install Hyprland core packages (from Hyprland Wiki)"
echo " • Install optional packages you choose"
echo " • Copy configuration files"
echo " • Backup existing configs automatically"
echo
echo "This repository WILL NOT:"
echo " • Modify bootloader"
echo " • Touch kernel files"
echo " • Delete your data"
echo
echo "Read docs/REPOSITORY-WILL.md before continuing."
echo
read -rp "Do you want to continue? (Y/n): " CONSENT

if [[ ! "$CONSENT" =~ ^[Yy]$ ]]; then
  echo -e "${RED}Installation aborted.${RESET}"
  exit 0
fi

echo -e "${GREEN}✔ Consent received${RESET}"
echo

# ===============================
# Script directory
# ===============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===============================
# Load helper scripts
# ===============================
source "$SCRIPT_DIR/scripts/detect-distro.sh"
source "$SCRIPT_DIR/scripts/install-packages.sh"
source "$SCRIPT_DIR/scripts/install-hyprshot.sh"
source "$SCRIPT_DIR/scripts/config-manager.sh"

echo -e "${BOLD}Detected distro:${RESET} $DISTRO"
echo

# ===============================
# Core packages
# ===============================
echo -e "${BOLD}Installing Hyprland core packages...${RESET}"
install_packages "$SCRIPT_DIR/packages/core.txt"
install_packages "$SCRIPT_DIR/packages/distros/${DISTRO}.txt"

# ===============================
# Optional packages
# ===============================
echo
echo -e "${BOLD}Optional components:${RESET}"

select_extra() {
  local file="$1"
  local label="$2"

  read -rp "Install $label? (Y/n): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    install_packages "$SCRIPT_DIR/packages/extras/$file"
  fi
}

select_extra "hypr-ecosystem.txt" "Hyprland ecosystem tools"
select_extra "screenshot.txt"     "Screenshot dependencies"
install_hyprshot
select_extra "launcher.txt"       "App launcher"
select_extra "bar.txt"            "Waybar"
select_extra "notify.txt"         "Notifications"
select_extra "terminal.txt"       "Terminal"
select_extra "utils.txt"          "Utilities"

# ===============================
# Configuration setup
# ===============================
echo
echo -e "${BOLD}Configuration setup:${RESET}"

install_config() {
  local name="$1"
  local source="$2"
  local target="$3"

  read -rp "Install ${name} config? (Y/n): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    copy_config "$name" "$source" "$target"
  fi
}

# Hyprland config
install_config "Hyprland" \
  "$SCRIPT_DIR/config/hypr" \
  "$HOME/.config/hypr"

# Waybar config (optional)
if [[ -d "$SCRIPT_DIR/config/waybar" ]]; then
  install_config "Waybar" \
    "$SCRIPT_DIR/config/waybar" \
    "$HOME/.config/waybar"
fi

# Kitty config (optional)
if [[ -d "$SCRIPT_DIR/config/kitty" ]]; then
  install_config "Kitty" \
    "$SCRIPT_DIR/config/kitty" \
    "$HOME/.config/kitty"
fi

# ===============================
# Done
# ===============================
echo
echo -e "${GREEN}${BOLD}✔ Installation complete.${RESET}"
echo "Log out and start Hyprland 🚀"

