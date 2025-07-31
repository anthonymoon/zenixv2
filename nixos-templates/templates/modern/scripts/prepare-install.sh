#!/usr/bin/env bash
# Prepare system for NixOS installation with disko

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root (use sudo)${NC}"
        exit 1
    fi
}

# Function to check internet connectivity
check_internet() {
    echo -e "${GREEN}Checking internet connectivity...${NC}"
    if ! ping -c 1 github.com &> /dev/null; then
        echo -e "${RED}No internet connection detected${NC}"
        echo "Please ensure you have a working internet connection"
        exit 1
    fi
    echo "Internet connection: OK"
}

# Function to setup nix experimental features
setup_nix() {
    echo -e "${GREEN}Setting up Nix experimental features...${NC}"
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    export NIX_CONFIG="experimental-features = nix-command flakes"
}

# Function to detect available disks
detect_disks() {
    echo -e "${GREEN}Detecting available disks...${NC}"
    echo ""
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -E "disk|nvme"
    echo ""
    
    # Show current partition layout
    echo -e "${YELLOW}Current disk layout:${NC}"
    lsblk
    echo ""
}

# Function to load necessary kernel modules
load_modules() {
    echo -e "${GREEN}Loading necessary kernel modules...${NC}"
    
    # For ZFS support
    modprobe zfs 2>/dev/null || echo "ZFS module not available (normal if not using ZFS)"
    
    # For encryption support
    modprobe dm-crypt 2>/dev/null || true
    modprobe dm-mod 2>/dev/null || true
    
    # For TPM2 support
    modprobe tpm_tis 2>/dev/null || true
    modprobe tpm_crb 2>/dev/null || true
}

# Function to check TPM availability
check_tpm() {
    echo -e "${GREEN}Checking TPM2 availability...${NC}"
    if [ -e /sys/class/tpm/tpm0 ]; then
        echo "TPM2 device found at /sys/class/tpm/tpm0"
        if command -v tpm2_getcap &> /dev/null; then
            echo "TPM2 tools available"
        else
            echo "TPM2 tools not installed (install with: nix-shell -p tpm2-tools)"
        fi
    else
        echo "No TPM2 device found"
    fi
    echo ""
}

# Function to generate machine-id if needed
generate_machine_id() {
    if [ ! -f /etc/machine-id ]; then
        echo -e "${GREEN}Generating machine-id...${NC}"
        systemd-machine-id-setup || dbus-uuidgen > /etc/machine-id
    fi
}

# Main execution
echo -e "${GREEN}=== NixOS Disko Installation Preparation ===${NC}"
echo ""

# Check if running as root
check_root

# Check internet
check_internet

# Setup nix
setup_nix

# Load modules
load_modules

# Generate machine-id (needed for ZFS hostId)
generate_machine_id

# Detect disks
detect_disks

# Check TPM
check_tpm

# Show recommendations
echo -e "${GREEN}=== Preparation Complete ===${NC}"
echo ""
echo "Recommendations:"
echo "1. Note your target disk device (e.g., /dev/sda, /dev/nvme0n1)"
echo "2. Ensure you have backed up any important data"
echo "3. For ZFS: Consider your pool layout and redundancy needs"
echo "4. For encryption: Have a strong passphrase ready"
echo ""
echo "Next steps:"
echo "1. Clone or copy your flake configuration"
echo "2. Edit the host configuration to set the correct disk device"
echo "3. Run: ./install-disko.sh <hostname>"
echo ""

# Optional: Install useful tools
echo -e "${YELLOW}Would you like to enter a nix-shell with useful tools? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Entering nix-shell with installation tools..."
    nix-shell -p git vim cryptsetup parted gptfdisk tpm2-tools
fi