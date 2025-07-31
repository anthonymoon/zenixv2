{ config
, lib
, pkgs
, ...
}: {
  # NVIDIA GPU configuration (auto-detected)
  boot = {
    kernelParams = lib.mkDefault [
      "nvidia-drm.modeset=1"
    ];
    blacklistedKernelModules = [ "nouveau" ];
  };

  services.xserver.videoDrivers = lib.mkBefore [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    powerManagement.enable = lib.mkDefault true;
    open = lib.mkDefault false;
    nvidiaSettings = lib.mkDefault true;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkDefault true;
  };
}
