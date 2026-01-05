#!/usr/bin/env bash

install_packages() {
  local file="$1"
  [[ ! -f "$file" ]] && return

  mapfile -t PKGS < <(grep -v '^#' "$file" | sed '/^$/d')

  [[ "${#PKGS[@]}" -eq 0 ]] && return

  case "$DISTRO" in
    arch)
      sudo pacman -S --needed --noconfirm "${PKGS[@]}"
      ;;
    fedora)
      sudo dnf install -y "${PKGS[@]}"
      ;;
    opensuse)
      sudo zypper install -y "${PKGS[@]}"
      ;;
    gentoo)
      sudo emerge "${PKGS[@]}"
      ;;
    nixos)
      echo "NixOS detected – manual package integration required."
      ;;
  esac
}

