# ZFS mirror configuration
{ lib
, config
, pkgs
, ...
}:
let
  hostname = config.networking.hostName or "nixos";
in
{
  disko.devices = {
    disk = {
      disk1 = {
        type = "disk";
        device = lib.mkDefault "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };
            zfs = {
              priority = 2;
              name = "zfsroot1";
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
      disk2 = {
        type = "disk";
        device = lib.mkDefault "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP-mirror";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # Not mounted - used for manual ESP sync
              };
            };
            zfs = {
              priority = 2;
              name = "zfsroot2";
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
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
          acltype = "posixacl";
          xattr = "sa";
          relatime = "on";
          canmount = "off";
          mountpoint = "none";
        };
        datasets = {
          # Root dataset
          "local" = {
            type = "zfs_fs";
            options.canmount = "off";
          };
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              canmount = "noauto";
              mountpoint = "legacy";
            };
            postCreateHook = "zfs snapshot rpool/local/root@blank";
          };
          # Home dataset
          "local/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              canmount = "noauto";
              mountpoint = "legacy";
            };
          };
          # Nix store dataset
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              atime = "off";
              canmount = "noauto";
              mountpoint = "legacy";
            };
          };
          # Var dataset
          "local/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options = {
              canmount = "noauto";
              mountpoint = "legacy";
            };
          };
          # Reserved space dataset (not mounted)
          "reserved" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              reservation = "5G";
            };
          };
        };
      };
    };
  };

  # ZFS-specific configuration
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partlabel";
  networking.hostId = lib.mkDefault "$(head -c 8 /etc/machine-id)";

  # Systemd service to sync ESP partitions
  systemd.services.esp-mirror-sync = {
    description = "Sync ESP to mirror disk";
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.rsync}/bin/rsync -a --delete /boot/ /mnt/esp-mirror/";
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p /mnt/esp-mirror"
        "${pkgs.util-linux}/bin/mount /dev/disk/by-partlabel/ESP-mirror /mnt/esp-mirror"
      ];
      ExecStartPost = "${pkgs.util-linux}/bin/umount /mnt/esp-mirror";
    };
  };
  systemd.timers.esp-mirror-sync = {
    description = "Sync ESP to mirror disk daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
