# KDE Plasma desktop environment
{ config, lib, pkgs, ... }:

{
  # Enable X11 and Plasma
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };
  
  # KDE packages
  environment.systemPackages = with pkgs; [
    # KDE applications
    kate
    konsole
    dolphin
    ark
    spectacle
    okular
    gwenview
    
    # KDE utilities
    kdeconnect
    yakuake
    krdc
    filelight
    ksystemlog
    partition-manager
    
    # Plasma customization
    latte-dock
  ];
  
  # Enable KDE Connect
  programs.kdeconnect.enable = true;
  
  # Qt theme
  qt = {
    enable = true;
    platformTheme = "kde";
  };
}