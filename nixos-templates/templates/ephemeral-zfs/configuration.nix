{ pkgs
, lib
, ...
}: {
  imports = [
    # Hardware configuration is imported via flake.nix
  ];

  # Networking
  networking.hostName = lib.mkDefault "@HOSTNAME@";
  # Use systemd-networkd instead of NetworkManager
  networking.useNetworkd = true;
  networking.useDHCP = false; # Disable global DHCP, configure per-interface

  # Configure all network interfaces for DHCP
  systemd.network = {
    enable = true;
    networks."10-all-interfaces" = {
      matchConfig.Name = "en* eth*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
      dhcpV4Config.RouteMetric = 100;
    };
  };

  # Disable IPv6
  networking.enableIPv6 = false;
  boot.kernelParams = [ "ipv6.disable=1" ];

  # Enable systemd-resolved for DNS
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    extraConfig = ''
      DNSStubListener=yes
    '';
  };

  # Time zone
  time.timeZone = "America/Chicago";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # Users
  users.users.amoon = {
    isNormalUser = true;
    extraGroups = [ "wheel" "systemd-journal" ];
    shell = pkgs.zsh;
    password = "nixos"; # Default password, change after installation
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA898oqxREsBRW49hvI92CPWTebvwPoUeMSq5VMyzoM3"
    ];
  };

  # Add nixos user for installation
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    password = "nixos"; # Default password, change after installation
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA898oqxREsBRW49hvI92CPWTebvwPoUeMSq5VMyzoM3"
    ];
  };

  # Allow root SSH access during installation
  users.users.root = {
    password = "nixos"; # Default password, change after installation
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA898oqxREsBRW49hvI92CPWTebvwPoUeMSq5VMyzoM3"
    ];
  };

  # Default shell
  programs.zsh.enable = true;

  # Minimal packages for system operation
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    git
    curl

    # Shell and terminal
    zsh

    # System utilities
    htop
    lsof
    file
    which
    tree

    # Network tools
    iproute2
    iputils
    dnsutils
    tcpdump

    # Hardware tools
    pciutils
    usbutils
    lshw
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Enable SSH in the boot process
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  # Enable zram swap (50% of RAM)
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;

      # Binary caches for faster downloads
      # Local cache has highest priority (listed first)
      substituters = [
        "http://10.10.10.10:5000"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ];

      trusted-public-keys = [
        "cachy.local:/5+zDOluBKCtE2CdtE/aV4vB1gp1M1HsQFKbfCWKO14="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      ];

      # Parallel downloads for faster installation
      max-jobs = "auto";
      cores = 0; # Use all available cores

      # Keep outputs for better caching
      keep-outputs = true;
      keep-derivations = true;

      # Allow using more substituters
      trusted-users = [ "root" "@wheel" ];

      # Trusted substituters (can be used by any user)
      trusted-substituters = [
        "http://10.10.10.10:5000"
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # ZFS services
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 12;
    };
  };

  # Persistence for ephemeral root
  systemd.tmpfiles.rules = [
    "L /var/lib/NetworkManager/secret_key - - - - /persist/var/lib/NetworkManager/secret_key"
    "L /var/lib/NetworkManager/seen-bssids - - - - /persist/var/lib/NetworkManager/seen-bssids"
    "L /var/lib/NetworkManager/timestamps - - - - /persist/var/lib/NetworkManager/timestamps"
  ];

  # SSH host key persistence
  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/persist/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # Machine ID persistence
  environment.etc."machine-id".source = "/persist/etc/machine-id";

  # State version
  system.stateVersion = "25.05";
}
