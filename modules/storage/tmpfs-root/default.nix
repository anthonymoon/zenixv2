# Tmpfs root filesystem module
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Root on tmpfs
  fileSystems."/" = lib.mkDefault {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=2G"
      "mode=755"
    ];
  };

  # Persistent storage required
  fileSystems."/persist" = lib.mkDefault {
    device = "/dev/disk/by-label/persist";
    fsType = "ext4";
    neededForBoot = true;
    options = ["noatime"];
  };

  # Boot partition
  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Essential bind mounts
  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    options = ["bind"];
  };

  fileSystems."/var/log" = {
    device = "/persist/var/log";
    options = ["bind"];
  };

  # SSH host keys persistence
  fileSystems."/etc/ssh" = {
    device = "/persist/etc/ssh";
    options = ["bind"];
  };

  # Machine ID persistence
  environment.etc."machine-id".source = "/persist/etc/machine-id";

  # Clean tmp on boot
  boot.tmp.cleanOnBoot = true;

  # No swap on tmpfs root
  swapDevices = lib.mkForce [];
}
