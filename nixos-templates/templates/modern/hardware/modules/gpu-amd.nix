{ config
, lib
, pkgs
, ...
}: {
  # AMD GPU configuration (auto-detected)
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    kernelParams = lib.mkDefault [
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
  };

  services.xserver.videoDrivers = lib.mkBefore [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkDefault true;
    extraPackages = with pkgs; [
      amdvlk
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
}
