#!/usr/bin/env bash
set -e

# Direct installation script for NixOS ephemeral root ZFS
# Can be run directly from GitHub raw URL

# Function to print usage
usage() {
    echo "NixOS Ephemeral Root ZFS Installer"
    echo ""
    echo "Usage: bash <(curl -sL https://raw.githubusercontent.com/USER/REPO/main/install-from-url.sh) <hostname> <disk>"
    echo ""
    echo "Example: bash <(curl -sL ...) myhost /dev/nvme0n1"
    echo ""
    echo "Options:"
    echo "  hostname    System hostname (letters, numbers, hyphens only)"
    echo "  disk        Target disk device (e.g., /dev/nvme0n1, /dev/sda)"
    echo ""
    echo "This will:"
    echo "  - Download the configuration from GitHub"
    echo "  - Partition the disk with ZFS ephemeral root"
    echo "  - Install NixOS with the specified hostname"
    exit 1
}

# Check if running in NixOS installer environment
if [ ! -f /etc/NIXOS ]; then
    echo "Error: This script must be run from a NixOS installer environment"
    echo "Boot from a NixOS minimal ISO first"
    exit 1
fi

# Check arguments
if [ $# -ne 2 ]; then
    usage
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

# Configuration repository
# Update these to match your GitHub repository
GITHUB_USER="${GITHUB_USER:-YourGitHubUser}"
GITHUB_REPO="${GITHUB_REPO:-YourRepoName}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
REPO_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO"
RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$GITHUB_BRANCH"

echo "=== NixOS Ephemeral Root ZFS Installation ==="
echo ""
echo "Configuration:"
echo "  Repository: $REPO_URL"
echo "  Hostname: $HOSTNAME"
echo "  Disk: $DISK"
echo ""
echo "WARNING: This will DESTROY all data on $DISK"
read -r -p "Continue? (yes/no): " confirm
[[ "$confirm" != "yes" ]] && exit 1

# Enable experimental features and performance optimizations
export NIX_CONFIG="experimental-features = nix-command flakes max-jobs = auto cores = 0 substituters = https://cache.nixos.org https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Downloading configuration..."
# Clone the repository (or download files individually for smaller footprint)
if command -v git >/dev/null 2>&1; then
    git clone --depth 1 --branch "$GITHUB_BRANCH" "$REPO_URL" .
else
    # Fallback: download individual files if git is not available
    echo "Git not available, downloading files individually..."
    curl -sL "$RAW_URL/flake.nix" -o flake.nix
    curl -sL "$RAW_URL/configuration.nix" -o configuration.nix
    mkdir -p hardware
    curl -sL "$RAW_URL/hardware/hardware-configuration.nix" -o hardware/hardware-configuration.nix
    curl -sL "$RAW_URL/hardware/disko-config.nix" -o hardware/disko-config.nix
fi

# Get disk ID
DISK_ID=$(find /dev/disk/by-id/ -name "*$(basename "$DISK")" -printf "%f\n" | head -1)
if [ -z "$DISK_ID" ]; then
    echo "Error: Could not find disk ID for $DISK"
    exit 1
fi

echo "Using disk ID: $DISK_ID"

# Replace templates
echo "Configuring for hostname: $HOSTNAME"
if [ -f flake.nix ]; then
    sed -i "s|@HOSTNAME@|$HOSTNAME|g" flake.nix
fi
sed -i "s|@HOSTNAME@|$HOSTNAME|g" configuration.nix
sed -i "s|@DISK_ID@|$DISK_ID|g" hardware/disko-config.nix

# Check if using master flake
if [ -f flake-master.nix ] && grep -q "nixosConfigurations.$HOSTNAME" flake-master.nix; then
    echo "Using master flake configuration for $HOSTNAME"
    mv flake-master.nix flake.nix
fi

# Run disko
echo "Partitioning disk..."
nix run github:nix-community/disko -- --mode disko hardware/disko-config.nix

# Copy configuration
echo "Copying configuration..."
mkdir -p /mnt/etc/nixos
cp -r . /mnt/etc/nixos/

# Create persist directories
echo "Creating persistent directories..."
mkdir -p /mnt/persist/etc/ssh
mkdir -p /mnt/persist/var/lib

# Generate machine-id
echo "Generating machine-id..."
systemd-machine-id-setup --root=/mnt
cp /mnt/etc/machine-id /mnt/persist/etc/

# Install NixOS with optimizations
echo "Installing NixOS with binary cache optimizations..."
nixos-install --flake "/mnt/etc/nixos#$HOSTNAME" --no-root-password \
    --option substituters "https://cache.nixos.org https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org" \
    --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=" \
    --max-jobs auto \
    --cores 0

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Default passwords (change after first login):"
echo "  root: nixos"
echo "  amoon: nixos"
echo "  nixos: nixos"
echo ""
echo "SSH access is enabled with your authorized key."
echo "Network interfaces are configured for DHCP (IPv4 only)."
echo ""
echo "After reboot, you can rebuild remotely with:"
echo "  nixos-rebuild switch --flake github:$GITHUB_USER/$GITHUB_REPO#$HOSTNAME --target-host root@<ip>"
echo ""
echo "Or locally after cloning:"
echo "  sudo nixos-rebuild switch --flake /path/to/repo#$HOSTNAME"
echo ""
echo "Remove installation media and reboot to enter your ephemeral root system."