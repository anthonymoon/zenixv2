# Dynamic Installation with Hardware Detection

This flake supports fully dynamic installation that automatically detects your hardware and configures the system accordingly.

## Features

- **Automatic Hardware Detection**: Uses nixos-facter to detect CPU, memory, disks, and boot mode
- **Dynamic Disk Selection**: Automatically selects NVMe or SATA disks
- **UEFI/BIOS Detection**: Configures boot loader based on detected firmware
- **ZFS Optimization**: Tunes ZFS ARC based on available memory
- **GPU Detection**: Automatically configures graphics drivers

## Quick Start

### One-Command Installation

```bash
# Run the automatic installer
sudo nix run github:anthonymoon/zenixv2#install-auto
```

This will:
1. Detect your hardware using nixos-facter
2. Display detected hardware for confirmation
3. Automatically select the primary disk
4. Partition and format using disko
5. Install NixOS with optimal configuration

### Custom Options

```bash
# Use a specific hostname
HOSTNAME=my-system nix run github:anthonymoon/zenixv2#install-auto

# Use a different ZFS pool name
POOL_NAME=tank nix run github:anthonymoon/zenixv2#install-auto
```

## Manual Steps

If you prefer to run each step manually:

### 1. Hardware Detection

```bash
# Generate hardware report
sudo nix run nixpkgs#nixos-facter -- -o facter.json

# View the report
cat facter.json | jq .
```

### 2. Dynamic Disko Configuration

The `auto-zfs` configuration automatically adapts based on detected hardware:

```bash
# Format and mount with auto-detection
nix run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake github:anthonymoon/zenixv2#auto-zfs
```

### 3. Install NixOS

```bash
nixos-install --flake github:anthonymoon/zenixv2#auto-zfs
```

## How It Works

### Hardware Detection

The installer uses nixos-facter to detect:
- **CPU**: Intel vs AMD for KVM modules
- **Memory**: For ZFS ARC tuning
- **Disks**: NVMe preferred over SATA
- **Boot Mode**: UEFI vs BIOS
- **GPU**: NVIDIA, AMD, or Intel

### Dynamic Configuration

Based on detection, the system automatically:
- Selects the appropriate disk device
- Configures UEFI or BIOS boot
- Sets up GPU drivers
- Tunes ZFS parameters
- Configures CPU-specific features

### Disk Layout

The dynamic configuration creates:
- **ESP/BIOS Boot**: 512MB for UEFI, 1MB for BIOS
- **ZFS Pool**: Remaining space with:
  - `rpool/root`: Root filesystem
  - `rpool/nix`: Nix store (optimized)
  - `rpool/home`: User data
  - `rpool/var`: Variable data (optimized)

## Customization

### Using Your Own Facter Report

```bash
# Generate report
sudo nixos-facter -o my-hardware.json

# Use it for installation
nix run github:anthonymoon/zenixv2#install-auto -- --facter-report my-hardware.json
```

### Extending Auto-Detection

The `hosts/auto-zfs/default.nix` configuration can be extended to detect and configure:
- Network interfaces
- Wireless cards
- Bluetooth adapters
- USB devices
- Special hardware

## Troubleshooting

### No Disk Detected

If the installer can't find a suitable disk:
1. Check `lsblk` to see available disks
2. Manually specify: `DISK=/dev/sda nix run ...`

### Detection Fails

If hardware detection fails:
1. Run `nixos-facter` manually to see errors
2. Check dmesg for hardware issues
3. Use a static configuration like `minimal-zfs`

### ZFS Pool Exists

If you get "pool already exists":
```bash
zpool destroy -f rpool
wipefs -af /dev/nvme0n1  # or your disk
```

## Architecture

The dynamic installation system consists of:

1. **nixos-facter**: Hardware detection tool
2. **dynamic-disko.nix**: Configuration generator
3. **auto-zfs host**: Adaptive NixOS configuration
4. **install-auto app**: Orchestration script

This provides a fully declarative, reproducible installation that adapts to any hardware.