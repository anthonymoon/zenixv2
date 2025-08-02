# Hyprland stability fixes and enhancements
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Critical session management
  services.seatd = {
    enable = true;
    user = "seatd";
    group = "seat";
  };

  # Ensure systemd-logind is properly configured
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "ignore";
    extraConfig = ''
      HandlePowerKey=suspend
      HandlePowerKeyLongPress=poweroff
      RuntimeDirectorySize=50%
    '';
  };

  # Fix greetd configuration for proper session initialization
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --sessions ${config.services.displayManager.sessionData.desktops}/share/xsessions:${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd 'systemd-cat -t hyprland Hyprland'";
        user = "greeter";
      };
    };
  };

  # Ensure PAM is properly configured for Wayland sessions
  security.pam.services = {
    greetd = {
      enableGnomeKeyring = true;
      startSession = true;
    };
    swaylock = {};
  };

  # Critical environment variables for stability
  environment.sessionVariables = lib.mkMerge [
    (lib.mkAfter {
      # Hyprland-specific
      _JAVA_AWT_WM_NONREPARENTING = "1";
      XCURSOR_SIZE = "24";
      
      # GPU/rendering fixes
      WLR_NO_HARDWARE_CURSORS = "1"; # Fix cursor issues
      WLR_RENDERER_ALLOW_SOFTWARE = "1"; # Fallback renderer
      
      # Qt fixes
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      
      # Electron/Chromium apps
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      
      # GTK fixes
      GDK_BACKEND = "wayland,x11";
      GTK_USE_PORTAL = "1";
      
      # Firefox
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DBUS_REMOTE = "1";
    })
  ];

  # Hyprland-specific packages and dependencies
  environment.systemPackages = with pkgs; [
    # Session management
    seatd
    
    # Qt Wayland support
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    
    # Additional portal support
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    
    # GPU utilities
    glxinfo
    vulkan-tools
    wayland-utils
    wlr-randr
    
    # Debugging tools
    wev # Wayland event viewer
    wayland-protocols
    
    # Authentication agent
    polkit_gnome
    
    # Notification daemon (ensure it's available)
    mako
    
    # Screen locking
    swaylock-effects
    
    # Idle management
    swayidle
    
    # Clipboard manager
    wl-clipboard
    cliphist
    
    # Screenshot utilities
    grim
    slurp
    swappy
    
    # Display configuration
    kanshi
    
    # System tray support
    waybar
    
    # App launcher
    fuzzel
    wofi
  ];

  # XDG portal configuration with proper ordering
  xdg.portal = {
    enable = true;
    wlr.enable = lib.mkForce false; # Disable wlr portal in favor of hyprland portal
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config = {
      common = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
        "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
      };
      hyprland = {
        default = ["hyprland" "gtk"];
      };
    };
  };

  # D-Bus configuration
  services.dbus = {
    enable = true;
    implementation = "broker"; # Use dbus-broker for better performance
    packages = with pkgs; [
      dconf
      gcr
      gnome-keyring
    ];
  };

  # Systemd user services
  systemd.user.services = {
    polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wants = ["graphical-session.target"];
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  # GPU-specific fixes for AMD
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocmPackages.clr.icd
      mesa
      mesa.drivers
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      vaapiVdpau
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      amdvlk
      mesa
      mesa.drivers
    ];
  };

  # Kernel parameters for better Wayland/GPU performance
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "video=DP-1:2560x1440@144" # Adjust to your display
    "amdgpu.ppfeaturemask=0xffffffff" # Enable all power features
    "amdgpu.dc=1" # Enable display core
  ];

  # Additional AMD environment variables
  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  # Ensure Hyprland can access input devices
  services.udev.packages = with pkgs; [
    libinput
  ];

  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /var/lib/seatd 0755 seatd seat"
  ];

  # Users need to be in these groups
  users.groups = {
    seat = {};
    render = {};
  };
}