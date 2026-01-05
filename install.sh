#!/usr/bin/env bash
set -e

# ===============================
# Colors & formatting
# ===============================
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# ===============================
# ASCII Art Splash
# ===============================
clear
cat <<'EOF'
 _   _                  _                 _
 | | | |_   _ _ __  _ __| | __ _ _ __   __| |
 | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
 |  _  | |_| | |_) | |  | | (_| | | | | (_| |
 |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
        |___/|_|

-----------------------------------------------------
EOF

echo -e "${BOLD}Hyprland Rice Installer${RESET}"
echo -e "by ${BOLD}notrealekansh${RESET}"
echo

# ===============================
# Mandatory warning
# ===============================
echo -e "${YELLOW}${BOLD}⚠️  MUST READ BEFORE INSTALLATION ⚠️${RESET}"
echo
echo "This repository WILL:"
echo " • Install Hyprland core packages (from Hyprland Wiki)"
echo " • Install optional packages you choose"
echo " • Copy configs to ~/.config"
echo " • Backup existing configs automatically"
echo
echo "This repository WILL NOT:"
echo " • Modify bootloader"
echo " • Touch kernel files"
echo " • Delete your personal data"
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
# Load scripts
# ===============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/detect-distro.sh"
source "$SCRIPT_DIR/scripts/install-packages.sh"

echo -e "${BOLD}Detected system:${RESET} $DISTRO"
echo

# ===============================
# Core installation
# ===============================
echo -e "${BOLD}Installing Hyprland core packages...${RESET}"
install_packages "packages/core.txt"
install_packages "packages/distros/${DISTRO}.txt"

# ===============================
# Extras selection
# ===============================
echo
echo -e "${BOLD}Optional components:${RESET}"

select_extra() {
  local file="$1"
  local name="$2"
  read -rp "Install $name? (Y/n): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    install_packages "packages/extras/$file"
  fi
}

select_extra "screenshot.txt" "Screenshot tools (Hyprshot)"
select_extra "launcher.txt"   "App launcher"
select_extra "bar.txt"        "Waybar"
select_extra "notify.txt"     "Notifications"
select_extra "terminal.txt"   "Terminal"
select_extra "utils.txt"      "Utilities"

echo
echo -e "${GREEN}${BOLD}✔ Installation complete.${RESET}"
echo "Log out and start Hyprland 🚀"

