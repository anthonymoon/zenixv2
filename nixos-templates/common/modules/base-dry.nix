# Common base module using DRY principles
{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./hardware-profiles.nix
    ./service-profiles.nix
    ./package-profiles.nix
  ];
  
  # System version
  system.stateVersion = mkDefault "24.11";
  
  # Default hardware profile for AMD workstations
  hardware.profiles = {
    type = mkDefault "amd";
    platform = mkDefault "desktop";
    enableBluetooth = mkDefault true;
    enableSound = mkDefault true;
  };
  
  # Default service profiles
  services.profiles = {
    base.enable = mkDefault true;
    desktop.enable = mkDefault (config.hardware.profiles.platform == "desktop");
    server.enable = mkDefault (config.hardware.profiles.platform == "server");
  };
  
  # Default package profiles
  packages.profiles = {
    base = mkDefault true;
    desktop = mkDefault (config.hardware.profiles.platform == "desktop");
    monitoring = mkDefault (config.hardware.profiles.platform == "server");
  };
  
  # Basic system settings
  console = {
    keyMap = mkDefault "us";
    useXkbConfig = mkDefault true;
  };
  
  # Timezone and localization
  time.timeZone = mkDefault "UTC";
  i18n.defaultLocale = mkDefault "en_US.UTF-8";
  
  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = mkDefault true;
      trusted-users = [ "root" "@wheel" ];
    };
    
    gc = {
      automatic = mkDefault true;
      dates = mkDefault "weekly";
      options = mkDefault "--delete-older-than 14d";
    };
  };
  
  # Basic user template
  users = {
    mutableUsers = mkDefault true;
    users.root = {
      hashedPassword = mkDefault null;
      openssh.authorizedKeys.keys = mkDefault [];
    };
  };
  
  # Template system integration
  environment.etc."nixos-templates/version".text = "2.0.0"; # Updated for DRY version
  
  # Minimal filesystem configuration (templates should override)
  fileSystems."/" = lib.mkDefault {
    device = "rpool/root";
    fsType = "zfs";
  };
  
  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  
  # ZFS requires hostId
  networking.hostId = lib.mkDefault "deadbeef";
  
  # Automatic System Upgrades (now simpler)
  system.autoUpgrade = {
    enable = mkDefault true;
    dates = mkDefault "09:00";
    randomizedDelaySec = mkDefault (45 * 60);
    allowReboot = mkDefault false;
    flake = mkDefault "github:user/nixos-templates#${config.networking.hostName}";
    flags = mkDefault [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
  };
  
  # Dynamic Library Compatibility (simplified)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Core libraries
      stdenv.cc.cc.lib
      zlib
      icu
      nss
      openssl
      curl
      expat
      
      # Graphics (conditional on hardware)
      libGL
      libva
      vulkan-loader
      
      # System libraries
      systemd
      dbus
      glib
      freetype
      fontconfig
    ] ++ optionals (config.hardware.profiles.platform == "desktop") [
      # Desktop-specific libraries
      gtk3
      gtk4
      qt5.qtbase
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      wayland
      libdrm
    ];
  };
}