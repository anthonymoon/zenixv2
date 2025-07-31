{ config
, lib
, pkgs
, ...
}: {
  # Generic CPU configuration for non-Intel/AMD CPUs
  # This includes ARM, RISC-V, older CPUs, or VMs with masked CPU info

  hardware.cpu = {
    # No vendor-specific optimizations
  };

  # Basic CPU frequency management
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Enable basic CPU features
  boot.kernelModules = lib.mkDefault [ ];
}
