#!/usr/bin/env bash
set -e

# Installation script for ephemeral root NixOS with ZFS - Virtual disk support

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <hostname> <disk>"
    echo "Example: $0 myhost /dev/vda"
    exit 1
fi

HOSTNAME="$1"
DISK="$2"

# Validate inputs
if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "Error: Invalid hostname. Use only letters, numbers, and hyphens."
    exit 1
fi

if [[ ! -b "$DISK" ]]; then
    echo "Error: $DISK is not a block device"
    exit 1
fi

echo "=== NixOS Ephemeral Root ZFS Installation ==="
echo
echo "Configuration:"
echo "  Hostname: $HOSTNAME"
echo "  Username: amoon (hardcoded)"
echo "  Disk: $DISK"
echo
echo "This will create a system where root (/) is wiped on every boot."
echo "Only /home, /nix, /persist, /var/log, /var/lib, and /etc/nixos persist."
echo
echo "WARNING: This will DESTROY all data on $DISK"
read -r -p "Continue? (yes/no): " confirm
[[ "$confirm" != "yes" ]] && exit 1

# Get disk ID - handle virtual disks
if [[ "$DISK" == "/dev/vda" ]] || [[ "$DISK" == "/dev/vdb" ]]; then
    # For virtual disks, use by-path
    DISK_ID=$(find /dev/disk/by-path/ -name "virtio-*" -not -name "*-part*" -printf "%f\n" | head -1)
    if [ -z "$DISK_ID" ]; then
        # Fallback to direct device
        echo "Warning: Could not find disk ID, using device path directly"
        DISK_ID="../..$(basename "$DISK")"
    fi
else
    # For physical disks, use by-id
    DISK_ID=$(find /dev/disk/by-id/ -name "*$(basename "$DISK")" -printf "%f\n" | head -1)
    if [ -z "$DISK_ID" ]; then
        echo "Error: Could not find disk ID for $DISK"
        exit 1
    fi
fi

echo "Using disk ID: $DISK_ID"

# Create temporary directory for template processing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Copy all files to temp directory
cp -r . "$TEMP_DIR/"

# Replace templates in configuration files
echo "Processing templates..."
sed -i "s|@HOSTNAME@|$HOSTNAME|g" "$TEMP_DIR/configuration.nix"

# For virtual disks, modify disko config to use direct path
if [[ "$DISK" == "/dev/vda" ]] || [[ "$DISK" == "/dev/vdb" ]]; then
    sed -i "s|/dev/disk/by-id/@DISK_ID@|$DISK|g" "$TEMP_DIR/hardware/disko-common.nix"
else
    sed -i "s|@DISK_ID@|$DISK_ID|g" "$TEMP_DIR/hardware/disko-common.nix"
fi

# Update flake.nix to use the hostname
sed -i "s|@HOSTNAME@|$HOSTNAME|g" "$TEMP_DIR/flake.nix"

# Run disko
echo "Partitioning disk..."
nix run github:nix-community/disko -- --mode disko "$TEMP_DIR/hardware/disko-common.nix"

# Copy configuration
echo "Copying configuration..."
mkdir -p /mnt/etc/nixos
cp -r "$TEMP_DIR"/* /mnt/etc/nixos/

# Create persist directories
echo "Creating persistent directories..."
mkdir -p /mnt/persist/etc/ssh
mkdir -p /mnt/persist/var/lib/NetworkManager

# Generate machine-id
echo "Generating machine-id..."
systemd-machine-id-setup --root=/mnt
cp /mnt/etc/machine-id /mnt/persist/etc/

# Generate hardware config if needed
echo "Generating hardware configuration..."
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hardware/generated.nix || true

# Install
echo "Installing NixOS..."
nixos-install --flake "/mnt/etc/nixos#${HOSTNAME}" --no-root-password

echo
echo "Installation complete!"
echo "Default passwords: root:nixos, amoon:nixos, nixos:nixos"
echo "Then reboot to enter your ephemeral root system."