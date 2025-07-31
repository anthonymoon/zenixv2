{ config, lib, pkgs, ... }:

{
  # System basics
  system.stateVersion = "24.05";

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      trusted-users = [ "root" "@wheel" ];
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Basic networking
  networking = {
    hostName = lib.mkDefault "nixos-zfs";
    useDHCP = lib.mkDefault true;
    firewall.enable = true;
  };

  # Time and locale
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Essential packages
  environment.systemPackages = with pkgs; [
    # System tools
    vim
    git
    htop
    tmux
    tree
    ncdu

    # Network tools
    curl
    wget
    dig

    # ZFS tools (additional)
    zfs-prune-snapshots
    zfstools
  ];

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # User configuration
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
    initialPassword = "nixos"; # Change on first login
  };

  # Sudo configuration
  security.sudo.wheelNeedsPassword = false;

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
