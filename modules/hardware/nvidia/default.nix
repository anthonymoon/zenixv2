# NVIDIA GPU support
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for wayland
    modesetting.enable = true;

    # Use the NVidia open source kernel module
    open = lib.mkDefault false;

    # Enable the nvidia settings menu
    nvidiaSettings = true;

    # Optionally, you can select the driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # OpenGL
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # CUDA support
  environment.systemPackages = with pkgs; [
    cudatoolkit
    nvtop
  ];
}
