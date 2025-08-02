# Bulletproof Hyprland configuration to prevent crashes
{ config, lib, pkgs, ... }:

{
  # Critical session management
  services.seatd = {
    enable = true;
    group = "seat";
  };

  # Ensure user is in required groups
  users.groups.seat = {};
  users.users.amoon = {
    extraGroups = [ "seat" "video" "render" "input" ];
  };

  # Complete Wayland environment setup
  environment.sessionVariables = {
    # Wayland basics
    WAYLAND_DISPLAY = "wayland-1";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    
    # Critical for stability
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes cursor crashes
    WLR_RENDERER_ALLOW_SOFTWARE = "1"; # Fallback renderer
    NIXOS_OZONE_WL = "1"; # Electron apps
    
    # Toolkit settings
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland,x11";
    CLUTTER_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    
    # AMD GPU specific
    AMD_VULKAN_ICD = "RADV";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
  };

  # Critical Hyprland dependencies
  environment.systemPackages = with pkgs; [
    # Session management
    seatd
    polkit_gnome
    
    # Wayland essentials
    wayland
    wayland-protocols
    wayland-utils
    wlroots
    
    # XDG desktop portals
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-desktop-portal
    
    # Qt/GTK support
    libsForQt5.qt5.qtwayland
    qt6.qtwayland
    gtk3
    gtk4
    
    # Notifications and clipboard
    mako
    wl-clipboard
    
    # GPU tools
    vulkan-tools
    vulkan-validation-layers
    mesa-demos
    
    # Debug tools
    wlr-randr
    wayland-utils
    libseat
  ];

  # XDG Portal configuration - critical for stability
  xdg.portal = {
    enable = true;
    wlr.enable = false; # Conflicts with hyprland portal
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };
  };

  # D-Bus services
  services.dbus = {
    enable = true;
    packages = with pkgs; [
      dconf
      gcr
      gnome-keyring
    ];
  };

  # PolicyKit authentication agent
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Create Hyprland config with crash prevention
  environment.etc."hypr/hyprland.conf".text = ''
    # Monitor configuration - adjust to your setup
    monitor = , preferred, auto, 1
    
    # Critical startup commands
    exec-once = systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    exec-once = dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    exec-once = ${pkgs.mako}/bin/mako
    exec-once = ${pkgs.seatd}/bin/seatd-launch
    
    # Input configuration
    input {
        kb_layout = us
        follow_mouse = 1
        touchpad {
            natural_scroll = yes
        }
    }
    
    # General settings for stability
    general {
        gaps_in = 5
        gaps_out = 10
        border_size = 2
        layout = dwindle
        no_cursor_warps = true # Prevents cursor issues
    }
    
    # Safe animation settings
    animations {
        enabled = yes
        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        animation = windows, 1, 3, myBezier
        animation = windowsOut, 1, 3, default, popin 80%
        animation = border, 1, 5, default
        animation = fade, 1, 3, default
        animation = workspaces, 1, 3, default
    }
    
    # Misc settings for stability
    misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
        force_default_wallpaper = 0
        vfr = false # Disable variable frame rate - can cause crashes
        vrr = 0 # Disable variable refresh rate
        no_direct_scanout = true # More stable
    }
    
    # Debug settings
    debug {
        disable_logs = false
        disable_time = false
    }
    
    # Window rules for common applications
    windowrulev2 = float, class:^(pavucontrol)$
    windowrulev2 = float, class:^(nm-connection-editor)$
    windowrulev2 = float, class:^(polkit-gnome-authentication-agent-1)$
    
    # Basic keybindings
    bind = SUPER, Return, exec, kitty
    bind = SUPER, Q, killactive
    bind = SUPER SHIFT, E, exit
    bind = SUPER, F, fullscreen
    bind = SUPER, Space, togglefloating
    bind = SUPER, D, exec, fuzzel
    
    # Focus movement
    bind = SUPER, H, movefocus, l
    bind = SUPER, L, movefocus, r
    bind = SUPER, K, movefocus, u
    bind = SUPER, J, movefocus, d
    
    # Workspace switching
    bind = SUPER, 1, workspace, 1
    bind = SUPER, 2, workspace, 2
    bind = SUPER, 3, workspace, 3
    bind = SUPER, 4, workspace, 4
    bind = SUPER, 5, workspace, 5
  '';
}