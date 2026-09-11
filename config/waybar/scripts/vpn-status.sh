#!/usr/bin/env bash

active_vpn=$(
    nmcli -t -f NAME,TYPE connection show --active \
        | awk -F: '$2 ~ /vpn|wireguard/ { print $1; found=1 } END { exit found ? 0 : 1 }'
)

if [ -n "$active_vpn" ]; then
    jq -nc --arg tooltip "VPN: ${active_vpn}" '{ text: "󰌾", tooltip: $tooltip, class: "connected" }'
else
    jq -nc '{ text: "󰦝", tooltip: "VPN disconnected", class: "disconnected" }'
fi
