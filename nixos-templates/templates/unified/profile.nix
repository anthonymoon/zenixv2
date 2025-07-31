# NixOS system profile configuration
{ config, lib, pkgs, ... }:

{

  # ZFS services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    autoSnapshot = {
      enable = true;
      frequent = 4;  # 15-minute snapshots
      hourly = 24;   # hourly snapshots
      daily = 7;     # daily snapshots
      weekly = 4;    # weekly snapshots
      monthly = 12;  # monthly snapshots
    };
  };

  networking = {
    # Use systemd-networkd for consistent networking
    useNetworkd = true;
    useDHCP = false;
  };

  # systemd-networkd configuration
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "en* eth*";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      dhcpV4Config = {
        UseDNS = true;
        UseRoutes = true;
      };
    };
  };

  # Security configuration
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
      execWheelOnly = true;
    };
    
    # AppArmor for additional security
    apparmor.enable = true;
    
    # Real-time priority for audio
    rtkit.enable = true;
  };

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      # Security settings
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      
      # Performance settings
      UseDns = false;
      
      # Connection limits
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      LoginGraceTime = 30;
    };
    
    # Strong host keys
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  # Fail2ban for intrusion detection
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "168h"; # 1 week max
      factor = "4";
    };
    maxretry = 3;
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
  };

  # Nix configuration
  nix = {
    settings = {
      # Enable flakes and new commands
      experimental-features = [ "nix-command" "flakes" ];
      
      # Optimize store automatically
      auto-optimise-store = true;
      
      # Build settings
      max-jobs = "auto";
      cores = 0; # Use all available cores
      
      # Security: only allow wheel users to manage Nix
      allowed-users = [ "@wheel" ];
      trusted-users = [ "@wheel" ];
      
      # Substituters for faster builds
      substituters = [
        "https://cache.nixos.org"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    
    # Optimize store weekly
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # Essential packages
  environment.systemPackages = with pkgs; [
    # Text editors
    nano
    vim
    
    # File management
    file
    tree
    
    # Network tools
    curl
    wget
    dig
    
    # System tools
    htop
    iotop
    lsof
    pciutils
    usbutils
    
    # Archive tools
    unzip
    zip
    
    # Git for configuration management
    git
    
    # Process management
    psmisc
    
    # System information
    neofetch
    
    # Security tools
    gnupg
    
    # Nix tools
    nix-tree
    nix-du
  ];

  # Programs
  programs = {
    # Enable command-not-found
    command-not-found.enable = true;
    
    # Enable completion for system packages
    bash.completion.enable = true;
    
    # GPG agent for key management
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    
    # Git configuration
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };
  };

  # User configuration
  users = {
    # Use immutable users for security
    mutableUsers = false;
    
    # Default shell
    defaultUserShell = pkgs.bash;
    
    # Default user
    users = {
      # Disable root login
      root.hashedPassword = "!";
      
      # Default admin user
      admin = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
        # Set password after installation with: passwd admin
        hashedPassword = null;
        openssh.authorizedKeys.keys = [
          # Add your SSH public keys here
        ];
        description = "System Administrator";
      };
    };
  };

  # Locale and timezone
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # System logging
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=10M
    SystemKeepFree=1G
  '';

  # NixOS version
  system.stateVersion = "24.11";
}
