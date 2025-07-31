# NixOS Ephemeral Root ZFS Installation

This configuration creates a NixOS system with an ephemeral root filesystem that resets on every boot.

## Features

- Root filesystem (`/`) resets to clean state on every boot
- Persistent data in `/home`, `/nix`, `/persist`, `/var/log`, `/var/lib`, `/etc/nixos`
- ZFS with LZ4 compression
- systemd-boot (UEFI) with proper ZFS integration
- Pre-commit hooks for code quality
- Critical ZFS boot configuration (often missed in other guides)
- Minimal system with systemd-networkd and zsh
- zram swap (50% of RAM) with zstd compression
- Support for exFAT, XFS, and NTFS filesystems
- Intel 40GbE (i40e) and Mac HID support
- DHCP enabled on all network interfaces
- SSH access enabled for root, amoon, and nixos users
- **Cachix binary caches for 50-80% faster installations**
- Parallel downloads and multi-core builds

## Hardware Requirements

- ASUS B550-F motherboard (or compatible B550 chipset)
- AMD Ryzen 5600X CPU (Zen 3 architecture)
- AMD Radeon 7800XT GPU (RDNA3)
- UEFI boot support

## Installation Methods

### Method 1: Direct from GitHub URL
Boot NixOS installer and run directly:
```bash
# Set root password first for SSH access
passwd

# Run installer from GitHub
bash <(curl -sL https://raw.githubusercontent.com/anthonymoon/zfs/main/install-from-url.sh) hostname /dev/nvme0n1
```

### Method 2: Remote Installation via SSH
From your local machine:
```bash
# Clone the repository locally
git clone https://github.com/anthonymoon/zfs
cd zfs

# Run remote installer
./remote-install.sh 192.168.1.100 hostname /dev/nvme0n1
```

### Method 3: Local Installation
1. Boot NixOS minimal installer ISO
2. Enable flakes:
   ```bash
   export NIX_CONFIG="experimental-features = nix-command flakes"
   ```
3. Clone this repository
4. Run installation:
   ```bash
   ./install.sh hostname /dev/nvme0n1
   # Or use optimized installer for faster installation:
   ./install-optimized.sh hostname /dev/nvme0n1
   ```

## Default Credentials
All users have default password: `nixos` (change after first login)
- root: Full system access
- amoon: Primary user with sudo
- nixos: Installation/recovery user

SSH key is pre-authorized for all users.

## Network and SSH Configuration

### Network
- All network interfaces (en*, eth*) are configured for DHCP automatically
- systemd-networkd manages network configuration
- IPv6 is enabled with router advertisements accepted

### SSH Access
- SSH is enabled and starts automatically on boot
- Password authentication is enabled
- Root login is permitted (useful during initial setup)
- Three users have SSH access: root, amoon, and nixos

To add SSH keys, edit `/etc/nixos/configuration.nix` and add your public keys to the appropriate user's `openssh.authorizedKeys.keys` array before installation.

## Multi-Host Configuration (Master Flake)

This repository includes `flake-master.nix` which supports multiple hosts in a single flake. This enables:

### Automatic Hostname Matching
```bash
# On any configured host, simply run:
sudo nixos-rebuild switch --flake /path/to/repo
# It automatically uses the configuration matching the machine's hostname
```

### Remote Deployment
```bash
# Build locally and deploy to remote host:
sudo nixos-rebuild switch --flake .#homeserver --target-host root@192.168.1.100

# Or deploy directly from GitHub:
sudo nixos-rebuild switch --flake github:anthonymoon/zfs#homeserver --target-host root@192.168.1.100
```

### Adding New Hosts
Edit `flake-master.nix` and add your host:
```nix
nixosConfigurations = {
  "your-hostname" = mkHost "your-hostname" "your-disk-id";
  # ... other hosts
};
```

Then rename `flake-master.nix` to `flake.nix` to use the multi-host configuration.

## Performance Optimizations

### Binary Caches (Cachix)
This configuration uses multiple binary caches for significantly faster installations:

- **cache.nixos.org**: Official NixOS cache
- **nix-community.cachix.org**: Community packages
- **nixpkgs-unfree.cachix.org**: Unfree packages

Benefits:
- 50-80% faster installation times
- Pre-built packages instead of compiling from source
- Reduced bandwidth usage
- Lower CPU usage during installation

### Optimization Features
- **Parallel downloads**: Multiple packages download simultaneously
- **Multi-core builds**: Uses all CPU cores when building
- **Smart caching**: Keeps build outputs for reuse
- **Connection optimization**: Fast timeouts and retry logic

### Enable Cachix on Existing Systems
Run the setup script:
```bash
sudo ./setup-cachix.sh
```

Or manually add to `/etc/nixos/configuration.nix`:
```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://nixpkgs-unfree.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
  ];
};
```

## Working with Ephemeral Root

### What Persists
- `/home` - User data
- `/nix` - Nix store  
- `/persist` - Explicit persistent storage
- `/var/log` - System logs
- `/var/lib` - Application state
- `/etc/nixos` - System configuration

### What Doesn't Persist
- `/` - Root filesystem
- `/tmp` - Temporary files
- Any file not in persistent paths

### Testing Ephemeral Root
```bash
touch /test-file        # Create file in root
ls -la /test-file      # File exists
sudo reboot            # Reboot system
ls -la /test-file      # File is gone
```

## Development

Enter development shell with pre-commit hooks:
```bash
nix develop
```

The hooks will automatically format Nix files on commit.

### Testing

Run all tests:
```bash
./tests/run-all-tests.sh
```

Individual tests:
- `tests/test-template-replacement.sh` - Tests template substitution
- `tests/test-install-script.sh` - Tests parameter validation
- `tests/test-ephemeral-root.sh` - Tests ephemeral root configuration

## Template System

This configuration uses templates that are replaced during installation:
- `@HOSTNAME@` - System hostname
- `@DISK_ID@` - Target disk ID for installation

The primary user is hardcoded as `amoon` for consistency.