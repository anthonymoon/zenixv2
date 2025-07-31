{ config
, lib
, pkgs
, ...
}: {
  # Intel GPU configuration (auto-detected)
  boot.initrd.kernelModules = [ "i915" ];

  services.xserver.videoDrivers = lib.mkBefore [ "modesetting" ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = lib.mkDefault true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Enable Intel GPU tools
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];
}
