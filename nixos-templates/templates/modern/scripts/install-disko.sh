#!/usr/bin/env bash
# Disko installation wrapper script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
FLAKE_DIR="/mnt/etc/nixos"
DRY_RUN=false
MODE=""

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS] HOSTNAME

Install NixOS using disko with a flake configuration.

OPTIONS:
    -f, --flake-dir PATH    Path to flake directory (default: /mnt/etc/nixos)
    -d, --dry-run          Show what would be done without executing
    -m, --mode MODE        Force disk mode instead of auto-detection
    -h, --help             Show this help message

MODES:
    btrfs-single    Btrfs single disk (no encryption)
    btrfs-luks      Btrfs with LUKS2 encryption
    zfs-single      ZFS single disk (no encryption)
    zfs-mirror      ZFS mirror configuration
    zfs-luks        ZFS with LUKS2 encryption

EXAMPLE:
    $0 myhost                     # Auto-detect mode from host configuration
    $0 -m zfs-luks myhost        # Force ZFS with LUKS mode
    $0 -d myhost                 # Dry run to see what would happen

EOF
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--flake-dir)
            FLAKE_DIR="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            HOSTNAME="$1"
            shift
            ;;
    esac
done

# Check if hostname was provided
if [ -z "${HOSTNAME:-}" ]; then
    echo -e "${RED}Error: Hostname is required${NC}"
    usage
fi

# Function to detect disk mode from configuration
detect_mode() {
    local config_file="$FLAKE_DIR/hosts/$HOSTNAME/configuration.nix"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Configuration file not found: $config_file${NC}"
        exit 1
    fi
    
    # Look for disko module imports
    if grep -q "btrfs-single.nix" "$config_file"; then
        echo "btrfs-single"
    elif grep -q "btrfs-luks.nix" "$config_file"; then
        echo "btrfs-luks"
    elif grep -q "zfs-single.nix" "$config_file"; then
        echo "zfs-single"
    elif grep -q "zfs-mirror.nix" "$config_file"; then
        echo "zfs-mirror"
    elif grep -q "zfs-luks.nix" "$config_file"; then
        echo "zfs-luks"
    else
        echo ""
    fi
}

# Determine disk mode
if [ -z "$MODE" ]; then
    MODE=$(detect_mode)
    if [ -z "$MODE" ]; then
        echo -e "${RED}Error: Could not detect disk mode from configuration${NC}"
        echo "Please specify mode with -m option"
        exit 1
    fi
    echo -e "${GREEN}Detected disk mode: $MODE${NC}"
else
    echo -e "${GREEN}Using specified disk mode: $MODE${NC}"
fi

# Warning for destructive operations
echo -e "${YELLOW}WARNING: This will DESTROY all data on the target disk(s)!${NC}"
echo -e "Mode: $MODE"
echo -e "Hostname: $HOSTNAME"
echo -e "Flake directory: $FLAKE_DIR"
echo ""

# Check for encrypted modes
if [[ "$MODE" == *"luks"* ]]; then
    echo -e "${YELLOW}This configuration uses disk encryption.${NC}"
    echo "You will be prompted to enter a passphrase during installation."
    echo ""
fi

# Check for ZFS modes
if [[ "$MODE" == "zfs"* ]]; then
    echo -e "${YELLOW}This configuration uses ZFS.${NC}"
    echo "Make sure to set a unique hostId in your configuration."
    echo ""
fi

# Confirmation
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Dry run option
DISKO_FLAGS=""
if [ "$DRY_RUN" = true ]; then
    DISKO_FLAGS="--dry-run"
    echo -e "${YELLOW}Running in dry-run mode...${NC}"
fi

# Run disko
echo -e "${GREEN}Running disko...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo "Would run: nix run github:nix-community/disko -- --mode disko --flake ${FLAKE_DIR}#${HOSTNAME} ${DISKO_FLAGS}"
else
    nix run github:nix-community/disko -- --mode disko --flake "${FLAKE_DIR}#${HOSTNAME}" ${DISKO_FLAGS}
fi

# For encrypted setups, handle TPM enrollment
if [[ "$MODE" == *"luks"* ]] && [ "$DRY_RUN" = false ]; then
    echo -e "${GREEN}Setting up TPM2 enrollment (if available)...${NC}"
    if [ -e /sys/class/tpm/tpm0 ]; then
        echo "TPM2 device found. Enrollment will happen on first boot."
        echo "Run 'systemd-cryptenroll /dev/disk/by-partlabel/cryptroot --tpm2-device=auto' after boot."
    else
        echo "No TPM2 device found. Skipping TPM enrollment."
    fi
fi

# Mount check
if [ "$DRY_RUN" = false ]; then
    echo -e "${GREEN}Checking mounts...${NC}"
    mount | grep /mnt || true
    
    # For ZFS, show pool status
    if [[ "$MODE" == "zfs"* ]]; then
        echo -e "${GREEN}ZFS pool status:${NC}"
        zpool status || true
    fi
fi

echo -e "${GREEN}Disko formatting complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Copy your flake to /mnt/etc/nixos"
echo "2. Run: nixos-install --flake /mnt/etc/nixos#${HOSTNAME}"
echo "3. Reboot into your new system"

# For encrypted setups
if [[ "$MODE" == *"luks"* ]]; then
    echo ""
    echo "For TPM2 auto-unlock after first boot:"
    echo "sudo systemd-cryptenroll /dev/disk/by-partlabel/cryptroot --tpm2-device=auto --tpm2-pcrs=0+2+7"
fi