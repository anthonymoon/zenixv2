# Wayland desktop configuration with Hyprland and Niri
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # Enable Wayland support
  programs.xwayland.enable = true;

  # Common Wayland environment
  environment.sessionVariables = {
    # Wayland-specific
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # XDG
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    # QT Theme
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };

  # Fix Hyprland crashes by ensuring proper GPU drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Ensure proper permissions for Wayland
  security.polkit.enable = true;

  # Enable Hyprland (via omarchy-nix)
  # This is already handled by omarchy-nix

  # Enable Niri as an alternative compositor
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # Common Wayland utilities
  environment.systemPackages = with pkgs; [
    # Wayland tools
    wayland
    wayland-protocols
    wayland-utils
    wlroots

    # Screenshot/screen recording
    grim
    slurp
    wf-recorder

    # Clipboard
    wl-clipboard
    cliphist

    # Display management
    wlr-randr
    kanshi

    # Idle/lock
    swayidle
    swaylock

    # Notification daemon (if not provided by omarchy)
    mako

    # Application launcher (if not provided by omarchy)
    fuzzel
    tofi

    # Terminal (additional to kitty/ghostty)
    foot

    # File manager
    pcmanfm-qt

    # Polkit agent
    polkit_gnome

    # XDG desktop portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
  ];

  # XDG portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
    };
  };

  # D-Bus for Wayland
  services.dbus = {
    enable = true;
    packages = with pkgs; [
      dconf
      gcr
      gnome-keyring
    ];
  };

  # Enable gnome-keyring for authentication dialogs
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Fonts for Wayland
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      source-code-pro
      ubuntu_font_family
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [
          "JetBrains Mono"
          "Source Code Pro"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Create Niri config directory
  system.activationScripts.niriConfig = ''
    mkdir -p /etc/niri
    cat > /etc/niri/config.kdl << 'EOF'
    // Niri configuration
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }
        
        touchpad {
            tap
            natural-scroll
            accel-speed 0.2
        }
    }

    outputs {
        // Configure your displays here
        // Example: "DP-1" {
        //     mode "2560x1440@144"
        //     scale 1
        // }
    }

    layout {
        gaps 16
        center-focused-column "never"
        
        preset-column-widths {
            proportion 0.5
            proportion 0.66667
            proportion 1.0
        }
        
        default-column-width { proportion 0.5; }
        
        focus-ring {
            width 4
            active-color "#7fc8ff"
            inactive-color "#505050"
        }
        
        border {
            width 4
            active-color "#ffc87f"
            inactive-color "#505050"
        }
    }

    spawn-at-startup "systemctl" "--user" "start" "graphical-session.target"

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    hotkey-overlay {
        skip-at-startup
    }

    binds {
        // Mod-Shift-Slash to show help
        Mod+Shift+Slash { show-hotkey-overlay; }
        
        // Mod-Return to spawn terminal
        Mod+Return { spawn "kitty"; }
        
        // Mod-D to spawn launcher
        Mod+D { spawn "fuzzel"; }
        
        // Mod-Shift-E to logout
        Mod+Shift+E { quit; }
        
        // Mod-Q to close window
        Mod+Q { close-window; }
        
        // Window movement
        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up { focus-window-up; }
        Mod+Down { focus-window-down; }
        
        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up { move-window-up; }
        Mod+Shift+Down { move-window-down; }
        
        // Workspace switching
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        
        // Window sizing
        Mod+R { switch-preset-column-width; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        
        // Screenshot
        Print { screenshot; }
        Mod+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }
    }
    EOF
  '';
}
