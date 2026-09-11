#!/bin/bash

# Set your hostname in the appropriate file
# disable in waybar if not needed

if [[ ! -f "$HOME/.config/.secrets/hostname.txt" ]]; then
    echo "No target hostname configured in ~/.config/.secrets/hostname.txt"
    read -n 1 -s -r -p "Press any key to close..."
    echo
    exit 1
fi

hostname=$(cat "$HOME/.config/.secrets/hostname.txt")
ip=$(tailscale ip -4 "$hostname" 2>/dev/null || true)
if [[ -z "$ip" ]]; then
    echo "Could not resolve Tailscale IP for host: $hostname"
    read -n 1 -s -r -p "Press any key to close..."
    echo
    exit 1
fi

echo "Connecting to $hostname: $ip..."
read -p "Enter username: " username

ssh "$username"@"$ip"

