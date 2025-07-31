# Desktop profile using DRY modules
{ config, lib, pkgs, ... }:

{
  # Enable desktop hardware features
  hardware.profiles = {
    enableBluetooth = true;
    enableSound = true;
    platform = "desktop";
  };
  
  # Enable desktop services
  services.profiles = {
    base.enable = true;
    desktop.enable = true;
  };
  
  # Enable desktop packages
  packages.profiles = {
    desktop = true;
    multimedia = true;
  };
  
  # X11/Wayland configuration
  services.xserver = {
    enable = true;
    
    # Keyboard layout
    xkb = {
      layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };
  };
  
  # Display manager will be set by specific DE profiles
  
  # Enable touchpad support
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
    };
  };
  
  # Enable Wayland where possible
  programs.xwayland.enable = lib.mkDefault true;
  
  # Security for desktop
  security.pam.services.swaylock = {};
  
  # XDG portal for desktop integration
  xdg.portal = {
    enable = true;
    wlr.enable = lib.mkDefault true;
  };
  
  # Enable flatpak for desktop apps
  services.flatpak.enable = lib.mkDefault true;
}