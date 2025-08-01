# KDE Plasma desktop environment - Wayland only
{ config, lib, pkgs, ... }:

{
  # Enable Wayland display server
  services.xserver.enable = false;
  
  # Enable SDDM with Wayland
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  
  # Enable Plasma 6 (Wayland by default)
  services.desktopManager.plasma6.enable = true;
  
  # Disable X11 sessions
  services.displayManager.sessionPackages = lib.mkForce [
    pkgs.kdePackages.plasma-workspace
  ];
  
  # KDE packages
  environment.systemPackages = with pkgs; [
    # KDE applications (Plasma 6 versions)
    kdePackages.kate
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.gwenview
    
    # KDE utilities
    kdePackages.kdeconnect-kde
    kdePackages.yakuake
    kdePackages.krdc
    kdePackages.filelight
    kdePackages.ksystemlog
    kdePackages.partitionmanager
    
    # Wayland-specific tools
    wl-clipboard
    wev
    wlr-randr
  ];
  
  # Enable KDE Connect
  programs.kdeconnect.enable = true;
  
  # Qt theme for Wayland
  qt = {
    enable = true;
    platformTheme = "kde";
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