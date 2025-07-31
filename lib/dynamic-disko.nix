# Dynamic disko configuration generator based on hardware detection
{ lib, pkgs, ... }:

{
  # Generate disko configuration from facter report
  generateDiskoConfig = { facterReport, poolName ? "rpool", bootSize ? "512M" }:
    let
      # Find the primary disk (prefer NVMe, then SATA)
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
          throw "No suitable disk found for installation";

      # Determine if we should use UEFI or BIOS
      isUEFI = facterReport.boot.efi or false;
      
      # Check available memory for ZFS tuning
      memoryGB = (facterReport.hardware.memory.total or 0) / 1024 / 1024 / 1024;
      zfsArcMax = if memoryGB > 32 then 16 else if memoryGB > 16 then 8 else 4;
    in
    {
      disko.devices = {
        disk = {
          main = {
            type = "disk";
            device = primaryDisk;
            content = {
              type = "gpt";
              partitions = {
                ESP = lib.mkIf isUEFI {
                  size = bootSize;
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
                  type = "EF02"; # BIOS boot
                };
                zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = poolName;
                  };
                };
              };
            };
          };
        };
        zpool = {
          ${poolName} = {
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
    };
}