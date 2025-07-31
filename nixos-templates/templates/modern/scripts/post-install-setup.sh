#!/usr/bin/env bash
# Post-installation setup script for disko-based NixOS systems

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

# Function to detect system configuration
detect_config() {
    echo -e "${GREEN}Detecting system configuration...${NC}"
    
    # Check for LUKS
    if lsblk -o NAME,FSTYPE | grep -q "crypto_LUKS"; then
        echo "LUKS encryption detected"
        LUKS_DEVICE=$(lsblk -o NAME,PARTLABEL,FSTYPE | grep crypto_LUKS | grep -E "cryptroot|luks" | awk '{print "/dev/disk/by-partlabel/" $2}' | head -1)
        echo "LUKS device: $LUKS_DEVICE"
        HAS_LUKS=true
    else
        HAS_LUKS=false
    fi
    
    # Check for ZFS
    if command -v zfs &> /dev/null && zpool list &> /dev/null; then
        echo "ZFS detected"
        HAS_ZFS=true
        ZPOOL_NAME=$(zpool list -H -o name | head -1)
        echo "ZFS pool: $ZPOOL_NAME"
    else
        HAS_ZFS=false
    fi
    
    # Check for Btrfs
    if mount -t btrfs | grep -q "on / "; then
        echo "Btrfs root filesystem detected"
        HAS_BTRFS=true
    else
        HAS_BTRFS=false
    fi
    
    echo ""
}

# Function to setup TPM2 auto-unlock
setup_tpm2() {
    if [ "$HAS_LUKS" = false ]; then
        echo "No LUKS encryption detected, skipping TPM2 setup"
        return
    fi
    
    echo -e "${GREEN}Setting up TPM2 auto-unlock...${NC}"
    
    # Check for TPM2
    if [ ! -e /sys/class/tpm/tpm0 ]; then
        echo -e "${YELLOW}No TPM2 device found, skipping TPM2 enrollment${NC}"
        return
    fi
    
    # Check if already enrolled
    if cryptsetup luksDump "$LUKS_DEVICE" | grep -q "tpm2"; then
        echo "TPM2 already enrolled for this device"
        return
    fi
    
    echo "Enrolling TPM2 for automatic unlock..."
    echo "This will bind the encryption to your current system state (PCRs 0, 2, 7)"
    echo ""
    read -p "Continue with TPM2 enrollment? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        systemd-cryptenroll "$LUKS_DEVICE" --tpm2-device=auto --tpm2-pcrs=0+2+7
        echo -e "${GREEN}TPM2 enrollment complete!${NC}"
        echo "The system will automatically unlock on next boot if the system state hasn't changed"
    else
        echo "TPM2 enrollment skipped"
    fi
    echo ""
}

# Function to setup recovery key
setup_recovery_key() {
    if [ "$HAS_LUKS" = false ]; then
        return
    fi
    
    echo -e "${GREEN}Setting up LUKS recovery key...${NC}"
    echo "This will add a recovery key that you should store securely"
    echo ""
    read -p "Setup a recovery key? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        RECOVERY_KEY=$(systemd-cryptenroll "$LUKS_DEVICE" --recovery-key)
        echo ""
        echo -e "${YELLOW}IMPORTANT: Save this recovery key in a secure location!${NC}"
        echo -e "${RED}$RECOVERY_KEY${NC}"
        echo ""
        echo "You can use this key to unlock your disk if TPM2 unlock fails"
    else
        echo "Recovery key setup skipped"
    fi
    echo ""
}

# Function to setup Btrfs snapshots
setup_btrfs_snapshots() {
    if [ "$HAS_BTRFS" = false ]; then
        return
    fi
    
    echo -e "${GREEN}Setting up Btrfs snapshot schedule...${NC}"
    
    # Check if snapper is available
    if ! command -v snapper &> /dev/null; then
        echo "Snapper not installed. Add it to your configuration:"
        echo "  environment.systemPackages = [ pkgs.snapper ];"
        echo "  services.snapper.configs = { ... };"
        return
    fi
    
    # Create snapshot directory if it doesn't exist
    if [ ! -d "/.snapshots" ]; then
        mkdir -p /.snapshots
    fi
    
    echo "Btrfs snapshot configuration can be added to your NixOS configuration"
    echo ""
}

# Function to setup ZFS snapshots
setup_zfs_snapshots() {
    if [ "$HAS_ZFS" = false ]; then
        return
    fi
    
    echo -e "${GREEN}Setting up ZFS automatic snapshots...${NC}"
    
    # Check current snapshot policy
    echo "Current ZFS datasets:"
    zfs list -o name,used,avail,mountpoint
    echo ""
    
    echo "To enable automatic ZFS snapshots, add to your configuration:"
    echo "  services.zfs.autoSnapshot.enable = true;"
    echo "  services.zfs.autoSnapshot.frequent = 4;  # 15-minute snapshots to keep"
    echo "  services.zfs.autoSnapshot.hourly = 24;"
    echo "  services.zfs.autoSnapshot.daily = 7;"
    echo "  services.zfs.autoSnapshot.weekly = 4;"
    echo "  services.zfs.autoSnapshot.monthly = 12;"
    echo ""
    
    # Show current snapshots
    if zfs list -t snapshot 2>/dev/null | grep -q .; then
        echo "Current snapshots:"
        zfs list -t snapshot
    else
        echo "No snapshots found"
    fi
    echo ""
}

