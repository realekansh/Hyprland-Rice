#!/usr/bin/env bash

active_vpn=$(
    nmcli -t -f TYPE,NAME connection show --active 2>/dev/null \
        | awk -F: '$1 ~ /vpn|wireguard/ { print $2; found=1 } END { exit found ? 0 : 1 }'
)

if [ -n "$active_vpn" ]; then
    jq -nc --arg tooltip "VPN: ${active_vpn}" '{ text: "󰌾", tooltip: $tooltip, class: "connected" }'
else
    jq -nc '{ text: "󰦝", tooltip: "VPN disconnected", class: "disconnected" }'
fi
