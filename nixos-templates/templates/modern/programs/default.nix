{ config
, lib
, pkgs
, ...
}: {
  imports = [
    # Base system packages
    ./base
    ./base/audio.nix
    ./base/boot.nix
    ./base/hardware.nix

    # Development
    ./development
    ./development/languages.nix
    ./development/tools.nix

    # Networking
    ./networking

    # Virtualization
    ./virtualization

    # Monitoring
    ./monitoring

    # File management
    ./file-management

    # Text processing
    ./text-processing

    # Shell
    ./shell
    ./zsh
    ./fish

    # Terminal
    ./terminal

    # Security
    ./security

    # Backup
    ./backup

    # Media
    ./media

    # Editors
    ./editors

    # System management
    ./system
  ];
}
