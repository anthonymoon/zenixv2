# Example host-specific configuration
# This shows common settings you might want to customize

{ config, pkgs, lib, ... }:

{
  # System hostname
  networking.hostName = "nixos-example";

  # Timezone and locale
  time.timeZone = "America/New_York"; # Change to your timezone
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

  # User accounts
  users.users = {
    # Primary user
    alice = {
      isNormalUser = true;
      description = "Alice User";
      extraGroups = [
        "wheel" # sudo access
        "networkmanager" # network configuration
        "video" # video devices
        "audio" # audio devices
        "docker" # docker access (if enabled)
        "libvirtd" # virtualization (if enabled)
      ];
      # Generate with: mkpasswd -m sha-512
      # hashedPassword = "$6$rounds=10000$..."; 
      initialPassword = "changeme123"; # MUST CHANGE on first login

      # SSH keys for remote access
      openssh.authorizedKeys.keys = [
        # "ssh-rsa AAAAB3... alice@laptop"
      ];

      # User-specific packages
      packages = with pkgs; [
        firefox
        thunderbird
        libreoffice
      ];
    };

    # Additional users can be added here
  };

  # Desktop Environment (choose one)

  # Option 1: KDE Plasma
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;

    # Configure display
    # videoDrivers = [ "nvidia" ]; # If using NVIDIA
    # videoDrivers = [ "amdgpu" ]; # If using AMD

    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape"; # Make Caps Lock act as Escape
    };
  };

  # Option 2: GNOME (comment out KDE above and uncomment this)
  # services.xserver = {
  #   enable = true;
  #   displayManager.gdm.enable = true;
  #   desktopManager.gnome.enable = true;
  # };

  # Option 3: Sway (Wayland tiling WM)
  # programs.sway = {
  #   enable = true;
  #   wrapperFeatures.gtk = true;
  # };

  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false; # Using pipewire instead
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Networking
  networking = {
    networkmanager.enable = true;

    # Firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # 22    # SSH (if enabled below)
        # 80    # HTTP
        # 443   # HTTPS
      ];
      allowedUDPPorts = [
        # 51820 # WireGuard
      ];
    };

    # Static IP configuration (optional)
    # interfaces.enp2s0.ipv4.addresses = [{
    #   address = "192.168.1.100";
    #   prefixLength = 24;
    # }];
    # defaultGateway = "192.168.1.1";
    # nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  # System services
  services = {
    # SSH server
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false; # Only allow key auth
        KbdInteractiveAuthentication = false;
      };
      openFirewall = true;
    };

    # Printing
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
      ];
    };

    # Bluetooth
    blueman.enable = true;

    # Power management for laptops
    # tlp = {
    #   enable = true;
    #   settings = {
    #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
    #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    #     CPU_MIN_PERF_ON_AC = 0;
    #     CPU_MAX_PERF_ON_AC = 100;
    #     CPU_MIN_PERF_ON_BAT = 0;
    #     CPU_MAX_PERF_ON_BAT = 50;
    #   };
    # };

    # Automatic updates (optional)
    # system.autoUpgrade = {
    #   enable = true;
    #   flake = "github:yourusername/yourrepo";
    #   flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
    #   dates = "weekly";
    # };
  };

  # Hardware support
  hardware = {
    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # OpenGL
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true; # For 32-bit applications

      # For AMD GPUs
      # extraPackages = with pkgs; [
      #   amdvlk
      #   rocm-opencl-icd
      #   rocm-opencl-runtime
      # ];

      # For Intel GPUs
      # extraPackages = with pkgs; [
      #   intel-media-driver
      #   vaapiIntel
      #   vaapiVdpau
      #   libvdpau-va-gl
      # ];
    };

    # CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Enable firmware
    enableRedistributableFirmware = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Terminal utilities
    vim
    neovim
    git
    tmux
    wget
    curl
    htop
    btop
    ripgrep
    fd
    bat
    eza
    zoxide
    starship

    # Development tools
    gcc
    gnumake
    python3
    nodejs
    rustup
    go

    # System tools
    pciutils
    usbutils
    lshw
    dmidecode

    # File management
    ranger
    ncdu
    unzip
    p7zip

    # Networking
    networkmanager-openvpn
    wireguard-tools

    # Multimedia (if using desktop)
    vlc
    mpv
    spotify

    # Productivity (if using desktop)
    obsidian
    zotero
    nextcloud-client
  ];

  # Development environments
  programs = {
    # Git
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        pull.rebase = true;
        rebase.autoStash = true;
      };
    };

    # Shell
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}";
        update = "sudo nix flake update /etc/nixos";
      };
    };

    # Neovim
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # Docker (optional)
    # docker = {
    #   enable = true;
    #   storageDriver = "zfs";
    #   enableOnBoot = true;
    # };

    # Steam gaming (optional)
    # steam = {
    #   enable = true;
    #   remotePlay.openFirewall = true;
    #   dedicatedServer.openFirewall = true;
    # };
  };

  # Fonts
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
      liberation_ttf
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      source-han-sans
      source-han-serif
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" "Source Han Serif" ];
        sansSerif = [ "Noto Sans" "Source Han Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Virtualization (optional)
  # virtualisation = {
  #   libvirtd = {
  #     enable = true;
  #     qemu = {
  #       package = pkgs.qemu_kvm;
  #       runAsRoot = false;
  #       swtpm.enable = true;
  #       ovmf = {
  #         enable = true;
  #         packages = [ pkgs.OVMFFull.fd ];
  #       };
  #     };
  #   };
  #   
  #   docker = {
  #     enable = true;
  #     storageDriver = "zfs";
  #   };
  # };

  # Security
  security = {
    # Sudo configuration
    sudo = {
      extraRules = [{
        users = [ "alice" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ]; # Remove for production
          }
        ];
      }];
    };

    # AppArmor
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Additional persistence directories for impermanence
  environment.persistence."/persist" = {
    directories = [
      # System
      "/var/lib/bluetooth"
      "/var/lib/NetworkManager"
      "/var/lib/systemd/timers"

      # Desktop environment specific
      "/var/lib/sddm" # For KDE
      # "/var/lib/gdm" # For GNOME

      # Services
      # "/var/lib/docker" # If using Docker
      # "/var/lib/libvirt" # If using libvirt
      # "/var/lib/postgresql" # If using PostgreSQL
    ];

    # User-specific persistence
    users.alice = {
      directories = [
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Public"
        "Templates"
        "Videos"
        "Projects" # Custom directory
        ".cache"
        ".config"
        ".local"
        ".mozilla" # Firefox profile
        ".thunderbird" # Email
        ".ssh"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".secrets"; mode = "0700"; }
      ];
      files = [
        ".bash_history"
        ".zsh_history"
        ".gitconfig"
        ".npmrc"
      ];
    };
  };
}
