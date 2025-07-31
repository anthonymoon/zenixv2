{ config, lib, ... }:

{
  # Disko configuration for physical hardware
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = lib.mkDefault "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };

    zpool = {
      zroot = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "off";
          compression = "lz4";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          mountpoint = "none";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = ''
              zfs set com.sun:auto-snapshot=false zroot/root
            '';
          };

          "nix" = {
            type = "zfs_fs";
            options = {
              atime = "off";
              mountpoint = "legacy";
            };
            mountpoint = "/nix";
          };

          "home" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/home";
            postCreateHook = ''
              zfs set com.sun:auto-snapshot=true zroot/home
            '';
          };

          "var" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/var";
          };

          "tmp" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              sync = "disabled";
            };
            mountpoint = "/tmp";
            postCreateHook = ''
              zfs set com.sun:auto-snapshot=false zroot/tmp
            '';
          };
        };
      };
    };
  };

  # Hardware-specific settings
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
