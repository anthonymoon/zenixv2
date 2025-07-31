# Btrfs single disk with LUKS encryption and TPM2 auto-unlock
{ config
, lib
, pkgs
, inputs
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
      minSizeGB = 64; # Minimum 64GB for encrypted system
    });
in
{
  # Import lanzaboote for secure boot when encryption is used
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # Add configuration options
  options.disko = {
    primaryDisk = lib.mkOption {
      type = lib.types.str;
      description = "Primary disk to use for installation (auto-detected if not specified)";
    };

    enableTPM2 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TPM2 auto-unlock for LUKS";
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
              luks = {
                priority = 2;
                name = "cryptroot";
                label = "cryptroot";
                size = "100%";
                content = {
                  type = "luks";
                  name = "root";
                  # LUKS2 with optimized settings
                  settings = {
                    # Enable discards for SSD TRIM
                    allowDiscards = true;
                    # Use Argon2id with reasonable parameters for SSD systems
                    pbkdfForceIterations = 4;
                    # Additional crypttab options for TPM2
                    crypttabExtraOpts = lib.optionals config.disko.enableTPM2 [
                      "tpm2-device=auto"
                      "tpm2-pcrs=0,1,2,3,7"
                      "timeout=10"
                    ];
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = [
                      "-f" # Force create
                      "-L"
                      "nixos-encrypted" # Filesystem label
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
    };

    # LUKS configuration
    boot.initrd.luks.devices."root" = {
      device = "/dev/disk/by-partlabel/cryptroot";
      allowDiscards = true;

      # TPM2 configuration
      crypttabExtraOpts = lib.optionals config.disko.enableTPM2 [
        "tpm2-device=auto"
        "tpm2-pcrs=0,1,2,3,7"
        "timeout=10"
      ];
    };

    # Enable TPM2 support
    security.tpm2 = lib.mkIf config.disko.enableTPM2 {
      enable = true;
      abrmd.enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };

    # Configure lanzaboote for secure boot with encryption
    boot.lanzaboote = lib.mkIf config.disko.enableTPM2 {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    # Enable Btrfs optimizations
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    # Additional boot configuration for encrypted Btrfs
    boot = {
      # Include necessary modules for encryption and Btrfs
      initrd.availableKernelModules = [
        "btrfs"
        "dm_crypt"
        "dm_mod"
        "aesni_intel"
        "cryptd"
      ];

      # Add TPM modules
      initrd.kernelModules = lib.optionals config.disko.enableTPM2 [
        "tpm"
        "tpm_tis"
        "tpm_crb"
      ];

      # Optimized kernel parameters for encrypted Btrfs
      kernelParams = [
        # Btrfs optimizations
        "rootflags=compress=zstd:1,noatime,ssd,discard=async"
        # Crypto optimizations
        "cryptomgr.notests" # Skip crypto self-tests for faster boot
      ];

      # Improve boot performance
      loader = {
        timeout = 3;
        systemd-boot = lib.mkIf (!config.boot.lanzaboote.enable) {
          enable = true;
          configurationLimit = 10;
          editor = false; # Disable editor for security
        };
      };
    };

    # Enable filesystem trim
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };

    # Systemd service for TPM2 enrollment (run after installation)
    systemd.services.enroll-tpm2-luks = lib.mkIf config.disko.enableTPM2 {
      description = "Enroll TPM2 for LUKS auto-unlock";
      wantedBy = [ "multi-user.target" ];
      after = [ "tpm2-abrmd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "enroll-tpm2" ''
          # Check if TPM2 is already enrolled
          if ${pkgs.systemd}/bin/systemd-cryptenroll /dev/disk/by-partlabel/cryptroot --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0,1,2,3,7 2>/dev/null; then
            echo "TPM2 enrollment successful"
          else
            echo "TPM2 enrollment failed or already enrolled"
          fi
        '';
      };
      # Only run once after successful boot
      unitConfig.ConditionPathExists = "!/var/lib/systemd/tpm2-enrolled";
      postStart = "touch /var/lib/systemd/tpm2-enrolled";
    };
  };
}
