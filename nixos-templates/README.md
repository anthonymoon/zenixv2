# 🚀 NixOS Templates - AMD Workstation Unified System

A comprehensive template system optimized for AMD workstations with ZFS root filesystem and modern desktop environments.

## ✨ AMD Workstation Features

- 🖥️ **AMD-Optimized** - AMDGPU driver, AMD CPU microcode, optimized kernel modules
- 💾 **ZFS Root Standard** - All templates use ZFS root with systemd-boot
- 🎨 **Modern Desktops** - Plasma 6, GNOME, Hyprland with Wayland-first approach
- 📺 **Display Manager Choice** - TUI-greet (minimal) or GDM integration
- 🔧 **DHCP Networking** - NetworkManager handles all networking automatically
- 🎵 **PipeWire Audio** - Modern audio system with low latency
- 🔄 **Auto-Updates** - Safe unattended system upgrades with easy rollback
- 🔗 **Binary Compatibility** - Run dynamically linked Linux executables (nix-ld)
- ⚙️ **Easy Services** - Create systemd services right in your NixOS config
- 📦 **One-Command Installation** - Interactive or scripted deployment
- 🏗️ **Modular Architecture** - Shared modules eliminate duplication
- 📋 **Template Validation** - Ensure configurations work before deployment
- 🌐 **Remote Installation** - Deploy over network or from live ISO

## 🎨 Available Templates

| Template | Description | Use Case | Key Features |
|----------|-------------|----------|--------------|
| 🚀 **modern** | Dynamic system with auto-detection | Workstations, Laptops | Auto-hardware detection, Profile composition, Performance optimization |
| 💾 **ephemeral-zfs** | ZFS ephemeral root system | Secure systems, Testing | Boot-time reset, Persistent paths, ZFS snapshots |
| 🔧 **minimal-zfs** | Lightweight ZFS system | Servers, NAS | Minimal packages, ZFS root, Basic security |
| 🌐 **deployment** | Automated deployment focused | CI/CD, Remote installs | Template substitution, Remote management |
| 👤 **personal** | Personal dotfiles configuration | Developer machines | Age encryption, Home-manager, User-centric |
| 🏗️ **unified** | Simple disko-based system | General purpose | Disko integration, Standard layout |
| 💿 **installer** | ZFS installer configuration | System installation | Installation-focused, Automated partitioning |
| 🧪 **legacy** | Testing and experimental | Development, Testing | Version testing, Experimental features |

## 🚀 Quick Start

### Option 1: Interactive Installation (Recommended)
```bash
cd nixos-templates
./install.sh --interactive
```

### Option 2: Direct Installation
```bash
# Modern desktop system
./install.sh modern workstation desktop kde stable

# ZFS ephemeral server  
./install.sh ephemeral-zfs server headless stable

# Personal development laptop
./install.sh personal laptop desktop hyprland unstable
```

### Option 3: Using Nix (from anywhere)
```bash
# List available templates
nix run github:user/nixos-templates#list

# Install with guided setup
nix run github:user/nixos-templates#install -- --interactive

# Direct install
nix run github:user/nixos-templates#install -- modern workstation kde
```

## 📋 Template Profiles

### AMD Workstation Template Profiles
- **Desktop**: `kde` (Plasma 6), `gnome`, `hyprland`
- **Display Manager**: `tui-greet` (minimal), `gdm` (graphical)
- **System**: `stable`, `unstable`, `hardened`  
- **Usage**: `gaming`, `development`

### ZFS Template Profiles  
- **System**: `stable`
- **Usage**: `headless`, `desktop`
- **Desktop**: `kde`, `gnome`, `hyprland` (when desktop usage)

### AMD Workstation Standards
- **Filesystem**: ZFS root with automatic snapshots and scrubs
- **Boot**: systemd-boot with EFI support
- **GPU**: AMDGPU driver with ROCm support (no Intel/NVIDIA)  
- **CPU**: AMD microcode updates and KVM virtualization
- **Audio**: PipeWire with ALSA/JACK/PulseAudio compatibility
- **Network**: NetworkManager with automatic DHCP
- **Kernel Modules**: Pre-loaded modules for AMD hardware, ZFS, Bluetooth, WiFi
- **Desktop**: Wayland-first with X11 fallback support

## 🔧 Advanced Usage

