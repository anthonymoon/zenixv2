# ZFS ephemeral root module
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../zfs
  ];

  # Rollback root dataset on boot
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/root@blank
  '';

  # Note: ZFS datasets should be created during installation with disko or manually
  # This module assumes the datasets already exist

  # Bind mounts for persistence
  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    options = ["bind"];
  };

  fileSystems."/var/log" = {
    device = "/persist/var/log";
    options = ["bind"];
  };

  fileSystems."/etc/ssh" = {
    device = "/persist/etc/ssh";
    options = ["bind"];
  };

  fileSystems."/home" = {
    device = "/persist/home";
    options = ["bind"];
  };

  # Machine ID persistence
  environment.etc."machine-id".source = "/persist/etc/machine-id";
}
