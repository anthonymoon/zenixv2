# Intel GPU support
{ config, lib, pkgs, ... }:

{
  # Intel drivers
  services.xserver.videoDrivers = [ "modesetting" ];
  
  # Enable Intel GPU
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime
    ];
  };
  
  # Intel GPU tools
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];
  
  # Enable VA-API
  environment.variables = {
    VDPAU_DRIVER = lib.mkDefault "va_gl";
  };
}