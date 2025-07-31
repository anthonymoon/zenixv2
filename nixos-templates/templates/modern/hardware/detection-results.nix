{ cpuVendor
, hasNvidia
, hasAmdGpu
, hasIntelGpu
, isVirtual
, vmType
,
}: { config
   , lib
   , pkgs
   , ...
   }: {
  # Make detection results available to the system
  system.build.detectedHardware = {
    cpu = cpuVendor;
    gpus = lib.filter (x: x != null) [
      (
        if hasNvidia
        then "nvidia"
        else null
      )
      (
        if hasAmdGpu
        then "amd"
        else null
      )
      (
        if hasIntelGpu
        then "intel"
        else null
      )
    ];
    platform =
      if isVirtual
      then "virtual"
      else "physical";
    virtualHost = vmType;
  };

  # Show detection in system description
  system.nixos.label = lib.mkDefault (
    "${cpuVendor}-cpu"
    + lib.optionalString hasNvidia "+nvidia"
    + lib.optionalString hasAmdGpu "+amd-gpu"
    + lib.optionalString hasIntelGpu "+intel-gpu"
    + lib.optionalString isVirtual " (${vmType})"
  );
}
