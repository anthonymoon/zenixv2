# Ephemeral profile - stateless operation
{ config, lib, pkgs, ... }:

{
  imports = [
    ../minimal
  ];
  
  # Ephemeral-specific settings
  boot.tmp.cleanOnBoot = true;
  
  # Disable state
  systemd.coredump.enable = false;
  
  # Memory-only journal
  services.journald.storage = "volatile";
  
  # Disable swap
  swapDevices = lib.mkForce [ ];
  
  # Note: To use environment.persistence, you need to add the impermanence input to your flake
  # and import its NixOS module. For now, we'll handle persistence through bind mounts
  # defined in the host configuration.
}