{ config, lib, pkgs, ... }:

{
  # KDE Plasma 6 Desktop Environment (workstation standard)
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  
  services.desktopManager.plasma6.enable = true;
  
  # Use SDDM display manager by default
  services.displayManager.sddm = {
    enable = lib.mkDefault true;
    wayland.enable = true; # Enable Wayland support
  };

  # KDE Plasma 6 applications and tools
  environment.systemPackages = with pkgs; [
    # Core KDE applications
    kate
    dolphin
    konsole
    spectacle
    gwenview
    okular
    ark
    
    # Multimedia
    krita
    kdenlive
    
    # System tools
    partition-manager
    
    # Additional workstation applications
    firefox
    libreoffice
    gimp
  ];

  # Enable Wayland support
  environment.sessionVariables = {
    # Wayland-specific environment variables
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };

  # KDE-specific services
  services = {
    # Enable location services
    geoclue2.enable = true;
  };

  # Enable KDE Connect program
  programs.kdeconnect.enable = true;

  # AMD GPU optimizations for KDE
  environment.variables = {
    # AMD GPU acceleration
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  # Font configuration for workstations
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # KDE recommended fonts
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
        sansSerif = [ "Source Sans Pro" "Noto Sans" ];
        monospace = [ "JetBrains Mono" "Fira Code" ];
      };
    };
  };
}
