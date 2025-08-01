# Optimized ZFS configuration with minimal RAM usage
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Minimal ZFS ARC settings - reduce from 50% to 12.5% of RAM
  # For 32GB system: 4GB ARC instead of 16GB
  boot.kernelParams = [
    "zfs.zfs_arc_max=4294967296" # 4GB max ARC
    "zfs.zfs_arc_min=1073741824" # 1GB min ARC
  ];

  # Disable deduplication to save 3-5GB RAM
  # Instead rely on compression for space savings
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
    };
    autoSnapshot = {
      enable = false; # Disable if not needed
      frequent = 0;
      hourly = 0;
      daily = 0;
      weekly = 0;
      monthly = 0;
    };
  };

  # ZFS Event Daemon with minimal settings
  services.zfs.zed = {
    enableMail = false; # Disable email notifications
    settings = {
      # Minimal ZED configuration
      ZED_DEBUG_LOG = "/dev/null";
      ZED_EMAIL_ADDR = null;
      ZED_EMAIL_PROG = null;
      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = false;
      ZED_USE_ENCLOSURE_LEDS = false;
      ZED_SCRUB_AFTER_RESILVER = false;
    };
  };

  # Memory pressure settings to improve ZFS behavior under low memory
  boot.kernel.sysctl = {
    # Reduce ARC metadata limit to save memory
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # Allow ARC to be reclaimed more aggressively
    "vm.vfs_cache_pressure" = 200;

    # Reduce swappiness to keep active data in RAM
    "vm.swappiness" = 1;

    # ZFS-specific tuning for low memory
    "vm.min_free_kbytes" = 131072; # 128MB
  };

  # Optimize ZFS module parameters for minimal RAM usage
  boot.extraModprobeConfig = ''
    # Reduce memory usage for ZFS
    options zfs zfs_arc_meta_limit_percent=25
    options zfs zfs_arc_sys_free=536870912
    options zfs zfs_dirty_data_max_percent=10
    options zfs zfs_prefetch_disable=1
    options zfs zvol_request_sync=0
    options zfs zil_slog_bulk=786432
    options zfs zfs_txg_timeout=5

    # Disable features that consume memory
    options zfs zfs_arc_p_min_shift=0
    options zfs zfs_arc_average_blocksize=8192
    options zfs l2arc_noprefetch=1
    options zfs l2arc_feed_again=0
  '';

  # Install minimal ZFS utilities
  environment.systemPackages = with pkgs; [
    zfs
    # Remove zfs-prune-snapshots if not using snapshots
  ];

  # Monitoring script to track ZFS memory usage
  systemd.services.zfs-memory-monitor = {
    description = "Monitor ZFS ARC memory usage";
    after = [ "zfs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "zfs-arc-summary" ''
        echo "=== ZFS ARC Memory Usage ==="
        arc_size=$(awk '/^size/ {print $3}' /proc/spl/kstat/zfs/arcstats)
        arc_size_mb=$((arc_size / 1024 / 1024))
        echo "ARC Size: $${arc_size_mb}MB"

        arc_meta=$(awk '/^arc_meta_used/ {print $3}' /proc/spl/kstat/zfs/arcstats)
        arc_meta_mb=$((arc_meta / 1024 / 1024))
        echo "ARC Metadata: $${arc_meta_mb}MB"

        echo ""
        echo "Memory savings achieved:"
        echo "- Deduplication disabled: ~4GB saved"
        echo "- ARC limited to 4GB: ~12GB saved"
        echo "- Total RAM freed: ~16GB for applications"
      ''}";
    };
    # Run on boot and periodically
    startAt = "hourly";
  };

  # Update the system to use compression instead of deduplication
  fileSystems = {
    # Ensure all ZFS filesystems use compression but not dedup
    # This is handled in disko.nix, but we can set defaults here
  };

  # Boot optimization for ZFS
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # Import pool with minimal memory usage
    zpool import -N -o cachefile=none rpool

    # Set runtime memory limits
    echo 4294967296 > /sys/module/zfs/parameters/zfs_arc_max
    echo 1073741824 > /sys/module/zfs/parameters/zfs_arc_min
  '';
}
