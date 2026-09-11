#!/usr/bin/env bash
set -euo pipefail

threshold_yellow=5
threshold_red=50

token=$(cat ~/.config/.secrets/notifications.token 2>/dev/null) || token=""
username=$(cat ~/.config/.secrets/github_username.txt 2>/dev/null) || username=""

if [ -z "$token" ] || [ -z "$username" ]; then
    jq -nc '{ text: "?", tooltip: "GitHub: missing credentials", class: "error" }'
    exit 0
fi

count=$(curl -sf -u "${username}:${token}" "https://api.github.com/notifications" 2>/dev/null | jq '. | length' 2>/dev/null) || count=0

if [ -z "$count" ] || ! [[ "$count" =~ ^[0-9]+$ ]]; then
    count=0
fi

if [ "$count" -gt "$threshold_red" ]; then
    css_class="red"
elif [ "$count" -gt "$threshold_yellow" ]; then
    css_class="yellow"
else
    css_class="green"
fi

jq -nc \
    --arg text "$count" \
    --arg tooltip "GitHub Notifications: $count" \
    --arg class "$css_class" \
    '{ text: $text, tooltip: $tooltip, class: $class }'
