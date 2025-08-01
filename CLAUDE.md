# CLAUDE.md - AI Assistant Context for ZenixV2

This file provides context and guidelines for AI assistants working with the ZenixV2 NixOS configuration framework.

## Project Overview

ZenixV2 is a high-performance NixOS configuration framework that emphasizes:
- **Modularity**: Reusable components for different hardware and use cases
- **Performance**: Optimized for gaming, content creation, and development
- **Correctness**: Type-safe configuration with comprehensive validation
- **Documentation**: Every module and option must be documented

## Architecture Principles

### 1. Module Design
- Each module should have a single, clear purpose
- Use `mkOption` with full type and description for all options
- Provide sensible defaults that work out-of-the-box
- Enable conditional loading with `mkIf` guards
- Group related configuration under logical namespaces

### 2. Code Style
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.namespace.module;
in
{
  options.namespace.module = {
    enable = lib.mkEnableOption "module description";
    # Additional options with types and descriptions
  };
  
  config = lib.mkIf cfg.enable {
    # Implementation
  };
}
```

### 3. Performance Considerations
- Use `mkDefault` for performance settings users might want to override
- Cache expensive operations where possible
- Lazy evaluation is your friend - don't compute unless needed
- Document performance implications of options

## Key Components

### Storage (ZFS)
- **Datasets**: Optimized recordsizes per workload (16K for DBs, 1M for VMs)
- **NVMe**: Special optimizations enabled by default
- **Memory**: Configurable ARC size with sensible defaults (2-8GB)
- **Compression**: ZSTD globally, LZ4 for temporary data

### Hardware Support
- **AMD**: Full GPU (amdgpu, ROCm) and CPU (zenpower) support
- **Intel**: Basic CPU and integrated GPU support
- **Nvidia**: Proprietary driver support (currently disabled)
- **Auto-detection**: Hardware detected and configured automatically

### Networking
- **Bonding**: LACP mode 4 for redundancy and performance
- **Performance**: TCP BBR, optimized buffers for 20Gbps
- **Services**: mDNS, SMB3, SSH with sensible defaults

### Desktop (via omarchy-nix)
- **Hyprland**: Wayland compositor with GPU acceleration
- **Terminal**: Kitty as default, Ghostty as alternative
- **Shell**: Zsh with Starship prompt
- **Editor**: Neovim with AstroNvim configuration

## Common Tasks

### Adding a New Module
1. Create module file in appropriate directory
2. Follow standard module pattern with options/config
3. Add to parent directory's imports
4. Document all options
5. Test with minimal configuration
6. Add usage example to module header

### Hardware Detection
```nix
# Example from hardware/auto-detect.nix
cpu = {
  isIntel = builtins.elem "GenuineIntel" (getCpuVendor cpuinfo);
  isAmd = builtins.elem "AuthenticAMD" (getCpuVendor cpuinfo);
};
```

### Performance Tuning
- Always measure before optimizing
- Document why specific values were chosen
- Provide options to disable optimizations
- Consider resource constraints (RAM, CPU)

## Testing Guidelines

### Build Testing
```bash
# Check syntax and evaluation
nix flake check

# Build configuration without switching
nixos-rebuild build --flake .#hostname

# Test in VM
nixos-rebuild build-vm --flake .#hostname
```

### Integration Testing
- Test module combinations for conflicts
- Verify hardware detection works correctly
- Check resource usage is within bounds
- Ensure clean rollback capability

## Troubleshooting Patterns

### Module Conflicts
- Check for duplicate option definitions
- Verify `mkForce` usage for overrides
- Look for circular dependencies
- Use `--show-trace` for detailed errors

### Performance Issues
- Check enabled services and their resource usage
- Verify ZFS ARC size is appropriate
- Look for CPU governor settings
- Monitor with `htop`, `iotop`, `amdgpu_top`

### Boot Failures
- Previous generation is always available
- ZFS pools can be imported from live ISO
- Hardware modules can be disabled if problematic
- Bootloader is systemd-boot (not GRUB)

## AI Assistant Instructions

When working with this codebase:

1. **Respect Modularity**: Changes should enhance reusability
2. **Maintain Compatibility**: Don't break existing configurations
3. **Document Everything**: Update docs when changing functionality
4. **Test Suggestions**: Provide test commands with code changes
5. **Think Performance**: Consider impact on system resources
6. **Security First**: Never compromise security for convenience

### Code Generation Guidelines

When generating Nix code:
- Use established patterns from existing modules
- Include proper option types and descriptions
- Add header comments explaining the module's purpose
- Consider edge cases and provide safe defaults
- Test with `nix flake check` before suggesting

### Common Patterns

#### Conditional Service Enable
```nix
services.foo = lib.mkIf (cfg.enable && cfg.foo.enable) {
  enable = true;
  settings = cfg.foo.settings;
};
```

#### Hardware-Specific Configuration
```nix
boot.kernelModules = lib.mkIf config.hardware.amd.enable [
  "amdgpu"
  "zenpower"
];
```

#### Performance Options
```nix
performance = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = "Enable performance optimizations (increases resource usage)";
};
```

## Recent Changes

### Partition Labels (Latest)
- Boot partition uses label `disk-main-esp`
- ZFS uses `/dev/disk/by-partlabel` for reliability
- Disko handles all filesystem configuration

### Download Buffer Fix
- Added `download-buffer-size = 256MB` to prevent warnings
- Configured in both cachix and performance modules
- Also includes parallel download optimizations

### Hardware Configuration
- Separated from filesystem definitions
- `hardware.nix` contains only hardware settings
- Disko handles all filesystem configuration

## Quick Reference

### File Locations
- Main config: `flake.nix`
- Host configs: `hosts/{hostname}/`
- Modules: `modules/{category}/{module}/`
- Scripts: `scripts/`

### Key Commands
```bash
# Check configuration
nix flake check

# Format code
alejandra .

# Build and switch
sudo nixos-rebuild switch --flake .#hostname

# Update inputs
nix flake update
```

### Module Categories
- `common/` - Base system configuration
- `hardware/` - CPU, GPU, platform support
- `storage/` - Filesystems and disk management
- `networking/` - Network configuration and optimization
- `services/` - System services and daemons
- `desktop/` - Desktop environments and display servers
- `security/` - Hardening and security features

Remember: The goal is maintainable, performant, and reliable NixOS configurations that work across diverse hardware.