# nix-config

Configuration files for my NixOS machine.

A clean, minimal Nix configuration for a single host called "nixies".

## Features

- Single NixOS host configuration
- **ZFS Root**: Single disk ZFS configuration with no encryption
- **Pure Disko**: Complete declarative disk management using disk-by-id references
- Home Manager integration
- agenix for secrets management
- Modular configuration structure
- AMD CPU support with microcode updates
- UEFI boot with systemd-boot

## Installation

### Prerequisites

From your host, copy the public SSH key to the server

```bash
export NIXOS_HOST=192.168.2.xxx
ssh-add ~/.ssh/amoon
ssh-copy-id -i ~/.ssh/amoon root@$NIXOS_HOST
```

SSH into the host with agent forwarding enabled (for the secrets repo access)

```bash
ssh -A root@$NIXOS_HOST
```

### Disk Preparation

First, identify your disk using disk-by-id:

```bash
ls -la /dev/disk/by-id/
```

Look for your NVMe or SATA disk. Example output:
```
nvme-Samsung_SSD_970_EVO_Plus_1TB_S4P2NF0M419620D -> ../../nvme0n1
ata-Samsung_SSD_850_EVO_500GB_S21PNXAG803516N -> ../../sda
```

### Partitioning with Disko (ZFS)

This configuration uses ZFS on a single disk with pure disko management:

```bash
# Clone the repository first
git clone https://github.com/anthonymoon/nix-config-notthebees.git /tmp/nix-config
cd /tmp/nix-config

# IMPORTANT: Update the disk-by-id path in disko.nix
# Edit machines/nixos/nixies/disko.nix and replace "/dev/disk/by-id/nvme-CHANGEME" 
# with your actual disk-by-id path from the step above

# Run disko to partition, create ZFS pool, and mount filesystems
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko --flake .#nixies

# This will:
# - Create GPT partition table
# - Create 512M EFI boot partition (FAT32)
# - Create ZFS partition with remaining space
# - Create ZFS pool "rpool" with datasets:
#   - rpool/root (mounted at /)
#   - rpool/home (mounted at /home)
#   - rpool/nix (mounted at /nix)
#   - rpool/var (mounted at /var)
#   - rpool/persist (mounted at /persist)

# Copy the configuration to the mounted filesystem
cp -r /tmp/nix-config /mnt/etc/nixos
```

### Installation

```bash
# The disk should already be partitioned and mounted by disko at this point
# Repository should already be cloned to /mnt/etc/nixos

cd /mnt/etc/nixos

# Generate hardware configuration (disko handles filesystems, so use --no-filesystems)
nixos-generate-config --no-filesystems --root /mnt --dir /mnt/etc/nixos/machines/nixos/nixies

# Set up SSH key for agenix (optional, for secrets management)
mkdir -p /mnt/home/amoon/.ssh
# Copy your SSH key from the host machine if needed

# Install the system with pure disko disk management
nixos-install --no-root-passwd --flake .#nixies

# The system will use the disko-configured disk layout automatically
```

## Configuration Structure

```
├── flake.nix                    # Main flake configuration
├── flakeHelpers.nix            # Helper functions
├── machines/
│   └── nixos/
│       ├── _common/            # Common configuration
│       └── nixies/             # Host-specific configuration
│           ├── default.nix     # System config with ZFS support
│           ├── hardware-configuration.nix
│           └── disko.nix       # ZFS pool and dataset definitions
├── modules/                    # Custom NixOS modules
├── users/amoon/               # User configuration
└── dots/                      # Dotfiles
```

## ZFS Configuration Details

The system uses a single ZFS pool (`rpool`) with the following datasets:
- `rpool/root` → `/` - Root filesystem
- `rpool/home` → `/home` - User home directories
- `rpool/nix` → `/nix` - Nix store (atime=off for performance)
- `rpool/var` → `/var` - Variable data
- `rpool/persist` → `/persist` - Persistent state (useful for impermanence)

ZFS features enabled:
- **Compression**: LZ4 compression on all datasets
- **Auto-trim**: Weekly TRIM operations for SSD optimization
- **Auto-scrub**: Weekly data integrity checks
- **Stable paths**: Using `/dev/disk/by-id` for reliable device identification

## Deployment

After initial installation, you can rebuild the system:

```bash
sudo nixos-rebuild switch --flake .#nixies
```

## Secrets

Secrets are managed using [agenix](https://github.com/ryantm/agenix) and stored in a private repository.