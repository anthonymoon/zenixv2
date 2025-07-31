# NixOS Multi-Host Configuration with Disko-Install

A comprehensive NixOS configuration framework with automated disk management, hardware auto-detection, and performance optimizations.

## 🚀 Features

- **🔧 Dynamic Configuration**: Use `hostname.profile1.profile2` syntax for flexible system builds
- **💾 Auto Disk Detection**: Smart disk detection with preference for NVMe > SATA SSD > HDD
- **🗄️ Multiple Filesystems**: Support for Btrfs and ZFS with performance optimizations
- **🔒 Encryption Ready**: LUKS2 + TPM2 auto-unlock + Secure Boot (lanzaboote)
- **⚡ Performance Tuned**: NVMe optimizations, ZRAM swap, kernel tuning
- **🔧 Hardware Auto-Detection**: CPU, GPU, and platform detection with optimal configurations
- **📦 Local Binary Cache**: High-performance local Nix cache with automatic population

## 📋 Quick Start

### 1. Installation Methods

#### Interactive Installation (Recommended)
```bash
# Clone and enter the configuration directory
git clone https://github.com/anthonymoon/nixos-fun.git nixos-config
cd nixos-config

# Run interactive installer (experimental features enabled automatically)
./scripts/install-interactive.sh
```

#### Direct Installation
```bash
# Install with auto-detection (experimental features enabled automatically)
./scripts/install-host.sh laptop.kde.gaming.unstable

# Install with specific disk
./scripts/install-host.sh server.headless.stable /dev/nvme0n1

# Dry run to see what would happen
./scripts/install-host.sh workstation.hyprland.unstable --dry-run

# Mount existing system for recovery
./scripts/install-host.sh hostname --mount-only
```

#### Manual Installation
```bash
# Auto-detect disk and install
sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
  --flake '.#hostname.profiles' \
  --write-efi-boot-entries

# Specify disk explicitly
sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
  --flake '.#hostname.profiles' \
  --disk main /dev/nvme0n1 \
  --write-efi-boot-entries
```

### 2. Configuration Syntax

The configuration uses a dynamic naming scheme: `hostname.profile1.profile2.profile3`

**Available Profiles:**
- **Desktop Environments**: `kde`, `gnome`, `hyprland`, `niri`
- **System Types**: `stable`, `unstable`, `hardened`, `chaotic`
- **Use Cases**: `gaming`, `headless`

**Example Configurations:**
```bash
laptop.kde.gaming.unstable      # Gaming laptop with KDE on unstable
server.headless.hardened        # Headless server with security focus  
workstation.hyprland.unstable   # Hyprland workstation on unstable
vm.gnome.stable                 # GNOME VM on stable channel
desktop.kde.stable              # KDE desktop on stable
```

## 🗄️ Disk Configurations

### Filesystem Options

1. **Btrfs (Single Disk)**: `modules/disko/btrfs-single.nix`
   - Subvolumes: `@`, `@home`, `@nix`, `@var`, `@tmp`, `@snapshots`
   - Optimized mount options for NVMe/SSD
   - ZRAM swap (16GB max)

2. **Btrfs + LUKS**: `modules/disko/btrfs-luks.nix`
   - Full disk encryption with LUKS2
   - TPM2 auto-unlock support
   - Lanzaboote secure boot integration

3. **ZFS (Single Disk)**: `modules/disko/zfs-single.nix`
   - Datasets: `root`, `home`, `nix`, `var`, `tmp`
   - Auto-snapshots and scrubbing
   - Deduplication on nix store
   - Stable hostId generation from hostname

4. **ZFS + LUKS**: `modules/disko/zfs-luks.nix`
   - ZFS with LUKS encryption
   - TPM2 integration
   - Enterprise-grade reliability

### Partition Layout

All configurations use:
```
GPT Partition Table:
├── ESP (1GB) - EFI System Partition (FAT32)
└── Root - Remaining space
    ├── LUKS container (if encrypted)
    └── Btrfs/ZFS filesystem
```

## 🔧 Advanced Features

### Nix Configuration

The system automatically enables:
- **Experimental Features**: `nix-command` and `flakes` enabled by default
- **Performance Optimizations**: Auto-optimise store, parallel builds
- **Binary Caches**: NixOS, nix-community, Hyprland, and Chaotic-AUR caches
- **Environment Variables**: `NIX_CONFIG` set automatically for all users
- **Garbage Collection**: Weekly automatic cleanup of old generations

### Auto-Detection System

The system automatically detects:
- **CPU**: Intel vs AMD with appropriate optimizations
- **GPU**: NVIDIA, AMD, or Intel with driver configuration  
- **Storage**: NVMe vs SATA with optimal I/O schedulers
- **Platform**: Physical vs Virtual with appropriate settings

### Performance Optimizations

- **NVMe Specific**: No I/O scheduler, optimal queue depths, polling
- **ZRAM Swap**: 16GB compressed swap using ZSTD
- **Kernel Tuning**: BBR congestion control, optimized VM settings
- **File System**: Async TRIM, optimized mount options
- **CPU**: Performance governor, C-state limits for low latency

