#!/usr/bin/env bash
# Based on Mr. Cejas's blog: https://fernandocejas.com/blog/engineering/2022-03-30-arch-linux-system-maintance/

echo "=== System Maintenance ==="
echo ""

echo "→ Updating system..."
yay -Syu

echo ""
echo "→ Clearing pacman cache..."
pacman_cache_space_used="$(du -sh /var/cache/pacman/pkg/)"
sudo paccache -r
echo "Space saved: $pacman_cache_space_used"

echo ""
echo "→ Removing orphan packages..."
orphans=$(yay -Qdtq 2>/dev/null) || true
if [ -n "$orphans" ]; then
    echo "$orphans" | yay -Rns -
else
    echo "No orphans found."
fi

echo ""
echo "→ Clearing ~/.cache..."
home_cache_used="$(du -sh ~/.cache 2>/dev/null || echo 'N/A')"
read -n1 -rep "Delete ~/.cache? This removes ALL application caches. (y/n) " CONFIRM
echo ""
if [[ "$CONFIRM" == "Y" || "$CONFIRM" == "y" ]]; then
    rm -rf ~/.cache/
    echo "Cleared. Previous usage: $home_cache_used"
else
    echo "Skipped."
fi

echo ""
echo "→ Clearing system logs (older than 7 days)..."
sudo journalctl --vacuum-time=7d

echo ""
echo "✓ Maintenance complete!"
echo ""
echo "Press any key to close."
read -n1
