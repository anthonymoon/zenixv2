#!/usr/bin/env bash
# Remote NixOS ZFS installation script
set -euo pipefail

# Configuration
REMOTE_HOST="10.10.10.79"
REMOTE_USER="root"
REMOTE_PASS="nixos"
DISK="/dev/vda"  # Target disk on remote system
HOSTNAME="nixos-remote"
USERNAME="admin"

echo "NixOS ZFS Remote Installation"
echo "============================"
echo ""
echo "Target: $REMOTE_USER@$REMOTE_HOST"
echo "Disk: $DISK"
echo "Hostname: $HOSTNAME"
echo ""

# First, let's update the configuration for the target disk
echo "Updating configuration for target disk..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $REMOTE_USER@$REMOTE_HOST << 'EOF'
cd /root/nixos-config
# Update the disk device in the configuration
sed -i 's|/dev/nvme0n1|/dev/vda|g' nixos-zfs-root-config.nix

# Install necessary tools
nix-env -iA nixos.git nixos.vim nixos.gptfdisk

# Create host directory
mkdir -p hosts/nixos-remote
EOF

echo "Creating host configuration..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $REMOTE_USER@$REMOTE_HOST << 'EOF'
cat > /root/nixos-config/hosts/nixos-remote/configuration.nix << 'HOSTCONFIG'
{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos-remote";
  
  # Timezone
  time.timeZone = "UTC";
  
  # Create admin user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme"; # CHANGE THIS after first boot
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };
  
  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # Change to false after adding SSH keys
    };
  };
  
  # Enable NetworkManager
  networking.networkmanager.enable = true;
  
  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    htop
    tmux
    curl
  ];
  
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
HOSTCONFIG
EOF

echo ""
echo "Running disko to partition and format the disk..."
echo "WARNING: This will DESTROY all data on $DISK!"
read -p "Continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborting installation."
    exit 1
fi

echo "Partitioning disk..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $REMOTE_USER@$REMOTE_HOST << 'EOF'
cd /root/nixos-config
# Run disko
nix run github:nix-community/disko -- --mode disko ./nixos-zfs-root-config.nix
EOF

echo "Generating hardware configuration..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $REMOTE_USER@$REMOTE_HOST << 'EOF'
nixos-generate-config --root /mnt --show-hardware-config > /root/nixos-config/hosts/nixos-remote/hardware-configuration.nix
EOF

echo "Installing NixOS..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $REMOTE_USER@$REMOTE_HOST << 'EOF'
cd /root/nixos-config
nixos-install --flake .#nixos-remote --no-root-password
EOF

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Reboot the system: ssh $REMOTE_USER@$REMOTE_HOST 'reboot'"
echo "2. After reboot, login as 'admin' with password 'changeme'"
echo "3. IMMEDIATELY change the password: passwd"
echo "4. Add your SSH public key to the configuration"
echo "5. Disable password authentication in SSH"
echo ""
echo "The configuration is stored in /etc/nixos on the remote system."