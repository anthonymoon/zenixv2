#!/usr/bin/env bash
# NixOS ZFS System Management Script
# Provides common maintenance operations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get hostname from flake
HOSTNAME=$(hostname)
FLAKE_PATH="/etc/nixos"

# Helper functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "NixOS ZFS System Management"
    echo "==========================="
    echo ""
    echo "1. System Status"
    echo "2. Update System"
    echo "3. ZFS Pool Status"
    echo "4. Snapshot Management"
    echo "5. Disk Usage Analysis"
    echo "6. Rollback Root to Blank"
    echo "7. Create Manual Snapshot"
    echo "8. Scrub ZFS Pool"
    echo "9. Backup Configuration"
    echo "0. Exit"
    echo ""
    read -p "Select option: " choice
}

# System status
system_status() {
    info "System Information"
    echo "Hostname: $HOSTNAME"
    echo "NixOS Version: $(nixos-version)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo ""
    
    info "Memory Usage"
    free -h
    echo ""
    
    info "Disk Usage"
    df -h | grep -E "^/dev/|^rpool"
    echo ""
    
    info "ZFS ARC Stats"
    arc_summary | grep -E "ARC Size:|Hit Ratio:" || echo "arc_summary not found"
}

# Update system
update_system() {
    info "Updating flake inputs..."
    cd "$FLAKE_PATH"
    
    if check_root; then
        nix flake update
    else
        sudo nix flake update
    fi
    
    info "Rebuilding system..."
    if check_root; then
        nixos-rebuild switch --flake ".#$HOSTNAME"
    else
        sudo nixos-rebuild switch --flake ".#$HOSTNAME"
    fi
    
    success "System updated successfully!"
}

# ZFS pool status
zfs_status() {
    info "ZFS Pool Status"
    if check_root; then
        zpool status -v
    else
        sudo zpool status -v
    fi
    echo ""
    
    info "ZFS Datasets"
    zfs list -o name,used,avail,refer,mountpoint
    echo ""
    
    info "Compression Ratios"
    zfs get compressratio -t filesystem | grep -v "@"
}

# Snapshot management
snapshot_management() {
    echo "1. List all snapshots"
    echo "2. List snapshots by dataset"
    echo "3. Delete old snapshots"
    echo "4. Back"
    read -p "Select option: " snap_choice
    
    case $snap_choice in
        1)
            info "All Snapshots"
            zfs list -t snapshot -o name,used,refer,creation
            ;;
        2)
            read -p "Enter dataset name (e.g., rpool/safe/home): " dataset
            info "Snapshots for $dataset"
            zfs list -t snapshot -o name,used,refer,creation | grep "^$dataset@"
            ;;
        3)
            warning "This will delete snapshots older than 30 days"
            read -p "Continue? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                if check_root; then
                    zfs-prune-snapshots --keep 30d rpool/safe
                else
                    sudo zfs-prune-snapshots --keep 30d rpool/safe
                fi
                success "Old snapshots deleted"
            fi
            ;;
        4)
            return
            ;;
    esac
}

# Disk usage analysis
disk_analysis() {
    info "Analyzing disk usage..."
    echo ""
    
    info "Largest directories in /home"
    du -sh /home/*/ 2>/dev/null | sort -hr | head -10
    echo ""
    
    info "Largest directories in /nix/store"
    du -sh /nix/store/* 2>/dev/null | sort -hr | head -20
    echo ""
    
    info "Nix garbage collection estimation"
    nix-collect-garbage --dry-run
}

# Rollback root
rollback_root() {
    warning "This will rollback the root filesystem to blank state!"
    warning "All changes outside of persistent directories will be lost!"
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        info "Rolling back root filesystem..."
        if check_root; then
            zfs rollback -r rpool/local/root@blank
        else
            sudo zfs rollback -r rpool/local/root@blank
        fi
        success "Root filesystem rolled back. Reboot to see changes."
    else
        info "Rollback cancelled"
    fi
}

# Create manual snapshot
create_snapshot() {
    echo "Select dataset to snapshot:"
    echo "1. Home directories (rpool/safe/home)"
    echo "2. Persistent data (rpool/safe/persist)"
    echo "3. All safe datasets"
    echo "4. Back"
    read -p "Select option: " snap_target
    
    case $snap_target in
        1)
            dataset="rpool/safe/home"
            ;;
        2)
            dataset="rpool/safe/persist"
            ;;
        3)
            dataset="rpool/safe"
            ;;
        4)
            return
            ;;
        *)
            error "Invalid option"
            ;;
    esac
    
    timestamp=$(date +%Y%m%d-%H%M%S)
    read -p "Enter snapshot description: " description
    snapshot_name="${dataset}@manual-${timestamp}-${description// /-}"
    
    info "Creating snapshot: $snapshot_name"
    if check_root; then
        zfs snapshot "$snapshot_name"
    else
        sudo zfs snapshot "$snapshot_name"
    fi
    success "Snapshot created successfully"
}

# Scrub pool
scrub_pool() {
    info "Starting ZFS scrub..."
    if check_root; then
        zpool scrub rpool
    else
        sudo zpool scrub rpool
    fi
    
    info "Scrub started. Check status with 'zpool status'"
}

# Backup configuration
backup_config() {
    backup_dir="$HOME/nixos-config-backup-$(date +%Y%m%d-%H%M%S)"
    info "Backing up configuration to $backup_dir"
    
    mkdir -p "$backup_dir"
    cp -r "$FLAKE_PATH"/* "$backup_dir/" 2>/dev/null || true
    
    # Create a snapshot of the configuration
    if check_root; then
        zfs snapshot "rpool/safe/persist@config-backup-$(date +%Y%m%d-%H%M%S)"
    else
        sudo zfs snapshot "rpool/safe/persist@config-backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    success "Configuration backed up to $backup_dir"
    info "ZFS snapshot also created"
}

# Main loop
while true; do
    show_menu
    
    case $choice in
        1) system_status ;;
        2) update_system ;;
        3) zfs_status ;;
        4) snapshot_management ;;
        5) disk_analysis ;;
        6) rollback_root ;;
        7) create_snapshot ;;
        8) scrub_pool ;;
        9) backup_config ;;
        0) 
            info "Exiting..."
            exit 0
            ;;
        *)
            error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done