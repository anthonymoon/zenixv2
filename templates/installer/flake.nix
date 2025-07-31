{
  description = "NixOS installer configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter = {
      url = "github:nix-community/nixos-facter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zenixv2.url = "github:anthonymoon/zenixv2";
  };

  outputs = { self, nixpkgs, disko, nixos-facter, zenixv2 }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Generate hardware report at evaluation time
      facterReport = builtins.fromJSON (builtins.readFile ./facter.json);
      
      # Extract hardware information
      primaryDisk = 
        let
          disks = facterReport.hardware.storage.disks or [];
          nvmeDisks = builtins.filter (d: nixpkgs.lib.hasPrefix "nvme" d.name) disks;
          sataDisks = builtins.filter (d: nixpkgs.lib.hasPrefix "sd" d.name) disks;
        in
        if nvmeDisks != [] then
          "/dev/${(builtins.head nvmeDisks).name}"
        else if sataDisks != [] then
          "/dev/${(builtins.head sataDisks).name}"
        else
          throw "No suitable disk found in hardware report";
          
      isUEFI = facterReport.boot.efi or true;
      
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
                  ESP = nixpkgs.lib.mkIf isUEFI {
                    size = "512M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "defaults" ];
                    };
                  };
                  boot = nixpkgs.lib.mkIf (!isUEFI) {
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
        specialArgs = { inherit facterReport; };
        modules = [
          disko.nixosModules.disko
          diskoConfig
          ({ config, lib, pkgs, ... }: {
            imports = [ 
              # Import base configuration from zenixv2
              "${zenixv2}/modules/common"
              "${zenixv2}/modules/storage/zfs"
            ];
            
            # Hardware-specific configuration based on facter
            boot.loader.systemd-boot.enable = isUEFI;
            boot.loader.efi.canTouchEfiVariables = isUEFI;
            boot.loader.grub.enable = !isUEFI;
            boot.loader.grub.device = if isUEFI then "nodev" else primaryDisk;
            
            # Set host ID for ZFS
            networking.hostId = builtins.substring 0 8 (builtins.hashString "sha256" "installer");
            networking.hostName = "nixos";
            
            # CPU-specific modules
            boot.kernelModules = lib.optional 
              (lib.hasInfix "Intel" (facterReport.hardware.cpu.vendor or ""))
              "kvm-intel" ++
              lib.optional
              (lib.hasInfix "AMD" (facterReport.hardware.cpu.vendor or ""))
              "kvm-amd";
            
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
      
      # Output the detected hardware info
      hardwareInfo = {
        inherit primaryDisk isUEFI;
        report = facterReport;
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
            echo "Detected configuration:"
            echo "  Primary disk: ${primaryDisk}"
            echo "  Boot mode: ${if isUEFI then "UEFI" else "BIOS"}"
            echo "  CPU: ${facterReport.hardware.cpu.vendor or "Unknown"} ${facterReport.hardware.cpu.model or ""}"
            echo "  Memory: ${toString ((facterReport.hardware.memory.total or 0) / 1073741824)}GB"
            echo ""
            echo "This will DESTROY all data on ${primaryDisk}!"
            echo "Press Ctrl+C to abort, or wait 5 seconds to continue..."
            sleep 5
            
            echo ""
            echo "Starting installation using disko-install..."
            exec ${disko.packages.${system}.disko-install}/bin/disko-install \
              --flake ".#installer" \
              --disk main "${primaryDisk}" \
              --option substituters "https://cache.nixos.org https://nix-community.cachix.org" \
              --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          '';
        in toString installScript;
      };
    };
}