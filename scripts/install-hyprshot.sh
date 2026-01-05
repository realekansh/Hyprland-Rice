#!/usr/bin/env bash

install_hyprshot() {
  echo
  echo -e "${BOLD}Screenshot tool:${RESET} Hyprshot (GitHub)"
  read -rp "Install Hyprshot? (Y/n): " ans

  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Skipping Hyprshot."
    return
  fi

  # Ensure git exists
  if ! command -v git &>/dev/null; then
    echo -e "${RED}Error:${RESET} git is not installed."
    echo "Please install git first."
    return
  fi

  # Ensure ~/.local/bin exists
  mkdir -p "$HOME/.local/bin"

  # Dependency check (safety)
  deps=(grim slurp wl-clipboard jq)
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      echo -e "${RED}Missing dependency:${RESET} $dep"
      echo "Install screenshot dependencies first."
      return
    fi
  done

  echo -e "${BOLD}Installing Hyprshot from GitHub...${RESET}"

  tmpdir="$(mktemp -d)"

  if ! git clone https://github.com/Gustash/Hyprshot.git "$tmpdir/hyprshot"; then
    echo -e "${RED}Failed to clone Hyprshot repository.${RESET}"
    rm -rf "$tmpdir"
    return
  fi

  if [[ ! -f "$tmpdir/hyprshot/hyprshot" ]]; then
    echo -e "${RED}Hyprshot binary not found.${RESET}"
    rm -rf "$tmpdir"
    return
  fi

  install -Dm755 "$tmpdir/hyprshot/hyprshot" "$HOME/.local/bin/hyprshot"
  rm -rf "$tmpdir"

  if command -v hyprshot &>/dev/null; then
    echo -e "${GREEN}✔ Hyprshot installed successfully.${RESET}"
    echo "Binary location: ~/.local/bin/hyprshot"
  else
    echo -e "${RED}Hyprshot installation failed.${RESET}"
  fi
}
