# ZenixV2 - NixOS Configuration

A modern NixOS configuration with ZFS, AMD GPU support, and high-performance networking.

## Features

- 🎨 **Hyprland Desktop** - Wayland compositor via [omarchy-nix](https://github.com/henrysipp/omarchy-nix)
- 💾 **ZFS Filesystem** - Advanced storage with compression and deduplication
- 🚀 **AMD GPU** - Full Vulkan and Wayland support
- 🌐 **20Gbps Networking** - Dual 10GbE with LACP bonding
- 🎮 **Gaming Ready** - Steam, GameMode, and low-latency audio
- 📦 **Declarative** - Fully reproducible system configuration

## Quick Start

### Installation

```bash
# Clone repository
git clone https://github.com/anthonymoon/zenixv2.git
cd zenixv2

# Automated install with disko
sudo nix --experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode disko hosts/nixie/disko.nix

# Install NixOS
sudo nixos-install --flake .#nixie
```

See [Installation Guide](docs/INSTALLATION.md) for detailed instructions and fallback options.

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- [Configuration Guide](docs/CONFIGURATION.md) - System customization and modules
- [Hardware Setup](hosts/nixie/hardware-configuration.nix) - Example hardware configuration

## System Configuration

### Hardware Support

- **CPU**: AMD Ryzen (with microcode updates)
- **GPU**: AMD with amdgpu driver
- **Network**: Intel i40e dual 10GbE
- **Storage**: NVMe with ZFS

### Key Modules

- `modules/hardware/amd` - AMD GPU configuration
- `modules/storage/zfs` - ZFS filesystem setup
- `modules/networking/bonding` - LACP network bonding
- `modules/networking/performance` - TCP optimizations
- `modules/services/samba` - SMB3 file sharing
- `modules/extras/pkgs` - Gaming and multimedia packages

### ZFS Layout

Optimized dataset configuration:
- Deduplication on `/home` and `/nix`
- Large recordsize for VMs and Docker
- Disabled sync for `/tmp` and `/nix`
- Throughput-optimized logging

## Usage

### System Management

```bash
# Update system
sudo nixos-rebuild switch --flake /etc/nixos#nixie

# Update home-manager
home-manager switch --flake /etc/nixos#amoon@nixie

# Check ZFS status
zpool status
zfs list
```

### Development

```bash
# Enter dev shell
nix develop

# Format code
nix develop -c nixfmt ./**/*.nix

# Run checks
nix flake check
```

## Customization

Edit `flake.nix` to modify:
```nix
omarchy = {
  full_name = "Your Name";
  email_address = "your@email.com";
  theme = "tokyo-night";
};
```

Available themes: `tokyo-night`, `kanagawa`, `everforest`, `catppuccin`, `nord`, `gruvbox`

## Performance Features

- **Network**: 20Gbps bonded connection with BBR congestion control
- **Storage**: ZFS with optimized recordsizes and deduplication
- **Audio**: PipeWire with 64-sample buffer (1.3ms latency)
- **Gaming**: GameMode, mangohud, and esync support

## Requirements

- UEFI boot mode
- AMD GPU (NVIDIA removed)
- 8GB+ RAM for ZFS
- NVMe SSD at `/dev/nvme0n1`

## Credits

Built on [omarchy-nix](https://github.com/henrysipp/omarchy-nix) by Henry Sipp.

## License

MIT