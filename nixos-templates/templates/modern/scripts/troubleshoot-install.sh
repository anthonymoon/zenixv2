#!/usr/bin/env bash
# NixOS installation troubleshooting script

echo "NixOS Installation Troubleshooting"
echo "=================================="
echo ""

# 1. Check disk partitions
echo "1. Disk Partitions:"
echo "-------------------"
lsblk -f
echo ""

# 2. Check if filesystems are mounted
echo "2. Current Mounts:"
echo "------------------"
mount | grep -E "/mnt|/dev/sd|/dev/nvme" | sort
echo ""

# 3. Check available space
echo "3. Disk Space:"
echo "--------------"
df -h | grep -E "Filesystem|/mnt|tmpfs|overlay"
echo ""

# 4. Check nix store status
echo "4. Nix Store Status:"
echo "--------------------"
if [[ -d /mnt/nix/store ]]; then
    echo "Mounted nix store size: $(du -sh /mnt/nix/store 2>/dev/null | cut -f1)"
    echo "Number of store paths: $(find /mnt/nix/store -maxdepth 1 -type d | wc -l)"
else
    echo "No nix store found at /mnt/nix/store"
fi
echo ""

# 5. Check network and cache connectivity
echo "5. Network & Cache Status:"
echo "--------------------------"
echo "Testing connectivity..."
ping -c 1 cache.nixos.org &>/dev/null && echo "✓ cache.nixos.org reachable" || echo "✗ cache.nixos.org unreachable"
ping -c 1 cachy.local &>/dev/null && echo "✓ cachy.local reachable" || echo "✗ cachy.local unreachable"

if curl -s -o /dev/null -w "%{http_code}" http://cachy.local/nix-cache-info 2>/dev/null | grep -q 200; then
    echo "✓ cachy.local cache responding"
else
    echo "✗ cachy.local cache not responding"
fi
echo ""

# 6. Check nix configuration
echo "6. Nix Configuration:"
echo "---------------------"
echo "Current /etc/nix/nix.conf:"
if [[ -f /etc/nix/nix.conf ]]; then
    cat /etc/nix/nix.conf | grep -v "^#" | grep -v "^$"
else
    echo "No nix.conf found"
fi
echo ""
echo "Target /mnt/etc/nix/nix.conf:"
if [[ -f /mnt/etc/nix/nix.conf ]]; then
    cat /mnt/etc/nix/nix.conf | grep -v "^#" | grep -v "^$"
else
    echo "No target nix.conf found"
fi
echo ""

# 7. Check for common errors in journal
echo "7. Recent Install Errors:"
echo "-------------------------"
sudo journalctl -b -p err -n 20 --no-pager | grep -E "nix|install|disk|mount|space" || echo "No recent errors found"
echo ""

# 8. Manual recovery commands
echo "8. Recovery Commands:"
echo "---------------------"
echo "If installation failed after partitioning:"
echo "  # Mount existing partitions:"
echo "  sudo mount /dev/sda3 /mnt  # Adjust device as needed"
echo "  sudo mount /dev/sda1 /mnt/boot"
echo ""
echo "  # Continue installation:"
echo "  sudo nixos-install --flake github:anthonymoon/nixos-fun#workstation.kde.stable"
echo ""
echo "If out of space during install:"
echo "  # Clean up:"
echo "  sudo nix-collect-garbage -d"
echo "  sudo rm -rf /tmp/*"
echo ""
echo "  # Use bind mount to avoid tmpfs:"
echo "  sudo mkdir -p /mnt/nix/store /mnt/nix/var"
echo "  sudo mount --bind /mnt/nix/store /nix/store"
echo "  sudo mount --bind /mnt/nix/var /nix/var"
echo ""
echo "To manually partition with disko:"
echo "  sudo nix run github:nix-community/disko -- \\"
echo "    --mode disko \\"
echo "    --flake github:anthonymoon/nixos-fun#default \\"
echo "    --arg device '\"/dev/sda\"'"
echo ""
echo "To check what disko will do (dry run):"
echo "  sudo nix run github:nix-community/disko -- \\"
echo "    --mode disko \\"
echo "    --dry-run \\"
echo "    --flake github:anthonymoon/nixos-fun#default"