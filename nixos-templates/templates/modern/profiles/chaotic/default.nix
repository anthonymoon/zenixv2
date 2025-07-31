{ config
, lib
, pkgs
, inputs
, ...
}: {
  # Chaotic-Nyx integration

  imports = [
    inputs.chaotic.nixosModules.default
  ];

  # Use CachyOS kernel from Chaotic
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Enable Chaotic packages
  chaotic.nyx.enable = true;

  # Add Chaotic cache
  nix.settings = {
    substituters = [
      "https://nyx.chaotic.cx"
    ];
    trusted-public-keys = [
      "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };

  # Performance optimizations from CachyOS
  boot.kernelParams = [
    "mitigations=off"
    "nowatchdog"
    "tsc=reliable"
    "clocksource=tsc"
  ];

  # CPU scheduler optimizations
  services.scx = {
    enable = true;
    scheduler = "scx_rusty"; # or scx_lavd
  };
}
