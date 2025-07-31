{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot configuration for NixOS 25.11pre with ZFS
  boot = {
    # Use ZFS-compatible kernel - let ZFS determine the best kernel version
    # This ensures ZFS module compatibility
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    
    # Alternative: If you need kernel 6.14.10 specifically (check ZFS compatibility first)
    # kernelPackages = pkgs.linuxPackages_6_14 or config.boot.zfs.package.latestCompatibleLinuxPackages;

    # Boot loader configuration
    loader = {
      # For EFI systems
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
      
      # For legacy BIOS systems, use GRUB instead:
      # grub = {
      #   enable = true;
      #   device = "nodev";
      #   efiSupport = true;
      #   zfsSupport = true;
      # };
    };

    # Kernel parameters
    kernelParams = [
      # ZFS tuning
      "zfs.zfs_arc_max=8589934592" # 8GB ARC max (adjust based on your RAM)
      
      # AMD CPU optimization (if applicable)
      "amd_pstate=active"
      
      # Intel CPU (if applicable)
      # "intel_pstate=active"
      
      # Misc optimizations
      "transparent_hugepage=madvise"
    ];

    # Required kernel modules
    kernelModules = [ "kvm-amd" ]; # or "kvm-intel" for Intel
    
    # ZFS configuration
    supportedFilesystems = [ "zfs" ];
    zfs = {
      # Force import if needed during boot
      forceImportRoot = false;
      forceImportAll = false;
      
      # Request encryption credentials
      requestEncryptionCredentials = true;
      
      # Enable ZFS Event Daemon
      package = pkgs.zfs;  # or pkgs.zfs_unstable if needed
    };

    # Initial RAM disk
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      
      # For ZFS root
      supportedFilesystems = [ "zfs" ];
      
      # Network support in initrd (for remote unlock if using encryption)
      # network.enable = true;
    };
  };

  # Networking
  networking = {
    hostName = "nixos"; # Define your hostname
    hostId = "deadbeef"; # Required for ZFS - generate with: head -c 8 /etc/machine-id
    
    networkmanager.enable = true;
    
    # Firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH
      # allowedUDPPorts = [ ];
    };
  };

  # Time zone
  time.timeZone = "America/New_York"; # Adjust to your timezone

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # ZFS services
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
    # ZED (ZFS Event Daemon)
    zed = {
      enable = true;
      settings = {
        ZED_DEBUG_LOG = "/tmp/zed.debug.log";
        ZED_EMAIL_ADDR = [ "root" ];
        ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
        ZED_EMAIL_OPTS = "-a default";
        ZED_NOTIFY_VERBOSE = true;
      };
    };
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    wget
    curl
    git
    htop
    tmux
    
    # ZFS utilities
    zfs
    zfstools
    
    # System monitoring
    lsof
    iotop
    nmon
    
    # Network tools
    iproute2
    iputils
    dnsutils
  ];

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes"; # Change to "no" after initial setup
      PasswordAuthentication = true; # Disable after setting up keys
    };
  };

  # User configuration
  users.users.root = {
    # Set initial root password - CHANGE THIS!
    initialPassword = "nixos";
  };

  # Create a regular user
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos"; # CHANGE THIS!
    # openssh.authorizedKeys.keys = [ "ssh-rsa ..." ];
  };

  # Enable sudo
  security.sudo.wheelNeedsPassword = true;

  # System state version - using 25.11
  system.stateVersion = "25.11";

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Hardware-specific optimizations
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  # Additional performance tuning
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
