# ZenixV2 - Unified NixOS Configuration Framework

A modular, maintainable NixOS configuration framework that consolidates multiple system configurations into a single, well-organized flake.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Available Configurations](#available-configurations)
- [Module System Architecture](#module-system-architecture)
- [Usage Guide](#usage-guide)
- [System Profiles](#system-profiles)
- [API Reference](#api-reference)
- [Migration Guide](#migration-guide)
- [Contributing](#contributing)

## Features

- 🚀 **Modular Architecture** - Reusable modules for common functionality
- 🔧 **Auto-Detection** - Automatic hardware detection for CPU, GPU, and platform
- 💾 **Storage Flexibility** - Unified ZFS, tmpfs, and standard filesystem support
- 🎨 **Desktop Environment** - Modern Hyprland Wayland compositor
- 🔒 **Security Profiles** - From minimal to fully hardened configurations
- 📦 **Smart Caching** - Integrated Cachix with local cache support
- 🏗️ **Profile System** - Mix and match configurations for different use cases

## Quick Start

### Pure Nix Installation (Recommended)

```bash
# Generate hardware-specific installer
sudo nix run github:anthonymoon/zenixv2#generate-installer

# This creates a hardware-specific installer that:
# - Detects your hardware using nixos-facter
# - Generates optimal disk configuration
# - Creates a ready-to-run installer

# The command will output the location of generated installer
# Navigate there and run: nix run .
```

### Direct Installation

```bash
# Install a specific configuration to a specific disk
sudo DISK=/dev/nvme0n1 nix run github:anthonymoon/zenixv2#install-minimal-zfs

# Or using disko-install directly
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake github:anthonymoon/zenixv2#minimal-zfs \
  --disk main /dev/nvme0n1
```

### Hardware-Specific Template

```bash
# Create installer in current directory
nix flake init -t github:anthonymoon/zenixv2#installer

# Detect hardware (requires root)
sudo nix run nixpkgs#nixos-facter -- -o facter.json

# Install with detected hardware
sudo nix run .
```

### Using Other Templates

```bash
# Create a new NixOS configuration from template
nix flake new -t github:anthonymoon/zenixv2#workstation my-nixos-config
cd my-nixos-config
```

### Building Configurations

```bash
# Build without switching
nixos-rebuild build --flake .#workstation

# Test in VM
nixos-rebuild build-vm --flake .#workstation

# Switch to configuration
sudo nixos-rebuild switch --flake .#workstation
```

## Project Structure

```
.
├── flake.nix           # Main flake definition
├── lib/                # Helper functions and utilities
│   └── default.nix     # Core library functions
├── modules/            # Reusable NixOS modules
│   ├── common/         # Base configuration
│   ├── desktop/        # Desktop environments
│   ├── hardware/       # Hardware support
│   ├── profiles/       # System profiles
│   ├── security/       # Security hardening
│   ├── services/       # System services
│   └── storage/        # Storage configurations
├── hosts/              # Host-specific configurations
├── scripts/            # Installation and utility scripts
└── templates/          # Quick-start templates
```

## Available Configurations

| Configuration | Description | Use Case |
|--------------|-------------|----------|
| `minimal` | Bare minimum system | Servers, containers |
| `minimal-zfs` | Minimal with ZFS | Storage servers |
| `ephemeral` | Stateless with tmpfs root | Kiosks, testing |
| `ephemeral-zfs` | Stateless with ZFS | Secure workstations |
| `workstation` | Hyprland desktop with ZFS | Modern daily driver |
| `gaming` | Gaming-optimized Hyprland | Gaming + work |
| `server` | Server configuration | Web services |
| `dev` | Development with Hyprland | Programming |
| `hardened` | Security-focused | High-security needs |

## Module System Architecture

### Design Principles

1. **Separation of Concerns** - Each module handles one specific aspect
2. **Composability** - Modules can be mixed and matched freely
3. **Override Capability** - Any setting can be overridden at the host level
4. **Smart Defaults** - Sensible defaults that work for most cases
5. **Progressive Disclosure** - Simple to use, powerful when needed

### Module Types

#### Core Modules
Always loaded, provide essential functionality:
- **base** - Fundamental NixOS settings
- **nix-settings** - Nix daemon configuration
- **boot** - Bootloader and kernel settings

#### Feature Modules
Optional modules that add specific functionality:
```nix
{
  options.feature.name = {
    enable = mkEnableOption "description";
    # Additional options
  };
  
  config = mkIf cfg.enable {
    # Implementation
  };
}
```

#### Profile Modules
High-level modules that enable multiple features:
```nix
{
  config = mkIf cfg.profiles.workstation.enable {
    # Enable multiple features
    desktop.kde.enable = true;
    storage.zfs.enable = true;
    services.printing.enable = true;
  };
}
```

### Using Modules

Enable modules in your host configuration:

```nix
# hosts/myhost/default.nix
{ config, lib, pkgs, ... }:

{
  # Enable ZFS with custom settings
  storage.zfs = {
    enable = true;
    arcSize.max = 16884901888; # 16GB
    optimizeForNvme = true;
  };

  # Enable KDE desktop
  desktop.kde.enable = true;

  # Enable specific profiles
  profiles.gaming.enable = true;
  profiles.development.enable = true;
}
```

## Usage Guide

### Initial Setup

#### Fresh Installation

1. Prepare installation media:
```bash
# Download NixOS ISO
wget https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso

# Write to USB
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress
```

2. Install NixOS:
```bash
# Generate hardware configuration
nixos-generate-config --root /mnt

# Clone this repository
git clone https://github.com/anthonymoon/zenixv2.git /mnt/etc/nixos

# Install
nixos-install --flake /mnt/etc/nixos#myhost
```

### Daily Operations

#### System Updates
```bash
# Update everything
nix flake update
sudo nixos-rebuild switch --flake .#$(hostname)

# Update specific input
nix flake lock --update-input nixpkgs
```

#### Package Management
```bash
# Temporary usage
nix run nixpkgs#htop

# Add to system
# Edit hosts/myhost/default.nix
environment.systemPackages = with pkgs; [
  firefox
  thunderbird
];
```

### Common Workflows

#### Adding a New Host

1. Create host directory:
```bash
mkdir -p hosts/newhost
```

2. Create configuration:
```nix
# hosts/newhost/default.nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  
  # Your configuration
  storage.zfs.enable = true;
  desktop.hyprland.enable = true;
}
```

3. Add to flake.nix:
```nix
nixosConfigurations.newhost = lib.mkSystem {
  hostname = "newhost";
  modules = [ ./hosts/newhost ];
};
```

## System Profiles

### Base Profiles

#### minimal
- Absolute minimum viable NixOS system
- Core utilities, SSH, basic networking
- ~200MB RAM, ~2GB disk

#### workstation
- Full-featured desktop system with Hyprland
- Office apps, browsers, media players
- Modern Wayland compositor with tiling

#### server
- Headless server configuration
- Enhanced security, monitoring tools
- Network optimization

### Specialized Profiles

#### development
- Multiple language toolchains
- Version control, database clients
- Container tools, IDEs

#### gaming
- Gaming platforms (Steam, etc.)
- 32-bit graphics libraries
- Low-latency kernel

#### hardened
- Maximum security configuration
- Kernel hardening, AppArmor/SELinux
- Audit logging, encrypted storage

### Profile Combinations

```nix
# Developer workstation
{
  profiles.workstation.enable = true;
  profiles.development.enable = true;
  desktop.hyprland.enable = true;
}

# Secure server
{
  profiles.server.enable = true;
  profiles.hardened.enable = true;
  storage.zfs.enable = true;
}
```

## API Reference

### Core Functions

#### mkSystem
Creates a complete NixOS system configuration.

```nix
lib.mkSystem {
  hostname = "myserver";
  system = "x86_64-linux";
  modules = [
    ./hosts/myserver
    ./modules/profiles/server
  ];
}
```

### Hardware Detection

#### hardware.detectCPU
Returns: "intel" | "amd" | "generic"

#### hardware.detectGPU
Returns: "nvidia" | "amd" | "intel" | "none"

#### hardware.detectPlatform
Returns: "system76" | "dell" | "lenovo" | "asus" | "apple" | "generic"

### Helper Functions

#### helpers.mkHostId
Generates ZFS-compatible host ID from hostname.

#### helpers.formatBytes
Formats byte count to human-readable string.

### Module Builders

#### builders.mkServiceModule
Creates standardized service module.

#### builders.mkProgramModule
Creates standardized program module.

## Migration Guide

### From Existing NixOS

1. Backup current configuration:
```bash
sudo cp -r /etc/nixos /etc/nixos.backup
```

2. Clone unified configuration:
```bash
cd /etc/nixos
sudo git clone https://github.com/anthonymoon/zenixv2.git .
```

3. Create host configuration:
```bash
sudo mkdir -p hosts/$(hostname)
sudo cp /etc/nixos.backup/hardware-configuration.nix hosts/$(hostname)/
```

4. Test and switch:
```bash
sudo nixos-rebuild build --flake .#$(hostname)
sudo nixos-rebuild switch --flake .#$(hostname)
```

### From Multiple Projects

If migrating from multiple separate NixOS projects:

1. Identify common patterns
2. Map to unified modules
3. Test each configuration
4. Gradually migrate systems

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `nix flake check`
5. Submit a pull request

### Code Style

- Use `nixfmt-rfc-style` for formatting (available in dev shell)
- Follow existing module patterns
- Document all options
- Add tests for complex features

### Development Workflow

```bash
# Enter the dev shell for all tools
nix develop

# Or run commands directly with dev shell
nix develop -c git commit -m "your message"

# Or use the helper script
./scripts/git-commit.sh -m "your message"
```

## License

MIT License - See LICENSE file for details

## Acknowledgments

- NixOS community for excellent documentation
- Module patterns inspired by various community configurations
- Hardware detection logic adapted from nixos-hardware project