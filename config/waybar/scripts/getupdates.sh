#!/usr/bin/env bash

threshold_yellow=15
threshold_red=100

AUR_HELPER=""
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
fi

# Capture update lists once (avoids running checkupdates and yay/paru twice)
list_updates_arch=$(checkupdates 2>/dev/null | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g") || true
if [ -n "$AUR_HELPER" ]; then
    list_updates_aur=$("$AUR_HELPER" -Qua 2>/dev/null | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g") || true
else
    list_updates_aur=""
fi

# Derive counts from captured output
if [ -n "$list_updates_arch" ]; then
    updates_arch=$(echo "$list_updates_arch" | wc -l)
else
    updates_arch=0
fi

if [ -n "$list_updates_aur" ]; then
    updates_aur=$(echo "$list_updates_aur" | wc -l)
else
    updates_aur=0
fi

list_updates=""

if [ "$updates_arch" -gt 0 ]; then
    list_updates+="${list_updates_arch}"
    if [ "$updates_aur" -gt 0 ]; then
        list_updates+=$'\n'
    fi
fi

if [ "$updates_aur" -gt 0 ]; then
    list_updates+="${list_updates_aur}"
fi

# Output JSON for the Waybar custom-updates module
updates=$(("$updates_arch" + "$updates_aur"))
tooltip="Update the system (<span size=\"small\">${updates} package(s)):"$'\n'"${list_updates}</span>"

if [ "$updates" -lt "$threshold_yellow" ]; then
    css_class="green"
elif [ "$updates" -lt "$threshold_red" ]; then
    css_class="yellow"
else
    css_class="red"
fi

jq -nc \
    --arg text "$updates" \
    --arg tooltip "$tooltip" \
    --arg class "$css_class" \
    '{
        text: $text,
        tooltip: $tooltip,
        class: $class
    }'