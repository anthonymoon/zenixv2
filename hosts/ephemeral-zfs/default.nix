# Ephemeral ZFS system
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/common
    ../../modules/storage/zfs
  ];
  
  # Filesystems for ZFS ephemeral system
  fileSystems."/" = lib.mkDefault {
    device = "zroot/root";
    fsType = "zfs";
  };
  
  fileSystems."/persist" = lib.mkDefault {
    device = "zroot/persist";
    fsType = "zfs";
  };
  
  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Boot loader for ZFS
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  
  # Generate host ID for ZFS
  networking.hostId = lib.mkDefault (builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName));
  
  # Ephemeral root on ZFS
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r zroot/root@blank
  '';
  
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

  # Enable SSH with persistent host keys
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