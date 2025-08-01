# Performance optimizations and tuning
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Boot kernel parameters for maximum performance
  boot.kernelParams = [
    # Disable CPU mitigations for maximum performance
    "mitigations=off"

    # Gaming optimizations
    "preempt=full"
    "threadirqs"
    "split_lock_detect=off"
    "pci=pcie_bus_perf"
    "intel_pstate=active"

    # NVMe optimizations
    "nvme_core.default_ps_max_latency_us=0"
    "nvme_core.io_timeout=255"

    # Memory and VM optimizations
    "transparent_hugepage=always"
    "vm.dirty_ratio=10"
    "vm.dirty_background_ratio=5"

    # Display settings for 4K screen
    "video=1920x1080"
    "fbcon=nodefer"

    # Enable KMS (Kernel Mode Setting)
    "amdgpu.modeset=1"
    "amdgpu.dc=1"

    # Additional performance
    "nowatchdog"
    "nmi_watchdog=0"
    "quiet"
    "splash"
    "rd.udev.log_level=3"
    "udev.log_level=3"
  ];

  # VT console configuration for 4K displays
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v24n.psf.gz";
    # Set console resolution to 1920x1080
    packages = with pkgs; [ terminus_font ];
  };

  # Console resolution is already set in main boot.kernelParams above

  # Enable multiple VT TTYs (1-6 by default, we'll ensure 1-3 are active)
  services.getty = {
    # Ensure TTYs 1-3 are always available
    extraArgs = [ "--noclear" ];
  };

  systemd.services."getty@tty1".enable = true;
  systemd.services."getty@tty2".enable = true;
  systemd.services."getty@tty3".enable = true;

  # Plymouth boot splash
  boot.plymouth = {
    enable = true;
    theme = "bgrt"; # Uses vendor logo if available, otherwise fallback
    # For a more gaming-oriented theme, you could use:
    # theme = "solar";
  };

  # Ensure KMS is enabled early for Plymouth
  boot.initrd.kernelModules = [ "amdgpu" ];

  # Enable VFAT filesystem support
  boot.supportedFilesystems = [
    "vfat"
    "fat32"
    "fat16"
    "fat12"
  ];

  # Nix daemon optimizations
  nix = {
    settings = {
      # Performance optimizations
      auto-optimise-store = true;
      cores = 0; # Use all available cores
      max-jobs = "auto"; # Build multiple derivations in parallel

      # Binary cache settings
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://hyprland.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      # Parallel downloading
      http-connections = 128;
      http2 = true;

      # Build performance
      build-cores = 0; # Use all cores for each build
      sandbox = true;

      # Trusted users for binary cache
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    # Garbage collection settings
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # Enable flakes and new commands
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      # Fallback quickly if substituters are not available
      connect-timeout = 5
      # Parallelize downloads
      download-attempts = 3
      narinfo-cache-negative-ttl = 0
      # Improve performance for large builds
      min-free = ${toString (1024 * 1024 * 1024 * 10)} # 10GB
      max-free = ${toString (1024 * 1024 * 1024 * 50)} # 50GB
    '';
  };

  # System-wide performance tuning
  powerManagement = {
    cpuFreqGovernor = "performance";
    powertop.enable = false; # Disable power saving
  };

  # Disable suspend/hibernate for gaming systems
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # CPU performance settings
  boot.kernel.sysctl = {
    # Disable CPU frequency scaling
    "kernel.sched_energy_aware" = 0;

    # Gaming optimizations (vm.max_map_count is defined in extras/pkgs)
    "kernel.split_lock_mitigate" = 0;

    # NVMe optimizations
    "vm.dirty_expire_centisecs" = 3000;
    "vm.dirty_writeback_centisecs" = 500;
  };

  # Enable gamemode for automatic optimizations
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        desiredgov = "performance";
        igpu_desiredgov = "performance";
        igpu_power_threshold = 0.3;
        softrealtime = "auto";
        reaper_freq = 5;
        defaultgov = "performance";
        inhibit_screensaver = 1;
      };

      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  # Install performance tools
  environment.systemPackages = with pkgs; [
    # Performance monitoring
    htop
    iotop
    iftop
    powertop

    # CPU tools
    cpufrequtils
    linuxPackages.cpupower

    # Gaming tools
    gamemode
    mangohud

    # System tools
    pciutils
    usbutils
    nvme-cli
  ];

  # MangoHud configuration via config file
  environment.etc."MangoHud/MangoHud.conf".text = ''
    # Performance metrics
    fps
    fps_limit=0
    frame_timing=1
    cpu_stats
    cpu_temp
    cpu_power
    gpu_stats
    gpu_temp
    gpu_power
    gpu_mem_clock
    gpu_core_clock
    vram
    ram

    # Display settings
    position=top-left
    font_size=24
    background_alpha=0.4
    round_corners=10

    # Colors
    gpu_color=2E9762
    cpu_color=2E97CB
    vram_color=AD64C1
    ram_color=C26693
    fps_color=E8E3E3

    # Features
    gamemode
    vulkan_driver
    wine

    # Toggle keys
    toggle_hud=Shift_R+F12
    toggle_fps_limit=Shift_L+F1

    # Additional settings
    gpu_load_change
    cpu_load_change
    core_load_change
    legacy_layout=0
    frametime
    table_columns=3
  '';

  # MangoHud environment variables
  environment.variables = {
    MANGOHUD = "1";
    MANGOHUD_CONFIG = "/etc/MangoHud/MangoHud.conf";
  };
}
