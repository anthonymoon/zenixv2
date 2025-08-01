# Configuration Guide

This guide explains the NixOS configuration structure and customization options.

## Repository Structure

```
zenixv2/
├── flake.nix              # Main flake configuration
├── flake.lock             # Pinned dependencies
├── hosts/
│   └── nixie/            # Host-specific configuration
│       ├── disko.nix     # Disk partitioning
│       ├── hardware-configuration.nix
│       └── install-zfs-fallback.sh
├── modules/              # Reusable NixOS modules
│   ├── common/          # Base system configuration
│   ├── hardware/
│   │   └── amd/         # AMD GPU support
│   ├── storage/
│   │   └── zfs/         # ZFS filesystem support
│   ├── networking/
│   │   ├── bonding/     # LACP network bonding
│   │   └── performance/ # Network optimizations
│   ├── services/
│   │   └── samba/       # SMB file sharing
│   └── extras/
│       └── pkgs/        # Additional packages
└── docs/                # Documentation

```

## Core Configuration

### Flake Configuration (`flake.nix`)

The flake defines the system with omarchy-nix integration:

```nix
{
  nixosConfigurations.nixie = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/nixie/hardware-configuration.nix
      ./modules/common
      # ... other modules
      omarchy-nix.nixosModules.default
      {
        networking.hostName = "nixie";
        omarchy = {
          full_name = "Anthony Moon";
          email_address = "tonymoon@gmail.com";
          theme = "tokyo-night";
        };
      }
    ];
  };
}
```

### Omarchy-nix Integration

The configuration uses [omarchy-nix](https://github.com/henrysipp/omarchy-nix) for:
- Hyprland Wayland compositor
- Preconfigured desktop environment
- Development tools
- Theme management

## Module System

### Hardware Modules

#### AMD GPU (`modules/hardware/amd/`)
- Enables amdgpu kernel module
- Configures Vulkan support
- Sets up hardware acceleration

#### Storage (`modules/storage/zfs/`)
- ZFS filesystem support
- Automatic snapshots
- Scrub scheduling
- Boot support

### Networking Modules

#### Bonding (`modules/networking/bonding/`)
Configures LACP bonding for dual 10GbE interfaces:

```nix
networking.bonds.bond0 = {
  interfaces = [ "enp4s0f0np0" "enp4s0f1np1" ];
  driverOptions = {
    mode = "802.3ad";        # LACP
    lacp_rate = "fast";
    xmit_hash_policy = "layer3+4";
  };
};
```

#### Performance (`modules/networking/performance/`)
Optimizes for 20Gbps throughput:
- TCP BBR congestion control
- Increased buffer sizes
- CPU affinity for interrupts
- Receive packet steering

### Services

#### Samba (`modules/services/samba/`)
SMB3 file sharing with:
- Multi-channel support
- Performance optimizations
- Avahi discovery

### Extra Packages (`modules/extras/pkgs/`)
Includes:
- Gaming support (Steam, GameMode, Vulkan)
- Media tools (MPV, FFmpeg, OBS)
- Development tools (Helix, Neovim, VSCode)
- Low-latency audio (PipeWire)

## Customization

### Adding a New Host

1. Create host directory:
   ```bash
   mkdir -p hosts/myhost
   ```

2. Generate hardware configuration:
   ```bash
   nixos-generate-config --root /mnt --dir hosts/myhost
   ```

3. Add to flake.nix:
   ```nix
   nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
     # ... configuration
   };
   ```

### Modifying Network Configuration

Edit `modules/networking/bonding/default.nix`:
```nix
networking.interfaces.bond0.ipv4.addresses = [{
  address = "10.0.0.100";
  prefixLength = 24;
}];
```

### Adding Packages

Edit `modules/extras/pkgs/default.nix`:
```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  package-name
];
```

### Changing User Settings

Modify the omarchy configuration in `flake.nix`:
```nix
omarchy = {
  full_name = "Your Name";
  email_address = "your.email@example.com";
  theme = "catppuccin-mocha";  # or other theme
};
```

## Performance Tuning

### ZFS Tuning

Adjust dataset properties in `hosts/nixie/disko.nix`:
```nix
datasets."mydata" = {
  type = "zfs_fs";
  options = {
    recordsize = "1M";      # For large files
    compression = "zstd-3"; # Higher compression
    dedup = "off";          # Save CPU cycles
  };
};
```

### Network Tuning

Modify sysctls in `modules/networking/performance/default.nix`:
```nix
boot.kernel.sysctl = {
  "net.core.rmem_max" = 268435456;  # 256MB for 40Gbps
  "net.core.wmem_max" = 268435456;
};
```

## Development Workflow

### Enter Development Shell

```bash
nix develop
```

This provides:
- nixfmt for code formatting
- git with pre-commit hooks
- nix tools for testing

### Format Code

```bash
nix develop -c nixfmt ./**/*.nix
```

### Test Configuration

```bash
nix flake check
```

### Build Without Switching

```bash
nixos-rebuild build --flake .#nixie
```

## Maintenance

### System Updates

```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#nixie
```

### Garbage Collection

```bash
# Remove old generations
sudo nix-collect-garbage -d

# Keep last 7 days
sudo nix-collect-garbage --delete-older-than 7d
```

### ZFS Maintenance

```bash
# Check pool status
zpool status

# Scrub pool (monthly)
sudo zpool scrub rpool

# Check dataset usage
zfs list -o name,used,avail,refer,mountpoint
```

## Troubleshooting

### Configuration Errors

Check syntax:
```bash
nix flake check --show-trace
```

### Module Conflicts

Review module imports in flake.nix and ensure no duplicate definitions.

### Performance Issues

Monitor with:
```bash
# Network performance
iperf3 -s  # On server
iperf3 -c server-ip -P 4  # On client

# Disk performance
fio --name=test --size=4G --rw=randrw --bs=32k
```