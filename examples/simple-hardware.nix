# Simple hardware configuration without over-abstraction
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Instead of complex detection functions, just use simple conditions

  # AMD CPU support
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Intel CPU support
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Kernel modules for virtualization
  boot.kernelModules =
    lib.optionals config.hardware.cpu.amd.updateMicrocode ["kvm-amd"]
    ++ lib.optionals config.hardware.cpu.intel.updateMicrocode ["kvm-intel"];

  # Graphics - just enable what you need
  # For NVIDIA:
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.modesetting.enable = true;

  # For AMD:
  # services.xserver.videoDrivers = [ "amdgpu" ];
  # hardware.opengl.driSupport = true;
  # hardware.opengl.driSupport32Bit = true;

  # Common hardware support
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = false; # Only if really needed

  # Sound - simple and direct
  sound.enable = true;
  hardware.pulseaudio.enable = false; # Use pipewire instead
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
