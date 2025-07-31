# Remote Installation Guide

This NixOS ephemeral root ZFS configuration supports multiple installation methods for maximum flexibility.

## Quick Start

### Option 1: Direct from GitHub (Simplest)
```bash
# On target machine booted into NixOS installer:
passwd  # Set root password
bash <(curl -sL https://raw.githubusercontent.com/anthonymoon/zfs/main/install-from-url.sh) myhost /dev/nvme0n1
```

### Option 2: Remote Install via SSH
```bash
# From your workstation:
git clone https://github.com/anthonymoon/zfs
cd zfs
./remote-install.sh 192.168.1.100 myhost /dev/nvme0n1
```

## Authentication

All users have:
- Default password: `nixos`
- SSH key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA898oqxREsBRW49hvI92CPWTebvwPoUeMSq5VMyzoM3`

Users:
- `root`: Full system access
- `amoon`: Primary user with sudo
- `nixos`: Installation/recovery user

## Network Configuration

- All interfaces (en*, eth*) automatically use DHCP
- IPv6 is disabled by default
- SSH is enabled and starts on boot

## Multi-Host Management

### Using Master Flake

1. Copy `flake-master.nix` to `flake.nix`
2. Edit to add your hosts:
```nix
nixosConfigurations = {
  "host1" = mkHost "host1" "disk-id-1";
  "host2" = mkHost "host2" "disk-id-2";
};
```

### Deployment Options

**Local rebuild (hostname auto-matches):**
```bash
sudo nixos-rebuild switch --flake /path/to/repo
```

**Remote deployment:**
```bash
# From local repo
sudo nixos-rebuild switch --flake .#host1 --target-host root@192.168.1.100

# From GitHub
sudo nixos-rebuild switch --flake github:anthonymoon/zfs#host1 --target-host root@192.168.1.100
```

## Installation Flow

1. **Target boots NixOS installer** → Network auto-configures
2. **Installer downloads config** → From GitHub or local rsync
3. **Templates replaced** → Hostname and disk configured
4. **Disko partitions disk** → ZFS pool with ephemeral root
5. **NixOS installed** → With all persistent paths configured
6. **Reboot** → System ready with SSH access

## Post-Installation

1. Change default passwords immediately
2. Update SSH keys in configuration
3. Commit changes to your fork
4. Use remote deployment for updates

## Troubleshooting

**SSH connection fails:**
- Ensure target has network (check with `ip a`)
- Verify root password is set
- Check firewall isn't blocking port 22

**Disk not found:**
- Use `lsblk` to list available disks
- Check `/dev/disk/by-id/` for disk IDs

**Installation fails:**
- Ensure sufficient RAM (2GB minimum)
- Verify disk isn't in use
- Check network connectivity