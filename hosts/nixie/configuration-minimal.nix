# Minimal configuration for nixie without enhanced AMD module
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Disko configuration (includes filesystem setup)
    inputs.disko.nixosModules.disko
    ./disko.nix

    # Hardware-specific settings without filesystem definitions
    ./hardware.nix

    # Common modules
    ../../modules/common
    ../../modules/common/performance.nix
    ../../modules/common/user-config.nix
    ../../modules/storage/zfs
    ../../modules/hardware/amd  # Basic AMD support (not enhanced)
    ../../modules/hardware/ntsync
    ../../modules/networking/intel-x710.nix
    ../../modules/networking/performance
    ../../modules/services/samba
    ../../modules/extras/pkgs
    ../../modules/desktop/wayland
    ../../modules/desktop/hyprland-bulletproof.nix
    ../../modules/desktop/sddm.nix
    ../../modules/security/hardening

    # Omarchy modules
    inputs.omarchy-nix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  # System configuration
  networking.hostName = "nixie";

  # User configuration using the new module
  zenix.user = {
    username = "amoon";
    fullName = "Anthony Moon";
    email = "tonymoon@gmail.com";
    initialPassword = "nixos";
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "networkmanager"
      "docker"
    ];
    sudoTimeout = 15;
    passwordlessSudo = false;
  };

  # Root user configuration
  users.users.root = {
    initialPassword = "nixos";
  };

  # Configure omarchy
  omarchy = {
    full_name = "Anthony Moon";
    email_address = "tonymoon@gmail.com";
    theme = "tokyo-night";
  };

  # Configure home-manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.amoon = {
      imports = [inputs.omarchy-nix.homeManagerModules.default];
      home.stateVersion = "24.11";
    };
  };

  # Basic services - using systemd-networkd
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Timezone and NTP
  time.timeZone = "America/Vancouver";
  services.timesyncd = {
    enable = true;
    servers = ["time.google.com"];
  };

  # SSH configuration - Password auth enabled
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      ChallengeResponseAuthentication = false;
      UsePAM = true;
    };
  };

  # Enable firewall with specific ports
  networking.firewall = {
    enable = true;
    allowPing = lib.mkForce true;  # Override hardening module
    allowedTCPPorts = [ 
      22    # SSH
      445   # SMB
      139   # SMB
      5357  # WSDD
    ];
    allowedUDPPorts = [ 
      137   # NetBIOS
      138   # NetBIOS
      5353  # mDNS
      3702  # WSDD
    ];
  };

  # Enable mDNS
  services.avahi.nssmdns4 = true;

  # DNS configuration
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = ["~."];
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    extraConfig = ''
      DNS=94.140.14.14 94.140.15.15 2a10:50c0::ad1:ff 2a10:50c0::ad2:ff
      DNSOverTLS=yes
    '';
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  # System state version
  system.stateVersion = "24.11";
}