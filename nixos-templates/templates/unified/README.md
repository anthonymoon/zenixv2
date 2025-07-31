# NixOS Unified - Minimal

A single, minimal NixOS configuration optimized for bare metal installation with ZFS root filesystem.

## Features

- **Single Host**: Pre-configured for 'nixies' hostname
- **ZFS Root**: Automated ZFS setup with datasets for /, /nix, /home, /var
- **Hardware Optimized**: AMD CPU with NVMe storage support
- **Security Focused**: SSH hardening, fail2ban, AppArmor, secure defaults
- **Minimal Dependencies**: Only essential packages and services

## Quick Installation

Install to bare metal NVMe drive:

```bash
nix run github:anthonymoon/nixos-unified#install /dev/nvme0n1
```

## What's Included

### Core Files
- `flake.nix` - Minimal flake with single host configuration
- `hardware.nix` - Hardware-specific configuration for 'nixies' host
- `profile.nix` - System configuration (services, packages, users)
- `disko.nix` - ZFS disk partitioning configuration

### Default Configuration
- **Hostname**: nixies
- **User**: admin (no password - SSH keys only)
- **Filesystem**: ZFS with rpool (root, nix, home, var datasets)
- **Boot**: UEFI with systemd-boot
- **Network**: DHCP on all interfaces
- **Security**: SSH hardening, fail2ban, AppArmor enabled

## Post-Installation

1. Reboot into the new system
2. Set admin password: `passwd admin`
3. Add SSH keys: `~/.ssh/authorized_keys`
4. Customize `/etc/nixos/configuration.nix` as needed

## Architecture

```
Hardware Detection → Disko Partitioning → NixOS Installation
     ↓                      ↓                     ↓
  hardware.nix         ZFS Layout           System Config
(AMD/NVMe optimized)   (rpool datasets)    (profile.nix)
```

This is a drastically simplified version of the original nixos-unified framework, focused on a single use case: reliable bare metal NixOS installation with ZFS.