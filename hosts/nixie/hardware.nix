# Hardware configuration for nixie (without filesystem definitions)
# Filesystem configuration is handled by disko
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Boot configuration
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = ["zfs"];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];
  
  # Suppress kernel printk warnings
  boot.kernelParams = [
    "quiet"
    "loglevel=3"  # Only show critical messages
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];
  
  # Set console log level after boot
  boot.kernel.sysctl = {
    "kernel.printk" = "3 3 3 3";  # Suppress most kernel messages
  };

  # ZFS-specific settings
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.devNodes = "/dev/disk/by-partlabel";
  networking.hostId = "8425e349"; # Required for ZFS, generated from hostname

  # Hardware settings
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bootloader configuration for UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Force /boot to use partition label instead of UUID
  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-partlabel/disk-main-esp";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
