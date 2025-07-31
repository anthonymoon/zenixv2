# Common base module shared across all templates
# Standardized for AMD workstations with ZFS root
{ config, lib, pkgs, ... }:

{
  # System version
  system.stateVersion = lib.mkDefault "24.11";

  # AMD Workstation specific configuration
  # Only support AMD CPUs and GPUs
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    
    # AMD GPU support (AMDGPU only)
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };
    
    # Bluetooth support
    bluetooth.enable = lib.mkDefault true;
    
    # Disable Intel/NVIDIA support
    cpu.intel.updateMicrocode = false;
  };

  # Boot configuration for workstations
  boot = {
    # ZFS root support with systemd-boot
    supportedFilesystems = [ "zfs" ];
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    
    # Kernel modules from your lsmod output
    kernelModules = [
      "kvm-amd"       # AMD virtualization
      "amdgpu"        # AMD GPU driver
      "crypto_simd"   # Crypto acceleration
      "bluetooth"     # Bluetooth support
      "iwlwifi"       # WiFi
      "snd_hda_intel" # Audio
      "zfs"           # ZFS filesystem
      "fuse"          # FUSE support
    ];
    
    initrd.availableKernelModules = [
      "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sdhci_pci"
      "uas" "usbhid" "hid_generic"
    ];
    
    # AMD specific kernel parameters
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt" 
      "amdgpu.si_support=1"
      "amdgpu.cik_support=1"
      "radeon.si_support=0"
      "radeon.cik_support=0"
    ];
    
    # Blacklist problematic modules
    blacklistedKernelModules = [ 
      "nouveau" "radeon" # Only use amdgpu
      "intel_agp" "i915" # No Intel GPU support
    ];
  };

  # Basic system settings
  console = {
    keyMap = lib.mkDefault "us";
    useXkbConfig = lib.mkDefault true;
  };

  # Timezone and localization
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = lib.mkDefault true;
      trusted-users = [ "root" "@wheel" ];
    };
    
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 14d";
    };
  };

  # Basic security settings
  security = {
    sudo.wheelNeedsPassword = lib.mkDefault true;
    polkit.enable = lib.mkDefault true;
  };

  # Basic SSH configuration
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = lib.mkDefault "prohibit-password";
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = lib.mkDefault false;
    };
  };

  # Essential packages
  environment.systemPackages = with pkgs; [
    # System tools
    curl
    wget
    git
    vim
    htop
    tree
    
    # File management
    unzip
    zip
    rsync
    
    # Network tools
    networkmanager
  ];

  # Workstation networking (NetworkManager handles DHCP)
  networking = {
    networkmanager.enable = lib.mkDefault true;
    firewall = {
      enable = lib.mkDefault true;
      allowedTCPPorts = lib.mkDefault [ 22 ]; # SSH
    };
    
    # ZFS requires a unique host ID (8 hex characters)
    hostId = lib.mkDefault "deadbeef"; # Override this with actual value
    
    # Enable WiFi through NetworkManager
    wireless.enable = false; # Use NetworkManager instead
  };

  # Workstation services
  services = {
    # Audio with PipeWire (workstation standard)
    pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      jack.enable = lib.mkDefault true;
    };
    
    # Bluetooth
    blueman.enable = lib.mkDefault true;
    
    # Printing for workstations
    printing.enable = lib.mkDefault true;
    avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = lib.mkDefault true;
      openFirewall = lib.mkDefault true;
    };
    
    # Power management
    power-profiles-daemon.enable = lib.mkDefault true;
    upower.enable = lib.mkDefault true;
    
    # Hardware monitoring
    smartd.enable = lib.mkDefault true;
    fstrim.enable = lib.mkDefault true; # SSD optimization
  };

  # Basic user template
  users = {
    mutableUsers = lib.mkDefault true;
    users.root = {
      hashedPassword = lib.mkDefault null;
      openssh.authorizedKeys.keys = lib.mkDefault [];
    };
  };

  # Template system integration (metadata stored in system environment)
  environment.etc."nixos-templates/version".text = "1.0.0";
  
  # Automatic System Upgrades
  # Safe unattended updates thanks to NixOS declarative nature
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    dates = lib.mkDefault "09:00";  # Daily at 9:00 AM
    randomizedDelaySec = lib.mkDefault (45 * 60);  # Random delay up to 45 minutes
    allowReboot = lib.mkDefault false;  # Don't auto-reboot (let user decide)
    flake = lib.mkDefault "github:user/nixos-templates#${config.networking.hostName}";  # Update from flake
    flags = lib.mkDefault [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
  };

  # Dynamic Library Compatibility (nix-ld)
  # Allows running dynamically linked executables from other distributions
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Common libraries needed for dynamically linked executables
      stdenv.cc.cc.lib
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      
      # Graphics libraries (for AMD GPUs)
      libGL
      libva
      vulkan-loader
      
      # X11 libraries (for compatibility)
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXScrnSaver
      xorg.libXxf86vm
      xorg.libXext
      xorg.libXft
      xorg.libXinerama
      
      # Audio libraries
      alsa-lib
      pipewire
      
      # Common system libraries
      systemd
      dbus
      glib
      gtk3
      gtk4
      freetype
      fontconfig
      pango
      cairo
      gdk-pixbuf
      atk
      
      # Additional commonly needed libraries
      libxkbcommon
      wayland
      libdrm
      mesa
    ];
  };

  # Example Custom Systemd Services
  # Shows how easy it is to create services in NixOS
  systemd.services = {
    # Example: Run irssi (IRC client) in a screen session
    # Uncomment to enable:
    # irssi-screen = {
    #   description = "IRC client in screen session";
    #   after = [ "network.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     Type = "forking";
    #     User = "irc-user";  # Create this user in your config
    #     ExecStart = ''${pkgs.screen}/bin/screen -dmS irssi ${pkgs.irssi}/bin/irssi'';
    #     ExecStop = ''${pkgs.screen}/bin/screen -S irssi -X quit'';
    #     Restart = "always";
    #   };
    # };

    # Example: Custom backup service
    # custom-backup = {
    #   description = "Custom backup service";
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.writeShellScript "backup" ''
    #       #!/usr/bin/env bash
    #       # Your backup commands here
    #       echo "Running backup..."
    #     ''}";
    #   };
    # };
    # systemd.timers.custom-backup = {
    #   description = "Run backup daily";
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     Persistent = true;
    #   };
    # };
  };

  # Documentation for custom services
  environment.etc."nixos-templates/custom-services-guide.md".text = ''
    # Creating Custom Systemd Services in NixOS

    ## Basic Service Example
    ```nix
    systemd.services.my-app = {
      description = "My custom application";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "''${pkgs.my-app}/bin/my-app";
        Restart = "always";
        User = "myuser";
      };
    };
    ```

    ## Service with Timer
    ```nix
    systemd.services.my-task = {
      description = "Periodic task";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "''${pkgs.bash}/bin/bash -c 'echo Hello World'";
      };
    };
    
    systemd.timers.my-task = {
      description = "Run my task every hour";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
    ```

    ## Benefits over manual systemd units:
    - Integrated with NixOS configuration
    - Automatic dependency management
    - Type checking and validation
    - Easy rollback with NixOS generations
    - Declarative and reproducible
  '';
}