### TPM2 + Secure Boot

For encrypted configurations:
1. **Automatic TPM2 enrollment** for passwordless boot
2. **Lanzaboote** for secure boot with UEFI signing
3. **Recovery password** as fallback option
4. **PCR policy** (0,1,2,3,7) for security

## 🔧 System Modules

### Performance Module
```nix
# In your host configuration
imports = [ ./modules/system/performance.nix ];
```
Includes: ZRAM swap, kernel tuning, I/O optimization, CPU performance settings

### Boot Module  
```nix
imports = [ ./modules/system/boot.nix ];
```
Includes: Optimized initrd, kernel modules, boot parameters

### Maintenance Module
```nix
imports = [ ./modules/system/maintenance.nix ];

maintenance = {
  enable = true;
  nix.garbageCollect.enable = true;
  filesystem.scrub = true;
  logs.cleanup = true;
};
```
Includes: Automatic cleanup, filesystem maintenance, performance monitoring

## 🏗️ Project Structure

```
nixos-cachydotlocal/
├── flake.nix                    # Main flake with dynamic configuration
├── lib/
│   └── disk-detection.nix       # Auto-detection utilities
├── modules/
│   ├── disko/                   # Disk configurations
│   │   ├── btrfs-single.nix     # Btrfs single disk
│   │   ├── btrfs-luks.nix       # Btrfs + LUKS encryption  
│   │   ├── zfs-single.nix       # ZFS single disk
│   │   └── zfs-luks.nix         # ZFS + LUKS encryption
│   └── system/                  # System optimization modules
│       ├── performance.nix      # Performance tuning
│       ├── boot.nix             # Boot optimization
│       └── maintenance.nix      # Automated maintenance
├── profiles/                    # User-facing profiles
│   ├── kde/                     # KDE desktop environment
│   ├── gnome/                   # GNOME desktop environment
│   ├── headless/                # Server/headless configuration
│   ├── gaming/                  # Gaming optimizations
│   └── ...                      # Additional profiles
├── hardware/                    # Hardware detection and modules
│   ├── auto-detect.nix          # Main hardware detection
│   └── modules/                 # Hardware-specific modules
├── scripts/                     # Installation and management
│   ├── install-interactive.sh   # Interactive installer
│   └── install-host.sh          # Direct host installer
└── hosts/                       # Host-specific overrides
    └── hostname/
        └── default.nix          # Host-specific configuration
```

## 🔧 Customization

### Adding Custom Disk Detection

```nix
# In your host configuration
disko.primaryDisk = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_...";

# Or use pattern matching
disko.primaryDisk = diskLib.detectDiskByPattern {
  patterns = [ ".*Samsung.*" ".*WD.*" ];
  fallback = diskLib.detectPrimaryDisk { preferNvme = true; };
};
```

### Host-Specific Overrides

Create `hosts/hostname/default.nix`:
```nix
{ config, lib, pkgs, ... }:
{
  # Override auto-detected disk
  disko.primaryDisk = "/dev/nvme1n1";
  
  # Host-specific hardware
  hardware.nvidia.enable = true;
  
  # Custom services
  services.nginx.enable = true;
  
  # Performance tweaks
  maintenance.nix.garbageCollect.options = "--delete-older-than 7d";
}
```

### Custom Profiles

Create new profiles in `profiles/`:
```nix
# profiles/development/default.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vscode
    docker
    nodejs
    python3
  ];
  
  virtualisation.docker.enable = true;
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Flake check fails**: This is expected due to the dynamic configuration system
2. **Disk not detected**: Use manual disk specification with `--disk main /dev/...`
3. **TPM2 enrollment fails**: Ensure TPM2 is enabled in BIOS and `tpm2-tools` are available
4. **Secure boot issues**: Disable secure boot initially, set up lanzaboote, then re-enable

### Debugging

```bash
# Check detected hardware
nix eval .#lib.detectPrimaryDisk
nix eval .#nixosConfigurations.hostname.config.hardware

# Test disk detection
nix run .#lib.disk-detection.getAllDisks

# Validate configuration
nix build .#nixosConfigurations.hostname.config.system.build.toplevel

# Mount for debugging
sudo ./scripts/install-host.sh hostname --mount-only
sudo nixos-enter
```

### Recovery

```bash
# Mount existing system
sudo ./scripts/install-host.sh hostname --mount-only

# Enter system for repair
sudo nixos-enter

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Fix bootloader
sudo nixos-rebuild switch --install-bootloader
```

## 📚 References

- [Disko Documentation](https://github.com/nix-community/disko)
- [Lanzaboote (Secure Boot)](https://github.com/nix-community/lanzaboote)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Package Manager](https://nixos.org/manual/nix/stable/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with `nix flake check`
4. Submit a pull request

## 📄 License

This configuration is provided as-is for educational and personal use. Please review and understand all configurations before deployment, especially security-related settings.