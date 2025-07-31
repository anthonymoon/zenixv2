# KDE Plasma profile using DRY principles
{ config, lib, pkgs, ... }:

{
  imports = [ ./desktop-dry.nix ];
  
  # KDE Plasma desktop
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  
  # KDE-specific packages
  packages.profiles.customPackages = with pkgs; [
    # KDE applications
    ark
    dolphin
    kate
    kcalc
    kdeconnect
    kdenlive
    okular
    spectacle
    
    # Plasma addons
    plasma-browser-integration
    plasma-nm
    plasma-pa
  ];
  
  # KDE Connect firewall rules
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
  
  # Enable KDE partition manager
  programs.partition-manager.enable = true;
}