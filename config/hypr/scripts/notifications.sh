#!/bin/bash

count=$(swaync-client -c 2>/dev/null)

if [ -z "$count" ] || [ "$count" = "0" ]; then
    echo ""
else
    echo "• $count notifications"
fi
