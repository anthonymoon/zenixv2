{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ({ config, lib, pkgs, ... }: {
          # Disk configuration optimized for NVMe
          disko.devices = {
            disk.nvme = {
              device = lib.mkDefault "/dev/nvme0n1";
              type = "disk";
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
            zpool.rpool = {
              type = "zpool";
              options = {
                ashift = "12";
                autotrim = "on";
              };
              rootFsOptions = {
                compression = "zstd";
                "com.sun:auto-snapshot" = "false";
                atime = "off";
                xattr = "sa";
                acltype = "posixacl";
              };
              datasets = {
                root = {
                  type = "zfs_fs";
                  mountpoint = "/";
                  options = {
                    mountpoint = "legacy";
                    recordsize = "128K";
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
                    recordsize = "128K";
                  };
                };
              };
            };
          };

          # Boot optimized for Ryzen 5600X
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          boot.supportedFilesystems = [ "zfs" ];
          boot.zfs.devNodes = "/dev/disk/by-id";
          boot.kernelPackages = pkgs.linuxPackages_latest;
          boot.kernelParams = [
            "amd_pstate=active"
            "mitigations=off"
            "nowatchdog"
            "quiet"
            "splash"
          ];
          boot.initrd.kernelModules = [ "amdgpu" ];
          boot.kernelModules = [ "kvm-amd" ];

          # Hardware
          hardware.cpu.amd.updateMicrocode = true;
          hardware.enableRedistributableFirmware = true;
          hardware.opengl = {
            enable = true;
            driSupport = true;
            driSupport32Bit = true;
            extraPackages = with pkgs; [
              amdvlk
              rocm-opencl-icd
              rocm-opencl-runtime
            ];
          };

          # Networking
          networking.hostName = "nixos";
          networking.hostId = "8425e349";
          networking.networkmanager.enable = true;

          # User
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
            initialPassword = "nixos";
            openssh.authorizedKeys.keys = [ ];
          };

          # Wayland-only GNOME
          services.xserver = {
            enable = true;
            displayManager.gdm = {
              enable = true;
              wayland = true;
            };
            desktopManager.gnome.enable = true;
            videoDrivers = [ "amdgpu" ];
            excludePackages = [ pkgs.xterm ];
          };
          environment.gnome.excludePackages = with pkgs; [ gnome-tour epiphany ];

          # Force Wayland
          environment.sessionVariables = {
            NIXOS_OZONE_WL = "1";
            MOZ_ENABLE_WAYLAND = "1";
            QT_QPA_PLATFORM = "wayland";
            GDK_BACKEND = "wayland";
          };

          # Packages
          environment.systemPackages = with pkgs; [
            vim
            git
            firefox-wayland
            neofetch
            btop
          ];

          # Services
          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "no";
              PasswordAuthentication = true;
            };
          };
          services.zfs.autoScrub.enable = true;
          services.zfs.trim.enable = true;

          # Performance
          powerManagement.cpuFreqGovernor = "performance";
          services.thermald.enable = false;

          # Nix
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            max-jobs = 12;
            cores = 6;
          };

          system.stateVersion = "24.05";
        })
      ];
    };
  };
}
