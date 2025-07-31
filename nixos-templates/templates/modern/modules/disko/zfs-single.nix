# ZFS single disk configuration with NVMe optimizations
{ config
, lib
, pkgs
, ...
}:
let
  # Import disk detection utilities
  diskLib = import ../../lib/disk-detection.nix { inherit lib pkgs; };

  # Auto-detect the primary disk with fallback
  primaryDisk =
    config.disko.primaryDisk or (diskLib.detectPrimaryDisk {
      preferNvme = true;
      preferSSD = true;
      minSizeGB = 64; # Minimum 64GB for ZFS system
    });

  # Generate a stable, unique hostId from hostname
  # This ensures ZFS pools can be imported correctly
  generateHostId = hostname:
    let
      # Hash the hostname to get a stable ID
      hash = builtins.hashString "sha256" hostname;
      # Take first 8 characters of the hash
      hostId = builtins.substring 0 8 hash;
    in
    hostId;
in
{
  # Add configuration options
  options.disko = {
    primaryDisk = lib.mkOption {
      type = lib.types.str;
      description = "Primary disk to use for installation (auto-detected if not specified)";
    };
  };

  config = {
    # Set the detected disk as default
    disko.primaryDisk = lib.mkDefault primaryDisk;

    # Set the hostId based on hostname
    networking.hostId = generateHostId config.networking.hostName;

    # Use ZRAM instead of swap partition for better performance
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
      memoryMax = 16 * 1024 * 1024 * 1024; # 16GB max
      priority = 5;
    };

    # Enable ZFS support
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    # Enable ZFS services with optimizations
    services.zfs = {
      trim.enable = true;
      autoScrub = {
        enable = true;
        interval = "monthly";
      };
      autoSnapshot = {
        enable = true;
        frequent = 4; # Keep 4 15-minute snapshots
        hourly = 24; # Keep 24 hourly snapshots
        daily = 7; # Keep 7 daily snapshots
        weekly = 4; # Keep 4 weekly snapshots
        monthly = 12; # Keep 12 monthly snapshots
      };
    };

    # ZFS kernel parameters with NVMe optimizations
    boot.kernelParams = [
      "zfs.zfs_arc_max=8589934592" # 8GB ARC max
      "zfs.zfs_arc_min=2147483648" # 2GB ARC min
      "zfs.l2arc_noprefetch=0" # Enable L2ARC prefetch
      "zfs.l2arc_write_boost=33554432" # 32MB write boost
      "zfs.zfs_vdev_async_read_max_active=8" # Increase async reads for NVMe
      "zfs.zfs_vdev_async_write_max_active=8" # Increase async writes for NVMe
      "zfs.zfs_vdev_sync_read_max_active=8"
      "zfs.zfs_vdev_sync_write_max_active=8"
      "zfs.zfs_vdev_max_active=1000" # Max concurrent I/Os per vdev
      "zfs.zio_slow_io_ms=300" # Increase slow I/O threshold for NVMe
      "zfs.zfs_prefetch_disable=0" # Enable prefetch
      "zfs.zfs_txg_timeout=5" # Faster transaction groups
    ];

    disko.devices = {
      disk = {
        main = {
          device = config.disko.primaryDisk;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                label = "ESP";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "umask=0077"
                    "defaults"
                    "noatime"
                    "iocharset=iso8859-1"
                    "shortname=winnt"
                    "utf8"
                  ];
                };
              };
              zfs = {
                priority = 2;
                name = "zfs";
                label = "zfs";
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      };

      zpool = {
        rpool = {
          type = "zpool";
          mode = ""; # Single disk
          rootFsOptions = {
            # NVMe-optimized options
            ashift = "12"; # 4K sectors (2^12 = 4096)
            autotrim = "on"; # Enable automatic TRIM

            # Performance optimizations
            atime = "off";
            compression = "zstd";
            dedup = "off"; # Enable per-dataset if needed
            xattr = "sa";
            acltype = "posixacl";
            relatime = "on";

            # Record size optimizations
            recordsize = "128k"; # Default, tune per dataset

            # Sync behavior
            sync = "standard";
            logbias = "latency"; # Optimize for low latency (NVMe)

            # Checksumming
            checksum = "blake3"; # Faster than SHA256

            # Cache settings
            primarycache = "all";
            secondarycache = "all";
          };

          # NVMe-optimized mount options
          mountOptions = [
            "noatime"
            "nodiratime"
          ];

          datasets = {
            "root" = {
              type = "zfs_fs";
              mountpoint = "/";
              options = {
                mountpoint = "legacy";
                recordsize = "128k";
                logbias = "latency";
              };
            };
            "home" = {
              type = "zfs_fs";
              mountpoint = "/home";
              options = {
                mountpoint = "legacy";
                recordsize = "128k";
                logbias = "latency";
                # Optional compression for user data
                compression = "zstd-3";
              };
            };
            "nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options = {
                mountpoint = "legacy";
                atime = "off";
                recordsize = "128k";
                logbias = "throughput"; # Nix store benefits from throughput
                # Good candidate for deduplication
                dedup = "blake3,verify";
                # Optimize for many small files
                redundant_metadata = "all";
              };
            };
            "var" = {
              type = "zfs_fs";
              mountpoint = "/var";
              options = {
                mountpoint = "legacy";
                recordsize = "128k";
                logbias = "latency";
              };
            };
            "var/lib" = {
              type = "zfs_fs";
              options = {
                mountpoint = "legacy";
                recordsize = "128k";
              };
            };
            "var/log" = {
              type = "zfs_fs";
              options = {
                mountpoint = "legacy";
                recordsize = "128k";
                # Enable compression for logs
                compression = "zstd-1";
              };
            };
            "tmp" = {
              type = "zfs_fs";
              mountpoint = "/tmp";
              options = {
                mountpoint = "legacy";
                recordsize = "128k";
                compression = "off"; # No compression for tmp
                sync = "disabled"; # Fast writes for tmp
              };
            };
          };
        };
      };
    };

    # Additional boot configuration for ZFS
    boot = {
      # Include necessary modules
      initrd.availableKernelModules = [
        "zfs"
      ];

      # ZFS-specific settings
      initrd.postDeviceCommands = lib.mkAfter ''
        # Import ZFS pool if needed
        zpool import -f rpool || true
      '';
    };

    # Enable filesystem trim
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };
  };
}
