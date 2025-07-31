{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  # Basic hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  # Networking
  networking = {
    hostName = "nixies";
    networkmanager.enable = true;
    # Required for ZFS - must be exactly 8 hexadecimal characters
    hostId = "8425e349";  # Generated randomly, change if needed
  };

  # Boot configuration with ZFS support
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    
    # ZFS support
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;  # We're not using encryption
      devNodes = "/dev/disk/by-id";  # Use stable disk identifiers
    };
    
    # Use default kernel (ZFS is now compatible with latest kernel)
    # If you need a specific kernel version for ZFS compatibility:
    # kernelPackages = pkgs.linuxPackages_6_6;
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    # ZFS tools
    zfs
    zfs-autobackup
  ];

  # Enable basic services
  services = {
    openssh.enable = true;
    
    # ZFS services
    zfs = {
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
      trim = {
        enable = true;
        interval = "weekly";
      };
    };
  };

  # System version
  system.stateVersion = "25.05";
}
