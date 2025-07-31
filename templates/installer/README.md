# NixOS Installer - UEFI AMD Systems

This template provides a simplified NixOS installer for UEFI AMD systems with NVMe drives.

## Prerequisites

- UEFI system with AMD CPU
- NVMe drive at `/dev/nvme0n1`
- NixOS live environment
- Root access

## Usage

### Installation

From the NixOS installer environment:

```bash
# Initialize the installer
nix flake init -t github:anthonymoon/zenixv2#installer

# Run the installer (no hardware detection needed)
sudo nix run .
```

## What It Does

1. **Disk Configuration**: 
   - GPT partitioning on `/dev/nvme0n1`
   - 512MB EFI System Partition
   - ZFS root pool (rpool) with optimized datasets

2. **System Installation**: Uses `disko-install` to:
   - Partition and format `/dev/nvme0n1`
   - Create ZFS datasets (root, nix, home, var)
   - Mount filesystems
   - Install NixOS with systemd-boot
   - Configure AMD CPU modules

## System Configuration

This installer is configured for:
- **Boot**: UEFI with systemd-boot
- **CPU**: AMD (kvm-amd module)
- **Disk**: `/dev/nvme0n1` only
- **Filesystem**: ZFS with compression

### Add Custom Configuration

```nix
# In flake.nix, add to the modules section:
{
  # Your custom configuration
  services.openssh.enable = true;
  users.users.myuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
```

## Troubleshooting

### Requirements Not Met

This installer requires:
- UEFI boot mode
- AMD CPU
- NVMe drive at `/dev/nvme0n1`

If your system doesn't meet these requirements, you'll need to use a different installer configuration.

### Installation Fails

Check:
- Disk is not in use: `lsblk`
- No existing ZFS pools: `zpool list`
- Sufficient disk space
- Network connectivity for package downloads