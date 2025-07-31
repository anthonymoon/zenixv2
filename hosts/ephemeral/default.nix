# Ephemeral system with tmpfs root
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/common
  ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Tmpfs root
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };
  
  # Persistent storage for necessary data
  fileSystems."/persist" = {
    device = "/dev/disk/by-label/persist";
    fsType = "ext4";
    neededForBoot = true;
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  
  # Bind mounts for persistent data
  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    options = [ "bind" ];
  };
  
  fileSystems."/var/log" = {
    device = "/persist/var/log";
    options = [ "bind" ];
  };
  
  # Basic system
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  
  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];

  # Enable SSH
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Basic user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "24.11";
}