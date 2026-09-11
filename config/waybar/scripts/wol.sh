#!/bin/bash

# Set your ip and mac address in appropriate files
# disable in waybar if not needed

if [[ ! -f "$HOME/.config/.secrets/ip-address.txt" || ! -f "$HOME/.config/.secrets/mac-address.txt" ]]; then
    exit 0
fi

if ! command -v wol >/dev/null 2>&1; then
    exit 0
fi

ip=$(cat "$HOME/.config/.secrets/ip-address.txt")
mac=$(cat "$HOME/.config/.secrets/mac-address.txt")

wol --wait=1 --host="$ip" --port=9 "$mac"