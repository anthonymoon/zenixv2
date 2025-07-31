{ config
, lib
, pkgs
, ...
}: {
  # Gaming profile

  # Gaming kernel optimizations
  boot.kernelParams = [
    "threadirqs"
    "tsc=reliable"
    "clocksource=tsc"
    "nohz_full=all"
    "rcu_nocbs=all"
  ];

  # Enable gamemode
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        desiredgov = "performance";
        igpu_desiredgov = "performance";
        igpu_power_threshold = 0.3;
        ioprio = 0;
      };
    };
  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    mangohud
    lutris
    wine-staging
    winetricks
    protontricks
    bottles
    heroic
    prismlauncher # Minecraft
    r2modman # Mod manager
    steamtinkerlaunch

    # Performance tools
    corectrl
    piper # Gaming mouse config

    # Compatibility
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    mesa-demos
  ];

  # Controller support
  hardware.xpadneo.enable = true; # Xbox controllers
  services.joycond.enable = true; # Nintendo controllers

  # Low latency audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;

    config.pipewire = {
      "context.properties" = {
        "default.clock.min-quantum" = 32;
        "default.clock.quantum" = 32;
        "default.clock.max-quantum" = 32;
      };
    };
  };
}
