#!/bin/bash
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-system-popup"
STATE_FILE="$RUNTIME_DIR/state"
PID_FILE="$RUNTIME_DIR/popup.pid"

is_open=0

if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE" 2>/dev/null)" = "1" ]; then
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        # Verify process is running and is our system-popup.py
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null && grep -q "system-popup.py" "/proc/$PID/cmdline" 2>/dev/null; then
            is_open=1
        else
            # Auto-recovery from ungraceful termination (e.g. SIGKILL): reset state
            echo "0" > "$STATE_FILE" 2>/dev/null
            rm -f "$PID_FILE" 2>/dev/null
        fi
    else
        echo "0" > "$STATE_FILE" 2>/dev/null
    fi
fi

if [ "$is_open" -eq 1 ]; then
    echo '{"text": "", "class": "open"}'
else
    echo '{"text": "", "class": "closed"}'
fi
