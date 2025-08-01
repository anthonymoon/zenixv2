# Hyprland Wayland compositor
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.desktop.hyprland;
in
{
  options.desktop.hyprland = {
    enable = mkEnableOption "Hyprland Wayland compositor";
  };

  config = mkIf cfg.enable {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

  # Essential packages for Hyprland desktop
  environment.systemPackages = with pkgs; [
    # Core Wayland tools
    wayland
    wayland-utils
    wl-clipboard
    wlr-randr
    
    # Desktop essentials
    waybar
    wofi
    mako
    swaylock
    swayidle
    
    # Terminal
    kitty
    alacritty
    
    # File manager
    nautilus
    
    # Screenshot tools
    grim
    slurp
    swappy
    
    # Additional utilities
    brightnessctl
    pamixer
    playerctl
    networkmanagerapplet
    
    # Theming
    gnome.gnome-themes-extra
    gnome.adwaita-icon-theme
    papirus-icon-theme
  ];

  # Enable required services
  services = {
    # D-Bus for desktop integration
    dbus.enable = true;
    
    # Pipewire for audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # For screen sharing
    pipewire.wireplumber.enable = true;
    
    # Power management
    upower.enable = true;
    
    # Authentication agent
    gnome.gnome-keyring.enable = true;
  };

  # XDG desktop portal for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  # Security for Wayland
  security = {
    polkit.enable = true;
    pam.services.swaylock = {};
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    GDK_BACKEND = "wayland,x11";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };

  };
}