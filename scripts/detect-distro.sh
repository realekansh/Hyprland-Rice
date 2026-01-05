#!/usr/bin/env bash

if [[ -f /etc/os-release ]]; then
  source /etc/os-release
else
  echo "Cannot detect distro."
  exit 1
fi

case "$ID" in
  arch) DISTRO="arch" ;;
  fedora) DISTRO="fedora" ;;
  opensuse*|suse) DISTRO="opensuse" ;;
  gentoo) DISTRO="gentoo" ;;
  nixos) DISTRO="nixos" ;;
  *)
    echo "Unsupported distro: $ID"
    exit 1
    ;;
esac

