# Extra packages including gaming, multimedia, and tools
{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:

{
  # Import gaming optimizations from nixos-gaming if available
  imports = lib.optionals (inputs ? nixos-gaming) [
    inputs.nixos-gaming.nixosModules.pipewireLowLatency
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Enable Flatpak
  services.flatpak.enable = true;

  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Gamemode is configured in performance module

  # System packages
  environment.systemPackages = with pkgs; [
    # Media players and tools
    mpv
    ffmpeg-full
    obs-studio

    # Editors and IDEs
    helix
    neovim
    vscode
    zed-editor

    # Terminal emulators
    kitty
    ghostty

    # Browsers - Firefox removed as requested
    chromium
    microsoft-edge

    # File managers
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-archive-plugin
    nemo

    # Gaming tools
    mangohud
    goverlay
    gamescope
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
    vkbasalt

    # Gaming emulators and platforms
    discord
    # fightcade - not in nixpkgs
    mame

    # Torrent
    qbittorrent

    # Audio tools
    noisetorch

    # Network tools and monitoring
    mtr
    traceroute
    iperf3
    bandwhich
    fping
    wireshark
    gns3-gui
    gns3-server
    cifs-utils
    # autofs - configured via services below

    # System monitoring and performance
    fio
    glances
    btop
    htop
    iotop
    ioping
    ncdu
    dust
    gdu
    lsd
    fastfetch
    smartmontools
    lm_sensors
    openrgb
    linuxPackages.cpupower
    strace
    perf-tools
    linuxPackages.perf
    systemd-bootchart
    blktrace

    # Benchmarking
    geekbench
    unigine-heaven # cinebench not in nixpkgs
    unigine-valley
    unigine-superposition
    # furmark2 not available, using unigine

    # Development tools
    nodejs
    python3
    python3Packages.pip
    jdk # Java
    rustup
    go
    aider-chat
    powershell

    # AI tools
    # lmstudio not in nixpkgs, would need custom derivation

    # Security and reverse engineering
    ghidra

    # Virtualization
    qemu_full
    quickemu
    virt-manager

    # Shell tools
    zsh
    fish
    bat
    fzf
    ripgrep
    fd

    # Archive tools
    pigz
    p7zip
    unzip

    # Nerd fonts
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono

    # Powerlevel10k for zsh
    zsh-powerlevel10k

    # Filesystem tools
    ntfs3g
    exfatprogs
    xfsprogs
    btrfs-progs
    apfsprogs

    # Flatpak GUI
    gnome-software
  ];

  # Hardware support
  boot.kernelModules = [
    "hid-playstation" # PS5 DualSense controller
    "mac_hid" # Mac keyboard support
    "xpad" # Xbox controller support
  ];

  # Controller support
  hardware.xone.enable = lib.mkDefault false; # Xbox One wireless adapter (if needed)
  hardware.xpadneo.enable = true; # Better Xbox controller support

  # Vulkan support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      vulkan-validation-layers
    ];
  };

  # PipeWire low latency configuration
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # Low latency configuration via drop-in files
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 64;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 128;
      };
    };

    extraConfig.pipewire-pulse."92-low-latency" = {
      "context.properties" = {
        "pulse.min.req" = "32/48000";
        "pulse.default.req" = "64/48000";
        "pulse.max.req" = "128/48000";
        "pulse.min.quantum" = "32/48000";
        "pulse.max.quantum" = "128/48000";
      };
      "stream.properties" = {
        "node.latency" = "64/48000";
        "resample.quality" = 1;
      };
    };
  };

  # XWayland support
  programs.xwayland.enable = true;

  # Udev rules for controllers
  services.udev.packages = with pkgs; [
    game-devices-udev-rules
  ];

  # Additional gaming-related kernel parameters
  boot.kernel.sysctl = {
    # Reduce swappiness for gaming
    "vm.swappiness" = 10;

    # Improve responsiveness
    "kernel.sched_cfs_bandwidth_slice_us" = 500;

    # Memory settings for gaming
    "vm.max_map_count" = 2147483642; # Required for some games
    "vm.overcommit_memory" = 1;
  };

  # Enable esync/fsync for better gaming performance
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=1048576
  '';

  systemd.extraConfig = ''
    DefaultLimitNOFILE=1048576
  '';

  # Security limits for gaming
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "1048576";
    }
  ];

  # Filesystem support
  boot.supportedFilesystems = [
    "ntfs"
    "exfat"
    "xfs"
    "btrfs"
    "apfs"
  ];

  # Hardware video acceleration packages are handled in the AMD module
  # Additional video acceleration packages can be added there

  # LibVA environment
  environment.variables = {
    LIBVA_DRIVER_NAME = "radeonsi"; # For AMD, override intel defaults
  };

  # Enable libvirtd for virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  # Add user to libvirtd and wireshark groups
  users.users.amoon.extraGroups = [
    "libvirtd"
    "kvm"
    "wireshark"
  ];

  # Enable zsh as default shell
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "docker"
        "kubectl"
      ];
      theme = "powerlevel10k/powerlevel10k";
    };
  };

  # Enable fish shell
  programs.fish.enable = true;

  # Powerlevel10k is already included in main package list

  # TUI greeter configuration
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # Enable SMART monitoring
  services.smartd = {
    enable = true;
    defaults.monitored = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../7/04) -W 4,35,40";
  };

  # Enable wireshark group
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  # Enable GNS3
  security.wrappers.ubridge = {
    source = "${pkgs.gns3-server}/bin/ubridge";
    capabilities = "cap_net_admin,cap_net_raw=ep";
    owner = "root";
    group = "root";
    permissions = "u+rx,g+x,o+x";
  };

  # AutoFS for automatic mounting
  services.autofs = {
    enable = true;
    autoMaster = ''
      /net -hosts --timeout=60
    '';
  };
}
