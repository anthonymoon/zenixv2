# Declarative Disk Management with Disko

This flake includes declarative disk configurations using [disko](https://github.com/nix-community/disko).

## Installation Methods

### Method 1: Direct Disko Formatting (Recommended)

Format the disk and install in one command:

```bash
# Set your target disk (default: /dev/nvme0n1)
export DISK=/dev/nvme0n1

# Format disk and install
nix run github:nix-community/disko -- \
  --mode disko \
  --flake github:anthonymoon/zenixv2#minimal-zfs

# Then install NixOS
nixos-install --flake github:anthonymoon/zenixv2#minimal-zfs
```

### Method 2: Using Flake's Format App

```bash
# Set your target disk
export DISK=/dev/nvme0n1

# Run the format app
nix run github:anthonymoon/zenixv2#format-minimal-zfs

# Then install
nixos-install --flake github:anthonymoon/zenixv2#minimal-zfs
```

### Method 3: Two-Step Process

```bash
# Step 1: Format the disk
nix run github:nix-community/disko -- \
  --mode format \
  --flake github:anthonymoon/zenixv2#minimal-zfs \
  --arg device '"/dev/nvme0n1"'

# Step 2: Mount the filesystems
nix run github:nix-community/disko -- \
  --mode mount \
  --flake github:anthonymoon/zenixv2#minimal-zfs

# Step 3: Install NixOS
nixos-install --flake github:anthonymoon/zenixv2#minimal-zfs
```

## Disk Layout

The `minimal-zfs` configuration creates:

- **ESP Partition**: 512MB FAT32 for `/boot`
- **ZFS Pool**: Remaining space with:
  - `zroot/root`: Root filesystem
  - `zroot/nix`: Nix store (atime=off for performance)
  - `zroot/home`: User home directories
  - `zroot/var`: Variable data (atime=off)

## ZFS Settings

- **Compression**: LZ4 (fast and efficient)
- **ashift**: 12 (4K sectors, optimal for NVMe)
- **autotrim**: Enabled for SSD optimization
- **atime**: Disabled on nix and var for performance
- **xattr**: SA (system attributes) for better performance
- **acltype**: POSIX ACLs for compatibility

## Customizing Disk Configuration

To use a different disk device:

```bash
# For SATA SSD
export DISK=/dev/sda

# For second NVMe
export DISK=/dev/nvme1n1
```

## Troubleshooting

### "Device is busy"
The disk might have existing partitions or filesystem. Wipe it first:
```bash
wipefs -af $DISK
```

### "Pool already exists"
If a ZFS pool named `zroot` already exists:
```bash
zpool destroy zroot
```

### "No such pool"
If you get pool errors during install, ensure the pool is imported:
```bash
zpool import zroot
```

## Adding Disko to Other Configurations

To add disko support to other host configurations:

1. Create a `disko.nix` file in the host directory
2. Import it in the host's `default.nix`
3. Add the configuration to `diskoConfigurations` in `flake.nix`
4. Create a format app in the flake

See `hosts/minimal-zfs/disko.nix` for an example.