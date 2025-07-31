{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Basic filesystem configuration for testing
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Swap configuration
  swapDevices = [ 
    { device = "/dev/disk/by-label/swap"; }
  ];

  # Boot loader configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Network hardware
  networking.useDHCP = lib.mkDefault true;

  # CPU microcode
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable firmware
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Common hardware support
  boot.initrd.availableKernelModules = [ 
    "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" 
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # NixOS settings
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
