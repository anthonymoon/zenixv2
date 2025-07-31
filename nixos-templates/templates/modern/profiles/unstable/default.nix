{ config
, lib
, pkgs
, ...
}: {
  # Unstable profile - bleeding edge

  # Use latest kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Aggressive updates
  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    allowReboot = false;
  };

  # Unstable nix settings
  nix = {
    settings = {
      # Try building from source if binary fails
      fallback = true;

      # More experimental features
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "recursive-nix"
        "impure-derivations"
      ];
    };

    # Frequent garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
