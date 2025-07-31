{ config
, lib
, pkgs
, ...
}:
let
  # Safe file reading that handles pure evaluation mode
  safeReadFile = path: default:
    let
      result = builtins.tryEval (builtins.readFile path);
    in
    if result.success
    then result.value
    else default;

  # Safe path checking for pure evaluation
  safePathExists = path:
    let
      result = builtins.tryEval (builtins.pathExists path);
    in
    if result.success
    then result.value
    else false;

  # Read system information safely
  cpuinfo = safeReadFile /proc/cpuinfo "";

  # CPU Detection with fallback
  cpuVendor =
    if cpuinfo != "" && lib.strings.hasInfix "GenuineIntel" cpuinfo
    then "intel"
    else if cpuinfo != "" && lib.strings.hasInfix "AuthenticAMD" cpuinfo
    then "amd"
    else "generic";

  # GPU Detection (check for kernel modules) with safe path checking
  hasNvidia =
    safePathExists /sys/module/nvidia
    || safePathExists /dev/nvidia0;
  hasAmdGpu =
    safePathExists /sys/module/amdgpu
    || safePathExists /dev/dri/renderD128;
  hasIntelGpu = safePathExists /sys/module/i915;

  # Virtualization Detection with safe file reading
  isVirtual =
    (cpuinfo != "" && lib.strings.hasInfix "hypervisor" cpuinfo)
    || safePathExists /sys/hypervisor/type;

  # VM Type Detection with safe file operations
  vmType =
    if !isVirtual
    then null
    else if safePathExists /sys/devices/virtual/dmi/id/sys_vendor
    then
      let
        vendor = lib.strings.removeSuffix "\n" (safeReadFile /sys/devices/virtual/dmi/id/sys_vendor "unknown");
      in
      if vendor == "QEMU" || vendor == "KVM"
      then "qemu-kvm"
      else if vendor == "VMware, Inc."
      then "vmware"
      else if vendor == "innotek GmbH"
      then "virtualbox"
      else if vendor == "Microsoft Corporation"
      then "hyperv"
      else if vendor == "Xen"
      then "xen"
      else "generic-vm"
    else "generic-vm";
in
{
  imports =
    [
      # Always import the detection results module
      (import ./detection-results.nix {
        inherit cpuVendor hasNvidia hasAmdGpu hasIntelGpu isVirtual vmType;
      })

      # Auto-import hardware modules based on detection
      ./modules/cpu-${cpuVendor}.nix
      ./modules/platform-${
        if isVirtual
        then "virtual"
        else "physical"
      }.nix
    ]
    ++
    # GPU modules (can have multiple)
    (lib.optional hasNvidia ./modules/gpu-nvidia.nix)
    ++ (lib.optional hasAmdGpu ./modules/gpu-amd.nix)
    ++ (lib.optional hasIntelGpu ./modules/gpu-intel.nix);

  # Export detection info for debugging
  system.nixos.tags =
    [
      "cpu:${cpuVendor}"
    ]
    ++ (lib.optional hasNvidia "gpu:nvidia")
    ++ (lib.optional hasAmdGpu "gpu:amd")
    ++ (lib.optional hasIntelGpu "gpu:intel")
    ++ (lib.optional isVirtual "vm:${vmType}")
    ++ (lib.optional (!isVirtual) "platform:physical");
}
