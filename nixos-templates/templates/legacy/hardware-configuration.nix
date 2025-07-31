# Hardware configuration for NixOS 25.11pre with ZFS
# This is a template - modify according to your actual hardware

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Boot configuration
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ]; # or "kvm-intel" for Intel
  boot.extraModulePackages = [ ];

  # File systems - Example ZFS pool configuration
  # Adjust these to match your actual ZFS pool layout
  
  # Root filesystem
  fileSystems."/" = {
    device = "zpool/root/nixos";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  # Boot filesystem
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/YOUR-BOOT-UUID"; # Replace with actual UUID
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Home filesystem
  fileSystems."/home" = {
    device = "zpool/home";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  # Nix store (optional separate dataset)
  fileSystems."/nix" = {
    device = "zpool/nix";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  # Example of additional datasets
  # fileSystems."/var/lib" = {
  #   device = "zpool/var/lib";
  #   fsType = "zfs";
  #   options = [ "zfsutil" ];
  # };

  # Swap configuration (if using zvol for swap)
  # swapDevices = [
  #   { device = "/dev/zvol/zpool/swap"; }
  # ];

  # Or use zram for compressed RAM swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Use up to 50% of RAM for compressed swap
  };

  # Networking (detected)
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eth0.useDHCP = lib.mkDefault true;

  # Hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  # CPU configuration
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Additional hardware support
  hardware.enableRedistributableFirmware = true;
  
  # Graphics configuration (example for AMD)
  # boot.initrd.kernelModules = [ "amdgpu" ];
  # services.xserver.videoDrivers = [ "amdgpu" ];
  
  # For NVIDIA:
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = true;
  #   open = false; # Use proprietary drivers
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };
}
