# Simple desktop configuration without complex builders
{ config, lib, pkgs, ... }:

{
  # Instead of mkDesktopConfig with complex if-else chains,
  # just enable what you need directly
  
  # Enable X11
  services.xserver = {
    enable = true;
    
    # Simple keyboard configuration
    layout = "us";
    xkbVariant = "";
    
    # Enable touchpad support
    libinput.enable = true;
  };
  
  # For KDE Plasma
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  
  # Or for GNOME (comment out KDE above)
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  
  # Common desktop packages - just list them directly
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    chromium
    
    # Office
    libreoffice
    thunderbird
    
    # Media
    vlc
    spotify
    
    # Utils
    kate
    konsole
    dolphin
    
    # Development
    vscode
    git
  ];
  
  # Enable CUPS for printing
  services.printing.enable = true;
  
  # Enable flatpak for additional apps
  services.flatpak.enable = true;
  
  # NetworkManager for easy network configuration
  networking.networkmanager.enable = true;
}