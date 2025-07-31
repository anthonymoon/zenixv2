# NixOS ZFS Root Installation Guide

This configuration provides a modern NixOS installation with ZFS root filesystem and impermanence pattern for a stateless, reproducible system.

## Features

- **Impermanence Pattern** - Root filesystem rolls back to blank state on every boot
- **Declarative Disk Partitioning** using Disko
- **Optimized ZFS Performance** settings for modern hardware
- **Automatic Snapshots** for persistent data
- **UEFI Boot** with systemd-boot
- **Flake-based Configuration**

## Prerequisites

1. NixOS installation ISO (24.11 or newer)
2. UEFI-capable system
3. At least 32GB storage (recommended: 64GB+)
4. 8GB+ RAM (ZFS benefits from more RAM for ARC cache)

## Directory Structure

```
.
├── flake.nix                    # Main flake configuration
├── nixos-zfs-root-config.nix    # ZFS and system configuration
├── README.md                    # This file
└── hosts/                       # Host-specific configurations
    └── <hostname>/
        ├── configuration.nix    # Host-specific settings
        └── hardware-configuration.nix  # Auto-generated hardware config
```

## Installation Steps

### 1. Boot from NixOS ISO

Download the latest NixOS ISO and boot from it. Ensure Secure Boot is disabled.

### 2. Connect to Network

```bash
# For WiFi
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "YOUR_SSID"
> set_network 0 psk "YOUR_PASSWORD"
> enable_network 0
> quit

# For Ethernet (usually automatic)
# Check connection
ip a
ping nixos.org
```

### 3. Prepare Installation Environment

```bash
# Become root
sudo -i

# Install git and other tools
nix-env -iA nixos.git nixos.vim

# Clone this configuration (or copy your files)
git clone <your-repo-url> /mnt/config
cd /mnt/config

# Or if files are on USB:
# mount /dev/sdX1 /mnt/usb
# cp -r /mnt/usb/nix-config /mnt/config
# cd /mnt/config
```

### 4. Identify Your Disk

```bash
# List all disks
lsblk

# For more details
fdisk -l

# For NVMe drives
nvme list

# Note your target disk (e.g., /dev/nvme0n1, /dev/sda)
```

### 5. Configure for Your System

Edit the configuration files:

```bash
# Update disk device if needed (default is /dev/nvme0n1)
vim nixos-zfs-root-config.nix
# Change line: device = "/dev/nvme0n1"; to your disk

# Create host directory
HOSTNAME="myhostname"  # Choose your hostname
mkdir -p hosts/$HOSTNAME

# The installation script will generate hardware-configuration.nix
```

### 6. Run Installation

**WARNING: This will DESTROY all data on the target disk!**

```bash
# Using the automated install script
nix run .#install

# Or manually:
# 1. Partition and format with disko
sudo nix run github:nix-community/disko -- --mode disko ./nixos-zfs-root-config.nix

# 2. Disko will partition and create the ZFS pool

# 3. Generate hardware configuration
sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/$HOSTNAME/hardware-configuration.nix

# 4. Create basic host configuration
cat > hosts/$HOSTNAME/configuration.nix << 'EOF'
{ config, pkgs, lib, ... }:

{
  networking.hostName = "myhostname"; # Change this
  
  # Create your user account
  users.users.myuser = {  # Change username
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme"; # CHANGE IMMEDIATELY after first login
    # hashedPassword = ""; # Use mkpasswd -m sha-512 to generate
  };
  
  # Enable desktop environment (optional)
  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  
  # Enable NetworkManager
  networking.networkmanager.enable = true;
  
  # Enable SSH (optional)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
  
  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    htop
    firefox  # If using desktop
  ];
}
EOF

# 5. Install NixOS
sudo nixos-install --flake .#$HOSTNAME --no-root-password
```

### 7. First Boot

1. Reboot into your new system
2. Login with your user and the initial password
3. **IMMEDIATELY** change your password: `passwd`

