# Hardware profiles module - DRY implementation
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.profiles;
  utils = import ../../lib/utils.nix { inherit lib; };
  
  # Common hardware configurations
  commonHardware = {
    enableRedistributableFirmware = mkDefault true;
    pulseaudio.enable = false; # We use pipewire
  };
  
  # AMD-specific configuration
  amdConfig = {
    hardware = commonHardware // {
      cpu.amd.updateMicrocode = mkDefault true;
      opengl = {
        enable = true;
        driSupport = true;
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
    };
    
    boot = {
      kernelModules = utils.kernelModules.amd;
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "amd_pstate=active"
        "amdgpu.si_support=1"
        "amdgpu.cik_support=1"
        "radeon.si_support=0"
        "radeon.cik_support=0"
      ];
      blacklistedKernelModules = [ "nouveau" "nvidia" ];
    };
  };
  
  # Intel-specific configuration
  intelConfig = {
    hardware = commonHardware // {
      cpu.intel.updateMicrocode = mkDefault true;
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    };
    
    boot = {
      kernelModules = utils.kernelModules.intel;
      kernelParams = [
        "intel_iommu=on"
        "iommu=pt"
        "i915.enable_guc=2"
        "i915.enable_fbc=1"
      ];
    };
  };
  
  # Common boot configuration
  commonBoot = {
    loader = utils.mkSystemdBootConfig {};
    initrd = {
      availableKernelModules = utils.kernelModules.storage;
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = utils.kernelModules.base;
    extraModulePackages = [ ];
  };
  
in {
  options.hardware.profiles = {
    type = mkOption {
      type = types.enum [ "amd" "intel" "generic" "vm" ];
      default = "generic";
      description = "Hardware profile type";
    };
    
    platform = mkOption {
      type = types.enum [ "desktop" "laptop" "server" "vm" ];
      default = "desktop";
      description = "Platform type";
    };
    
    enableBluetooth = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Bluetooth support";
    };
    
    enableSound = mkOption {
      type = types.bool;
      default = true;
      description = "Enable sound support";
    };
    
    enableVirtualisation = mkOption {
      type = types.bool;
      default = false;
      description = "Enable virtualisation support";
    };
  };
  
  config = mkMerge [
    # Base configuration for all profiles
    {
      boot = commonBoot;
      hardware.enableRedistributableFirmware = mkDefault true;
    }
    
    # AMD profile
    (mkIf (cfg.type == "amd") amdConfig)
    
    # Intel profile
    (mkIf (cfg.type == "intel") intelConfig)
    
    # Generic profile
    (mkIf (cfg.type == "generic") {
      hardware = commonHardware;
      boot.kernelModules = [ ];
    })
    
    # VM profile
    (mkIf (cfg.type == "vm") {
      hardware = commonHardware;
      boot = {
        kernelModules = [ ];
        initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" ];
      };
      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true;
    })
    
    # Platform-specific configurations
    (mkIf (cfg.platform == "laptop") {
      services = {
        tlp.enable = mkDefault true;
        logind = {
          lidSwitch = "suspend";
          lidSwitchExternalPower = "ignore";
        };
      };
      programs.light.enable = mkDefault true;
    })
    
    # Bluetooth
    (mkIf cfg.enableBluetooth {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      services.blueman.enable = mkDefault true;
    })
    
    # Sound
    (mkIf cfg.enableSound {
      sound.enable = false; # We use pipewire
      security.rtkit.enable = true;
      services.pipewire = utils.mkPipewireConfig {};
    })
    
    # Virtualisation
    (mkIf cfg.enableVirtualisation {
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = false;
            swtpm.enable = true;
            ovmf = {
              enable = true;
              packages = [ pkgs.OVMFFull.fd ];
            };
          };
        };
      };
      
      boot.kernelModules = utils.kernelModules.virtualisation;
      
      environment.systemPackages = with pkgs; [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
      ];
    })
  ];
}