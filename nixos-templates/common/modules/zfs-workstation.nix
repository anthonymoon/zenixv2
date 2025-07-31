# ZFS root configuration for AMD workstations
{ config, lib, pkgs, ... }:

{
  # ZFS configuration optimized for workstations
  boot = {
    # ZFS support
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      requestEncryptionCredentials = true;
    };
    
    # Systemd-boot (required for ZFS root)
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # Keep last 10 generations
      };
      efi.canTouchEfiVariables = true;
    };
  };

  # ZFS services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    autoSnapshot = {
      enable = true;
      flags = "-k -p --utc";
      frequent = 4;   # 15-minute snapshots
      hourly = 24;    # Hourly snapshots
      daily = 7;      # Daily snapshots
      weekly = 4;     # Weekly snapshots
      monthly = 12;   # Monthly snapshots
    };
    trim.enable = true;
  };

  # Standard ZFS filesystem layout for workstations
  # This is a template - actual filesystems configured via disko
  environment.etc."zfs-layout-template.md".text = ''
    # Standard ZFS Layout for Workstations
    
    Pool: rpool (root pool)
    ├── rpool/root (mountpoint: /)
    ├── rpool/root/nixos (mountpoint: /nix)
    ├── rpool/home (mountpoint: /home)
    ├── rpool/var (mountpoint: /var)
    └── rpool/tmp (mountpoint: /tmp)
    
    Boot: separate FAT32 EFI partition (/boot)
    
    Features:
    - Native ZFS encryption
    - Automatic snapshots
    - Weekly scrubs
    - Compression (lz4)
    - ARC cache optimization
  '';

  # ZFS kernel module parameters for workstations
  boot.extraModprobeConfig = ''
    # ZFS ARC cache settings (for workstations with 16GB+ RAM)
    options zfs zfs_arc_max=${toString (8 * 1024 * 1024 * 1024)} # 8GB max
    options zfs zfs_arc_min=${toString (2 * 1024 * 1024 * 1024)} # 2GB min
    
    # Performance tuning
    options zfs zfs_prefetch_disable=0
    options zfs zfs_txg_timeout=5
    options zfs zfs_vdev_scheduler=none
  '';

  # Workstation-specific ZFS tuning
  systemd.services.zfs-workstation-tuning = {
    description = "ZFS workstation performance tuning";
    after = [ "zfs-import.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Set workstation-optimized ZFS parameters
      echo 1 > /sys/module/zfs/parameters/zfs_prefetch_disable || true
      echo 5 > /sys/module/zfs/parameters/zfs_txg_timeout || true
      echo 64 > /sys/module/zfs/parameters/zfs_vdev_async_read_max_active || true
      echo 32 > /sys/module/zfs/parameters/zfs_vdev_async_write_max_active || true
    '';
    wantedBy = [ "multi-user.target" ];
  };

  # Additional workstation packages for ZFS management
  environment.systemPackages = with pkgs; [
    zfs
    sanoid  # Snapshot management (includes syncoid)
  ];
}
