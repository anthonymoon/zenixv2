# Common disko configuration with environment detection
{ lib, ... }:
let
  # Simple VM detection for disko configuration
  # This runs at evaluation time, so we use a simpler approach
  isVMEnv = builtins.getEnv "NIXOS_VM" == "1" ||
    builtins.pathExists "/dev/vda" ||
    builtins.pathExists "/dev/vdb";

  # Docker volume size based on environment
  dockerSize = if isVMEnv then "1G" else "50G";

  # ESP size based on environment  
  espSize = if isVMEnv then "512M" else "2G";

  # ZFS reservation based on environment
  reservationSize = if isVMEnv then "512M" else "1G";

  # Device path - will be overridden by installers
  devicePath = if isVMEnv then "/dev/vda" else "/dev/disk/by-id/@DISK_ID@";
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = devicePath;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = espSize;
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
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
        # ZFS pool options optimized for both environments
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "lz4";
          dnodesize = "auto";
          normalization = "formD";
          xattr = "sa";
        };
        mountpoint = "/";
        datasets = {
          # Docker volume with environment-appropriate size
          docker = {
            type = "zfs_volume";
            size = dockerSize;
            options = { };
          };

          # Main nixos dataset
          "nixos" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          # Ephemeral root dataset
          "nixos/empty" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            postCreateHook = ''
              zfs snapshot rpool/nixos/empty@start
            '';
          };

          # Nix store dataset with optimizations
          "nixos/nix" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              atime = "off";
            };
          };

          # Home directory dataset
          "nixos/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
          };

          # Persistent data dataset
          "nixos/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
          };

          # Configuration dataset
          "nixos/config" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              atime = "off";
            };
          };

          # Variable data parent dataset
          "nixos/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          # Variable library data
          "nixos/var/lib" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
          };

          # Variable log data
          "nixos/var/log" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
          };

          # Reserved space for ZFS operations
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              refreservation = reservationSize;
            };
          };
        };
      };
    };
  };
}
