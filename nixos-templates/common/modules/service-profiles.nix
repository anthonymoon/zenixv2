# Service profiles module - DRY implementation
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.profiles;
  utils = import ../../lib/utils.nix { inherit lib; };
  
in {
  options.services.profiles = {
    base = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable base services (SSH, networking, etc)";
      };
      
      ssh = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable SSH server";
        };
        
        ports = mkOption {
          type = types.listOf types.port;
          default = [ 22 ];
          description = "SSH ports";
        };
        
        passwordAuthentication = mkOption {
          type = types.bool;
          default = false;
          description = "Allow password authentication";
        };
      };
      
      networking = {
        firewall = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable firewall";
          };
          
          allowedTCPPorts = mkOption {
            type = types.listOf types.port;
            default = [ ];
            description = "Additional allowed TCP ports";
          };
          
          allowedUDPPorts = mkOption {
            type = types.listOf types.port;
            default = [ ];
            description = "Additional allowed UDP ports";
          };
        };
        
        networkManager = mkOption {
          type = types.bool;
          default = true;
          description = "Use NetworkManager";
        };
      };
    };
    
    desktop = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable desktop services";
      };
      
      printing = mkOption {
        type = types.bool;
        default = true;
        description = "Enable printing support";
      };
      
      scanning = mkOption {
        type = types.bool;
        default = true;
        description = "Enable scanning support";
      };
      
      power = mkOption {
        type = types.bool;
        default = true;
        description = "Enable power management";
      };
    };
    
    development = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable development services";
      };
      
      docker = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Docker";
      };
      
      podman = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Podman";
      };
      
      databases = {
        postgresql = mkOption {
          type = types.bool;
          default = false;
          description = "Enable PostgreSQL";
        };
        
        mysql = mkOption {
          type = types.bool;
          default = false;
          description = "Enable MySQL/MariaDB";
        };
        
        redis = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Redis";
        };
      };
    };
    
    server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable server services";
      };
      
      monitoring = mkOption {
        type = types.bool;
        default = true;
        description = "Enable monitoring services";
      };
      
      backup = mkOption {
        type = types.bool;
        default = true;
        description = "Enable backup services";
      };
    };
  };
  
  config = mkMerge [
    # Base services
    (mkIf cfg.base.enable {
      # SSH configuration
      services.openssh = mkIf cfg.base.ssh.enable (utils.mkSSHConfig {
        ports = cfg.base.ssh.ports;
        passwordAuthentication = cfg.base.ssh.passwordAuthentication;
      });
      
      # Networking
      networking = {
        networkmanager.enable = mkDefault cfg.base.networking.networkManager;
        firewall = utils.mkFirewallConfig {
          enable = cfg.base.networking.firewall.enable;
          allowedTCPPorts = cfg.base.ssh.ports ++ cfg.base.networking.firewall.allowedTCPPorts;
          allowedUDPPorts = cfg.base.networking.firewall.allowedUDPPorts;
        };
      };
      
      # Basic services
      services = {
        # Time synchronization
        timesyncd.enable = mkDefault true;
        
        # Firmware updates
        fwupd.enable = mkDefault true;
        
        # System monitoring
        smartd.enable = mkDefault true;
        
        # Periodic SSD TRIM
        fstrim.enable = mkDefault true;
      };
      
      # Basic security
      security = {
        sudo.wheelNeedsPassword = mkDefault true;
        polkit.enable = mkDefault true;
      };
    })
    
    # Desktop services
    (mkIf cfg.desktop.enable {
      services = {
        # Printing
        printing = mkIf cfg.desktop.printing {
          enable = true;
          drivers = with pkgs; [ 
            gutenprint
            gutenprintBin
            hplip
            epson-escpr
          ];
        };
        
        # Scanning
        saned.enable = mkIf cfg.desktop.scanning true;
        
        # Network discovery
        avahi = {
          enable = mkDefault true;
          nssmdns4 = mkDefault true;
          openFirewall = mkDefault true;
        };
        
        # Power management
        power-profiles-daemon.enable = mkIf cfg.desktop.power true;
        upower.enable = mkIf cfg.desktop.power true;
        
        # Desktop integration
        gnome.gnome-keyring.enable = mkDefault true;
        accounts-daemon.enable = mkDefault true;
        
        # Thumbnail generation
        tumbler.enable = mkDefault true;
      };
      
      # Desktop programs
      programs = {
        dconf.enable = mkDefault true;
        gnupg.agent = {
          enable = mkDefault true;
          enableSSHSupport = mkDefault true;
        };
      };
      
      # Hardware packages for scanning support
      hardware.sane = mkIf cfg.desktop.scanning {
        enable = true;
        extraBackends = with pkgs; [
          sane-airscan
          utsushi
          # epkowa requires allowUnfree
        ];
      };
    })
    
    # Development services
    (mkIf cfg.development.enable {
      # Container runtime
      virtualisation = {
        docker = mkIf cfg.development.docker {
          enable = true;
          enableOnBoot = mkDefault true;
          autoPrune = {
            enable = mkDefault true;
            dates = "weekly";
          };
        };
        
        podman = mkIf cfg.development.podman {
          enable = true;
          dockerCompat = mkDefault true;
          defaultNetwork.settings.dns_enabled = true;
        };
      };
      
      # Databases
      services = {
        postgresql = mkIf cfg.development.databases.postgresql {
          enable = true;
          enableTCPIP = mkDefault false;
          authentication = ''
            local all all trust
            host all all 127.0.0.1/32 trust
            host all all ::1/128 trust
          '';
        };
        
        mysql = mkIf cfg.development.databases.mysql {
          enable = true;
          package = pkgs.mariadb;
        };
        
        redis = mkIf cfg.development.databases.redis {
          servers."" = {
            enable = true;
            port = 6379;
          };
        };
      };
      
      # Development tools
      programs = {
        git = {
          enable = mkDefault true;
          lfs.enable = mkDefault true;
        };
        
        direnv = {
          enable = mkDefault true;
          nix-direnv.enable = mkDefault true;
        };
      };
    })
    
    # Server services
    (mkIf cfg.server.enable {
      services = {
        # Monitoring
        prometheus = mkIf cfg.server.monitoring {
          enable = true;
          exporters = {
            node = {
              enable = true;
              enabledCollectors = [ "systemd" ];
            };
          };
        };
        
        # Backup
        borgbackup.jobs = mkIf cfg.server.backup {
          system = {
            paths = [ "/etc" "/var" "/home" ];
            exclude = [ "/var/cache" "/var/tmp" ];
            repo = "/backup/borg";
            encryption.mode = "none";
            startAt = "daily";
            prune.keep = {
              daily = 7;
              weekly = 4;
              monthly = 6;
            };
          };
        };
        
        # Log management
        journald.extraConfig = ''
          SystemMaxUse=1G
          MaxRetentionSec=1month
          ForwardToSyslog=no
        '';
        
        # Automatic updates are handled by system.autoUpgrade in base module
      };
      
      # Server hardening
      security = {
        sudo.execWheelOnly = mkDefault true;
        hideProcessInformation = mkDefault true;
      };
    })
  ];
}