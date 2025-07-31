# Nix configuration with experimental features enabled by default
{ config
, lib
, pkgs
, inputs
, ...
}: {
  # Nix configuration
  nix = {
    settings = {
      # Enable experimental features
      experimental-features = [ "nix-command" "flakes" ];

      # Performance optimizations
      auto-optimise-store = true;
      max-jobs = "auto";

      # Substituters and trusted public keys
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://chaotic-nyx.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      ];

      # Allow unfree packages
      allow-unfree = true;

      # Build settings
      builders-use-substitutes = true;
      keep-derivations = true;
      keep-outputs = true;

      # Reduce disk usage
      min-free = 1024 * 1024 * 1024; # 1GB
      max-free = 5 * 1024 * 1024 * 1024; # 5GB

      # Network settings
      connect-timeout = 5;
      stalled-download-timeout = 300;

      # Trust wheel group for nix commands
      trusted-users = [ "root" "@wheel" ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Registry for flakes
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nixpkgs-stable.flake = inputs.nixpkgs-stable;
    };

    # Nix path
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
      "nixpkgs-stable=${inputs.nixpkgs-stable}"
    ];
  };

  # Nixpkgs config
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    allowUnsupportedSystem = false;
  };

  # Environment variables
  environment.variables = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
  };

  # System packages for nix development
  environment.systemPackages = with pkgs; [
    # Essential nix tools
    nix
    nix-output-monitor
    nvd

    # Development tools
    git
    curl
    wget

    # Compression tools
    gzip
    bzip2
    xz
    zstd

    # Build tools
    gcc
    gnumake

    # System utilities
    util-linux
    coreutils
    findutils
    gnugrep
    gnused
    gawk
  ];
}
