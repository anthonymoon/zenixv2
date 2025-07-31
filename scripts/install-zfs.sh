#!/usr/bin/env bash
# Installation script for NixOS with ZFS using disko

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DISK="${DISK:-/dev/nvme0n1}"
HOSTNAME="${HOSTNAME:-minimal-zfs}"
FLAKE="${FLAKE:-github:anthonymoon/zenixv2}"

echo -e "${GREEN}NixOS ZFS Installation Script${NC}"
echo -e "${YELLOW}This will ERASE all data on ${DISK}!${NC}"
echo ""
echo "Configuration:"
echo "  Disk: ${DISK}"
echo "  Hostname: ${HOSTNAME}"
echo "  Flake: ${FLAKE}"
echo ""
read -p "Continue? (yes/no) " -n 3 -r
echo

if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Aborting installation."
    exit 1
fi

# Method 1: Using disko directly (if available)
if command -v nix >/dev/null 2>&1 && nix flake show "${FLAKE}" 2>/dev/null | grep -q disko; then
    echo -e "${GREEN}Using disko for disk configuration...${NC}"
    
    # Format disk with disko
    nix run github:nix-community/disko -- \
        --mode disko \
        --flake "${FLAKE}#${HOSTNAME}" \
        --arg device "\"${DISK}\""
    
    # Install NixOS
    echo -e "${GREEN}Installing NixOS...${NC}"
    nixos-install --no-root-passwd --flake "${FLAKE}#${HOSTNAME}"
    
else
    # Method 2: Manual partitioning (fallback)
    echo -e "${YELLOW}Disko not available, using manual partitioning...${NC}"
    
    # Partition disk
    echo -e "${GREEN}Partitioning ${DISK}...${NC}"
    parted "${DISK}" -- mklabel gpt
    parted "${DISK}" -- mkpart ESP fat32 1MB 512MB
    parted "${DISK}" -- mkpart primary 512MB 100%
    parted "${DISK}" -- set 1 esp on
    
    # Wait for partitions
    sleep 2
    
    # Format boot partition
    echo -e "${GREEN}Formatting boot partition...${NC}"
    mkfs.fat -F 32 -n boot "${DISK}p1" || mkfs.fat -F 32 -n boot "${DISK}1"
    
    # Determine ZFS partition
    if [[ -e "${DISK}p2" ]]; then
        ZFS_PART="${DISK}p2"
    else
        ZFS_PART="${DISK}2"
    fi
    
    # Create ZFS pool
    echo -e "${GREEN}Creating ZFS pool...${NC}"
    zpool create -f \
        -o ashift=12 \
        -o autotrim=on \
        -O acltype=posixacl \
        -O compression=lz4 \
        -O atime=off \
        -O xattr=sa \
        -O mountpoint=none \
        zroot "${ZFS_PART}"
    
    # Create datasets
    echo -e "${GREEN}Creating ZFS datasets...${NC}"
    zfs create -o mountpoint=legacy zroot/root
    zfs create -o mountpoint=legacy -o atime=off zroot/nix
    zfs create -o mountpoint=legacy zroot/home
    zfs create -o mountpoint=legacy -o atime=off zroot/var
    
    # Mount filesystems
    echo -e "${GREEN}Mounting filesystems...${NC}"
    mount -t zfs zroot/root /mnt
    mkdir -p /mnt/{boot,nix,home,var}
    
    # Mount boot
    if [[ -e "${DISK}p1" ]]; then
        mount "${DISK}p1" /mnt/boot
    else
        mount "${DISK}1" /mnt/boot
    fi
    
    # Mount other datasets
    mount -t zfs zroot/nix /mnt/nix
    mount -t zfs zroot/home /mnt/home
    mount -t zfs zroot/var /mnt/var
    
    # Generate hardware configuration
    echo -e "${GREEN}Generating hardware configuration...${NC}"
    nixos-generate-config --root /mnt
    
    # Install NixOS
    echo -e "${GREEN}Installing NixOS...${NC}"
    nixos-install --no-root-passwd --flake "${FLAKE}#${HOSTNAME}"
fi

echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Reboot into your new system"
echo "2. Set a password for the admin user: passwd admin"
echo "3. Configure your system as needed"
echo ""
echo "To reboot now, run: reboot"