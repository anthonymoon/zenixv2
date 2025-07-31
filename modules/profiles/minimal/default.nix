# Minimal profile - bare essentials
{ config, lib, pkgs, ... }:

{
  # Minimal system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
  ];
  
  # Basic services
  services.openssh.enable = lib.mkDefault true;
  
  # Minimal documentation
  documentation.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;
  
  # Disable unnecessary features
  programs.command-not-found.enable = false;
  
  # Basic nix settings
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };
}