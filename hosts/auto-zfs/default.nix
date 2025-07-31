# Auto-configured ZFS system using hardware detection
{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/common
    ../../modules/storage/zfs
    # Import facter modules if available
  ] ++ lib.optional (inputs ? nixos-facter-modules) 
    inputs.nixos-facter-modules.nixosModules.default;

  # If we have a facter report, use it
  config = lib.mkMerge [
    {
      # Basic configuration
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      
      # ZFS specific settings
      boot.supportedFilesystems = [ "zfs" ];
      boot.zfs.forceImportRoot = false;
      
      # Generate host ID for ZFS
      networking.hostId = lib.mkDefault (builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName));
      
      # Basic system
      time.timeZone = lib.mkDefault "UTC";
      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
      
      # Minimal packages
      environment.systemPackages = with pkgs; [
        vim
        git
        htop
        zfs
      ];
      
      # Enable SSH
      services.openssh.enable = true;
      
      # Basic user
      users.users.admin = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        initialPassword = "changeme";
      };
      
      system.stateVersion = "24.11";
    }
    
    # Apply facter-based configuration if available
    (lib.mkIf (config.facter.report or null) != null {
      # Auto-configure based on detected hardware
      boot.kernelModules = lib.mkDefault (
        if lib.hasInfix "Intel" (config.facter.report.hardware.cpu.vendor or "")
        then [ "kvm-intel" ]
        else if lib.hasInfix "AMD" (config.facter.report.hardware.cpu.vendor or "")
        then [ "kvm-amd" ]
        else [ ]
      );
      
      # Auto-configure graphics if detected
      services.xserver.videoDrivers = lib.mkDefault (
        let
          gpus = config.facter.report.hardware.gpu or [];
        in
        if lib.any (gpu: lib.hasInfix "NVIDIA" gpu.vendor) gpus then [ "nvidia" ]
        else if lib.any (gpu: lib.hasInfix "AMD" gpu.vendor) gpus then [ "amdgpu" ]
        else if lib.any (gpu: lib.hasInfix "Intel" gpu.vendor) gpus then [ "modesetting" ]
        else [ ]
      );
    })
  ];
}