# Function to setup ESP mirroring (for mirror configurations)
setup_esp_mirror() {
    if [ ! -e /dev/disk/by-partlabel/ESP-mirror ]; then
        return
    fi
    
    echo -e "${GREEN}Setting up ESP mirroring...${NC}"
    echo "ESP mirror partition detected"
    
    # Check if systemd service exists
    if systemctl list-unit-files | grep -q esp-mirror-sync; then
        echo "Enabling ESP mirror sync service..."
        systemctl enable esp-mirror-sync.timer
        systemctl start esp-mirror-sync.service
        echo "ESP mirroring enabled and initial sync completed"
    else
        echo "ESP mirror service not configured in NixOS configuration"
    fi
    echo ""
}

# Function to optimize system
optimize_system() {
    echo -e "${GREEN}Optimizing system configuration...${NC}"
    
    # Btrfs optimizations
    if [ "$HAS_BTRFS" = true ]; then
        echo "Enabling Btrfs optimizations..."
        # Schedule scrub
        if command -v btrfs &> /dev/null; then
            echo "You can schedule regular Btrfs scrubs with:"
            echo "  services.btrfs.autoScrub.enable = true;"
            echo "  services.btrfs.autoScrub.interval = \"monthly\";"
        fi
    fi
    
    # ZFS optimizations
    if [ "$HAS_ZFS" = true ]; then
        echo "Enabling ZFS optimizations..."
        # Check ARC size
        if [ -f /proc/spl/kstat/zfs/arcstats ]; then
            ARC_SIZE=$(awk '/^size/ {print $3}' /proc/spl/kstat/zfs/arcstats)
            ARC_SIZE_GB=$((ARC_SIZE / 1024 / 1024 / 1024))
            echo "Current ZFS ARC size: ${ARC_SIZE_GB}GB"
            echo "You can tune ARC size with: boot.kernelParams = [ \"zfs.zfs_arc_max=SIZE_IN_BYTES\" ];"
        fi
        
        # Schedule scrub
        echo "You can schedule regular ZFS scrubs with:"
        echo "  services.zfs.autoScrub.enable = true;"
        echo "  services.zfs.autoScrub.interval = \"weekly\";"
    fi
    
    echo ""
}

# Function to show maintenance commands
show_maintenance() {
    echo -e "${GREEN}=== Useful Maintenance Commands ===${NC}"
    echo ""
    
    if [ "$HAS_LUKS" = true ]; then
        echo "LUKS Commands:"
        echo "  cryptsetup luksDump $LUKS_DEVICE  # Show LUKS header info"
        echo "  systemd-cryptenroll --list $LUKS_DEVICE  # List enrolled methods"
        echo ""
    fi
    
    if [ "$HAS_BTRFS" = true ]; then
        echo "Btrfs Commands:"
        echo "  btrfs filesystem show  # Show filesystem info"
        echo "  btrfs filesystem usage /  # Show space usage"
        echo "  btrfs subvolume list /  # List subvolumes"
        echo "  btrfs scrub start /  # Start scrub"
        echo "  btrfs device stats /  # Show device statistics"
        echo ""
    fi
    
    if [ "$HAS_ZFS" = true ]; then
        echo "ZFS Commands:"
        echo "  zpool status  # Show pool status"
        echo "  zfs list  # List datasets"
        echo "  zfs list -t snapshot  # List snapshots"
        echo "  zpool scrub $ZPOOL_NAME  # Start scrub"
        echo "  zpool iostat -v 1  # Show I/O statistics"
        echo ""
    fi
}

# Main execution
echo -e "${GREEN}=== NixOS Post-Installation Setup ===${NC}"
echo ""

# Check if running as root
check_root

# Detect system configuration
detect_config

# Setup TPM2 if applicable
setup_tpm2

# Setup recovery key
setup_recovery_key

# Setup snapshots
setup_btrfs_snapshots
setup_zfs_snapshots

# Setup ESP mirroring
setup_esp_mirror

# Optimize system
optimize_system

# Show maintenance commands
show_maintenance

echo -e "${GREEN}=== Post-installation setup complete! ===${NC}"
echo ""
echo "Remember to:"
echo "1. Change default passwords"
echo "2. Configure automatic backups"
echo "3. Set up monitoring/alerting"
echo "4. Review and adjust mount options if needed"
echo "5. Test your disaster recovery procedures"