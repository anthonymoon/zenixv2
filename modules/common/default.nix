{
  config,
  lib,
  pkgs,
  ...
}: {
  # Base system configuration
  config = {
    # Nix configuration
    nix = {
      settings = {
        # Enable flakes
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        # Optimizations
        auto-optimise-store = true;
        max-jobs = "auto";
        cores = 0; # Use all cores

        # Security
        allowed-users = ["@wheel"];
        trusted-users = [
          "root"
          "@wheel"
        ];

        # Better errors
        show-trace = true;
      };

      # Garbage collection
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      # Store optimization
      optimise = {
        automatic = true;
        dates = ["weekly"];
      };
    };

    # Boot configuration
    boot = {
      # Clean /tmp on boot
      tmp.cleanOnBoot = lib.mkDefault true;

      # Kernel modules for common hardware
      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];

      # Common kernel modules
      kernelModules = lib.mkDefault [
        "kvm-amd"
        "kvm-intel"
      ];
    };

    # Networking
    networking = {
      # Enable NetworkManager by default
      networkmanager.enable = lib.mkDefault true;

      # Firewall
      firewall = {
        enable = lib.mkDefault true;
        allowPing = lib.mkDefault true;
      };

      # Use systemd-resolved
      nameservers = lib.mkDefault [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    # Time and locale
    # Note: These are set by individual hosts
    # time.timeZone = lib.mkDefault "UTC";
    # i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

    # Console
    console = {
      font = lib.mkDefault "Lat2-Terminus16";
      keyMap = lib.mkDefault "us";
    };

    # Basic system packages
    environment.systemPackages = with pkgs; [
      # Core utilities
      coreutils
      util-linux
      procps
      psmisc

      # Editors
      vim
      nano

      # Network tools
      iproute2
      iputils
      nettools
      wget
      curl

      # System tools
      htop
      btop
      iotop
      lsof

      # File management
      tree
      ncdu
      fd
      ripgrep

      # Development basics
      git
      tmux

      # Hardware tools
      pciutils
      usbutils
      lshw
    ];

    # Enable basic services
    services = {
      # SSH daemon
      openssh = {
        enable = lib.mkDefault true;
        settings = {
          PermitRootLogin = lib.mkDefault "no";
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
        };
      };

      # Time sync
      timesyncd.enable = lib.mkDefault true;

      # Firmware updates
      fwupd.enable = lib.mkDefault true;
    };

    # Security basics
    security = {
      # Enable sudo
      sudo = {
        enable = true;
        wheelNeedsPassword = lib.mkDefault true;
      };

      # Polkit
      polkit.enable = true;
    };

    # System state version
    system.stateVersion = lib.mkDefault "24.11";
  };
}
