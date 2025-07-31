# Binary Cache Configuration

This document describes the hybrid binary cache setup for this NixOS configuration.

## Architecture: Hybrid Approach

This flake uses a **hybrid caching strategy** that separates concerns:

1. **flake.nix**: Public caches for development and CI/CD
2. **configuration.nix**: Environment-specific caches (including local cache)

## Cache Priority Order

Binary caches are used in the order they are listed in the configuration. The local cache at `10.10.10.10:5000` has the highest priority.

### Cache Layers:

#### Layer 1: Flake-level (flake.nix)
Applied during `nix develop`, `nix build`, and CI/CD:
- **https://nix-community.cachix.org** (Community packages)
- **https://nixpkgs-unfree.cachix.org** (Unfree packages)

#### Layer 2: System-level (configuration.nix)
Applied when system is deployed - **in priority order**:

1. **http://10.10.10.10:5000** (Local cache - HIGHEST PRIORITY)
   - Environment-specific nix-serve instance
   - Fastest access for frequently used packages
   - Reduces external bandwidth usage
   
2. **https://cache.nixos.org** (Official NixOS cache)
   - Default NixOS packages
   - Always available as fallback
   
3. **https://nix-community.cachix.org** (Community cache)
   - Popular community packages
   - Development tools
   
4. **https://nixpkgs-unfree.cachix.org** (Unfree packages)
   - Proprietary software
   - Drivers and firmware

## Configuration Details

The configuration in `configuration.nix` includes:

```nix
nix.settings = {
  # Local cache has highest priority (listed first)
  substituters = [
    "http://10.10.10.10:5000"
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://nixpkgs-unfree.cachix.org"
  ];
  
  trusted-public-keys = [
    "cachy.local:/5+zDOluBKCtE2CdtE/aV4vB1gp1M1HsQFKbfCWKO14="
    # ... other keys ...
  ];
  
  # Allow the local cache to be used by all users
  trusted-substituters = [
    "http://10.10.10.10:5000"
  ];
};
```

## Benefits of Hybrid Approach

### Development Benefits (flake.nix)
1. **Universal access**: All developers get cache benefits automatically
2. **CI/CD optimization**: Automated builds use optimized caches
3. **Portable**: Works regardless of deployment environment
4. **Version controlled**: Cache configuration is part of the flake

### Deployment Benefits (configuration.nix)
1. **Environment-specific**: Local cache tailored to infrastructure
2. **Highest priority**: Local cache checked first for maximum speed
3. **Flexible**: Different deployments can use different local caches
4. **Administrative control**: System admins can customize per environment

### Combined Benefits
1. **Faster builds**: Multi-layer caching strategy
2. **Reduced bandwidth**: Intelligent cache hierarchy
3. **Offline capability**: Local cache works without internet
4. **Custom packages**: Share environment-specific packages

## Verification

To verify the cache priority is working:

```bash
# Show current substituters in order
nix show-config | grep substituters

# Test fetching from cache
nix store ping --store http://10.10.10.10:5000
```

## Troubleshooting

If packages are not being fetched from the local cache:

1. Ensure nix-serve is running: `systemctl status nix-serve`
2. Check connectivity: `curl http://10.10.10.10:5000/nix-cache-info`
3. Verify the public key matches: `cat /var/lib/nix-serve/cache-pub-key.pem`
4. Check Nix daemon has reloaded config: `sudo systemctl restart nix-daemon`