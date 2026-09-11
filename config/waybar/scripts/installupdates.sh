#!/usr/bin/env bash

AUR=yay
if command -v paru >/dev/null 2>&1; then
    AUR=paru
fi

echo "Pacman updates list:"
checkupdates 2>/dev/null || echo "None"
echo "AUR updates list:"
"$AUR" -Qua 2>/dev/null || echo "None"

read -n1 -rep 'Download and install updates? (y/n) ' UPD
echo
if [[ $UPD == "Y" || $UPD == "y" ]]; then
    "$AUR" -Syu
fi