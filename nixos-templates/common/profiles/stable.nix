{ config, lib, pkgs, ... }:

{
  # NixOS stable channel configuration
  # This profile uses the stable nixpkgs channel for maximum stability
  
  # System configuration optimized for stability
  system.autoUpgrade = {
    enable = lib.mkForce false; # Disable automatic upgrades for stability
  };

  # Conservative kernel settings
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
  ];

  # Stable package preferences
  environment.systemPackages = with pkgs; [
    # Core utilities from stable channel
    git
    vim
    wget
    curl
    htop
  ];

  # Conservative services configuration
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    RuntimeMaxUse=100M
  '';
}
