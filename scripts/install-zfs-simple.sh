#!/usr/bin/env bash
# Simple installation script for NixOS with ZFS

set -e

# Default values
DISK="${DISK:-/dev/nvme0n1}"
HOSTNAME="${HOSTNAME:-minimal-zfs}"
FLAKE="${FLAKE:-github:anthonymoon/zenixv2}"

echo "NixOS ZFS Installation Script"
echo "============================="
echo ""
echo "This will ERASE all data on ${DISK}!"
echo ""
echo "Configuration:"
echo "  Disk: ${DISK}"
echo "  Hostname: ${HOSTNAME}"
echo "  Flake: ${FLAKE}"
echo ""
echo "Press Ctrl+C to abort, or wait 10 seconds to continue..."
sleep 10

echo "Starting installation..."

# Partition disk
echo "Partitioning ${DISK}..."
parted -s "${DISK}" -- mklabel gpt
parted -s "${DISK}" -- mkpart ESP fat32 1MB 512MB
parted -s "${DISK}" -- mkpart primary 512MB 100%
parted -s "${DISK}" -- set 1 esp on

# Wait for partitions
sleep 2

# Format boot partition
echo "Formatting boot partition..."
if [[ -e "${DISK}p1" ]]; then
    mkfs.fat -F 32 -n boot "${DISK}p1"
    BOOT_PART="${DISK}p1"
    ZFS_PART="${DISK}p2"
else
    mkfs.fat -F 32 -n boot "${DISK}1"
    BOOT_PART="${DISK}1"
    ZFS_PART="${DISK}2"
fi

# Create ZFS pool
echo "Creating ZFS pool..."
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
echo "Creating ZFS datasets..."
zfs create -o mountpoint=legacy zroot/root
zfs create -o mountpoint=legacy -o atime=off zroot/nix
zfs create -o mountpoint=legacy zroot/home
zfs create -o mountpoint=legacy -o atime=off zroot/var

# Mount filesystems
echo "Mounting filesystems..."
mount -t zfs zroot/root /mnt
mkdir -p /mnt/{boot,nix,home,var}
mount "${BOOT_PART}" /mnt/boot
mount -t zfs zroot/nix /mnt/nix
mount -t zfs zroot/home /mnt/home
mount -t zfs zroot/var /mnt/var

# Generate hardware configuration
echo "Generating hardware configuration..."
nixos-generate-config --root /mnt

# Install NixOS
echo "Installing NixOS..."
nixos-install --no-root-passwd --flake "${FLAKE}#${HOSTNAME}"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Reboot into your new system: reboot"
echo "2. Set a password for the admin user: passwd admin"
echo "3. Configure your system as needed"