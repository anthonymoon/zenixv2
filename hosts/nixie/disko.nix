# Disko configuration for nixie with ZFS
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
                # Use a label for the ESP partition
                extraArgs = [ "-n" "ESP" ];
              };
            };
            zfs = {
              priority = 2;
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
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
          acltype = "posixacl";
          atime = "off";
          xattr = "sa";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
              recordsize = "128k";
            };
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              mountpoint = "legacy";
              recordsize = "128k";
              dedup = "off"; # Disabled to save 3-5GB RAM
            };
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              atime = "off";
              sync = "disabled";
              dedup = "off"; # Disabled to save 3-5GB RAM
              redundant_metadata = "most";
            };
          };
          "var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options = {
              mountpoint = "legacy";
              recordsize = "128k";
            };
          };
          "var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
            options = {
              mountpoint = "legacy";
              recordsize = "16k";
            };
          };
          "var/lib/docker" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/docker";
            options = {
              mountpoint = "legacy";
              recordsize = "1M";
              dedup = "off";
            };
          };
          "var/log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options = {
              mountpoint = "legacy";
              recordsize = "128k";
              logbias = "throughput";
              dedup = "off";
            };
          };
          "var/lib/libvirt" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/libvirt";
            options = {
              mountpoint = "legacy";
              recordsize = "1M";
              compression = "off";
              dedup = "off";
            };
          };
          "tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options = {
              mountpoint = "legacy";
              sync = "disabled";
              compression = "lz4";
              dedup = "off";
            };
          };
        };
      };
    };
  };
}
