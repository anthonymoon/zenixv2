# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS ephemeral root system configuration using ZFS. The root filesystem resets to a clean state on every boot, with only explicitly defined paths persisting across reboots.

## Key Commands

### Development
```bash
# Enter development shell with pre-commit hooks
nix develop

# Build the system configuration
nixos-rebuild build --flake .#nixos

# Check flake validity
nix flake check

# Format all Nix files
alejandra .
```

### Installation from LiveCD
```bash
# Enable flakes on LiveCD
nix-shell -p nixFlakes
export NIX_CONFIG="experimental-features = nix-command flakes"

# Run installation with parameters
./install.sh <hostname> <username> <disk>
# Example: ./install.sh myhost myuser /dev/nvme0n1
```

### System Management
```bash
# Apply configuration changes (replace hostname with actual)
sudo nixos-rebuild switch --flake .#<hostname>

# Test configuration without switching
sudo nixos-rebuild test --flake .#<hostname>

# Check ZFS status
zfs list -t all
zpool status
```

### Testing
```bash
# Run all tests
./tests/run-all-tests.sh
```

## Architecture

### Ephemeral Root Design
The system uses ZFS snapshots to implement ephemeral root. The key mechanism is in `hardware/hardware-configuration.nix`:
- A systemd service `rollback-root` runs in initrd before mounting root
- It executes `zfs rollback -r rpool/nixos/empty@start` to reset the root dataset
- This ensures `/` always boots from a clean snapshot

### Persistent Paths
These directories survive reboots:
- `/home` - User data
- `/nix` - Nix store (required for system operation)
- `/persist` - Explicit persistent storage
- `/var/log` - System logs
- `/var/lib` - Application state
- `/etc/nixos` - System configuration

### ZFS Dataset Structure
```
rpool/nixos/empty     → / (ephemeral, rolled back on boot)
rpool/nixos/nix       → /nix
rpool/nixos/home      → /home
rpool/nixos/persist   → /persist
rpool/nixos/var/log   → /var/log
rpool/nixos/var/lib   → /var/lib
rpool/nixos/config    → /etc/nixos
rpool/docker          → /var/lib/containers (50GB zvol)
rpool/reserved        → (10% space reservation)
```

### Critical Files for Persistence
The configuration handles persistence in two ways:

1. **Direct mounting**: ZFS datasets mounted to persistent paths
2. **Symlinks/bind mounts**: Created via `systemd.tmpfiles.rules` in `configuration.nix` for NetworkManager state
3. **SSH host keys**: Stored in `/persist/etc/ssh/` and referenced in `services.openssh.hostKeys`
4. **Machine ID**: Persisted via `environment.etc."machine-id".source`

### Important Configuration Details
- **Templates**: Configuration uses `@HOSTNAME@`, `@USERNAME@`, and `@DISK_ID@` placeholders
- **Hardware**: Optimized for ASUS B550-F, Ryzen 5600X, and Radeon 7800XT
- **Host ID**: Set to `"deadbeef"` in hardware config - should be unique per system
- **Boot**: Uses systemd-boot (UEFI only), NOT GRUB
- **Compression**: LZ4 enabled on all datasets for performance
- **Reserved space**: 10% to prevent ZFS performance degradation

### Critical ZFS Configuration (Often Forgotten)
- **boot.initrd.supportedFilesystems = ["zfs"]** - Required for ZFS root filesystem
- **zfsutil mount option** - Added to all ZFS filesystems for proper mount ordering
- **ESP mounted at /boot** - systemd-boot requires this (not /boot/efi)
- **2GB ESP size** - Larger than typical 512MB for kernel/initrd storage with ZFS
- **Kernel selection** - Uses `pkgs.linuxPackages_6_6` (LTS) for ZFS stability
- **NixOS 25.05** - Configuration locked to stable channel for reliability

### Hardware Optimizations
- AMD P-State driver enabled for Zen 3 CPU power management
- IOMMU enabled for virtualization support
- PCIe ASPM disabled for B550 stability
- AMDGPU driver configured for Radeon 7800XT
- Early GPU initialization in initrd
- Uses `hardware.graphics` (NixOS 24.11+ compatible) instead of deprecated `hardware.opengl`

When modifying the system, remember that any changes outside persistent paths will be lost on reboot. All system modifications must be declarative in the Nix configuration.