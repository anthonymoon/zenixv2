# NixOS ZFS Root Installation Configuration
# Based on best practices from 2025 community standards
# Features: Impermanence, Disko declarative partitioning, ZFS without encryption

{ config, lib, pkgs, ... }:

{
  # Disko configuration for declarative disk partitioning
  disko.devices = {
    disk = {
      # Main system disk - adjust device path as needed
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1"; # Change to your disk
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition for UEFI boot
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "umask=0077"
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            # ZFS partition taking remaining space
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

    # ZFS pool configuration
    zpool = {
      rpool = {
        type = "zpool";
        # mode = "mirror"; # Uncomment for RAID1, add second disk

        # Pool-wide options for performance and features
        options = {
          ashift = "12"; # 4K sectors (modern SSDs/HDDs)
          autotrim = "on"; # Enable TRIM for SSDs
          cachefile = "none"; # Don't cache pool config
        };

        # Root filesystem options (inherited by children)
        rootFsOptions = {
          # Performance optimizations
          compression = "zstd"; # Better than lz4 for most workloads
          acltype = "posixacl"; # Required for systemd
          xattr = "sa"; # Store xattrs in inodes (performance)
          dnodesize = "auto"; # Dynamic dnode sizing
          normalization = "formD"; # UTF-8 normalization
          relatime = "on"; # Reduce write amplification

          # Disable features we don't need
          atime = "off"; # Don't track access times
          "com.sun:auto-snapshot" = "false";

          # Root dataset should not be mounted
          canmount = "off";
          mountpoint = "none";
        };

        # Create initial blank snapshot for impermanence
        postCreateHook = ''
          # Create local and safe parent datasets
          zfs create -o canmount=off -o mountpoint=none rpool/local
          zfs create -o canmount=off -o mountpoint=none rpool/safe
          
          # Snapshot the empty local dataset for rollback
          zfs snapshot rpool/local@blank
        '';

        # Dataset hierarchy following impermanence pattern
        datasets = {
          # Ephemeral root - rolled back on every boot
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
            };
            postCreateHook = ''
              # Create snapshot of empty root
              zfs snapshot rpool/local/root@blank
            '';
          };

          # Nix store - preserved across boots
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              atime = "off";
              # Higher compression for store
              compression = "zstd-3";
            };
          };

          # Persistent system state
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options = {
              mountpoint = "legacy";
              # Enable snapshots for persistent data
              "com.sun:auto-snapshot" = "true";
            };
          };

          # User home directories
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              mountpoint = "legacy";
              # User data might benefit from snapshots
              "com.sun:auto-snapshot" = "true";
            };
          };

          # Separate dataset for logs (optional)
          "local/var-log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options = {
              mountpoint = "legacy";
              # Logs compress well
              compression = "zstd-9";
            };
          };

          # Reserved space to prevent pool exhaustion
          "reserved" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              reservation = "5G";
              quota = "5G";
            };
          };
        };
      };
    };
  };

  # Boot configuration
  boot = {
    # Use systemd in initrd for better ZFS integration
    initrd.systemd.enable = true;

    # Latest kernel for best ZFS compatibility
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    # Enable ZFS support
    supportedFilesystems = [ "zfs" ];
    zfs = {

      # Enable ZFS Event Daemon for better monitoring
      enableUnstable = false; # Use stable ZFS
      forceImportRoot = false;
      allowHibernation = false; # Not compatible with ZFS
    };

    # Kernel parameters for ZFS
    kernelParams = [
      "zfs.zfs_arc_max=8589934592" # 8GB ARC max, adjust based on RAM
      "elevator=none" # ZFS has its own I/O scheduler
    ];

    # Use systemd-boot for UEFI
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30; # Keep 30 generations
        # Safeguard against full /boot
        graceful = true;
      };
      efi.canTouchEfiVariables = true;

      # Timeout for boot menu
      timeout = 3;
    };
  };

  # Impermanence configuration
  boot.initrd.systemd.services.rollback-root = {
    description = "Rollback root filesystem to blank state";
    wantedBy = [ "initrd.target" ];
    after = [ "zfs-import-rpool.service" ];
    before = [ "sysroot.mount" ];
    path = with pkgs; [ zfs ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      zfs rollback -r rpool/local/root@blank
    '';
  };

  # Filesystem configuration
  fileSystems = {
    # Mark /persist as needed for boot
    "/persist" = {
      neededForBoot = true;
    };
  };

  # Networking configuration for ZFS
  networking = {
    # Generate hostId from hostname (required for ZFS)
    hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);

    # Set your hostname
    hostName = "nixos-zfs"; # Change this
  };

  # Services for ZFS
  services = {
    # ZFS automatic snapshots (for safe datasets)
    zfs = {
      autoSnapshot = {
        enable = true;
        frequent = 4; # Keep 4 15-minute snapshots
        hourly = 24; # Keep 24 hourly snapshots
        daily = 7; # Keep 7 daily snapshots
        weekly = 4; # Keep 4 weekly snapshots
        monthly = 12; # Keep 12 monthly snapshots
      };

      # ZFS scrubbing for data integrity
      autoScrub = {
        enable = true;
        interval = "weekly";
      };

      # TRIM support for SSDs
      trim = {
        enable = true;
        interval = "weekly";
      };
    };

    # ZFS Event Daemon for monitoring
    zfs.zed = {
      enableMail = false; # Enable if you want email alerts
      settings = {
        ZED_DEBUG_LOG = "/tmp/zed.debug.log";

        # Pushbullet example (optional)
        # ZED_PUSHBULLET_ACCESS_TOKEN = "your-token";
        # ZED_PUSHBULLET_CHANNEL_TAG = "nixos-zfs";
      };
    };
  };

  # Impermanence module configuration
  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/etc/nixos" # Keep system configuration
      "/var/lib" # System state
      "/var/db/sudo" # Sudo state
      "/etc/NetworkManager/system-connections" # Network configs
      { directory = "/var/lib/systemd/coredump"; user = "root"; group = "root"; mode = "0755"; }
    ];
    files = [
      "/etc/machine-id"
      { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "0755"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key.pub"; parentDirectory = { mode = "0755"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "0755"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key.pub"; parentDirectory = { mode = "0755"; }; }
    ];
    users.youruser = {
      # Change 'youruser' to actual username
      directories = [
        "Downloads"
        "Documents"
        "Pictures"
        "Videos"
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".config"; mode = "0755"; }
        { directory = ".local/share"; mode = "0755"; }
      ];
      files = [
        ".bashrc"
        ".gitconfig"
      ];
    };
  };

  # System packages for ZFS management
  environment.systemPackages = with pkgs; [
    # ZFS management tools
    zfs
    zfs-autobackup # Backup tool for ZFS

    # Monitoring tools
    zfs-prune-snapshots
    sanoid # Policy-driven snapshot management
    syncoid # ZFS snapshot replication

    # System tools
    gptfdisk # For partitioning
    cryptsetup # If using LUKS instead

    # Performance monitoring
    iotop
    htop
    nvme-cli # For NVMe drives
  ];

  # ZFS kernel module parameters
  boot.extraModprobeConfig = ''
    # Tune ZFS module parameters
    options zfs zfs_arc_max=8589934592
    options zfs zfs_arc_min=134217728
    options zfs zfs_prefetch_disable=0
    options zfs zfs_txg_timeout=5
    options zfs l2arc_noprefetch=0
    options zfs l2arc_write_max=536870912
    options zfs l2arc_write_boost=1073741824
  '';

  # Monitoring and alerts (optional)
  services.prometheus.exporters.zfs = {
    enable = true; # Enable if using Prometheus
  };
}
