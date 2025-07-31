{ config
, lib
, pkgs
, ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "mitigations=off"
      "nowatchdog"
      "audit=0"
      "msr.allow_writes=on"
      "pcie_aspm=off"
      "processor.max_cstate=1"
      "pcie_port_pm=off"
      "pcie_aspm.policy=performance"
      "intel_idle.max_cstate=0"
      "iommu=pt"
      "intel_iommu=on"
      "intel_pstate=active"
      "split_lock_detect=off"
      "kvm.ignore_msrs=1"
      "kvm.report_ignored_msrs=0"
      "kvm_intel.nested=1"
      "kvm_intel.emulate_invalid_guest_state=0"
      "kvm_intel.ept=1"
      "kvm_intel.flexpriority=1"
      "kvm_intel.enable_shadow_vmcs=1"
      "kvm_intel.enable_apicv=1"
      "kvm_intel.vpid=1"
      "nouveau.modeset=0"
    ];

    blacklistedKernelModules = [ "r8169" ];

    extraModulePackages = with config.boot.kernelPackages; [
      turbostat
    ];
  };
}
