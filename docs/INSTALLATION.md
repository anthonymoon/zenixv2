# NixOS Installation Guide

This guide covers installing NixOS with ZFS root filesystem on AMD64 UEFI systems.

## Prerequisites

- NixOS installer ISO (23.11 or newer)
- UEFI-capable system with AMD CPU
- NVMe SSD (tested with Crucial T500)
- Internet connection for downloading packages

## Installation Methods

### Method 1: Automated Disko Installation (Recommended)

Disko provides declarative disk partitioning and formatting.

```bash
# Boot from NixOS installer ISO and open a terminal

# Clone the configuration repository
git clone https://github.com/anthonymoon/zenixv2.git
cd zenixv2

# Run disko to automatically partition and format
sudo nix --experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode disko hosts/nixie/disko.nix

# Install NixOS with the flake configuration
sudo nixos-install --flake .#nixie

# Reboot into the new system
sudo reboot
```

### Method 2: Manual ZFS Installation (Fallback)

Use this method if disko fails or for custom partitioning needs.

```bash
# Boot from NixOS installer ISO and open a terminal

# Clone the configuration repository
git clone https://github.com/anthonymoon/zenixv2.git
cd zenixv2

# Run the fallback installation script
sudo bash hosts/nixie/install-zfs-fallback.sh

# Copy the flake configuration to the new system
sudo cp -r . /mnt/etc/nixos/

# Install NixOS
sudo nixos-install --flake /mnt/etc/nixos#nixie

# Reboot
sudo reboot
```

## ZFS Configuration Details

### Pool Layout

The installation creates a ZFS pool named `rpool` with the following datasets:

| Dataset | Mount Point | Purpose | Optimizations |
|---------|-------------|---------|---------------|
| rpool/root | / | System root | recordsize=128k |
| rpool/home | /home | User data | recordsize=128k, dedup=on |
| rpool/nix | /nix | Nix store | sync=disabled, dedup=on |
| rpool/var | /var | Variable data | recordsize=128k |
| rpool/var/lib | /var/lib | Application data | recordsize=16k |
| rpool/var/lib/docker | /var/lib/docker | Docker storage | recordsize=1M, dedup=off |
| rpool/var/log | /var/log | System logs | logbias=throughput |
| rpool/var/lib/libvirt | /var/lib/libvirt | VM storage | recordsize=1M, compression=off |
| rpool/tmp | /tmp | Temporary files | sync=disabled, compression=lz4 |

### Performance Optimizations

- **Deduplication**: Enabled for `/home` and `/nix` to save space
- **Record sizes**: Optimized per dataset type (databases: 16k, VMs: 1M)
- **Sync behavior**: Disabled for `/nix` and `/tmp` for better performance
- **Compression**: ZStandard globally, LZ4 for `/tmp`
- **ARC**: Automatically tuned based on system RAM

## Post-Installation Setup

### First Boot

```bash
# Set your user password
passwd $USER

# Initialize home-manager
home-manager switch --flake /etc/nixos#amoon@nixie
```

### Verify Installation

```bash
# Check ZFS pool status
zpool status

# List ZFS datasets
zfs list

# Check mount points
mount | grep zfs

# Verify network bonding (if configured)
ip link show bond0
```

### System Management

```bash
# Update the system
sudo nixos-rebuild switch --flake /etc/nixos#nixie

# Update home configuration
home-manager switch --flake /etc/nixos#amoon@nixie

# Clean old generations
sudo nix-collect-garbage -d
```

## Troubleshooting

### ZFS Import Issues

If the pool fails to import on boot:

```bash
# Boot from installer ISO
# Import pool manually
zpool import -f rpool

# Check for errors
zpool status -v

# Clear errors if needed
zpool clear rpool
```

### Boot Issues

If system fails to boot:

1. Boot from installer ISO
2. Import and mount ZFS pool:
   ```bash
   zpool import -R /mnt rpool
   mount /dev/disk/by-label/EFI /mnt/boot
   ```
3. Chroot and rebuild:
   ```bash
   nixos-enter
   nixos-rebuild boot
   ```

### Network Configuration

The system is configured for:
- Dual 10GbE bonded interfaces (20Gbps aggregate)
- LACP mode 4 (802.3ad)
- Optimized TCP settings for high throughput

To verify bonding:
```bash
cat /proc/net/bonding/bond0
```

## Hardware Support

This configuration includes:
- AMD GPU drivers (amdgpu)
- Vulkan support
- PipeWire audio with low latency
- Game controller support
- Intel WiFi drivers

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [ZFS on Linux Documentation](https://openzfs.github.io/openzfs-docs/)
- [Disko Documentation](https://github.com/nix-community/disko)