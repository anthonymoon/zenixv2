#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
DISK="${1:-}"
HOST="${2:-zfs-physical}"
SWAP_SIZE="${SWAP_SIZE:-8G}"

# Help function
usage() {
    cat << EOF
Usage: $0 <disk> [host]

Install NixOS with ZFS root filesystem on GPT with FAT32 ESP.

Arguments:
  disk    Target disk (e.g., /dev/sda, /dev/nvme0n1)
  host    Configuration to install (default: zfs-physical)
          Options: zfs-physical, zfs-vm

Environment variables:
  SWAP_SIZE   Size of swap zvol (default: 8G, set to 0 to disable)

Examples:
  # Physical machine
  $0 /dev/sda

  # Virtual machine
  $0 /dev/vda zfs-vm

  # No swap
  SWAP_SIZE=0 $0 /dev/sda
EOF
}

# Validation
if [[ -z "$DISK" ]]; then
    echo -e "${RED}Error: No disk specified${NC}"
    usage
    exit 1
fi

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Error: $DISK is not a block device${NC}"
    exit 1
fi

# Confirmation
echo -e "${YELLOW}WARNING: This will DESTROY all data on $DISK${NC}"
echo -e "Installing configuration: ${GREEN}$HOST${NC}"
echo -e "Swap size: ${GREEN}${SWAP_SIZE}${NC}"
echo
read -p "Continue? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Detect if running in live environment
if [[ ! -d /mnt ]]; then
    echo -e "${RED}Error: /mnt not found. Are you running from NixOS installer ISO?${NC}"
    exit 1
fi

# Clean up any existing ZFS pools
echo -e "${GREEN}Cleaning up existing configurations...${NC}"
umount -R /mnt 2>/dev/null || true
zpool export -a 2>/dev/null || true

# Wipe disk
echo -e "${GREEN}Wiping disk...${NC}"
wipefs -af "$DISK"
sgdisk -Z "$DISK"
partprobe "$DISK"
sleep 2

# Run partitioning
echo -e "${GREEN}Partitioning disk...${NC}"
nix run github:nix-community/disko -- \
    --mode disko \
    --flake ".#$HOST" \
    --arg device "\"$DISK\""

# Create swap if requested
if [[ "$SWAP_SIZE" != "0" ]]; then
    echo -e "${GREEN}Creating swap zvol...${NC}"
    zfs create -V "$SWAP_SIZE" -b $(getconf PAGESIZE) \
        -o compression=zle \
        -o logbias=throughput \
        -o sync=always \
        -o primarycache=metadata \
        -o secondarycache=none \
        -o com.sun:auto-snapshot=false \
        zroot/swap
    
    mkswap /dev/zvol/zroot/swap
    swapon /dev/zvol/zroot/swap
fi

# Generate hardware configuration
echo -e "${GREEN}Generating hardware configuration...${NC}"
nixos-generate-config --root /mnt

# Install NixOS
echo -e "${GREEN}Installing NixOS...${NC}"
nixos-install --root /mnt --flake ".#$HOST" --no-root-passwd

# Set up initial snapshot
echo -e "${GREEN}Creating initial snapshot...${NC}"
zfs snapshot -r zroot@fresh-install

echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Next steps:"
echo "1. Reboot into your new system"
echo "2. Change the password for user 'nixos'"
echo "3. Add your SSH key to the configuration"
echo "4. Rebuild with: nixos-rebuild switch --flake .#$HOST"
echo
echo "ZFS commands:"
echo "  zfs list              - List all datasets"
echo "  zfs list -t snapshot  - List all snapshots"
echo "  zpool status          - Check pool health"