# GNOME desktop environment - Wayland only
{ config, lib, pkgs, ... }:

{
  # Enable Wayland display server
  services.xserver.enable = false;
  
  # Enable GDM with Wayland
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  
  # Enable GNOME (Wayland by default)
  services.xserver.desktopManager.gnome.enable = true;
  
  # Force Wayland sessions only
  services.xserver.displayManager.gdm.autoSuspend = false;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome.epiphany
    gnome.geary
    # Exclude X11 session
    gnome.gnome-session
  ];
  
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
    
    # Wayland-specific tools
    wl-clipboard
    wev
    wlr-randr
  ];
  
  # Enable GSConnect
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };
  
  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };
}