### Custom Parameters
```bash
# ZFS with custom host ID
./install.sh --param hostId=abcd1234 ephemeral-zfs myserver headless

# Personal template with email
./install.sh --param email=user@domain.com personal laptop hyprland

# Custom disk and user
./install.sh --disk /dev/nvme0n1 --user alice modern desktop kde
```

### Template Validation
```bash
# Validate template before installation
nix run .#validate modern workstation

# List profiles for a template
./install.sh --list-profiles modern
```

### Dry Run Mode
```bash
# See what would be installed without making changes
./install.sh --dry-run modern workstation kde stable
```

## 🏗️ Architecture

### Template Structure
```
nixos-templates/
├── flake.nix                 # Main flake with template system
├── install.sh                # Unified installation script
├── lib/                      # Template system libraries
│   ├── templates.nix         # Template definitions
│   ├── builders.nix          # Build system functions  
│   └── apps.nix              # Installation applications
├── common/                   # Shared modules
│   ├── modules/              # Common base modules
│   └── profiles/             # Shared profile configurations
└── templates/                # Individual template directories
    ├── modern/               # Modern dynamic system
    ├── ephemeral-zfs/        # ZFS ephemeral root
    ├── minimal-zfs/          # Minimal ZFS
    ├── deployment/           # Deployment focused
    ├── personal/             # Personal configuration
    ├── unified/              # Unified simple system
    ├── installer/            # ZFS installer  
    └── legacy/               # Legacy/testing
```

### Template System Features

#### 🎯 Dynamic Configuration
Build systems using hostname and profile composition:
```
hostname.template.profile1.profile2.profile3
```

#### 🔧 Parameter Substitution  
Templates support parameter replacement:
- `@HOSTNAME@` → Actual hostname
- `@USERNAME@` → Primary username  
- `@DISK@` → Target disk device
- Custom parameters via `--param key=value`

#### 🏗️ Modular Design
- **Common Modules**: Shared base functionality
- **Template Inheritance**: Templates can inherit from others
- **Profile Composition**: Mix desktop + system + usage profiles
- **Override System**: Sensible defaults with full customization

## 📖 Template Details

### 🚀 Modern Template
- **Based on**: Original nixos-fun repository
- **Features**: Auto-hardware detection, performance optimization, pre-commit hooks
- **Best for**: Workstations, gaming rigs, development machines
- **Profiles**: Full desktop environment support with gaming optimizations

### 💾 Ephemeral ZFS Template  
- **Based on**: Original nixos-zfs repository
- **Features**: Boot-time root reset, persistent paths, comprehensive documentation
- **Best for**: Secure systems, testing environments, immutable infrastructure
- **Key benefit**: System always boots to clean state

### 🔧 Minimal ZFS Template
- **Based on**: Original nixos-zfs-minimal repository  
- **Features**: Lightweight, essential packages only, ZFS root
- **Best for**: Servers, NAS systems, resource-constrained environments
- **Size**: Minimal footprint with maximum functionality

### 🌐 Deployment Template
- **Based on**: Original nixos-claude repository
- **Features**: Remote deployment, automated installation, template substitution
- **Best for**: CI/CD pipelines, automated deployments, remote management
- **Automation**: Full unattended installation support

### 👤 Personal Template
- **Based on**: Original nix-config repository
- **Features**: Dotfiles management, age encryption, user-focused configuration
- **Best for**: Personal development machines, customized user environments
- **Privacy**: Built-in encryption and personal data management

## 🔍 Examples

### AMD Gaming Workstation
```bash
./install.sh modern gaming-rig kde gaming stable \
  --disk /dev/nvme0n1 \
  --user gamer \
  --param hostId=deadbeef
```

### AMD Development Workstation  
```bash
./install.sh modern devbox hyprland tui-greet development unstable \
  --user developer \
  --param email=dev@company.com \
  --param hostId=cafebabe
```

### AMD Creative Workstation
```bash  
./install.sh modern creative-station kde stable \
  --disk /dev/nvme0n1 \
  --user artist \
  --param hostId=deadc0de
```

### ZFS Ephemeral Workstation
```bash
./install.sh ephemeral-zfs secure-ws kde stable \
  --param hostId=feedface \
  --param poolName=secure \
  --user secure
```

## 🚀 System Enhancements

### Automatic System Upgrades

