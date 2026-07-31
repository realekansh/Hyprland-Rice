#!/usr/bin/env bash

# Stop the current Waybar instance
pkill -x waybar

# Wait until Waybar has fully exited
while pgrep -x waybar >/dev/null; do
    sleep 0.1
done

# Start Waybar again
waybar >/dev/null 2>&1 &
