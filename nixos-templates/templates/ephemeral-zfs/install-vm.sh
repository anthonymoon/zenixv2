#!/usr/bin/env bash
set -e

# Installation script for ephemeral root NixOS with ZFS - VM-specific version

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

echo "=== NixOS Ephemeral Root ZFS Installation (VM) ==="
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

# Create temporary directory for template processing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT EXIT

# Copy all files to temp directory
cp -r . "$TEMP_DIR/"

# Use unified configuration with VM environment variable
echo "Using unified configuration with VM detection..."
export NIXOS_VM=1

# Replace templates in configuration files
echo "Processing templates..."
sed -i "s|@HOSTNAME@|$HOSTNAME|g" "$TEMP_DIR/configuration.nix"

# Update flake.nix to use the hostname
sed -i "s|@HOSTNAME@|$HOSTNAME|g" "$TEMP_DIR/flake.nix"

# Run disko with VM config directly (no disk ID replacement needed)
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

# Install with Cachix optimization
echo "Installing NixOS with Cachix optimization..."
nixos-install \
  --flake "/mnt/etc/nixos#test-vm" \
  --no-root-password \
  --option substituters "https://cache.nixos.org https://nix-community.cachix.org" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

echo
echo "Installation complete!"
echo "Default passwords: root:nixos, amoon:nixos, nixos:nixos"
echo "Then reboot to enter your ephemeral root system."