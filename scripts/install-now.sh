#!/usr/bin/env bash
# Non-interactive NixOS ZFS installer
# Run with: curl -sL https://raw.githubusercontent.com/anthonymoon/zenixv2/main/scripts/install-now.sh | bash

set -e

# Configuration
DISK="${DISK:-/dev/nvme0n1}"
HOSTNAME="${HOSTNAME:-nixie}"
FLAKE="${FLAKE:-github:anthonymoon/zenixv2}"

echo "Starting NixOS ZFS installation on ${DISK}..."

# Force non-interactive partitioning
wipefs -af "${DISK}" || true
sgdisk -Z "${DISK}"
sgdisk -n 1:0:+512M -t 1:ef00 "${DISK}"
sgdisk -n 2:0:0 -t 2:bf00 "${DISK}"

# Wait for kernel to recognize partitions
partprobe "${DISK}"
sleep 2

# Determine partition names
if [[ -e "${DISK}p1" ]]; then
    BOOT="${DISK}p1"
    ZFS="${DISK}p2"
else
    BOOT="${DISK}1"
    ZFS="${DISK}2"
fi

# Format boot
mkfs.fat -F32 "${BOOT}"

# Create ZFS pool (force create, no questions)
zpool create -f zroot "${ZFS}"

# Set ZFS properties
zfs set atime=off zroot
zfs set compression=lz4 zroot
zfs set xattr=sa zroot
zfs set acltype=posixacl zroot

# Create datasets
zfs create -o mountpoint=legacy zroot/root
zfs create -o mountpoint=legacy zroot/nix
zfs create -o mountpoint=legacy zroot/home
zfs create -o mountpoint=legacy zroot/var

# Mount everything
mount -t zfs zroot/root /mnt
mkdir -p /mnt/{boot,nix,home,var}
mount "${BOOT}" /mnt/boot
mount -t zfs zroot/nix /mnt/nix
mount -t zfs zroot/home /mnt/home
mount -t zfs zroot/var /mnt/var

# Install
nixos-install --no-root-passwd --flake "${FLAKE}#${HOSTNAME}"

echo "Done! Reboot and set admin password."