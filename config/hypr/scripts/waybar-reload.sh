#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Waybar Graceful Reload Script
#
# Cleanly terminates running Waybar instances and relaunches the bar once
# the process has fully exited.
#
# Triggered anytime via SUPER + SHIFT + R
# -----------------------------------------------------------------------------

# Stop the current Waybar instance
pkill -x waybar

# Wait until Waybar has fully exited
while pgrep -x waybar >/dev/null; do
    sleep 0.1
done

# Start Waybar again via Hyprland IPC
hyprctl dispatch exec waybar
