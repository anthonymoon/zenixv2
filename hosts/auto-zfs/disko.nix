# Dynamic disko configuration that adapts to detected hardware
{ config, lib, ... }:

let
  # Use facter report if available, otherwise use defaults
  facterReport = config.facter.report or {
    hardware = {
      storage = {
        disks = [{ name = "nvme0n1"; }];
      };
      memory = {
        total = 8 * 1024 * 1024 * 1024; # 8GB default
      };
    };
    boot = {
      efi = true;
    };
  };
  
  # Find the primary disk
  primaryDisk = 
    let
      disks = facterReport.hardware.storage.disks or [];
      nvmeDisks = lib.filter (d: lib.hasPrefix "nvme" d.name) disks;
      sataDisks = lib.filter (d: lib.hasPrefix "sd" d.name) disks;
    in
    if nvmeDisks != [] then
      "/dev/${(lib.head nvmeDisks).name}"
    else if sataDisks != [] then
      "/dev/${(lib.head sataDisks).name}"
    else
      "/dev/nvme0n1"; # fallback
      
  isUEFI = facterReport.boot.efi or true;
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = lib.mkDefault primaryDisk;
        content = {
          type = "gpt";
          partitions = {
            ESP = lib.mkIf isUEFI {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            boot = lib.mkIf (!isUEFI) {
              size = "1M";
              type = "EF02";
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