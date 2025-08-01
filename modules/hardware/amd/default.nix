# AMD GPU support
{
  config,
  lib,
  pkgs,
  ...
}: {
  # AMD drivers - Wayland optimized
  services.xserver.videoDrivers = ["amdgpu"];

  # Graphics support with AMD (using new option names)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocmPackages.clr.icd
      rocmPackages.clr
      mesa
      vulkan-loader
      vulkan-validation-layers
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  # AMD GPU tools
  environment.systemPackages = with pkgs; [
    radeontop
    rocmPackages.rocm-smi
    glxinfo
    vulkan-tools
    wayland-utils
  ];

  # Enable Vulkan for Wayland
  environment.variables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/amd_icd64.json";
    # Prefer Wayland
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Kernel modules for AMD GPU
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = ["kvm-amd"];
}
