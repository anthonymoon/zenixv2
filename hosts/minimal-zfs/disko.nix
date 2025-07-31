# Disko configuration for minimal-zfs host
{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = lib.mkDefault "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
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
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "lz4";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          mountpoint = "none";
        };
        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
            };
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              atime = "off";
            };
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              mountpoint = "legacy";
            };
          };
          var = {
            type = "zfs_fs";
            mountpoint = "/var";
            options = {
              mountpoint = "legacy";
              atime = "off";
            };
          };
        };
      };
    };
  };
}