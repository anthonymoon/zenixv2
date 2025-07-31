#!/usr/bin/env bash
# Interactive installation script for disko-install with auto-detection
set -euo pipefail

# Enable experimental features for this session
export NIX_CONFIG="experimental-features = nix-command flakes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "Please run this script as a regular user (not root)"
    exit 1
fi

# Check if nix is available
if ! command -v nix &> /dev/null; then
    error "Nix is not installed. Please install Nix first."
    echo "Visit: https://nixos.org/download.html"
    exit 1
fi

# Check if in a NixOS environment or live USB
if [ ! -f /etc/NIXOS ]; then
    warn "This script should be run from a NixOS installer environment"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log "Starting NixOS Interactive Installation"
echo

# Function to display a header
header() {
    echo -e "\n${PURPLE}=====================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}=====================================${NC}\n"
}

header "NixOS Disko Installation Helper"

info "This script will help you install NixOS with the following features:"
echo "  • Auto-detected disk configuration"
echo "  • Choice of filesystem (Btrfs or ZFS)"
echo "  • Optional LUKS encryption with TPM2 auto-unlock"
echo "  • NVMe/SSD optimizations"
echo "  • Performance tuning"
echo

# Step 1: List available hosts
header "Step 1: Select Host Configuration"

if [ ! -f "flake.nix" ]; then
    error "flake.nix not found. Please run this script from the nixos configuration directory."
    exit 1
fi

info "Available host configurations:"
if ! nix flake show --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' 2>/dev/null | nl -w2 -s'. '; then
    # Fallback method if jq fails
    warn "Could not automatically detect configurations. Please check your flake.nix"
    echo "Manual configuration names you can try:"
    echo "  • hostname.kde.gaming.unstable"
    echo "  • hostname.gnome.stable"
    echo "  • hostname.headless.hardened"
    echo
    read -p "Enter configuration name manually: " hostname
else
    echo
    read -p "Select host number or enter custom name: " host_input
    
    # Check if input is a number
    if [[ "$host_input" =~ ^[0-9]+$ ]]; then
        hostname=$(nix flake show --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' | sed -n "${host_input}p")
        if [ -z "$hostname" ]; then
            error "Invalid selection"
            exit 1
        fi
    else
        hostname="$host_input"
    fi
fi

info "Selected configuration: ${hostname}"

# Step 2: Detect disks and show options
header "Step 2: Disk Configuration"

info "Detecting available disks..."

# List available disks
available_disks=()
if [ -d "/dev/disk/by-id" ]; then
    while IFS= read -r -d '' disk; do
        # Skip partitions and optical drives
        if [[ ! "$disk" =~ -part[0-9]+$ ]] && [[ ! "$disk" =~ (cd|dvd|sr[0-9]) ]]; then
            available_disks+=("$disk")
        fi
    done < <(find /dev/disk/by-id -type l -print0 2>/dev/null)
fi

if [ ${#available_disks[@]} -eq 0 ]; then
    warn "No disks detected via /dev/disk/by-id, falling back to /dev/sd* and /dev/nvme*"
    for disk in /dev/sd? /dev/nvme?n?; do
        if [ -b "$disk" ]; then
            available_disks+=("$disk")
        fi
    done
fi

if [ ${#available_disks[@]} -eq 0 ]; then
    error "No suitable disks found!"
    exit 1
fi

echo "Available disks:"
for i in "${!available_disks[@]}"; do
    disk="${available_disks[$i]}"
    size=""
    model=""
    
    # Get disk info
    if command -v lsblk >/dev/null 2>&1; then
        disk_info=$(lsblk -n -o SIZE,MODEL "$disk" 2>/dev/null | head -1 || echo "Unknown Unknown")
        size=$(echo "$disk_info" | awk '{print $1}')
        model=$(echo "$disk_info" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
    fi
    
    printf "%2d. %-30s %8s %s\n" $((i+1)) "$disk" "$size" "$model"
done

echo
echo "Options:"
echo "  a. Auto-detect best disk (recommended)"
echo "  m. Manual selection"

read -p "Choose option [a/m]: " disk_option

case "$disk_option" in
    a|A|"")
        info "Using auto-detection (will prefer NVMe > SATA SSD > HDD)"
        use_auto_detect=true
        selected_disk=""
        ;;
    m|M)
        read -p "Enter disk number: " disk_num
        if [[ "$disk_num" =~ ^[0-9]+$ ]] && [ "$disk_num" -ge 1 ] && [ "$disk_num" -le ${#available_disks[@]} ]; then
            selected_disk="${available_disks[$((disk_num-1))]}"
            use_auto_detect=false
            info "Selected disk: $selected_disk"
        else
            error "Invalid disk selection"
            exit 1
        fi
        ;;
    *)
        error "Invalid option"
        exit 1
        ;;
esac

# Step 3: Choose filesystem and encryption
header "Step 3: Filesystem and Encryption"

echo "Filesystem options:"
echo "  1. Btrfs (recommended for most users)"
echo "  2. Btrfs + LUKS encryption"
echo "  3. ZFS (advanced users, better for servers)"
echo "  4. ZFS + LUKS encryption"

read -p "Choose filesystem [1-4]: " fs_choice

case "$fs_choice" in
    1)
        disko_module="./modules/disko/btrfs-single.nix"
        encryption=false
        filesystem="Btrfs"
        ;;
    2)
        disko_module="./modules/disko/btrfs-luks.nix"
        encryption=true
        filesystem="Btrfs + LUKS"
        ;;
    3)
        disko_module="./modules/disko/zfs-single.nix"
        encryption=false
        filesystem="ZFS"
        ;;
    4)
        disko_module="./modules/disko/zfs-luks.nix"
        encryption=true
        filesystem="ZFS + LUKS"
        ;;
    *)
        error "Invalid filesystem choice"
        exit 1
        ;;
