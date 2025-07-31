# CLAUDE.md - AI Assistant Specification for ZenixV2

This file provides context and guidelines for AI assistants working with the ZenixV2 NixOS configuration framework.

## Project Overview

ZenixV2 is a unified NixOS configuration framework that consolidates multiple system configurations into a modular, maintainable structure. It emphasizes:
- Code reusability through modular design
- Hardware auto-detection and adaptation
- Security-first approach with multiple hardening levels
- Flexible storage options (ZFS, tmpfs, standard filesystems)
- Profile-based system configuration

## Key Principles

1. **Modularity First**: Every feature should be a reusable module
2. **Smart Defaults**: Configurations should work out-of-box with sensible defaults
3. **Progressive Enhancement**: Simple for beginners, powerful for experts
4. **Security Conscious**: Never compromise security for convenience
5. **Documentation Driven**: Every module and option must be documented

## Code Style Guidelines

### Nix Code
- Use `nixfmt` for consistent formatting
- Prefer attribute sets over long function argument lists
- Use `mkOption` with full type and description for all options
- Group related configuration under logical namespaces
- Follow the module pattern: options definition → config implementation

### Module Structure
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

### Naming Conventions
- Modules: lowercase with hyphens (e.g., `zfs-ephemeral`)
- Options: camelCase (e.g., `arcSize`, `optimizeForNvme`)
- Files: lowercase with hyphens
- Functions: camelCase for helpers, mkPascalCase for builders

## Common Tasks

### Adding a New Module
1. Create module file in appropriate directory under `modules/`
2. Follow standard module pattern with options and config
3. Add to parent directory's `default.nix`
4. Document all options with descriptions
5. Add usage example to module header comment
6. Test in at least one configuration

### Adding Hardware Support
1. Detect hardware in `hardware/auto-detect.nix`
2. Create specific module in `hardware/modules/`
3. Apply configuration conditionally based on detection
4. Test on actual hardware if possible
5. Document any hardware-specific quirks

### Creating a Profile
1. Create profile directory under `profiles/`
2. Enable and configure related modules
3. Add profile option to enable/disable
4. Document target use case and requirements
5. Test profile combinations for conflicts

## Architecture Decisions

### Module Hierarchy
- **Core**: Essential system functions (always loaded)
- **Common**: Shared base configurations (usually loaded)
- **Hardware**: Hardware-specific adaptations (auto-detected)
- **Storage**: Filesystem and storage configurations
- **Desktop**: Desktop environment configurations
- **Services**: System services and daemons
- **Security**: Hardening and security features
- **Profiles**: High-level configuration combinations

### Configuration Resolution
1. Host-specific configuration (highest priority)
2. Profile configuration
3. Module defaults
4. NixOS defaults (lowest priority)

### Hardware Detection
- CPU detection reads `/proc/cpuinfo`
- GPU detection scans PCI devices
- Platform detection reads DMI information
- All detection has fallback defaults

## Testing Guidelines

### Module Testing
- Test enable/disable functionality
- Verify option interactions
- Check for assertion failures
- Test with minimal configuration
- Test in combination with other modules

### Integration Testing
- Use `nixos-rebuild build` before switching
- Test in VM with `nixos-rebuild build-vm`
- Verify profile combinations work
- Check resource usage (RAM, disk)
- Ensure clean rollback capability

## Security Considerations

### Never Do
- Store secrets in plain text
- Disable security features by default
- Use weak cryptographic defaults
- Expose services without authentication
- Run services as root unnecessarily

### Always Do
- Use `mkDefault` for security settings
- Enable firewall by default
- Use systemd service hardening
- Validate user input
- Document security implications

## Performance Guidelines

### Optimization Approach
1. Measure first (use metrics)
2. Optimize critical paths
3. Cache expensive operations
4. Lazy evaluation where possible
5. Document performance tradeoffs

### Resource Targets
- Minimal: <200MB RAM, <2GB disk
- Workstation: <2GB RAM idle, <15GB disk
- Server: Optimize for specific workload
- Always leave headroom for operation

## Troubleshooting Patterns

### Common Issues
1. **Module conflicts**: Check option definitions
2. **Hardware detection failures**: Add manual overrides
3. **Performance problems**: Check enabled services
4. **Boot failures**: Use previous generation
5. **Network issues**: Verify firewall rules

### Debugging Tools
- `nixos-option` - Query configuration values
- `nix repl` - Interactive configuration exploration
- `nix-diff` - Compare derivations
- System logs via `journalctl`
- Build with `--show-trace` for errors

## Contributing Guidelines

### Pull Request Checklist
- [ ] Code follows style guidelines
- [ ] All options have descriptions
- [ ] Changes are tested
- [ ] Documentation is updated
- [ ] No security regressions
- [ ] Commits are semantic

### Commit Message Format
```
type(scope): description

Longer explanation if needed.
Fixes/Closes #issue
```

Types: feat, fix, docs, style, refactor, perf, test, chore

## AI Assistant Instructions

When working with this codebase:

1. **Respect Modularity**: Suggest changes that enhance reusability
2. **Maintain Backwards Compatibility**: Don't break existing configurations
3. **Document Everything**: Update docs when changing functionality
4. **Think Security**: Consider security implications of changes
5. **Test Suggestions**: Provide test commands with code changes
6. **Keep It Simple**: Prefer simple solutions over complex ones

### Code Generation

When generating Nix code:
- Use the established module patterns
- Include option types and descriptions
- Add header comments explaining purpose
- Provide usage examples
- Consider edge cases and failures

### Review Priorities

When reviewing code:
1. Security vulnerabilities
2. Breaking changes
3. Performance regressions
4. Missing documentation
5. Style inconsistencies

## Quick Reference

### File Locations
- Modules: `modules/`
- Host configs: `hosts/`
- Library functions: `lib/`
- Scripts: `scripts/`
- Documentation: `docs/` and inline

### Key Commands
```bash
# Check syntax
nix flake check

# Build configuration
nixos-rebuild build --flake .#hostname

# Test in VM
nixos-rebuild build-vm --flake .#hostname

# Format code
nixfmt *.nix

# Run pre-commit
./scripts/pre-commit.sh
```

### Useful Patterns
- Enable module: `module.enable = true;`
- Override default: `lib.mkForce value`
- Conditional config: `lib.mkIf condition { ... }`
- Merge configs: `lib.mkMerge [ ... ]`
- Default value: `lib.mkDefault value`

## Contact

Repository: https://github.com/anthonymoon/zenixv2
Issues: https://github.com/anthonymoon/zenixv2/issues

Remember: The goal is maintainable, secure, and flexible NixOS configurations that work reliably across diverse hardware and use cases.