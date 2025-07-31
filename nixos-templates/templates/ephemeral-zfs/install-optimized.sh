#!/usr/bin/env bash
set -e

# Optimized installation script with Cachix support
# Significantly faster installation through binary caches

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <hostname> <disk>"
    echo "Example: $0 myhost /dev/nvme0n1"
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

echo "=== NixOS Ephemeral Root ZFS Installation (Optimized) ==="
echo
echo "Configuration:"
echo "  Hostname: $HOSTNAME"
echo "  Username: amoon (hardcoded)"
echo "  Disk: $DISK"
echo
echo "This installation is optimized with:"
echo "  ✓ Cachix binary caches"
echo "  ✓ Parallel downloads"
echo "  ✓ Multi-core builds"
echo
echo "WARNING: This will DESTROY all data on $DISK"
read -r -p "Continue? (yes/no): " confirm
[[ "$confirm" != "yes" ]] && exit 1

# Configure Nix for optimal performance during installation
echo "Configuring Nix for optimal performance..."
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
substituters = https://cache.nixos.org https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=
connect-timeout = 5
download-attempts = 3
EOF

# Also export for current session
NIX_CONFIG=$(tr '\n' ' ' < ~/.config/nix/nix.conf)
export NIX_CONFIG

# Get disk ID
DISK_ID=$(find /dev/disk/by-id/ -name "*$(basename "$DISK")" -printf "%f\n" | head -1)
if [ -z "$DISK_ID" ]; then
    echo "Error: Could not find disk ID for $DISK"
    exit 1
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
sed -i "s|@DISK_ID@|$DISK_ID|g" "$TEMP_DIR/hardware/disko-common.nix"

# Update flake.nix to use the hostname
sed -i "s|@HOSTNAME@|$HOSTNAME|g" "$TEMP_DIR/flake.nix"

# Run disko with progress
echo "Partitioning disk..."
echo "This may take a few minutes..."
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

# Pre-download popular packages to speed up installation
echo "Pre-fetching common packages..."
nix-store -r "$(nix-instantiate '<nixpkgs>' -A \
    stdenv \
    bash \
    coreutils \
    systemd \
    zfs \
    linux \
    2>/dev/null | head -20)" \
    --option substituters "https://cache.nixos.org https://nix-community.cachix.org" \
    2>/dev/null || true

# Install with optimizations
echo "Installing NixOS with optimizations..."
echo "This will download packages from binary caches when available."
nixos-install --flake "/mnt/etc/nixos#${HOSTNAME}" --no-root-password \
    --option substituters "https://cache.nixos.org https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org" \
    --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=" \
    --max-jobs auto \
    --cores 0

echo
echo "=== Installation Complete! ==="
echo
echo "Performance optimizations applied:"
echo "  ✓ Cachix binary caches configured"
echo "  ✓ Parallel downloads enabled"
echo "  ✓ Multi-core builds enabled"
echo
echo "Default passwords (change immediately):"
echo "  root: nixos"
echo "  amoon: nixos"
echo "  nixos: nixos"
echo
echo "Your system will use binary caches for faster updates."
echo "Remove installation media and reboot."