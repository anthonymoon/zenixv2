# Package profiles module - DRY implementation
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.packages.profiles;
  utils = import ../../lib/utils.nix { inherit lib; };
  
in {
  options.packages.profiles = {
    base = mkOption {
      type = types.bool;
      default = true;
      description = "Install base system packages";
    };
    
    desktop = mkOption {
      type = types.bool;
      default = false;
      description = "Install desktop packages";
    };
    
    development = mkOption {
      type = types.bool;
      default = false;
      description = "Install development packages";
    };
    
    monitoring = mkOption {
      type = types.bool;
      default = false;
      description = "Install monitoring and debugging packages";
    };
    
    networking = mkOption {
      type = types.bool;
      default = false;
      description = "Install networking tools";
    };
    
    multimedia = mkOption {
      type = types.bool;
      default = false;
      description = "Install multimedia packages";
    };
    
    gaming = mkOption {
      type = types.bool;
      default = false;
      description = "Install gaming packages";
    };
    
    customPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional custom packages to install";
    };
  };
  
  config = {
    environment.systemPackages = with pkgs; mkMerge [
      # Base packages - always installed
      (mkIf cfg.base (utils.packageGroups.base pkgs))
      
      # Desktop packages
      (mkIf cfg.desktop [
        # Browsers
        firefox
        chromium
        
        # Office
        libreoffice-fresh
        thunderbird
        
        # Media viewers
        evince  # PDF
        feh     # Images
        mpv     # Video
        
        # System tools
        pavucontrol
        networkmanagerapplet
        blueman
        
        # File managers
        pcmanfm
        ranger
        
        # Terminal emulators
        alacritty
        kitty
        
        # Text editors
        kate
        gedit
        
        # Utils
        flameshot  # Screenshots
        keepassxc  # Password manager
        remmina    # Remote desktop
      ])
      
      # Development packages
      (mkIf cfg.development (utils.packageGroups.development pkgs ++ [
        # Additional dev tools
        direnv
        nix-direnv
        
        # Container tools
        docker-compose
        podman-compose
        
        # Cloud tools
        kubectl
        terraform
        ansible
        
        # Database clients
        postgresql
        mysql
        redis
        sqlite
        
        # API tools
        curl
        httpie
        jq
        yq
        
        # Documentation
        man-pages
        man-pages-posix
      ]))
      
      # Monitoring packages
      (mkIf cfg.monitoring (utils.packageGroups.monitoring pkgs ++ [
        # Additional monitoring tools
        sysstat
        dstat
        glances
        nmon
        
        # Process monitoring
        psmisc
        procps
        
        # Disk tools
        ncdu
        duf
        dust
        
        # Network monitoring
        bandwhich
        vnstat
        nload
      ]))
      
      # Networking packages
      (mkIf cfg.networking (utils.packageGroups.networking pkgs ++ [
        # VPN tools
        networkmanager-openvpn
        networkmanager-vpnc
        
        # Network analysis
        wireshark
        tcpflow
        
        # File transfer
        rsync
        rclone
        sshfs
        
        # Download tools
        aria2
        yt-dlp
      ]))
      
      # Multimedia packages
      (mkIf cfg.multimedia [
        # Audio
        audacity
        ardour
        lmms
        
        # Video
        kdenlive
        obs-studio
        handbrake
        
        # Graphics
        gimp-with-plugins
        inkscape
        krita
        blender
        
        # Media players
        vlc
        mpv
        # spotify - requires allowUnfree
        
        # Codecs
        ffmpeg-full
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
      ])
      
      # Gaming packages
      (mkIf cfg.gaming [
        # Gaming platforms
        # steam - requires allowUnfree
        lutris
        heroic
        
        # Game tools
        mangohud
        gamemode
        
        # Compatibility
        wine-staging
        winetricks
        proton-ge-bin
        
        # Controllers
        antimicrox
        sc-controller
        
        # Performance
        corectrl  # GPU control for AMD
      ])
      
      # Custom packages
      cfg.customPackages
    ];
    
    # Font packages - included with desktop
    fonts.packages = mkIf cfg.desktop (with pkgs; [
      # System fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      
      # Programming fonts
      fira-code
      fira-code-symbols
      jetbrains-mono
      cascadia-code
      
      # Icon fonts
      font-awesome
      material-design-icons
      
      # Microsoft compatibility
      # corefonts - requires allowUnfree
      # vistafonts - requires allowUnfree
    ]);
  };
}