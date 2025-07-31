{ config, lib, pkgs, ... }:

{
  # ZFS boot requirements
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      requestEncryptionCredentials = true;
    };

    # Kernel modules for ZFS
    initrd = {
      supportedFilesystems = [ "zfs" ];
      kernelModules = [ "zfs" ];
    };

    # Use systemd-boot for UEFI
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Kernel parameters
    kernelParams = [
      "zfs.zfs_arc_max=2147483648" # 2GB ARC max
      "mitigations=off" # Performance (disable for security-critical systems)
    ];
  };

  # ZFS services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 6;
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # ZFS-specific optimizations
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # Networking (required for ZFS hostId)
  networking.hostId = lib.mkDefault "8425e349";

  # Basic system packages
  environment.systemPackages = with pkgs; [
    zfs
    sanoid
    mbuffer
    lzop
    pv
  ];
}
