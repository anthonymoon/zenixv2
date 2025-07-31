#!/usr/bin/env bash
# Disko installation with bind mount to avoid tmpfs space issues

set -euo pipefail

CONFIG_NAME="${1:-workstation.kde.stable}"
DISK="${2:-/dev/sda}"

echo "Disko Installation with Bind Mount"
echo "=================================="
echo "Configuration: $CONFIG_NAME"
echo "Disk: $DISK"
echo ""

# Step 1: Partition and format the disk
echo "Step 1: Partitioning disk..."
sudo nix run github:nix-community/disko -- \
  --mode disko \
  --flake "github:anthonymoon/nixos-fun#$CONFIG_NAME" \
  --arg device "\"$DISK\""

# Step 2: Check if /mnt/nix exists
echo ""
echo "Step 2: Setting up bind mount for nix store..."
if [[ ! -d /mnt/nix ]]; then
    echo "Creating /mnt/nix directory..."
    sudo mkdir -p /mnt/nix
fi

# Step 3: Bind mount /nix to /mnt/nix to use disk space instead of RAM
echo "Bind mounting /nix to use disk space..."
sudo mkdir -p /mnt/nix/store
sudo mkdir -p /mnt/nix/var

# Copy existing nix store content if needed
if [[ -d /nix/store ]] && [[ ! -L /nix/store ]]; then
    echo "Moving existing nix store to disk..."
    sudo cp -a /nix/store/* /mnt/nix/store/ 2>/dev/null || true
    sudo cp -a /nix/var/* /mnt/nix/var/ 2>/dev/null || true
fi

# Create bind mounts
sudo mount --bind /mnt/nix/store /nix/store
sudo mount --bind /mnt/nix/var /nix/var

# Step 4: Configure nix settings
echo ""
echo "Step 4: Configuring nix settings..."
sudo tee /etc/nix/nix.conf << 'EOF'
substituters = https://cache.nixos.org http://cachy.local
trusted-substituters = http://cachy.local
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc=
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
# Use less memory during builds
gc-reserved-space = 1073741824
EOF

# Also create config in target system
sudo mkdir -p /mnt/etc/nix
sudo cp /etc/nix/nix.conf /mnt/etc/nix/

# Step 5: Clean up any garbage
echo ""
echo "Step 5: Cleaning up to free space..."
sudo nix-collect-garbage -d

# Step 6: Run the installation
echo ""
echo "Step 6: Running NixOS installation..."
sudo nixos-install \
  --flake "github:anthonymoon/nixos-fun#$CONFIG_NAME" \
  --no-channel-copy

echo ""
echo "Installation complete!"
echo ""
echo "NOTE: The system is installed. Set the root password when prompted."
echo "After setting the password, you can reboot into your new system."