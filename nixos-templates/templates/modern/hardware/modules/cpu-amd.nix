{ config
, lib
, pkgs
, ...
}: {
  # AMD CPU configuration (auto-detected)
  boot = {
    kernelModules = [ "kvm-amd" ];
    kernelParams = lib.mkDefault [
      "amd_pstate=active"
      "amd_iommu=on"
    ];
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
