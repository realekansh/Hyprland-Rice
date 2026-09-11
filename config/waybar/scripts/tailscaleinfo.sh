#!/usr/bin/env bash

# Set your hostname in the appropriate file
# disable in waybar if not needed

if [[ -f "$HOME/.config/.secrets/hostnames.txt" ]]; then
    mapfile -t hostnames < "$HOME/.config/.secrets/hostnames.txt"
else
    hostnames=()
fi
sshhost=$(cat "$HOME/.config/.secrets/hostname.txt" 2>/dev/null || true)

if [ "${#hostnames[@]}" -eq 0 ]; then
    if [ -n "$sshhost" ]; then
        hostnames=("$sshhost")
    else
        jq -nc '{ text: "", class: "disconnected" }'
        exit 0
    fi
fi

text=""
css_class="green"

for i in "${!hostnames[@]}"; do
    hostname="${hostnames[$i]}"

    ip=$(tailscale ip -4 "$hostname" 2>/dev/null) || ip="N/A"
    status=$(tailscale status 2>/dev/null | awk -v h="$hostname" '$0 ~ h {print $NF}')

    if [ "$status" = "offline" ]; then
        if [ "$sshhost" = "$hostname" ]; then
            css_class=red
        fi
        status_icon=""
    else
        css_class=green
        status_icon=""
    fi

    if [ "$sshhost" = "$hostname" ]; then
        text+=">  <span foreground = \"${css_class}\">${hostname}: ${ip} ${status_icon} </span>"
    else
        text+="   <span foreground = \"${css_class}\">${hostname}: ${ip} ${status_icon} </span>"
    fi

    j=$((i + 1))
    if [ "$j" -lt "${#hostnames[@]}" ]; then
        text+=$'\n'
    fi
done

jq -nc \
        --arg text "$text" \
        --arg class "$css_class" \
        '{
            text: $text,
            class: $class
        }'