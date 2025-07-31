{ config, lib, pkgs, ... }:

{
  # Gaming-optimized system configuration
  
  # Gaming kernel with better performance
  boot.kernelPackages = pkgs.linuxPackages_zen;
  
  # Gaming-specific kernel parameters
  boot.kernelParams = [
    "preempt=full"
    "mitigations=off" # Better performance, slightly less secure
  ];

  # Gaming services and drivers
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    steam-hardware.enable = true;
  };

  # Enable Steam and other gaming platforms
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    lutris
    heroic
    bottles
    
    # Gaming utilities
    mangohud
    gamemode
    gamescope
    
    # Performance monitoring
    htop
    btop
    
    # Media and communication
    discord
    obs-studio
  ];

  # Gaming-optimized services
  services.gamemode.enable = true;

  # Performance tweaks
  systemd.extraConfig = ''
    DefaultCPUAccounting=true
    DefaultBlockIOAccounting=true
    DefaultMemoryAccounting=true
    DefaultTasksAccounting=true
  '';
}
