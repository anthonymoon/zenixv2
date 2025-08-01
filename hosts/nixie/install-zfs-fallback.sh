#!/usr/bin/env bash
set -euo pipefail

# Fallback ZFS installation script for nixie
# Based on optimized ZFS configuration

DISK="/dev/nvme0n1"
HOSTNAME="nixie"
POOL="rpool"

echo "=== ZFS Fallback Installation Script ==="
echo "Target disk: $DISK"
echo "Hostname: $HOSTNAME"
echo "Pool name: $POOL"
echo ""
echo "WARNING: This will destroy all data on $DISK!"
read -p "Continue? (yes/no): " confirm
[[ "$confirm" != "yes" ]] && exit 1

# Partition the disk
echo "Creating partitions..."
parted -s "$DISK" -- mklabel gpt
parted -s "$DISK" -- mkpart ESP fat32 1MB 513MB
parted -s "$DISK" -- set 1 esp on
parted -s "$DISK" -- mkpart primary 513MB 100%

# Format EFI partition
echo "Formatting EFI partition..."
mkfs.fat -F32 -n EFI "${DISK}p1"

# Create ZFS pool with optimized settings
echo "Creating ZFS pool..."
zpool create -f \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=zstd \
    -O acltype=posixacl \
    -O atime=off \
    -O xattr=sa \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O canmount=off \
    -O mountpoint=none \
    -R /mnt \
    "$POOL" "${DISK}p2"

# Create datasets with optimized settings
echo "Creating datasets..."

# Root dataset
zfs create -o mountpoint=legacy -o recordsize=128k "$POOL/root"

# Home dataset with deduplication
zfs create -o mountpoint=legacy -o recordsize=128k -o dedup=on "$POOL/home"

# Nix dataset with optimizations for package storage
zfs create -o mountpoint=legacy -o atime=off -o sync=disabled \
    -o dedup=on -o redundant_metadata=most "$POOL/nix"

# Var dataset
zfs create -o mountpoint=legacy -o recordsize=128k "$POOL/var"

# Var/lib dataset for databases
zfs create -o mountpoint=legacy -o recordsize=16k "$POOL/var/lib"

# Docker dataset with large recordsize
zfs create -o mountpoint=legacy -o recordsize=1M -o dedup=off "$POOL/var/lib/docker"

# Log dataset optimized for write throughput
zfs create -o mountpoint=legacy -o recordsize=128k -o logbias=throughput \
    -o dedup=off "$POOL/var/log"

# Libvirt dataset for VMs
zfs create -o mountpoint=legacy -o recordsize=1M -o compression=off \
    -o dedup=off "$POOL/var/lib/libvirt"

# Tmp dataset with fast compression
zfs create -o mountpoint=legacy -o sync=disabled -o compression=lz4 \
    -o dedup=off "$POOL/tmp"

# Mount filesystems
echo "Mounting filesystems..."
mount -t zfs "$POOL/root" /mnt

# Create mount points
mkdir -p /mnt/{boot,home,nix,var,tmp}
mkdir -p /mnt/var/{lib,log}
mkdir -p /mnt/var/lib/{docker,libvirt}

# Mount all datasets
mount "${DISK}p1" /mnt/boot
mount -t zfs "$POOL/home" /mnt/home
mount -t zfs "$POOL/nix" /mnt/nix
mount -t zfs "$POOL/var" /mnt/var
mount -t zfs "$POOL/var/lib" /mnt/var/lib
mount -t zfs "$POOL/var/lib/docker" /mnt/var/lib/docker
mount -t zfs "$POOL/var/log" /mnt/var/log
mount -t zfs "$POOL/var/lib/libvirt" /mnt/var/lib/libvirt
mount -t zfs "$POOL/tmp" /mnt/tmp

# Set permissions on tmp
chmod 1777 /mnt/tmp

# Generate hardware configuration
echo "Generating NixOS configuration..."
nixos-generate-config --root /mnt

# Get the host ID for ZFS
HOST_ID=$(head -c 8 /etc/machine-id)

# Update hardware configuration with ZFS settings
cat >> /mnt/etc/nixos/hardware-configuration.nix << EOF

  # Network configuration for ZFS
  networking.hostId = "$HOST_ID"; # Required for ZFS

  # Enable UEFI boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  
  # Kernel modules for ZFS
  boot.initrd.kernelModules = [ "zfs" ];
EOF

echo ""
echo "=== Installation preparation complete! ==="
echo ""
echo "Next steps:"
echo "1. Copy your flake configuration to /mnt/etc/nixos/"
echo "2. Run: nixos-install --flake /mnt/etc/nixos#nixie"
echo ""
echo "To verify ZFS setup:"
echo "  zpool status"
echo "  zfs list"
echo "  mount | grep zfs"