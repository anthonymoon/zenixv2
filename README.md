# ZenixV2 - Omarchy-based NixOS Configuration

A streamlined NixOS configuration based on [omarchy-nix](https://github.com/henrysipp/omarchy-nix) - an opinionated Hyprland setup for modern development.

## Features

- 🎨 **Hyprland Compositor** - Modern Wayland tiling window manager
- 💾 **ZFS Support** - Advanced filesystem with snapshots and compression
- 🚀 **AMD GPU Optimized** - Full Wayland support with Vulkan
- 🎯 **Omarchy Integration** - Beautiful themes and productivity tools
- 📦 **Minimal Profiles** - Simple configurations for different use cases

## Quick Start

### Installation

```bash
# Clone this repository
git clone https://github.com/anthonymoon/zenixv2.git
cd zenixv2

# Install NixOS with your chosen configuration
sudo nixos-install --flake .#workstation
```

### One-Command Installation

For a fresh install with disk formatting:

```bash
# Workstation setup (recommended)
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake github:anthonymoon/zenixv2#workstation \
  --disk main /dev/nvme0n1

# Gaming setup
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake github:anthonymoon/zenixv2#gaming \
  --disk main /dev/nvme0n1

# Development setup
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake github:anthonymoon/zenixv2#dev \
  --disk main /dev/nvme0n1
```

**WARNING**: This will destroy all data on `/dev/nvme0n1`!

## Available Configurations

| Configuration | Username | Theme | Description |
|--------------|----------|-------|-------------|
| `workstation` | user | tokyo-night | Daily driver with productivity apps |
| `gaming` | gamer | catppuccin | Gaming-optimized with Steam |
| `dev` | developer | gruvbox | Development environment |
| `minimal` | user | tokyo-night | Minimal ZFS system |

## Customization

### Basic Configuration

Edit `flake.nix` to customize your setup:

```nix
workstation = mkSystem {
  hostname = "my-pc";
  username = "myname";
  fullName = "My Full Name";
  email = "my.email@example.com";
  theme = "tokyo-night";  # or kanagawa, everforest, catppuccin, etc.
};
```

### Available Themes

- `tokyo-night` (default)
- `kanagawa`
- `everforest`
- `catppuccin`
- `nord`
- `gruvbox`
- `gruvbox-light`
- `generated_light` - Extract from wallpaper
- `generated_dark` - Extract from wallpaper

### Custom Wallpaper

To use a custom wallpaper with any theme:

```nix
{
  omarchy = {
    theme = "tokyo-night";
    theme_overrides = {
      wallpaper_path = ./wallpapers/my-wallpaper.png;
    };
  };
}
```

## What's Included

### Base System (via omarchy-nix)
- **Hyprland** - Tiling Wayland compositor
- **Waybar** - Status bar
- **Wofi** - Application launcher
- **Kitty** - Terminal emulator
- **VSCode** - Code editor
- **1Password** - Password manager
- **Brave** - Web browser
- **And more...**

### Additional Features
- **ZFS** - Advanced filesystem
- **AMD GPU drivers** - Full Wayland support
- **NetworkManager** - Easy network configuration
- **Pipewire** - Modern audio stack

## Post-Installation

### Change Password
```bash
passwd
```

### Update System
```bash
sudo nixos-rebuild switch --flake /etc/nixos#workstation
```

### Enter Development Shell
```bash
nix develop
```

## System Requirements

- UEFI boot mode
- AMD GPU (recommended)
- NVMe SSD at `/dev/nvme0n1`
- 8GB+ RAM for ZFS

## Credits

Based on [omarchy-nix](https://github.com/henrysipp/omarchy-nix) by Henry Sipp, which implements DHH's [Omarchy](https://omakub.org/) for NixOS.

## License

MIT