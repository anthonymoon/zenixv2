# Simplification Guide - From Over-Engineered to Simple

This guide shows how to simplify over-engineered NixOS configurations by following best practices.

## Common Over-Engineering Patterns to Avoid

### 1. Complex Builder Functions

❌ **Over-engineered:**
```nix
mkSystem = { hostname, system ? "x86_64-linux", modules ? [], specialArgs ? {} }:
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = specialArgs // { inherit inputs hostname; };
    modules = [ ./modules/core ] ++ modules;
  };
```

✅ **Simple and clear:**
```nix
# In flake.nix, just use nixosSystem directly:
nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./configuration.nix ];
};
```

### 2. Abstract Module Builders

❌ **Over-engineered:**
```nix
mkServiceModule = { name, description, config }: {
  options.services.${name} = {
    enable = lib.mkEnableOption description;
  };
  config = lib.mkIf config.services.${name}.enable config;
};
```

✅ **Direct and obvious:**
```nix
# Just write the module directly:
{ config, lib, pkgs, ... }:
{
  options.services.myservice.enable = lib.mkEnableOption "my service";
  
  config = lib.mkIf config.services.myservice.enable {
    # Your service configuration
  };
}
```

### 3. Complex Hardware Detection

❌ **Over-engineered:**
```nix
detectCPU = { lib, ... }: {
  hardware.cpu = 
    if builtins.pathExists "/proc/cpuinfo" then
      let cpuinfo = builtins.readFile "/proc/cpuinfo";
          isIntel = lib.hasInfix "GenuineIntel" cpuinfo;
          isAMD = lib.hasInfix "AuthenticAMD" cpuinfo;
      in if isIntel then "intel" else if isAMD then "amd" else "generic"
    else "generic";
};
```

✅ **Use NixOS built-ins:**
```nix
# NixOS already handles this:
hardware.cpu.intel.updateMicrocode = true;
hardware.cpu.amd.updateMicrocode = true;
# The system will use the appropriate one
```

### 4. Profile Abstractions

❌ **Over-engineered:**
```nix
profileMap = {
  desktop = ../profiles/desktop.nix;
  gaming = ../profiles/gaming.nix;
  # ... many more
};
profileModules = map (p: profileMap.${p}) enabledProfiles;
```

✅ **Direct imports:**
```nix
# In your system configuration:
imports = [
  ./hardware-configuration.nix
  ./modules/desktop.nix  # Just import what you need
  ./modules/gaming.nix   # Clear and obvious
];
```

### 5. Package Group Abstractions

❌ **Over-engineered:**
```nix
mkPackageGroup = { name, packages, condition ? true }: 
  mkIf condition packages;

developmentPackages = mkPackageGroup {
  name = "development";
  packages = with pkgs; [ git vim emacs ];
};
```

✅ **Just list packages:**
```nix
environment.systemPackages = with pkgs; [
  # Development
  git
  vim
  emacs
  
  # Desktop apps
  firefox
  thunderbird
];
```

## Best Practices

### 1. Prefer Direct Configuration

Instead of creating abstractions, write configuration directly:

```nix
# Good: Clear what's happening
services.nginx = {
  enable = true;
  virtualHosts."example.com" = {
    locations."/".proxyPass = "http://localhost:3000";
  };
};

# Bad: Hidden behind abstraction
services = mkWebServer {
  domain = "example.com";
  backend = 3000;
};
```

### 2. Only Abstract True Duplication

Abstract only when you have:
- The same configuration in 3+ places
- Configuration that changes together
- Complex logic that benefits from encapsulation

### 3. Use NixOS Built-in Features

NixOS already provides many abstractions:
- `mkEnableOption` for enable flags
- `mkDefault` for overridable defaults  
- `mkIf` for conditional configuration
- `types` system for option validation

### 4. Keep Modules Focused

Each module should do one thing:

```nix
# Good: Single purpose
# modules/services/nginx.nix
{ config, lib, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    # nginx specific config
  };
}

# Bad: Kitchen sink module
# modules/web-stack.nix
{ config, lib, pkgs, ... }:
{
  services.nginx = { ... };
  services.mysql = { ... };
  services.php = { ... };
  # Too much in one module
}
```

### 5. Make Dependencies Explicit

```nix
# Good: Clear dependencies
imports = [
  ./hardware-configuration.nix
  ./modules/zfs.nix
  ./modules/desktop.nix
];

# Bad: Hidden magic
imports = [ 
  (import ./profile-loader.nix { 
    profiles = [ "desktop" "zfs" ]; 
  })
];
```

## When Abstraction Makes Sense

Abstraction is useful for:

1. **Truly complex repeated patterns** - Like ZFS dataset creation
2. **Cross-cutting concerns** - Like monitoring all services
3. **External integrations** - Like secret management
4. **Generated configurations** - Like multi-host deployments

## Migration Strategy

1. **Identify over-engineered code** - Look for builders, factories, complex helpers
2. **Understand the intent** - What problem was it trying to solve?
3. **Write direct replacement** - Use simple, clear configuration
4. **Test thoroughly** - Ensure functionality is preserved
5. **Document if needed** - Add comments for non-obvious configuration

## Examples in This Repository

See the `examples/` directory for simple, idiomatic NixOS configurations:
- `simple-flake.nix` - Direct flake configuration
- `simple-module.nix` - Clear module structure
- `simple-hardware.nix` - Hardware without detection magic
- `simple-desktop.nix` - Desktop configuration without builders
- `simple-users.nix` - User management without complexity

Remember: **Explicit is better than implicit, and simple is better than complex.**