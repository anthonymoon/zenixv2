# Hyprland workstation profile
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../workstation
    ../../desktop/hyprland
  ];

  # Hyprland is enabled by importing the module
  desktop.hyprland.enable = true;

  # Hyprland-specific packages
  environment.systemPackages = with pkgs; [
    # Development tools for Wayland
    wev
    wlr-randr
    
    # Media
    mpv
    imv
    
    # Productivity
    zathura
    
    # System monitoring
    htop
    btop
    
    # Notifications
    dunst
    libnotify
  ];

  # Omarchy configuration options
  omarchy = {
    # These would be set per-host or by the user
    # full_name = "Your Name";
    # email_address = "your.email@example.com";
    theme = "tokyo-night";
    primary_font = "JetBrainsMono Nerd Font 11";
    scale = 1;
    monitors = [
      # Example: "DP-1,2560x1440@144,0x0,1"
    ];
  };
}