### 8. Post-Installation

```bash
# Verify ZFS is working
zfs list
zpool status

# Check impermanence is active
mount | grep zfs

# Update your configuration
cd /etc/nixos  # or wherever you keep your config
nixos-rebuild switch --flake .#yourhostname

# Set up persistent directories as needed
# Edit the environment.persistence section in nixos-zfs-root-config.nix
```

## Important Notes

### Impermanence

- Everything outside `/persist`, `/home`, and `/nix` is wiped on reboot
- Add important directories to the `environment.persistence` section
- User data in `/home` is preserved
- System configuration in `/persist/etc/nixos` is preserved

### Performance Tuning

The configuration includes optimizations for:
- Modern SSDs (ashift=12 for 4K sectors)
- Compression (zstd)
- Extended attributes stored in inodes (xattr=sa)
- ARC cache limited to 8GB (adjust based on your RAM)

### Maintenance

```bash
# Manual scrub (automatic weekly scrub is enabled)
sudo zpool scrub rpool

# Check pool status
zpool status -v

# List snapshots
zfs list -t snapshot

# Manual snapshot
sudo zfs snapshot rpool/safe/home@manual-$(date +%Y%m%d)

# Cleanup old snapshots (automatic cleanup is configured)
sudo zfs-prune-snapshots --keep 30 rpool/safe
```

## Advanced Configuration

### Remote Unlock via SSH

For headless systems, you can enable SSH in initrd:

```nix
# In your configuration.nix
boot.initrd = {
  network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      authorizedKeys = [ "ssh-rsa ..." ];
      hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];
    };
  };
};
```

### Multiple Disks / RAID

For mirror (RAID1) configuration:

```nix
# In nixos-zfs-root-config.nix
disk = {
  nvme0n1 = { ... };  # First disk
  nvme1n1 = {         # Second disk
    type = "disk";
    device = "/dev/nvme1n1";
    content = {
      type = "gpt";
      partitions = {
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "rpool";
          };
        };
      };
    };
  };
};

zpool = {
  rpool = {
    type = "zpool";
    mode = "mirror";  # Enable mirror mode
    # ... rest of configuration
  };
};
```

### Custom ZFS Properties

Add custom properties to any dataset:

```nix
datasets = {
  "safe/important" = {
    type = "zfs_fs";
    mountpoint = "/important";
    options = {
      # Custom record size for databases
      recordsize = "16K";
      # Disable compression for already-compressed data
      compression = "off";
      # Custom snapshot retention
      "com.sun:auto-snapshot:frequent" = "true";
      "com.sun:auto-snapshot:hourly" = "false";
    };
  };
};
```

## Troubleshooting

### Cannot Import Pool

```bash
# Force import (use carefully)
zpool import -f rpool

# Import with different host ID
zpool import -f -o cachefile=none rpool
```

### System Won't Boot

1. Boot from NixOS ISO
2. Import pool: `zpool import -R /mnt rpool`
3. Mount filesystems: `mount -t zfs rpool/local/root /mnt`, etc.
4. Fix configuration and rebuild: `nixos-rebuild boot --install-bootloader --flake /mnt/etc/nixos#hostname`

### Performance Issues

```bash
# Check ARC stats
arc_summary

# Adjust ARC size in configuration
# boot.kernelParams = [ "zfs.zfs_arc_max=17179869184" ]; # 16GB

# Check compression ratio
zfs get compressratio rpool/local/nix
```

## Security Considerations

1. Consider adding LUKS encryption if security is required
2. Enable secure boot after installation (requires additional setup)
3. Regular backups to separate media/location
4. Monitor ZFS pool health and replace failing drives immediately

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [OpenZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [Disko Documentation](https://github.com/nix-community/disko)
- [Impermanence Documentation](https://github.com/nix-community/impermanence)
- [ZFS on NixOS Wiki](https://nixos.wiki/wiki/ZFS)

## Contributing

Feel free to submit issues or pull requests to improve this configuration!