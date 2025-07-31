#!/usr/bin/env bash
# NixOS ZFS root installation script for 25.11pre

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
DISK="${1:-/dev/nvme0n1}"  # Default disk, can be overridden
POOL_NAME="zpool"
SWAP_SIZE="16G"  # Adjust based on your RAM
BOOT_SIZE="1G"

echo -e "${GREEN}NixOS ZFS Root Installation Script${NC}"
echo -e "${YELLOW}Target disk: $DISK${NC}"
echo -e "${RED}WARNING: This will DESTROY all data on $DISK${NC}"
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    exit 1
fi

# Partition the disk
echo -e "${GREEN}Creating partitions...${NC}"
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB "${BOOT_SIZE}"
parted "$DISK" -- mkpart primary "${BOOT_SIZE}" 100%
parted "$DISK" -- set 1 esp on

# Wait for partitions to appear
sleep 2

# Format boot partition
echo -e "${GREEN}Formatting boot partition...${NC}"
mkfs.fat -F 32 -n BOOT "${DISK}p1" || mkfs.fat -F 32 -n BOOT "${DISK}1"

# Create ZFS pool
echo -e "${GREEN}Creating ZFS pool...${NC}"
ZDEV="${DISK}p2"
[[ ! -e "$ZDEV" ]] && ZDEV="${DISK}2"

zpool create -f \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O compression=zstd \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O mountpoint=none \
    "$POOL_NAME" \
    "$ZDEV"

# Create datasets
echo -e "${GREEN}Creating ZFS datasets...${NC}"

# Root dataset
zfs create -o mountpoint=none "$POOL_NAME/root"
zfs create -o mountpoint=legacy "$POOL_NAME/root/nixos"

# Home dataset
zfs create -o mountpoint=legacy "$POOL_NAME/home"

# Nix store dataset (optional but recommended)
zfs create -o mountpoint=legacy -o atime=off "$POOL_NAME/nix"

# Reserved dataset to ensure pool isn't completely filled
zfs create -o mountpoint=none -o reservation=1G "$POOL_NAME/reserved"

# Swap zvol (optional)
echo -e "${GREEN}Creating swap zvol...${NC}"
zfs create -V "$SWAP_SIZE" -b $(getconf PAGESIZE) \
    -o compression=zle \
    -o logbias=throughput \
    -o sync=always \
    -o primarycache=metadata \
    -o secondarycache=none \
    -o com.sun:auto-snapshot=false \
    "$POOL_NAME/swap"

# Format swap
mkswap -f "/dev/zvol/$POOL_NAME/swap"

# Mount filesystems
echo -e "${GREEN}Mounting filesystems...${NC}"
mount -t zfs "$POOL_NAME/root/nixos" /mnt
mkdir -p /mnt/{boot,home,nix}
mount "${DISK}p1" /mnt/boot || mount "${DISK}1" /mnt/boot
mount -t zfs "$POOL_NAME/home" /mnt/home
mount -t zfs "$POOL_NAME/nix" /mnt/nix

# Enable swap
swapon "/dev/zvol/$POOL_NAME/swap"

# Generate hardware configuration
echo -e "${GREEN}Generating NixOS configuration...${NC}"
nixos-generate-config --root /mnt

# Get host ID
HOST_ID=$(head -c 8 /etc/machine-id)
echo -e "${YELLOW}Generated hostId: $HOST_ID${NC}"

# Create custom configuration
echo -e "${GREEN}Creating custom configuration...${NC}"
cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot configuration
  boot = {
    # Use ZFS-compatible kernel
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };

    kernelParams = [
      "zfs.zfs_arc_max=8589934592" # 8GB ARC max
    ];

    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      forceImportAll = false;
    };
  };

  # Networking
  networking = {
    hostName = "nixos";
    hostId = "$HOST_ID";
    networkmanager.enable = true;
  };

  # Time zone
  time.timeZone = "UTC"; # Change this

  # ZFS services
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    htop
    zfs
  ];

  # Users
  users.users.root.initialPassword = "nixos";
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
  };

  # Enable SSH
  services.openssh.enable = true;

  # System state version
  system.stateVersion = "25.11";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
EOF

# Show final instructions
echo -e "${GREEN}Configuration complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and edit /mnt/etc/nixos/configuration.nix"
echo "2. Run: nixos-install"
echo "3. After installation, change all default passwords!"
echo ""
echo -e "${YELLOW}ZFS pool information:${NC}"
zpool status "$POOL_NAME"
echo ""
echo -e "${YELLOW}Mounted filesystems:${NC}"
findmnt -t zfs,vfat -R /mnt