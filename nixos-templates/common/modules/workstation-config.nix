# Workstation configuration module with proper type checking
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.workstation;
  
  # Custom types for better validation
  hostIdType = types.strMatching "^[0-9a-fA-F]{8}$";
  usernameType = types.strMatching "^[a-z_][a-z0-9_-]{0,31}$";
  hostnameType = types.strMatching "^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$";
  
in {
  options.workstation = {
    enable = mkEnableOption "workstation configuration";
    
    # Hardware configuration
    hardware = {
      cpu = mkOption {
        type = types.enum [ "amd" "intel" ];
        default = "amd";
        description = "CPU manufacturer for microcode updates";
      };
      
      gpu = mkOption {
        type = types.enum [ "amd" "nvidia" "intel" "none" ];
        default = "amd";
        description = "GPU type for driver configuration";
      };
      
      audio = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable audio support";
        };
        
        system = mkOption {
          type = types.enum [ "pipewire" "pulseaudio" "alsa" ];
          default = "pipewire";
          description = "Audio system to use";
        };
        
        bluetooth = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Bluetooth audio support";
        };
      };
    };
    
    # Filesystem configuration
    filesystem = {
      type = mkOption {
        type = types.enum [ "zfs" "btrfs" "ext4" "xfs" ];
        default = "zfs";
        description = "Root filesystem type";
      };
      
      zfs = {
        hostId = mkOption {
          type = hostIdType;
          default = "deadbeef";
          example = "1234abcd";
          description = "ZFS host ID (8 hexadecimal characters)";
        };
        
        arc = {
          max = mkOption {
            type = types.nullOr types.int;
            default = null;
            example = 8589934592; # 8GB
            description = "Maximum ARC size in bytes";
          };
          
          min = mkOption {
            type = types.nullOr types.int;
            default = null;
            example = 1073741824; # 1GB
            description = "Minimum ARC size in bytes";
          };
        };
      };
    };
    
    # Network configuration
    networking = {
      hostname = mkOption {
        type = hostnameType;
        default = "nixos";
        example = "workstation";
        description = "System hostname";
      };
      
      manager = mkOption {
        type = types.enum [ "networkmanager" "systemd-networkd" "dhcpcd" ];
        default = "networkmanager";
        description = "Network management system";
      };
      
      firewall = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable firewall";
        };
        
        allowedTCPPorts = mkOption {
          type = types.listOf types.port;
          default = [ 22 ];
          example = [ 22 80 443 ];
          description = "List of allowed TCP ports";
        };
        
        allowedUDPPorts = mkOption {
          type = types.listOf types.port;
          default = [ ];
          example = [ 53 123 ];
          description = "List of allowed UDP ports";
        };
      };
    };
    
    # User configuration
    users = {
      primaryUser = mkOption {
        type = usernameType;
        default = "user";
        example = "alice";
        description = "Primary user account name";
      };
      
      extraUsers = mkOption {
        type = types.listOf usernameType;
        default = [ ];
        example = [ "bob" "charlie" ];
        description = "Additional user accounts";
      };
      
      autoLogin = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic login for primary user";
      };
    };
    
    # Desktop environment
    desktop = {
      environment = mkOption {
        type = types.nullOr (types.enum [ "kde" "gnome" "hyprland" "none" ]);
        default = null;
        description = "Desktop environment to install";
      };
      
      displayManager = mkOption {
        type = types.enum [ "sddm" "gdm" "lightdm" "tui-greet" "none" ];
        default = "sddm";
        description = "Display manager to use";
      };
      
      wayland = mkOption {
        type = types.bool;
        default = true;
        description = "Prefer Wayland over X11 when available";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Apply validated configuration
    networking.hostName = cfg.networking.hostname;
    networking.hostId = mkIf (cfg.filesystem.type == "zfs") cfg.filesystem.zfs.hostId;
    
    # CPU microcode
    hardware.cpu.${cfg.hardware.cpu}.updateMicrocode = mkDefault true;
    
    # GPU configuration
    hardware.opengl = mkIf (cfg.hardware.gpu != "none") {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; 
        if cfg.hardware.gpu == "amd" then [ amdvlk rocm-opencl-icd rocm-opencl-runtime ]
        else if cfg.hardware.gpu == "intel" then [ intel-media-driver vaapiIntel ]
        else [ ];
    };
    
    # Audio configuration
    services.pipewire = mkIf (cfg.hardware.audio.enable && cfg.hardware.audio.system == "pipewire") {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Network manager
    networking.networkmanager.enable = mkIf (cfg.networking.manager == "networkmanager") true;
    systemd.network.enable = mkIf (cfg.networking.manager == "systemd-networkd") true;
    networking.dhcpcd.enable = mkIf (cfg.networking.manager == "dhcpcd") true;
    
    # Firewall
    networking.firewall = {
      enable = cfg.networking.firewall.enable;
      allowedTCPPorts = cfg.networking.firewall.allowedTCPPorts;
      allowedUDPPorts = cfg.networking.firewall.allowedUDPPorts;
    };
    
    # User configuration
    users.users = mkMerge ([
      # Primary user
      {
        ${cfg.users.primaryUser} = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" "libvirtd" ];
          shell = pkgs.zsh;
        };
      }
    ] ++ 
    # Additional users
    (map (username: {
      ${username} = {
        isNormalUser = true;
        extraGroups = [ "audio" "video" ];
        shell = pkgs.bash;
      };
    }) cfg.users.extraUsers));
    
    # ZFS configuration
    boot.supportedFilesystems = mkIf (cfg.filesystem.type == "zfs") [ "zfs" ];
    boot.zfs = mkIf (cfg.filesystem.type == "zfs") {
      forceImportRoot = false;
      forceImportAll = false;
    };
    
    # ZFS ARC tuning
    boot.kernelParams = mkIf (cfg.filesystem.type == "zfs" && cfg.filesystem.zfs.arc.max != null) [
      "zfs.zfs_arc_max=${toString cfg.filesystem.zfs.arc.max}"
      "zfs.zfs_arc_min=${toString cfg.filesystem.zfs.arc.min}"
    ];
  };
}