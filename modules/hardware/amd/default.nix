# AMD GPU support
{ config, lib, pkgs, ... }:

{
  # AMD drivers
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  # OpenGL with AMD support
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
  
  # AMD GPU tools
  environment.systemPackages = with pkgs; [
    radeontop
    rocm-smi
  ];
  
  # Enable Vulkan
  environment.variables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/amd_icd64.json";
  };
}