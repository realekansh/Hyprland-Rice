#!/bin/bash
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-system-popup"
mkdir -p -m 700 "$RUNTIME_DIR" 2>/dev/null
PID_FILE="$RUNTIME_DIR/popup.pid"
SCRIPT="$HOME/.config/waybar/scripts/system-popup.py"

# If PID file exists and process is alive and is system-popup.py, signal it to toggle/close
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        if grep -q "system-popup.py" "/proc/$PID/cmdline" 2>/dev/null; then
            kill -USR1 "$PID" 2>/dev/null
            exit 0
        fi
    fi
    # If process was dead (crash / stale), clean up stale PID file
    rm -f "$PID_FILE" 2>/dev/null
fi

# Fresh start: launch system-popup.py
python3 "$SCRIPT" &