All templates include safe, unattended system updates:
- **Daily Updates**: Run at 9:00 AM with random delay (up to 45 minutes)
- **Flake-based**: Updates nixpkgs input from your flake automatically
- **Safe Rollback**: NixOS generations allow easy rollback if issues occur
- **No Auto-reboot**: System won't reboot automatically (user decides)

To disable auto-updates:
```nix
system.autoUpgrade.enable = false;
```

### Dynamic Library Compatibility (nix-ld)

Run binaries from other Linux distributions without issues:
- **Pre-configured Libraries**: Common libraries for AMD GPUs, audio, graphics
- **Easy Extension**: Add missing libraries to the list as needed
- **Binary Compatibility**: Fixes "cannot execute binary" errors

Example: Running a downloaded AppImage:
```bash
chmod +x some-app.AppImage
./some-app.AppImage  # Just works!
```

### Custom Systemd Services

Create services directly in your NixOS configuration:

```nix
# Example: Custom backup service
systemd.services.my-backup = {
  description = "Daily backup";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.rsync}/bin/rsync -av /home /backup";
  };
};

systemd.timers.my-backup = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};
```

Pre-configured examples include:
- **ZFS Pre-update Snapshots**: Auto-snapshot before system upgrades
- **GPU Memory Cleanup**: Periodic cleanup for AMD GPU performance
- **Development Services**: Auto-start dev environments

## 🛠️ Development

### 🚀 Parallel Development Tools

The project includes advanced parallelization for faster development:

#### Pre-commit Hooks (Automatic)
- **Parallel Execution**: All hooks run concurrently
- **Auto-scaling**: Uses all available CPU cores
- **Fast Feedback**: 3-5x faster than sequential execution

```bash
# Hooks run automatically on commit with parallelization
git commit -m "feat: add new feature"

# Or run manually
nix develop
pre-commit run --all-files
```

#### Parallel Development Commands
```bash
# Load parallel helper functions
source /etc/nixos-templates/parallel-dev.sh

# Format all Nix files in parallel
nix-format-all

# Run all checks concurrently
nix-check-all

# Build all templates in parallel (dry-run)
nix-build-templates
```

#### Custom Parallel Workflows
```bash
# Check specific file types in parallel
fd -e nix | parallel -j+0 statix check {}

# Format and check in parallel
parallel ::: "nixfmt-rfc-style ." "statix check" "deadnix --fail"

# Multi-system builds
parallel -j4 "nix build .#nixosConfigurations.{1}.{2}.config.system.build.toplevel" \
  ::: modern ephemeral-zfs minimal-zfs \
  ::: desktop server
```

### Adding New Templates
1. Create template directory: `templates/my-template/`
2. Add `template.nix` with metadata
3. Copy/create configuration files
4. Update `lib/templates.nix` definitions
5. Add builder functions in `lib/builders.nix`
6. Test with validation system

### Template Structure
```nix
# templates/my-template/template.nix
{
  meta = {
    description = "My custom template";
    features = [ "feature1" "feature2" ];
    profiles = { /* profile definitions */ };
  };
  
  parameters = { /* parameter definitions */ };
  examples = [ /* usage examples */ ];
}
```

### Testing Templates
```bash
# Validate template configuration
nix flake check

# Test specific template
nix run .#validate my-template test-host

# Build without installing
nix build .#nixosConfigurations.test.my-template.config.system.build.toplevel
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/my-template`
3. **Add** your template following the structure guidelines
4. **Test** thoroughly with validation system
5. **Document** your template in README
6. **Submit** pull request with clear description

## 📚 Inspiration & Credits

This unified template system combines and enhances these original repositories:
- **nixos-fun**: Dynamic configuration system with auto-detection
- **nixos-zfs**: Ephemeral root ZFS system with comprehensive docs
- **nixos-zfs-minimal**: Lightweight ZFS implementation
- **nixos-claude**: Deployment-focused configuration
- **nix-config**: Personal dotfiles and age encryption
- **nixos-unified**: Simple disko-based approach
- **nixos-zfs-installer**: Installation-focused system
- **nixos-25.11-updated**: Version testing configuration

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 **Documentation**: This README and template-specific docs
- 🐛 **Issues**: [GitHub Issues](https://github.com/user/nixos-templates/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/user/nixos-templates/discussions)
- 🌐 **Wiki**: [Project Wiki](https://github.com/user/nixos-templates/wiki)

---

**🎉 Happy Building!** Create your perfect NixOS system with the power of templates.