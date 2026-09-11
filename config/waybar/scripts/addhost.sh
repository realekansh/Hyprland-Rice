#!/bin/bash

mkdir -p "$HOME/.config/.secrets"
touch "$HOME/.config/.secrets/hostnames.txt"

cur=("$(cat "$HOME/.config/.secrets/hostnames.txt" 2>/dev/null || true)")
echo "Known hosts: ${cur[*]}"
read -rep 'Add new host: ' new
[[ -z "$new" ]] && exit 0
echo "Added '$new', updating list"

echo "$new" >> "$HOME/.config/.secrets/hostnames.txt"
sleep 0.5