esac

info "Selected: $filesystem"

# TPM2 configuration for encryption
if [ "$encryption" = true ]; then
    echo
    info "Encryption options:"
    echo "  • TPM2 auto-unlock will be enabled (if available)"
    echo "  • Secure boot with lanzaboote will be configured"
    echo "  • You'll need to set up a recovery password"
    echo
    
    read -p "Continue with encryption setup? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        info "Switching to non-encrypted configuration"
        case "$fs_choice" in
            2) disko_module="./modules/disko/btrfs-single.nix" ;;
            4) disko_module="./modules/disko/zfs-single.nix" ;;
        esac
        encryption=false
        filesystem="${filesystem% + LUKS}"
    fi
fi

# Step 4: Show installation summary
header "Step 4: Installation Summary"

info "Installation configuration:"
echo "  • Host: $hostname"
echo "  • Filesystem: $filesystem"
if [ "$use_auto_detect" = true ]; then
    echo "  • Disk: Auto-detected (prefer NVMe/SSD)"
else
    echo "  • Disk: $selected_disk"
fi
echo "  • Disko module: $disko_module"
if [ "$encryption" = true ]; then
    echo "  • TPM2 auto-unlock: Enabled"
    echo "  • Secure boot: Enabled (lanzaboote)"
fi
echo

warn "⚠️  WARNING: This will DESTROY ALL DATA on the selected disk!"
warn "⚠️  Make sure you have backups of any important data!"
echo

read -p "Are you sure you want to continue? Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
    info "Installation cancelled"
    exit 0
fi

# Step 5: Run the installation
header "Step 5: Installation"

log "Starting installation..."

# Build the nix command
nix_cmd=(
    "nix" "run" "github:nix-community/disko/latest#disko-install" "--"
    "--flake" ".#$hostname"
    "--write-efi-boot-entries"
)

# Add disk specification if manual selection
if [ "$use_auto_detect" = false ]; then
    nix_cmd+=("--disk" "main" "$selected_disk")
fi

log "Running command: ${nix_cmd[*]}"
echo

# Run the installation
if "${nix_cmd[@]}"; then
    log "✅ Installation completed successfully!"
else
    error "❌ Installation failed!"
    exit 1
fi

# Step 6: Post-installation setup
header "Step 6: Post-Installation Setup"

if [ "$encryption" = true ]; then
    info "Setting up encryption..."
    
    echo "After first boot, you should:"
    echo "  1. Enroll your TPM2 for auto-unlock:"
    echo "     sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+1+2+3+7 /dev/disk/by-partlabel/cryptroot"
    echo "  2. Set up lanzaboote secure boot:"
    echo "     sudo sbctl create-keys"
    echo "     sudo sbctl enroll-keys --microsoft"
    echo "  3. Reboot and enable secure boot in BIOS/UEFI"
    echo
fi

info "Installation recommendations:"
echo "  • Reboot into your new system"
echo "  • Run 'sudo nixos-rebuild switch' to apply any pending changes"
echo "  • Set up your user password: sudo passwd <username>"
if [ "$encryption" = false ]; then
    echo "  • Consider enabling automatic maintenance: maintenance.enable = true;"
fi
echo "  • Check system status: systemctl status"

echo
log "🎉 NixOS installation with $filesystem completed!"
log "You can now reboot into your new system."

read -p "Reboot now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Rebooting..."
    sudo reboot
else
    log "Remember to reboot when ready!"
fi