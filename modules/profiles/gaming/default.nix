# Gaming profile - optimized for gaming
{ config, lib, pkgs, ... }:

{
  imports = [
    ../workstation
  ];
  
  # Gaming kernel for better performance
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_latest;
  
  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    steam
    lutris
    heroic
    bottles
    
    # Gaming tools
    mangohud
    gamemode
    gamescope
    vkbasalt
    
    # Wine
    wine-staging
    winetricks
    protontricks
    
    # Emulators
    retroarch
    dolphin-emu
    
    # System monitoring
    corectrl
    goverlay
    
    # Communication
    discord
    teamspeak_client
  ];
  
  # Steam configuration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  # Gamemode
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        desiredgov = "performance";
        igpu_desiredgov = "performance";
        igpu_power_threshold = 0.3;
        disable_splitlock = 1;
      };
    };
  };
  
  # Performance tweaks
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # For some games
    "fs.file-max" = 524288;
  };
  
  # 32-bit support for games
  hardware.opengl = {
    driSupport32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libva
      vaapiIntel
    ];
  };
}