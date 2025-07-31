{ config, lib, pkgs, ... }:

{
  # Hyprland Wayland Compositor (workstation optimized)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Display manager choice (TUI-greet preferred for Hyprland)
  services.greetd = {
    enable = lib.mkDefault true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # Essential Hyprland ecosystem for workstations  
  environment.systemPackages = with pkgs; [
    # Core Hyprland tools
    hyprpaper          # Wallpaper daemon
    hyprcursor         # Cursor theme
    hyprlock           # Screen locker
    hypridle           # Idle daemon
    
    # Status bar and launchers
    waybar             # Status bar
    wofi               # App launcher
    fuzzel             # Alternative launcher
    
    # System tools
    wlogout            # Logout menu
    wl-clipboard       # Clipboard manager
    cliphist           # Clipboard history
    
    # Notifications
    mako               # Notification daemon
    libnotify          # Notification library
    
    # Screenshots and screen recording
    grim               # Screenshot tool
    slurp              # Screen selection
    wf-recorder        # Screen recording
    
    # File management
    thunar             # File manager
    tumbler            # Thumbnail service
    
    # Terminal and applications
    kitty              # Terminal
    foot               # Alternative lightweight terminal
    firefox            # Web browser
    
    # Media
    mpv                # Video player
    imv                # Image viewer
    
    # System monitoring
    btop               # System monitor
    
    # Utilities
    brightnessctl      # Brightness control
    pamixer            # Audio control
    playerctl          # Media control
    
    # Development tools (workstation focus)
    vscode             # Code editor
    
    # Themes and appearance
    gtk3
    gtk4
    adwaita-icon-theme
    papirus-icon-theme
  ];

  # Hyprland-specific environment
  environment.sessionVariables = {
    # Wayland-specific
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland,x11";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    
    # AMD GPU acceleration
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    
    # Hyprland specific
    WLR_NO_HARDWARE_CURSORS = "1"; # AMD GPU workaround
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  # XDG portal configuration for screen sharing and file dialogs
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Security and authentication
  security = {
    polkit.enable = true;
    pam.services.swaylock = {}; # For screen locking
  };

  # Enable services needed for Hyprland workstation
  services = {    
    # D-Bus for desktop integration
    dbus.enable = true;
    
    # Power management
    power-profiles-daemon.enable = true;
    upower.enable = true;
    
    # Audio (handled by base module but ensure it's available)
    pipewire.enable = true;
    
    # Thumbnail generation
    tumbler.enable = true;
    
    # Location services
    geoclue2.enable = true;
    
    # Bluetooth GUI
    blueman.enable = true;
  };

  # Font configuration optimized for tiling WM
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # Programming fonts (important for terminals/editors)
      jetbrains-mono
      fira-code
      fira-code-symbols
      hack-font
      source-code-pro
      
      # UI fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      
      # Icon fonts for status bars
      font-awesome
      material-design-icons
    ];
    
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrains Mono" "Fira Code" ];
      };
    };
  };

  # GTK theme configuration
  programs.dconf.enable = true;
  
  # Example Hyprland configuration snippet
  environment.etc."hyprland-workstation-example.conf".text = ''
    # Example Hyprland configuration for workstations
    # Place in ~/.config/hypr/hyprland.conf
    
    # AMD GPU optimizations
    env = WLR_NO_HARDWARE_CURSORS,1
    env = LIBVA_DRIVER_NAME,radeonsi
    env = VDPAU_DRIVER,radeonsi
    
    # Workstation-focused keybinds
    bind = SUPER, Return, exec, kitty
    bind = SUPER, D, exec, wofi --show drun
    bind = SUPER, L, exec, hyprlock
    bind = SUPER SHIFT, Q, killactive
    
    # Workspace bindings (10 workspaces for productivity)
    $(for i in {1..10}; do echo "bind = SUPER, $i, workspace, $i"; done)
  '';
}
