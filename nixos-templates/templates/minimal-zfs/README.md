# NixOS ZFS Minimal

A minimal, maintainable NixOS configuration with ZFS root filesystem on GPT partition table with FAT32 ESP. Designed for both physical and virtual machine deployments.

## Features

- **ZFS native encryption** support
- **GPT partitioning** with FAT32 ESP for UEFI boot
- **Automatic snapshots** with configurable retention
- **Weekly scrubs** for data integrity
- **Optimized for both physical and VM** deployments
- **Single command installation**
- **Declarative disk partitioning** with disko

## Directory Structure

```
.
├── flake.nix           # Flake configuration
├── hardware/
│   ├── physical.nix    # Physical machine disk config
│   └── vm.nix          # Virtual machine disk config
├── modules/
│   └── zfs-root.nix    # ZFS-specific configuration
├── profiles/
│   └── base.nix        # Base system configuration
└── install.sh          # Installation script
```

## Installation

### Prerequisites

Boot from NixOS installer ISO (24.05 or newer with flakes enabled).

### Quick Install

```bash
# Physical machine
./install.sh /dev/sda

# Virtual machine
./install.sh /dev/vda zfs-vm

# Custom swap size (default: 8G)
SWAP_SIZE=16G ./install.sh /dev/sda

# No swap
SWAP_SIZE=0 ./install.sh /dev/sda
```

### Manual Installation

```bash
# Build and run disko
nix build .#nixosConfigurations.zfs-physical.config.system.build.diskoScript
sudo ./result

# Install NixOS
sudo nixos-install --root /mnt --flake .#zfs-physical --no-root-passwd
```

## Configuration

### Disk Layout

- **ESP**: 1GB FAT32 partition for UEFI boot
- **ZFS Pool**: Remaining space with the following datasets:
  - `zroot/root` - Root filesystem (/)
  - `zroot/nix` - Nix store (/nix)
  - `zroot/home` - User home directories (/home)
  - `zroot/var` - Variable data (/var)
  - `zroot/tmp` - Temporary files (/tmp)
  - `zroot/swap` - Swap zvol (optional)

### ZFS Settings

- **Compression**: LZ4 (fast and efficient)
- **ARC limit**: 2GB (physical), 512MB (VM)
- **Auto-trim**: Enabled for SSDs
- **Snapshots**: Automatic with smart retention
- **Scrub**: Weekly data integrity checks

### Customization

1. **Change hostname**: Edit `networking.hostName` in `profiles/base.nix`
2. **Add SSH keys**: Add keys to `users.users.nixos.openssh.authorizedKeys.keys`
3. **Modify ZFS layout**: Edit dataset configuration in `hardware/physical.nix`
4. **Adjust ARC size**: Modify `boot.kernelParams` in `modules/zfs-root.nix`

## Usage

### System Management

```bash
# Rebuild system
nixos-rebuild switch --flake .#zfs-physical

# Update flake inputs
nix flake update

# Garbage collection
nix-collect-garbage -d
```

### ZFS Management

```bash
# Check pool status
zpool status

# List datasets
zfs list

# List snapshots
zfs list -t snapshot

# Create manual snapshot
zfs snapshot -r zroot@manual-$(date +%Y%m%d-%H%M%S)

# Restore from snapshot
zfs rollback zroot/home@snapshot-name
```

## VM-Specific Notes

The VM configuration includes:
- Reduced ARC size (512MB)
- VirtIO drivers for better performance
- QEMU guest agent
- Spice integration

## Security Considerations

- Root login via SSH is disabled
- Password authentication is disabled
- Initial user password should be changed immediately
- Consider enabling ZFS native encryption for sensitive data

## Performance Tuning

- Disable atime updates on most datasets
- Use legacy mountpoints for better control
- Sync disabled on /tmp for performance
- Separate datasets allow independent tuning

## Troubleshooting

### Boot Issues

```bash
# From installer ISO
zpool import -f zroot
mount -t zfs zroot/root /mnt
mount -t zfs zroot/nix /mnt/nix
mount /dev/disk/by-label/ESP /mnt/boot
nixos-enter
```

### Pool Import Issues

```bash
# Force import
zpool import -f zroot

# Import with different root
zpool import -R /mnt zroot
```

## License

MIT