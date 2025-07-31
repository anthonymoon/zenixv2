{ config
, lib
, pkgs
, ...
}: {
  # Stable profile - uses stable NixOS channel

  # Use stable kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

  # Conservative update strategy
  system.autoUpgrade = {
    enable = false; # Manual updates only
    allowReboot = false;
  };

  # Stable nix settings
  nix = {
    settings = {
      # Prefer binary caches
      fallback = false;

      # Conservative garbage collection
      min-free = lib.mkDefault (5 * 1024 * 1024 * 1024); # 5GB
    };

    # Keep derivations for rollback
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
