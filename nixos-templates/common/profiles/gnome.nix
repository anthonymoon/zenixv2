{ config, lib, pkgs, ... }:

{
  # GNOME Desktop Environment (workstation standard)
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Use GDM display manager by default
  services.displayManager.gdm = {
    enable = lib.mkDefault true;
    wayland = true; # Enable Wayland by default
  };

  # GNOME applications and tools
  environment.systemPackages = with pkgs; [
    # Core GNOME applications
    gnome.nautilus
    gnome.gnome-terminal
    gnome.gedit
    gnome.evince # PDF viewer
    gnome.eog # Image viewer
    gnome.file-roller # Archive manager
    gnome.gnome-calculator
    gnome.gnome-calendar
    gnome.gnome-contacts
    gnome.gnome-weather
    gnome.gnome-clocks
    
    # GNOME system tools
    gnome.gnome-system-monitor
    gnome.gnome-disk-utility
    gnome.dconf-editor
    gnome.gnome-tweaks
    gnome-extension-manager
    
    # Multimedia
    gnome.totem # Video player
    gnome.cheese # Camera
    
    # Development tools for workstations
    gnome.gnome-builder
    
    # Additional workstation applications
    firefox
    libreoffice
    gimp
    
    # GNOME Shell extensions (popular for workstations)
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.user-themes
    gnomeExtensions.workspace-indicator
    gnomeExtensions.system-monitor
  ];

  # Enable Wayland support
  environment.sessionVariables = {
    # Wayland-specific environment variables
    MOZ_ENABLE_WAYLAND = "1";
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
    XDG_SESSION_TYPE = "wayland";
  };

  # GNOME-specific services
  services = {
    # Enable location services
    geoclue2.enable = true;
    
    # Enable GNOME services
    gnome = {
      glib-networking.enable = true;
      gnome-keyring.enable = true;
      tracker-miners.enable = true;
      tracker.enable = true;
    };
    
    # Enable evolution data server
    evolution-data-server.enable = true;
  };

  # AMD GPU optimizations for GNOME
  environment.variables = {
    # AMD GPU acceleration
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    
    # GNOME specific optimizations
    GSK_RENDERER = "gl"; # Use OpenGL renderer
  };

  # Exclude some GNOME applications we don't want on workstations
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour # Welcome tour
    epiphany # GNOME web browser (we use Firefox)
    geary # Email client (can be added back if needed)
    gnome.simple-scan # Scanner app
  ];

  # GNOME Shell configuration
  programs.dconf.enable = true;
  
  # Font configuration for workstations
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # GNOME recommended fonts
      cantarell-fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      hack-font
      jetbrains-mono
      # Design fonts for workstations
      source-sans-pro
      source-serif-pro
      source-code-pro
    ];
    
    fontconfig = {
      defaultFonts = {
        serif = [ "Source Serif Pro" "Noto Serif" ];
        sansSerif = [ "Cantarell" "Source Sans Pro" "Noto Sans" ];
        monospace = [ "JetBrains Mono" "Fira Code" ];
      };
    };
  };
}
