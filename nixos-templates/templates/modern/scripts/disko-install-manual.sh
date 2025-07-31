#!/usr/bin/env bash
# Manual disko installation script to avoid space issues

set -euo pipefail

CONFIG_NAME="${1:-workstation.kde.stable}"
DISK="${2:-/dev/sda}"

echo "Manual Disko Installation"
echo "========================"
echo "Configuration: $CONFIG_NAME"
echo "Disk: $DISK"
echo ""

# Step 1: Partition and format the disk with disko
echo "Step 1: Partitioning disk with disko..."
sudo nix run github:nix-community/disko -- \
  --mode disko \
  --flake "github:anthonymoon/nixos-fun#$CONFIG_NAME" \
  --arg device "\"$DISK\""

# Step 2: Ensure everything is mounted
echo ""
echo "Step 2: Checking mounts..."
mount | grep /mnt

# Step 3: Clear tmpfs space by cleaning up
echo ""
echo "Step 3: Cleaning up tmpfs to free space..."
sudo nix-collect-garbage -d
sudo rm -rf /tmp/*

# Step 4: Create minimal nix.conf in the target system
echo ""
echo "Step 4: Setting up nix.conf in target system..."
sudo mkdir -p /mnt/etc/nix
sudo tee /mnt/etc/nix/nix.conf << 'EOF'
substituters = https://cache.nixos.org http://cachy.local
trusted-substituters = http://cachy.local
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc=
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
EOF

# Step 5: Install NixOS with explicit store path
echo ""
echo "Step 5: Installing NixOS to /mnt..."
sudo nixos-install \
  --flake "github:anthonymoon/nixos-fun#$CONFIG_NAME" \
  --no-channel-copy \
  --option substituters "https://cache.nixos.org http://cachy.local" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc="

echo ""
echo "Installation complete! You can now reboot into your new system."
echo "Don't forget to set the root password if prompted!"