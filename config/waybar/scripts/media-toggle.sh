#!/bin/bash
if pgrep -f media-popup.py > /dev/null; then
    pkill -f media-popup.py
else
    python3 ~/.config/waybar/scripts/media-popup.py &
fi
