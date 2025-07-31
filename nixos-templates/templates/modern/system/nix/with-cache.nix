{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./default.nix
    ./local-cache.nix
  ];

  # Override to merge substituters instead of replacing
  nix.settings.substituters = lib.mkForce [
    "http://localhost:5000" # Local cache (highest priority)
    "https://cache.nixos.org/" # Official NixOS cache
    "https://nix-community.cachix.org" # Community cache
  ];

  # Ensure all substituters are trusted
  nix.settings.trusted-substituters = lib.mkForce [
    "http://localhost:5000"
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
  ];
}
