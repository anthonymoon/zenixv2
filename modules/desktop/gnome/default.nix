# GNOME desktop environment
{ config, lib, pkgs, ... }:

{
  # Enable X11 and GNOME
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  
  # GNOME packages
  environment.systemPackages = with pkgs; [
    # GNOME apps
    gnome.gnome-tweaks
    gnome.gnome-terminal
    gnome.nautilus
    gnome.gedit
    gnome.evince
    gnome.eog
    
    # GNOME extensions
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gsconnect
    
    # Additional tools
    dconf-editor
    gnome-usage
  ];
  
  # Remove some default GNOME apps
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome.epiphany
    gnome.geary
  ];
  
  # Enable GSConnect
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };
}