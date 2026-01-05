#!/usr/bin/env bash

# ===============================
# Formatting
# ===============================
BOLD="\e[1m"
DIM="\e[2m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ===============================
# Logging setup
# ===============================
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

# Log everything
exec > >(tee -a "$LOG_FILE") 2>&1

# ===============================
# Splash screen
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
echo -e "${DIM}Log file:${RESET} $LOG_FILE"
echo

# ===============================
# Warning & consent
# ===============================
echo -e "${YELLOW}${BOLD}[ WARNING ] MUST READ BEFORE INSTALLATION${RESET}"
echo
echo -e "${BOLD}This repository WILL:${RESET}"
echo " • Install Hyprland core packages"
echo " • Install optional packages you choose"
echo " • Copy configuration files"
echo " • Backup existing configs automatically"
echo
echo -e "${BOLD}This repository WILL NOT:${RESET}"
echo " • Modify bootloader"
echo " • Touch kernel files"
echo " • Delete your data"
echo

read -rp "Do you want to continue? (Y/n): " CONSENT
if [[ -n "$CONSENT" && ! "$CONSENT" =~ ^[Yy]$ ]]; then
  echo -e "${RED}[ ABORTED ]${RESET} User declined."
  exit 0
fi

echo -e "${GREEN}[ OK ] Consent received${RESET}"
echo

# ===============================
# Script directory
# ===============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===============================
# Load helpers
# ===============================
source "$SCRIPT_DIR/scripts/detect-distro.sh"
source "$SCRIPT_DIR/scripts/install-hyprshot.sh"
source "$SCRIPT_DIR/scripts/config-manager.sh"

echo -e "${GREEN}[ OK ] Detected distro:${RESET} ${BOLD}$DISTRO${RESET}"
echo

# ===============================
# Safe package installer
# ===============================
install_safe_packages() {
  local file="$1"
  [[ ! -f "$file" ]] && return

  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    echo -e "${BLUE}[ INFO ]${RESET} Installing package: ${BOLD}$pkg${RESET}"

    case "$DISTRO" in
      arch)
        sudo pacman -S --needed --noconfirm "$pkg" \
          && echo -e "${GREEN}[ OK ]${RESET} $pkg" \
          || echo -e "${YELLOW}[ SKIP ]${RESET} $pkg"
        ;;
      fedora)
        sudo dnf install -y "$pkg" || echo -e "${YELLOW}[ SKIP ]${RESET} $pkg"
        ;;
      opensuse)
        sudo zypper install -y "$pkg" || echo -e "${YELLOW}[ SKIP ]${RESET} $pkg"
        ;;
    esac
  done < "$file"
}

# ===============================
# Core packages
# ===============================
echo -e "${BOLD}==============================${RESET}"
echo -e "${BOLD} Installing Hyprland Core${RESET}"
echo -e "${BOLD}==============================${RESET}"

install_safe_packages "$SCRIPT_DIR/packages/core.txt"
install_safe_packages "$SCRIPT_DIR/packages/distros/${DISTRO}.txt"

# ===============================
# Optional packages
# ===============================
select_extra() {
  local file="$1"
  local label="$2"
  read -rp "Install $label? (Y/n): " ans
  if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
    install_safe_packages "$SCRIPT_DIR/packages/extras/$file"
  else
    echo -e "${DIM}[ SKIP ]${RESET} $label"
  fi
}

echo
echo -e "${BOLD}==============================${RESET}"
echo -e "${BOLD} Optional Packages${RESET}"
echo -e "${BOLD}==============================${RESET}"

select_extra "hypr-ecosystem.txt" "Hyprland ecosystem tools"
select_extra "screenshot.txt"     "Screenshot dependencies"
install_hyprshot
select_extra "launcher.txt"       "Launchers (rofi / vicinae)"
select_extra "bar.txt"            "Waybar"
select_extra "notify.txt"         "Notifications (mako)"
select_extra "terminal.txt"       "Terminal"
select_extra "utils.txt"          "Utilities"

# ===============================
# Config installation
# ===============================
install_cfg() {
  local name="$1"
  local src="$2"
  local dst="$3"
  read -rp "Install $name config? (Y/n): " ans
  if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
    copy_config "$name" "$src" "$dst"
  else
    echo -e "${DIM}[ SKIP ]${RESET} $name config"
  fi
}

echo
echo -e "${BOLD}==============================${RESET}"
echo -e "${BOLD} Configuration Setup${RESET}"
echo -e "${BOLD}==============================${RESET}"

install_cfg "Hyprland" "$SCRIPT_DIR/config/hypr" "$HOME/.config/hypr"
[[ -d "$SCRIPT_DIR/config/waybar"  ]] && install_cfg "Waybar"  "$SCRIPT_DIR/config/waybar"  "$HOME/.config/waybar"
[[ -d "$SCRIPT_DIR/config/kitty"   ]] && install_cfg "Kitty"   "$SCRIPT_DIR/config/kitty"   "$HOME/.config/kitty"
[[ -d "$SCRIPT_DIR/config/mako"    ]] && install_cfg "Mako"    "$SCRIPT_DIR/config/mako"    "$HOME/.config/mako"
[[ -d "$SCRIPT_DIR/config/rofi"    ]] && install_cfg "Rofi"    "$SCRIPT_DIR/config/rofi"    "$HOME/.config/rofi"
[[ -d "$SCRIPT_DIR/config/vicinae" ]] && install_cfg "Vicinae" "$SCRIPT_DIR/config/vicinae" "$HOME/.config/vicinae"
[[ -d "$SCRIPT_DIR/config/Thunar"  ]] && install_cfg "Thunar"  "$SCRIPT_DIR/config/Thunar"  "$HOME/.config/Thunar"

# ===============================
# Done
# ===============================
echo
echo -e "${GREEN}${BOLD}[ DONE ] Installation complete!${RESET}"
echo -e "${DIM}Log saved to:${RESET} $LOG_FILE"
echo -e "${BOLD}Log out and start Hyprland ${RESET}"

