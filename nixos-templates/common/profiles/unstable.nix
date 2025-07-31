{ config, lib, pkgs, ... }:

{
  # NixOS unstable channel configuration
  # This profile uses bleeding-edge packages from nixpkgs-unstable
  
  # Enable experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Unstable package preferences
  environment.systemPackages = with pkgs; [
    # Latest versions of development tools
    git
    neovim
    wget
    curl
    btop
    ripgrep
    fd
    bat
    exa
  ];

  # More aggressive journald settings for development
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    RuntimeMaxUse=200M
  '';
}
