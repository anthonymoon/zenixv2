# Btrfs single disk configuration with auto-detection (no encryption)
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
      minSizeGB = 32; # Minimum 32GB for a usable system
    });
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

    # Use ZRAM instead of swap file for better performance
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
      memoryMax = 16 * 1024 * 1024 * 1024; # 16GB max
      priority = 5;
    };

    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = config.disko.primaryDisk;
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
                    "defaults"
                    "umask=0077"
                    "iocharset=iso8859-1"
                    "shortname=winnt"
                    "utf8"
                  ];
                };
              };
              root = {
                priority = 2;
                name = "root";
                label = "root";
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f" # Force create
                    "-L"
                    "nixos" # Filesystem label
                  ];
                  subvolumes = {
                    # Root subvolume with optimized mount options
                    "@" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd:1" # Fast compression level
                        "noatime"
                        "nodiratime"
                        "discard=async" # Async TRIM for SSDs
                        "space_cache=v2"
                        "ssd" # Enable SSD optimizations
                        "commit=120" # Longer commit interval for NVMe
                      ];
                    };
                    # Home subvolume
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd:3" # Better compression for user data
                        "noatime"
                        "nodiratime"
                        "discard=async"
                        "space_cache=v2"
                        "ssd"
                      ];
                    };
                    # Nix store subvolume with different optimization
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd:1" # Fast compression for frequent access
                        "noatime"
                        "nodiratime"
                        "discard=async"
                        "space_cache=v2"
                        "ssd"
                        "commit=300" # Longer commits for build performance
                      ];
                    };
                    # Var subvolume for logs and temporary data
                    "@var" = {
                      mountpoint = "/var";
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                        "nodiratime"
                        "discard=async"
                        "space_cache=v2"
                        "ssd"
                      ];
                    };
                    # Tmp subvolume for temporary files
                    "@tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [
                        "compress=no" # No compression for temp files
                        "noatime"
                        "nodiratime"
                        "discard=async"
                        "space_cache=v2"
                        "ssd"
                      ];
                    };
                    # Snapshots subvolume (not mounted by default)
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [
                        "compress=zstd:3"
                        "noatime"
                        "nodiratime"
                        "discard=async"
                        "space_cache=v2"
                        "ssd"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    # Enable Btrfs optimizations
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    # Additional boot configuration for Btrfs
    boot = {
      # Include necessary modules
      initrd.availableKernelModules = [ "btrfs" ];

      # Btrfs-specific kernel parameters
      kernelParams = [
        # Btrfs optimizations
        "rootflags=compress=zstd:1,noatime,ssd,discard=async"
      ];
    };

    # Enable filesystem trim
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };
  };
}
