{ config
, pkgs
, lib
, ...
}: {
  imports = [
    # System packages
    ./environment/systemPackages

    # Fonts configuration
    ./fonts/packages.nix

    # Nixpkgs configuration
    ./nixpkgs

    # Individual program configurations
    ./programs
  ];
}
