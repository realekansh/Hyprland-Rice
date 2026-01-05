#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config"
LOCAL_BIN="$HOME/.local/bin"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

backup_config() {
  local name="$1"
  local target="$2"

  if [[ -d "$target" ]]; then
    echo -e "${YELLOW}Backing up existing ${name} config...${RESET}"
    mv "$target" "${target}.backup-${TIMESTAMP}"
    echo -e "${GREEN}✔ Backup created:${RESET} ${target}.backup-${TIMESTAMP}"
  fi
}

copy_config() {
  local name="$1"
  local source="$2"
  local target="$3"

  if [[ ! -d "$source" ]]; then
    echo -e "${RED}Config source missing:${RESET} $source"
    return
  fi

  backup_config "$name" "$target"

  echo -e "${BOLD}Installing ${name} config...${RESET}"
  mkdir -p "$(dirname "$target")"
  cp -r "$source" "$target"

  echo -e "${GREEN}✔ ${name} config installed.${RESET}"
}
