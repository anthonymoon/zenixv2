# Pure Nix installer generator
{ lib
, writeText
, runCommand
}:

facterReport:

let
  # Parse facter report
  report = facterReport;
    
  # Extract hardware info
  disks = report.hardware.storage.disks or [];
  nvmeDisks = lib.filter (d: lib.hasPrefix "nvme" d.name) disks;
  sataDisks = lib.filter (d: lib.hasPrefix "sd" d.name) disks;
  
  primaryDisk = 
    if nvmeDisks != [] then
      "/dev/${(lib.head nvmeDisks).name}"
    else if sataDisks != [] then
      "/dev/${(lib.head sataDisks).name}"
    else
      throw "No suitable disk found";
      
  isUEFI = report.boot.efi or true;
  
  # Generate flake
  installerFlake = writeText "flake.nix" ''
    {
      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        disko.url = "github:nix-community/disko";
        disko.inputs.nixpkgs.follows = "nixpkgs";
        zenixv2.url = "github:anthonymoon/zenixv2";
      };
      
      outputs = { self, nixpkgs, disko, zenixv2 }:
        let
          system = "x86_64-linux";
        in
        {
          nixosConfigurations.target = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              disko.nixosModules.disko
              {
                # Disko configuration
                disko.devices = {
                  disk.main = {
                    type = "disk";
                    device = "${primaryDisk}";
                    content = {
                      type = "gpt";
                      partitions = {
                        ${if isUEFI then ''
                        ESP = {
                          size = "512M";
                          type = "EF00";
                          content = {
                            type = "filesystem";
                            format = "vfat";
                            mountpoint = "/boot";
                          };
                        };'' else ''
                        boot = {
                          size = "1M";
                          type = "EF02";
                        };''}
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
                      compression = "lz4";
                      atime = "off";
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
                
                # Import base config from zenixv2
                imports = [
                  zenixv2.nixosModules.common
                  zenixv2.nixosModules.zfs
                ];
                
                # Hardware-specific config
                boot.loader.systemd-boot.enable = ${if isUEFI then "true" else "false"};
                boot.loader.grub.enable = ${if isUEFI then "false" else "true"};
                ${if !isUEFI then ''boot.loader.grub.device = "${primaryDisk}";'' else ""}
                
                networking.hostId = builtins.substring 0 8 (builtins.hashString "sha256" "${primaryDisk}");
                networking.hostName = "nixos";
                
                system.stateVersion = "24.05";
              }
            ];
          };
        };
    }
  '';

in
runCommand "installer-${builtins.substring 0 8 (builtins.hashString "sha256" primaryDisk)}" {
  passthru = {
    inherit primaryDisk isUEFI;
    flake = installerFlake;
  };
} ''
  mkdir -p $out
  cp ${installerFlake} $out/flake.nix
  
  # Create disko configuration separately
  cat > $out/disko.nix << 'DISKO'
  {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = "${primaryDisk}";
        content = {
          type = "gpt";
          partitions = {
            ${if isUEFI then ''
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };'' else ''
            boot = {
              size = "1M";
              type = "EF02";
            };''}
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
          compression = "lz4";
          atime = "off";
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
  }
  DISKO
  
  # Create metadata
  cat > $out/metadata.json << JSON
  {
    "primaryDisk": "${primaryDisk}",
    "isUEFI": ${if isUEFI then "true" else "false"},
    "hostId": "${builtins.substring 0 8 (builtins.hashString "sha256" primaryDisk)}"
  }
  JSON
''