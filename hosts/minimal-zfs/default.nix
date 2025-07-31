# Minimal ZFS system configuration
{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/storage/zfs
    ./disko.nix
  ];

  # Boot loader for ZFS
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # ZFS specific settings
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  
  # Generate host ID for ZFS
  networking.hostId = lib.mkDefault (builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName));
  
  # Basic system
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  
  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    zfs
  ];

  # Enable SSH
  services.openssh.enable = true;

  # Basic user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Change this!
    initialPassword = "changeme";
  };

  system.stateVersion = "24.11";
}