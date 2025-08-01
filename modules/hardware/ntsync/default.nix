# NT synchronization primitive support for Wine gaming
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable ntsync module (Linux 6.10+ feature)
  boot.kernelModules = [ "ntsync" ];

  # Create ntsync device with proper permissions
  services.udev.extraRules = ''
    # NT synchronization primitive device
    KERNEL=="ntsync", MODE="0644", TAG+="uaccess"
  '';

  # Ensure the kernel has ntsync support
  boot.kernelPatches =
    lib.optionals (lib.versionOlder config.boot.kernelPackages.kernel.version "6.10")
      [
        {
          name = "ntsync";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            NTSYNC = module;
          };
        }
      ];

  # Add Wine with ntsync support to system packages
  environment.systemPackages = with pkgs; [
    # Wine with staging patches that support ntsync
    wineWowPackages.staging
    winetricks

    # Utilities
    cabextract
    p7zip

    # For debugging
    strace
  ];

  # Wine-specific optimizations
  environment.variables = {
    # Enable ntsync in Wine
    WINE_NTSYNC = "1";
    WINEESYNC = "1";
    WINEFSYNC = "1";

    # Wine performance
    WINE_CPU_TOPOLOGY = "8:4"; # Adjust based on CPU
    WINE_HEAP_DELAY_FREE = "1";
  };

  # Increase limits for Wine/Proton
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

  # System configuration for Wine
  boot.kernel.sysctl = {
    # For esync
    "fs.file-max" = 1048576;

    # Memory overcommit for Wine (also defined in extras/pkgs)
    # "vm.overcommit_memory" = 1;

    # Reduce latency
    "kernel.sched_latency_ns" = 1000000;
    "kernel.sched_min_granularity_ns" = 100000;
    "kernel.sched_wakeup_granularity_ns" = 25000;
    "kernel.sched_migration_cost_ns" = 5000000;
  };
}
