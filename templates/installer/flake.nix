{
  description = "NixOS installer configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zenixv2.url = "github:anthonymoon/zenixv2";
  };

  outputs = { self, nixpkgs, disko, zenixv2 }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Fixed configuration - UEFI only, AMD only, nvme0n1 only
      primaryDisk = "/dev/nvme0n1";
      isUEFI = true;
      
      # Generate disko configuration based on detected hardware
      diskoConfig = {
        disko.devices = {
          disk = {
            main = {
              type = "disk";
              device = primaryDisk;
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
                  options.mountpoint = "legacy";
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
                  options.mountpoint = "legacy";
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
    in
    {
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          diskoConfig
          ({ config, lib, pkgs, ... }: {
            imports = [ 
              # Import base configuration from zenixv2
              "${zenixv2}/modules/common"
              "${zenixv2}/modules/storage/zfs"
            ];
            
            # Fixed configuration - UEFI and AMD only
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            
            # Set host ID for ZFS
            networking.hostId = builtins.substring 0 8 (builtins.hashString "sha256" "installer");
            networking.hostName = "nixos";
            
            # AMD CPU modules
            boot.kernelModules = [ "kvm-amd" ];
            
            # Basic packages
            environment.systemPackages = with pkgs; [
              vim
              git
              htop
            ];
            
            # User
            users.users.admin = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              initialPassword = "changeme";
            };
            
            system.stateVersion = "24.05";
          })
        ];
      };
      
      # Fixed hardware info
      hardwareInfo = {
        primaryDisk = "/dev/nvme0n1";
        isUEFI = true;
        cpuType = "AMD";
      };
      
      # Installation command using disko-install
      apps.${system}.default = {
        type = "app";
        program = let
          installScript = pkgs.writeShellScript "install" ''
            #!/bin/sh
            set -e
            
            echo "NixOS Hardware-Specific Installer"
            echo "================================="
            echo ""
            echo "Fixed configuration:"
            echo "  Primary disk: /dev/nvme0n1"
            echo "  Boot mode: UEFI"
            echo "  CPU: AMD (kvm-amd module)"
            echo ""
            echo "This will DESTROY all data on /dev/nvme0n1!"
            echo "Press Ctrl+C to abort, or wait 5 seconds to continue..."
            sleep 5
            
            echo ""
            echo "Starting installation using disko-install..."
            exec ${disko.packages.${system}.disko-install}/bin/disko-install \
              --flake ".#installer" \
              --disk main "/dev/nvme0n1" \
              --option substituters "https://cache.nixos.org https://nix-community.cachix.org" \
              --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          '';
        in toString installScript;
      };
    };
}