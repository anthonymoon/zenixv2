# Hyprland configuration optimizations
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Create optimized Hyprland configuration
  environment.etc."hypr/hyprland.conf".text = ''
    # Monitor configuration - adjust to your setup
    # monitor=,preferred,auto,1
    monitor=,highres,auto,1

    # Execute critical services at startup
    exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    exec-once = ${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets
    exec-once = ${pkgs.waybar}/bin/waybar
    exec-once = ${pkgs.mako}/bin/mako
    exec-once = ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store
    exec-once = ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store
    exec-once = systemctl --user start graphical-session.target
    exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

    # GPU optimizations
    env = WLR_DRM_DEVICES,/dev/dri/card0
    env = WLR_NO_HARDWARE_CURSORS,1
    env = WLR_RENDERER_ALLOW_SOFTWARE,1
    
    # Toolkit backend variables
    env = GDK_BACKEND,wayland,x11
    env = QT_QPA_PLATFORM,wayland;xcb
    env = SDL_VIDEODRIVER,wayland
    env = CLUTTER_BACKEND,wayland
    env = XDG_CURRENT_DESKTOP,Hyprland
    env = XDG_SESSION_TYPE,wayland
    env = XDG_SESSION_DESKTOP,Hyprland
    
    # QT variables
    env = QT_AUTO_SCREEN_SCALE_FACTOR,1
    env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
    
    # Firefox/Thunderbird
    env = MOZ_ENABLE_WAYLAND,1
    env = MOZ_DBUS_REMOTE,1
    
    # Fix Java applications
    env = _JAVA_AWT_WM_NONREPARENTING,1

    # Input configuration
    input {
        kb_layout = us
        follow_mouse = 1
        touchpad {
            natural_scroll = yes
            disable_while_typing = yes
            tap-to-click = yes
        }
        sensitivity = 0
    }

    # General configuration
    general {
        gaps_in = 5
        gaps_out = 10
        border_size = 2
        col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
        col.inactive_border = rgba(595959aa)
        layout = dwindle
        allow_tearing = false
    }

    # Decorations
    decoration {
        rounding = 10
        blur {
            enabled = true
            size = 3
            passes = 1
        }
        drop_shadow = yes
        shadow_range = 4
        shadow_render_power = 3
        col.shadow = rgba(1a1a1aee)
    }

    # Animations
    animations {
        enabled = yes
        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
    }

    # Layout configuration
    dwindle {
        pseudotile = yes
        preserve_split = yes
    }

    master {
        new_is_master = true
    }

    # Gestures
    gestures {
        workspace_swipe = on
    }

    # Misc
    misc {
        force_default_wallpaper = 0
        disable_hyprland_logo = true
        disable_splash_rendering = true
        vfr = true
        vrr = 1
        mouse_move_enables_dpms = true
        key_press_enables_dpms = true
    }

    # Window rules for common applications
    windowrulev2 = float,class:^(pavucontrol)$
    windowrulev2 = float,class:^(nm-connection-editor)$
    windowrulev2 = float,class:^(polkit-gnome-authentication-agent-1)$
    windowrulev2 = float,title:^(Picture-in-Picture)$
    windowrulev2 = pin,title:^(Picture-in-Picture)$
    
    # Fix for some games
    windowrulev2 = fullscreen,class:^(steam_app_)
    windowrulev2 = immediate,class:^(steam_app_)
    
    # Workspace rules
    workspace = 1, monitor:DP-1, default:true
    workspace = 2, monitor:DP-1
    workspace = 3, monitor:DP-1
    workspace = 4, monitor:DP-1
    workspace = 5, monitor:DP-1

    # Keybindings
    $mainMod = SUPER

    # Core bindings
    bind = $mainMod, Q, killactive,
    bind = $mainMod, M, exit,
    bind = $mainMod, E, exec, ${pkgs.pcmanfm-qt}/bin/pcmanfm-qt
    bind = $mainMod, V, togglefloating,
    bind = $mainMod, R, exec, ${pkgs.fuzzel}/bin/fuzzel
    bind = $mainMod, P, pseudo,
    bind = $mainMod, J, togglesplit,
    bind = $mainMod, F, fullscreen
    bind = $mainMod, Return, exec, ${pkgs.kitty}/bin/kitty
    bind = $mainMod SHIFT, L, exec, ${pkgs.swaylock-effects}/bin/swaylock

    # Screenshot bindings
    bind = , Print, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
    bind = SHIFT, Print, exec, ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy
    bind = $mainMod, Print, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -

    # Move focus
    bind = $mainMod, left, movefocus, l
    bind = $mainMod, right, movefocus, r
    bind = $mainMod, up, movefocus, u
    bind = $mainMod, down, movefocus, d
    bind = $mainMod, h, movefocus, l
    bind = $mainMod, l, movefocus, r
    bind = $mainMod, k, movefocus, u
    bind = $mainMod, j, movefocus, d

    # Switch workspaces
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6
    bind = $mainMod, 7, workspace, 7
    bind = $mainMod, 8, workspace, 8
    bind = $mainMod, 9, workspace, 9
    bind = $mainMod, 0, workspace, 10

    # Move active window to workspace
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6
    bind = $mainMod SHIFT, 7, movetoworkspace, 7
    bind = $mainMod SHIFT, 8, movetoworkspace, 8
    bind = $mainMod SHIFT, 9, movetoworkspace, 9
    bind = $mainMod SHIFT, 0, movetoworkspace, 10

    # Scroll through workspaces
    bind = $mainMod, mouse_down, workspace, e+1
    bind = $mainMod, mouse_up, workspace, e-1

    # Move/resize windows with mouse
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow

    # Clipboard history
    bind = $mainMod, V, exec, ${pkgs.cliphist}/bin/cliphist list | ${pkgs.fuzzel}/bin/fuzzel -d | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy

    # Volume control
    binde = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

    # Brightness control
    binde = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
    binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

    # Media controls
    bind = , XF86AudioPlay, exec, playerctl play-pause
    bind = , XF86AudioNext, exec, playerctl next
    bind = , XF86AudioPrev, exec, playerctl previous
  '';
}