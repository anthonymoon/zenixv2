#!/usr/bin/env bash
set -e

# Automated remote installation script for NixOS ephemeral root ZFS
# Non-interactive version that auto-confirms installation

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <target-ip> <hostname> <disk>"
    echo "Example: $0 192.168.1.100 myhost /dev/nvme0n1"
    echo ""
    echo "WARNING: This will automatically proceed with installation!"
    echo "         All data on the target disk will be destroyed!"
    exit 1
fi

TARGET_IP="$1"
HOSTNAME="$2"
DISK="$3"

# Validate inputs
if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "Error: Invalid hostname. Use only letters, numbers, and hyphens."
    exit 1
fi

echo "=== NixOS Remote Installation (Automated) ==="
echo "Target: root@$TARGET_IP"
echo "Hostname: $HOSTNAME"
echo "Disk: $DISK"
echo ""
echo "WARNING: This will DESTROY all data on $DISK"
echo "Proceeding automatically in 5 seconds..."
sleep 5

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o PasswordAuthentication=yes root@"$TARGET_IP" "echo 'SSH connection successful'"; then
    echo "Error: Cannot connect to root@$TARGET_IP"
    echo "Make sure:"
    echo " - Target is booted into NixOS installer ISO"
    echo " - SSH is enabled (set root password)"
    echo " - Network is configured"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create remote directory
echo "Creating remote directory..."
ssh root@"$TARGET_IP" "mkdir -p /tmp/nixos-install"

# Rsync the repository
echo "Syncing repository to target..."
rsync -avz --delete \
    --exclude='.git' \
    --exclude='result*' \
    --exclude='test-build' \
    --exclude='*.swp' \
    "$SCRIPT_DIR"/ root@"$TARGET_IP":/tmp/nixos-install/

# Execute installation remotely with auto-confirm
echo "Starting remote installation..."
# Detect if target is a VM and use appropriate installer
if [[ "$DISK" == /dev/vd* ]]; then
    echo "Detected VM disk pattern, using VM-specific installer..."
    ssh root@"$TARGET_IP" "cd /tmp/nixos-install && echo yes | bash ./install-vm.sh '$HOSTNAME' '$DISK'"
else
    echo "Using optimized installer for physical disks..."
    ssh root@"$TARGET_IP" "cd /tmp/nixos-install && echo yes | bash ./install-optimized.sh '$HOSTNAME' '$DISK'"
fi

echo ""
echo "Remote installation completed!"
echo "The system will have:"
echo " - Hostname: $HOSTNAME"
echo " - SSH access: root:nixos, amoon:nixos, nixos:nixos"
echo " - Your SSH key is already authorized"
echo ""
echo "After reboot, you can rebuild remotely with:"
echo "  nixos-rebuild switch --flake .#$HOSTNAME --target-host root@$TARGET_IP"