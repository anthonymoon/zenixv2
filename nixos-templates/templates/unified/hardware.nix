# Hardware configuration for 'nixies' host
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Boot configuration
  boot = {
    # Kernel modules for this hardware
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "uas" "sd_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    
    # ZFS support
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    
    # UEFI boot with systemd-boot
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    
    # Clean temporary files on boot
    tmp.cleanOnBoot = true;
    
    # Use LTS kernel for ZFS compatibility
    kernelPackages = pkgs.linuxPackages_6_6;
    
    # Security-focused kernel parameters
    kernelParams = [
      "quiet"
      "loglevel=3"
    ];
  };

  # Hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Hardware configuration
  hardware = {
    # AMD CPU microcode updates
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    
    # Enable firmware updates
    enableRedistributableFirmware = true;
  };

  # Network interfaces (detected from hardware-configuration.nix)
  networking = {
    hostName = "nixies";
    
    # Required for ZFS - generate unique ID based on hostname
    hostId = "6e697869"; # hex encoding of "nixi"
    
    useDHCP = lib.mkDefault true;
    
    # Specific interface configuration (uncomment if needed)
    # interfaces = {
    #   enp4s0f0np0.useDHCP = lib.mkDefault true;
    #   enp4s0f1np1.useDHCP = lib.mkDefault true;
    #   wlp6s0.useDHCP = lib.mkDefault true;
    # };
    
    # Secure firewall
    firewall = {
      enable = true;
      allowPing = true;
      logRefusedConnections = false;
    };
  };

  fileSystems."/" = lib.mkDefault {
    device = "rpool/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = lib.mkDefault {
    device = "rpool/nix";
    fsType = "zfs";
  };

  fileSystems."/home" = lib.mkDefault {
    device = "rpool/home";
    fsType = "zfs";
  };

  fileSystems."/var" = lib.mkDefault {
    device = "rpool/var";
    fsType = "zfs";
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];
}
