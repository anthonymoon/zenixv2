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

  # Enable gamemode
  programs.gamemode.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Media players and tools
    mpv
    ffmpeg-full
    obs-studio

    # Editors
    helix
    neovim
    vscode # vscode-insiders would need custom overlay

    # Browsers
    firefox # zen-browser would need to be added via overlay or flake
    chromium # thorium would need custom build
    microsoft-edge

    # Gaming tools
    mangohud
    goverlay
    gamescope
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
    vkbasalt

    # Gaming stores/platforms
    discord

    # Audio tools
    noisetorch

    # Network tools
    mtr
    traceroute
    iperf3

    # System monitoring
    fio
    glances
    btop
    htop

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
}
