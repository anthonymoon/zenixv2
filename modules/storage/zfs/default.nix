{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.storage.zfs;
in {
  imports = [
    ./filesystem-labels.nix
  ];

  options.storage.zfs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ZFS filesystem support";
    };

    hostId = lib.mkOption {
      type = lib.types.str;
      default = lib.mkDefault (
        builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName)
      );
      description = "ZFS host ID (8 hex characters)";
    };

    arcSize = {
      min = lib.mkOption {
        type = lib.types.int;
        default = 2147483648; # 2GB
        description = "Minimum ARC size in bytes";
      };

      max = lib.mkOption {
        type = lib.types.int;
        default = 8589934592; # 8GB
        description = "Maximum ARC size in bytes";
      };
    };

    optimizeForNvme = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apply NVMe-specific optimizations";
    };

    datasets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            compression = lib.mkOption {
              type = lib.types.enum [
                "off"
                "lz4"
                "gzip"
                "zstd"
              ];
              default = "zstd";
              description = "Compression algorithm";
            };

            mountpoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Dataset mountpoint";
            };

            options = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = {};
              description = "Additional ZFS dataset options";
            };
          };
        }
      );
      default = {};
      description = "ZFS datasets configuration";
    };

    autoSnapshot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automatic ZFS snapshots";
    };

    autoScrub = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic ZFS scrubbing";
    };

    kernelParams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional kernel parameters for ZFS";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable ZFS
    boot.supportedFilesystems = ["zfs"];
    boot.zfs.devNodes = "/dev/disk/by-id";

    # Set host ID
    networking.hostId = cfg.hostId;

    # Kernel parameters
    boot.kernelParams =
      [
        "zfs.zfs_arc_max=${toString cfg.arcSize.max}"
        "zfs.zfs_arc_min=${toString cfg.arcSize.min}"
      ]
      ++ lib.optionals cfg.optimizeForNvme [
        # NVMe optimizations
        "zfs.l2arc_noprefetch=0"
        "zfs.l2arc_write_boost=33554432"
        "zfs.l2arc_write_max=16777216"
        "zfs.zfs_txg_timeout=5"
        "zfs.zfs_vdev_async_read_max_active=6"
        "zfs.zfs_vdev_async_read_min_active=2"
        "zfs.zfs_vdev_async_write_max_active=6"
        "zfs.zfs_vdev_async_write_min_active=2"
        "zfs.zfs_vdev_sync_read_max_active=6"
        "zfs.zfs_vdev_sync_read_min_active=2"
        "zfs.zfs_vdev_sync_write_max_active=6"
        "zfs.zfs_vdev_sync_write_min_active=2"
        "zfs.zfs_dirty_data_max_percent=40"
        "zfs.zfs_vdev_aggregation_limit=1048576"
      ]
      ++ cfg.kernelParams;

    # ZFS services
    services.zfs = {
      autoScrub = {
        enable = cfg.autoScrub;
        interval = "weekly";
      };

      autoSnapshot = lib.mkIf cfg.autoSnapshot {
        enable = true;
        frequent = 4;
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 12;
      };

      trim.enable = true;
    };

    # Required packages
    environment.systemPackages = with pkgs; [
      zfs
      zfs-autobackup
      sanoid
      syncoid
    ];

    # Common ZFS module parameters
    boot.extraModprobeConfig = ''
      # Tune ZFS module parameters
      options zfs zfs_arc_max=${toString cfg.arcSize.max}
      options zfs zfs_arc_min=${toString cfg.arcSize.min}
      ${lib.optionalString cfg.optimizeForNvme ''
        # NVMe optimizations
        options zfs l2arc_noprefetch=0
        options zfs l2arc_write_boost=33554432
        options zfs l2arc_write_max=16777216
      ''}
    '';

    # Assertions
    assertions = [
      {
        assertion = cfg.arcSize.min <= cfg.arcSize.max;
        message = "ZFS ARC minimum size must be less than or equal to maximum size";
      }
      {
        assertion = builtins.stringLength cfg.hostId == 8;
        message = "ZFS host ID must be exactly 8 characters";
      }
    ];
  };
}
