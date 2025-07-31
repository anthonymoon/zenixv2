{ lib }:

rec {
  # Template type definitions
  templateTypes = {
    modern = {
      description = "Modern dynamic system with profiles";
      profiles = {
        desktop = [ "kde" "gnome" "hyprland" "niri" ];
        system = [ "stable" "unstable" "hardened" "chaotic" ];
        usage = [ "gaming" "headless" "development" ];
      };
      features = [
        "auto-hardware-detection"
        "profile-composition"
        "performance-optimization"
        "modular-architecture"
      ];
    };

    ephemeral-zfs = {
      description = "ZFS ephemeral root system";
      profiles = {
        system = [ "stable" "25-05" ];
        usage = [ "headless" "desktop" ];
      };
      features = [
        "ephemeral-root"
        "zfs-snapshots"
        "persistent-paths"
        "template-substitution"
      ];
    };

    minimal-zfs = {
      description = "Minimal ZFS system";
      profiles = {
        system = [ "stable" ];
        usage = [ "base" "server" ];
      };
      features = [
        "zfs-root"
        "minimal-packages"
        "basic-security"
      ];
    };

    deployment = {
      description = "Deployment-focused system";
      profiles = {
        target = [ "remote" "local" "vm" ];
        system = [ "stable" ];
      };
      features = [
        "remote-deployment"
        "automated-installation"
        "template-substitution"
      ];
    };

    personal = {
      description = "Personal dotfiles configuration";
      profiles = {
        desktop = [ "kde" "hyprland" ];
        system = [ "stable" "unstable" ];
      };
      features = [
        "dotfiles-management"
        "age-encryption"
        "home-manager"
        "user-configuration"
      ];
    };

    unified = {
      description = "Unified disko-based system";
      profiles = {
        system = [ "stable" ];
        usage = [ "desktop" "server" ];
      };
      features = [
        "disko-integration"
        "simple-configuration"
        "standard-layout"
      ];
    };

    installer = {
      description = "ZFS installer system";
      profiles = {
        target = [ "installer" ];
        system = [ "stable" ];
      };
      features = [
        "installation-focused"
        "zfs-setup"
        "automated-partitioning"
      ];
    };

    legacy = {
      description = "Legacy and testing configurations";
      profiles = {
        version = [ "25-11-pre" ];
        usage = [ "testing" ];
      };
      features = [
        "version-testing"
        "experimental-features"
      ];
    };
  };

  # Template parameter system
  templateParameters = {
    common = {
      hostname = {
        type = "string";
        description = "System hostname";
        default = "nixos";
        validation = "^[a-zA-Z0-9-]+$";
      };
      username = {
        type = "string";
        description = "Primary user name";
        default = "user";
        validation = "^[a-zA-Z0-9_-]+$";
      };
      disk = {
        type = "string";
        description = "Target disk device";
        default = "/dev/sda";
        validation = "^/dev/[a-zA-Z0-9/_-]+$";
      };
      timezone = {
        type = "string";
        description = "System timezone";
        default = "UTC";
      };
    };

    zfs-specific = {
      hostId = {
        type = "string";
        description = "ZFS host ID (8 hex chars)";
        default = "deadbeef";
        validation = "^[a-fA-F0-9]{8}$";
      };
      poolName = {
        type = "string";
        description = "ZFS pool name";
        default = "rpool";
        validation = "^[a-zA-Z0-9_-]+$";
      };
    };

    modern-specific = {
      autoHardware = {
        type = "boolean";
        description = "Enable automatic hardware detection";
        default = true;
      };
      performanceOptimization = {
        type = "boolean";
        description = "Enable performance optimizations";
        default = true;
      };
    };
  };

  # Get available profiles for a template
  getProfilesForTemplate = templateName:
    if templateTypes ? ${templateName}
    then templateTypes.${templateName}.profiles
    else {};

  # Get all available profiles
  getAllProfiles = lib.foldl' (acc: template: 
    acc // (getProfilesForTemplate template)
  ) {} (lib.attrNames templateTypes);

  # Validate template configuration
  validateTemplateConfig = templateName: config:
    let
      template = templateTypes.${templateName} or null;
    in
    if template == null
    then { valid = false; error = "Unknown template: ${templateName}"; }
    else { valid = true; };

  # Template composition helpers
  composeProfiles = profiles: templateName:
    let
      availableProfiles = getProfilesForTemplate templateName;
      validProfiles = lib.filter (p: 
        lib.any (category: lib.elem p availableProfiles.${category}) 
        (lib.attrNames availableProfiles)
      ) profiles;
    in
    validProfiles;

  # Generate example configurations
  exampleConfigurations = {
    modern = [
      "workstation.desktop.kde.gaming.stable"
      "laptop.desktop.hyprland.development.unstable"
      "server.headless.hardened.stable"
      "gaming-rig.desktop.kde.gaming.chaotic"
    ];

    ephemeral-zfs = [
      "zfs-workstation.desktop.stable"
      "zfs-server.headless.stable"
      "zfs-dev.desktop.25-05"
    ];

    minimal-zfs = [
      "minimal-server.base.stable"
      "minimal-nas.server.stable"
    ];

    deployment = [
      "deploy-target.remote.stable"
      "vm-deploy.vm.stable"
    ];

    personal = [
      "personal-desktop.kde.stable"
      "personal-laptop.hyprland.unstable"
    ];
  };

  # Template inheritance system
  templateInheritance = {
    ephemeral-zfs.inheritsFrom = [ "minimal-zfs" ];
    deployment.inheritsFrom = [ "ephemeral-zfs" ];
    personal.inheritsFrom = [ "modern" ];
  };

  # Get profiles by template (for library export)
  getProfilesByTemplate = templateTypes;
}
