# Common hardware configuration that detects VM vs bare metal
{ config
, lib
, pkgs
, modulesPath
, ...
}:
let
  # Detect if running in a VM
  isVM =
    (builtins.pathExists "/sys/class/dmi/id/sys_vendor" &&
    lib.hasInfix "QEMU" (lib.fileContents "/sys/class/dmi/id/sys_vendor")) ||
    (builtins.pathExists "/sys/class/dmi/id/product_name" &&
    (lib.hasInfix "VirtualBox" (lib.fileContents "/sys/class/dmi/id/product_name") ||
    lib.hasInfix "VMware" (lib.fileContents "/sys/class/dmi/id/product_name")));

  # Disk device path - can be overridden by disko configuration
  diskDevice = lib.mkDefault (if isVM then "/dev/vda" else "/dev/disk/by-id/@DISK_ID@");
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ZFS support configuration
  boot.supportedFilesystems = [ "zfs" "exfat" "xfs" "ntfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ]; # Critical for ZFS root

  # ZFS configuration
  boot.zfs = {
    # Force import root pool even if hostid doesn't match
    forceImportRoot = true;
    # Use by-partuuid for VMs for better compatibility
    devNodes = lib.mkIf isVM "/dev/disk/by-partuuid";
  };

  # Kernel configuration - conditional based on environment
  boot.kernelPackages = if isVM then pkgs.linuxPackages else pkgs.linuxPackages_6_6;

  # Kernel modules - base modules for both, VM-specific additions
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "sr_mod"
  ] ++ lib.optionals isVM [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
  ] ++ lib.optionals (!isVM) [
    "nvme"
    "usb_storage"
    "sd_mod"
  ];

  boot.initrd.kernelModules = [ "zfs" ] ++ lib.optionals isVM [
    "virtio_balloon"
    "virtio_rng"
    "virtio_console"
  ];

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ] ++ lib.optionals (!isVM) [ "i40e" "mac_hid" ];
  boot.extraModulePackages = [ ];

  # Kernel parameters - environment specific
  boot.kernelParams =
    [ "ipv6.disable=1" ] ++ # Common: disable IPv6
    (if isVM then [
      "console=ttyS0,115200"
      "console=tty0"
    ] else [
      "amd_pstate=passive"
      "processor.max_cstate=5"
      "rcu_nocbs=0-11"
      "mitigations=off"
    ]);

  # systemd-boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = if isVM then 3 else 10;

  # Networking
  networking.hostId = "deadbeef";
  networking.useDHCP = lib.mkDefault true;

  # VM optimizations
  services.qemuGuest.enable = lib.mkIf isVM true;
  virtualisation.hypervGuest.enable = false;

  # Hardware features
  hardware.graphics.enable = true;
  hardware.cpu.amd.updateMicrocode = lib.mkIf (!isVM) (lib.mkDefault config.hardware.enableRedistributableFirmware);

  # systemd in initrd for better VM support and modern ZFS handling
  boot.initrd.systemd.enable = true;

  # Ephemeral root rollback service
  boot.initrd.systemd.services.rollback-root = {
    description = "Rollback root to blank state";
    wantedBy = [ "initrd.target" ];
    # Make sure we run after systemd-udev-settle to ensure devices are ready
    after = [ "systemd-udev-settle.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for ZFS module to be available
      echo "Ensuring ZFS module is loaded..."
      modprobe zfs || {
        echo "Failed to load ZFS module"
        exit 1
      }
      
      # Try to import the pool if it's not already imported
      echo "Checking ZFS pool status..."
      if ! zpool list rpool >/dev/null 2>&1; then
        echo "Importing ZFS pool 'rpool'..."
        zpool import -N -f rpool || {
          echo "Failed to import pool rpool"
          exit 1
        }
      fi
      
      # Perform the rollback
      echo "Rolling back root filesystem to empty state..."
      zfs rollback -r rpool/nixos/empty@start || {
        echo "Failed to rollback root filesystem!"
        exit 1
      }
      
      echo "Rollback completed successfully"
    '';
  };

  # Filesystem declarations with zfsutil for proper mount ordering
  fileSystems = {
    "/" = {
      device = "rpool/nixos/empty";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    "/nix" = {
      device = "rpool/nixos/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
      neededForBoot = true;
    };

    "/home" = {
      device = "rpool/nixos/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    "/var/log" = {
      device = "rpool/nixos/var/log";
      fsType = "zfs";
      options = [ "zfsutil" ];
      neededForBoot = true;
    };

    "/var/lib" = {
      device = "rpool/nixos/var/lib";
      fsType = "zfs";
      options = [ "zfsutil" ];
      neededForBoot = true;
    };

    "/etc/nixos" = {
      device = "rpool/nixos/config";
      fsType = "zfs";
      options = [ "zfsutil" ];
      neededForBoot = true;
    };

    "/persist" = {
      device = "rpool/nixos/persist";
      fsType = "zfs";
      options = [ "zfsutil" ];
      neededForBoot = true;
    };

    "/var/lib/containers" = {
      device = "/dev/zvol/rpool/docker";
      fsType = "ext4";
    };

    "/boot" = {
      device = lib.mkDefault "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
    };
  };

  # Swap configuration
  swapDevices = [ ];
}
