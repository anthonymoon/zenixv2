# ZenixV2 - High-Performance NixOS Configuration

A modern NixOS configuration framework featuring ZFS, AMD GPU optimization, and 20Gbps networking. Built on [omarchy-nix](https://github.com/henrysipp/omarchy-nix) for a streamlined Hyprland desktop experience.

## 🚀 Quick Start

```bash
# Boot from NixOS ISO, then:
curl -sL https://raw.githubusercontent.com/anthonymoon/zenixv2/main/scripts/install-now.sh | HOSTNAME=nixie bash

# Or manual installation:
git clone https://github.com/anthonymoon/zenixv2.git
cd zenixv2
sudo nix run github:nix-community/disko -- --mode disko hosts/nixie/disko.nix
sudo nixos-install --flake .#nixie
```

## 💾 System Requirements

- **Boot**: UEFI mode required
- **CPU**: AMD Ryzen (Intel supported with different module)
- **GPU**: AMD GPU with RDNA2/3 (7800 XT tested)
- **RAM**: 8GB minimum, 16GB+ recommended for ZFS
- **Storage**: NVMe SSD at `/dev/nvme0n1`
- **Network**: Optional dual 10GbE for bonding

## 🎯 Key Features

### Storage - Optimized ZFS
- **Smart Datasets**: Tuned recordsizes per workload
- **NVMe Optimized**: Special settings for flash storage
- **Memory Efficient**: Configurable ARC limits (default 2-8GB)
- **Compression**: ZSTD globally, LZ4 for temp files
- **Auto-snapshots**: Optional automated backups

### Performance - AMD Optimizations
- **GPU**: Full Vulkan, ROCm, and overclocking support
- **CPU**: Zenpower monitoring, P-state control
- **Gaming**: GameMode, MangoHud, low-latency audio
- **Network**: 20Gbps bonding with TCP BBR
- **Audio**: PipeWire with 64-sample buffer (1.3ms)

### Desktop - Hyprland via Omarchy
- **Compositor**: Latest Hyprland with rounded corners
- **Terminal**: Kitty (GPU accelerated)
- **Shell**: Zsh with Starship prompt
- **Editor**: Neovim with AstroNvim config
- **Tools**: Modern CLI replacements (eza, bat, ripgrep)

## 📁 Project Structure

```
zenixv2/
├── flake.nix          # Main configuration entry
├── hosts/             # Machine-specific configs
│   └── nixie/         # Example AMD gaming system
├── modules/           # Reusable components
│   ├── common/        # Base system settings
│   ├── hardware/      # AMD, Intel, Nvidia support
│   ├── storage/       # ZFS, tmpfs configurations
│   ├── networking/    # Bonding, performance tuning
│   └── desktop/       # Wayland/Hyprland setup
└── CLAUDE.md          # AI assistant context
```

## 🔧 Configuration

### Basic Customization

Edit `flake.nix` to set your details:
```nix
omarchy = {
  full_name = "Your Name";
  email_address = "your@email.com";
  theme = "tokyo-night";  # or catppuccin, kanagawa, etc.
};
```

### Hardware Modules

Enable modules based on your hardware:
```nix
modules = [
  ./modules/hardware/amd/enhanced.nix    # AMD GPU + Ryzen
  # ./modules/hardware/intel              # Intel CPU/GPU
  # ./modules/hardware/nvidia             # Nvidia GPU
  ./modules/storage/zfs                  # ZFS filesystem
  ./modules/networking/bonding           # Network bonding
  ./modules/networking/performance       # TCP optimization
];
```

### ZFS Configuration

Customize in `modules/storage/zfs/default.nix`:
```nix
storage.zfs = {
  enable = true;
  arcSize = {
    min = 2147483648;  # 2GB minimum
    max = 8589934592;  # 8GB maximum
  };
  optimizeForNvme = true;
  autoSnapshot = false;  # Enable for automatic backups
};
```

## 📋 Common Commands

### System Management
```bash
# Rebuild system
sudo nixos-rebuild switch --flake /etc/nixos#nixie

# Update flake inputs
nix flake update

# Clean old generations
sudo nix-collect-garbage -d

# Check ZFS status
zpool status
zfs list
```

### Development
```bash
# Enter dev shell
nix develop

# Format code
alejandra .

# Run checks
nix flake check

# Build without switching
nixos-rebuild build --flake .#nixie
```

### Performance Monitoring
```bash
# AMD GPU stats
amdgpu_top

# System performance
btop

# Network performance
iftop -i bond0

# ZFS ARC stats
arc_summary
```

## 🐛 Troubleshooting

### Download Buffer Warning
Already fixed in configuration. If you see it during installation:
```bash
export NIX_CONFIG="download-buffer-size = 268435456"
```

### ZFS Import Issues
```bash
# Boot from installer, then:
zpool import -f rpool
nixos-enter
nixos-rebuild boot
```

### GPU Not Detected
```bash
# Check if amdgpu loaded
lsmod | grep amdgpu

# Check PCI devices
lspci -k | grep -A 3 VGA
```

## 🎮 Gaming Features

- **Steam**: Native and Proton support
- **GameMode**: Automatic CPU/GPU optimization
- **MangoHud**: Performance overlay (Shift+F12)
- **Controllers**: Xbox, PlayStation, and generic
- **Low Latency**: Optimized kernel and audio pipeline

## 🔒 Security Features

- **Firewall**: Disabled by default (enable in production)
- **SSH**: Password auth enabled (disable in production)
- **Sudo**: Passwordless for wheel group
- **Updates**: Automatic security updates available

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Follow existing patterns
4. Run `nix flake check`
5. Submit pull request

## 📄 License

MIT License - See LICENSE file

## 🙏 Credits

- [omarchy-nix](https://github.com/henrysipp/omarchy-nix) - Base configuration framework
- [nixos-hardware](https://github.com/NixOS/nixos-hardware) - Hardware optimizations
- [disko](https://github.com/nix-community/disko) - Declarative disk partitioning

---

**Need help?** Check `/CLAUDE.md` for AI assistant integration or open an issue on GitHub.