{ config
, lib
, pkgs
, ...
}: {
  # Intel CPU configuration (auto-detected)
  boot = {
    kernelModules = [ "kvm-intel" ];
    kernelParams = lib.mkDefault [
      "intel_iommu=on"
      "intel_pstate=active"
    ];
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  services.thermald.enable = lib.mkDefault true;
}
