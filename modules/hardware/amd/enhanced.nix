# Enhanced AMD GPU and CPU configuration with monitoring and overclocking
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Import nixos-hardware AMD GPU optimizations
    inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  # AMD GPU kernel modules and firmware
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = [
    "kvm-amd"
    "amdgpu"
    "msr" # For CPU monitoring and overclocking
  ];

  # Kernel parameters optimized for AMD 7800 XT
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff" # Enable all power features
    "amdgpu.gpu_recovery=1" # Enable GPU recovery
    "amdgpu.deep_color=1" # Enable 10-bit color
    "amdgpu.dpm=1" # Dynamic power management
    "amdgpu.dc=1" # Display Core enabled
    "amdgpu.vm_update_mode=3" # CPU update mode for better performance
    "amdgpu.exp_hw_support=1" # Experimental hardware support
    "amdgpu.smu_memory_pool_size=512" # Larger SMU memory pool
    "amdgpu.audio=1" # HDMI/DP audio
    "amdgpu.sg_display=0" # Disable scatter/gather for display
    "amd_pstate=active" # Active P-state driver for Ryzen
    "processor.max_cstate=1" # Better performance (less power saving)
    "idle=nomwait" # Better performance
  ];

  # Extra module configuration for AMD GPU
  boot.extraModprobeConfig = ''
    # AMD GPU optimizations for 7800 XT
    options amdgpu ppfeaturemask=0xffffffff
    options amdgpu gpu_recovery=1
    options amdgpu deep_color=1
    options amdgpu dpm=1
    options amdgpu dc=1
    options amdgpu vm_update_mode=3
    options amdgpu exp_hw_support=1
    options amdgpu smu_memory_pool_size=512

    # Disable GPU reset on init for stability
    options amdgpu reset_method=4

    # Enable high priority compute queues
    options amdgpu sched_policy=1

    # Increase GART size for better performance
    options amdgpu gart_size=1024

    # Better memory management
    options amdgpu vm_block_size=12
    options amdgpu vm_fault_stop=0
    options amdgpu vm_debug=0

    # Audio settings
    options amdgpu audio=1
    options amdgpu disp_priority=2
  '';

  # MSR module is already added above in boot.kernelModules

  # Make MSRs writable for overclocking tools
  systemd.services.msr-tools = {
    description = "Enable MSR access for overclocking";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "enable-msr" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "Configuring MSR access for overclocking..."

        # Load MSR module
        if ${pkgs.kmod}/bin/modprobe msr; then
          echo "✓ MSR module loaded"
        else
          echo "✗ Failed to load MSR module"
          exit 1
        fi

        # Create msr group if it doesn't exist
        if ${pkgs.shadow}/bin/groupadd -f msr; then
          echo "✓ MSR group created/exists"
        else
          echo "✗ Failed to create MSR group"
        fi

        # Wait for MSR devices to appear
        sleep 1

        # Set permissions for MSR access
        msr_count=0
        for msr in /dev/cpu/*/msr; do
          if [[ -e "$msr" ]]; then
            if chown root:msr "$msr" && chmod 660 "$msr"; then
              ((msr_count++))
            else
              echo "⚠ Failed to set permissions on $msr"
            fi
          fi
        done

        if [[ $msr_count -gt 0 ]]; then
          echo "✓ Set permissions on $msr_count MSR devices"
        else
          echo "⚠ No MSR devices found - this is normal if running in a VM"
        fi

        echo "MSR configuration completed"
      ''}";
    };
  };

  # Add user to msr group for overclocking access
  users.groups.msr = {};
  
  # Add hardware-specific groups to the configured user
  # This uses mkIf to only apply when a user is configured
  users.users = lib.mkIf (config.zenix.user.username or null != null) {
    ${config.zenix.user.username}.extraGroups = [
      "msr"
      "video"
      "render"
    ];
  };

  # Hardware configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      # AMD Vulkan drivers
      amdvlk
      rocmPackages.clr.icd

      # Mesa drivers
      mesa

      # Video acceleration - AMD specific
      libvdpau-va-gl
      vaapiVdpau
      libva
      libva-utils

      # OpenCL
      rocmPackages.clr
      rocmPackages.rocm-runtime

      # ROCm SMI for GPU monitoring
      rocmPackages.rocm-smi
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [
      amdvlk
      mesa
      libva
    ];
  };

  # Vulkan packages are already included in the extraPackages above

  # AMD GPU and CPU monitoring/overclocking tools
  environment.systemPackages = with pkgs; [
    # GPU monitoring and control
    amdgpu_top # TUI for AMD GPU monitoring
    lact # GUI for AMD GPU control
    radeontop # GPU utilization monitor
    nvtopPackages.amd # GPU process monitor

    # ROCm tools
    rocmPackages.rocm-smi # GPU management
    rocmPackages.rocminfo # GPU information

    # CPU tools
    ryzen-monitor-ng # Ryzen monitoring
    zenstates # Ryzen P-state control
    cpupower-gui # CPU frequency control
    linuxPackages.turbostat # CPU turbo monitoring

    # MSR tools
    msr-tools # rdmsr/wrmsr utilities
    cpufrequtils # CPU frequency utilities

    # Monitoring
    lm_sensors # Hardware sensors
    s-tui # Stress test and monitor
    corectrl # GPU/CPU control GUI

    # Terminal emulators requested
    kitty # GPU-accelerated terminal
    ghostty # Modern terminal

    # Additional tools
    pciutils # lspci
    usbutils # lsusb
    dmidecode # System info
    hwinfo # Hardware information

    # Benchmarking
    glmark2 # OpenGL benchmark
    vkmark # Vulkan benchmark
    unigine-heaven # GPU benchmark
    unigine-valley # GPU benchmark
    unigine-superposition # GPU benchmark
    stress-ng # System stress test
    sysbench # System benchmark
  ];

  # AMD P-state driver is configured in performance module

  # Udev rules for AMD GPU
  services.udev.packages = with pkgs; [
    lact # LACT udev rules
  ];

  # Additional udev rules for overclocking access
  services.udev.extraRules = ''
    # AMD GPU power management
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="manual", ATTR{device/pp_power_profile_mode}="1"

    # MSR access for overclocking tools
    KERNEL=="msr[0-9]*", GROUP="msr", MODE="0660"

    # Allow video group to access GPU performance counters
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
  '';

  # Enable lm_sensors
  systemd.services.lm_sensors = {
    description = "Initialize hardware monitoring sensors";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.lm_sensors}/bin/sensors-detect --auto";
    };
  };

  # CoreCtrl for GUI overclocking
  programs.corectrl = {
    enable = true;
  };

  # Enable AMD GPU overclocking
  hardware.amdgpu.overdrive = {
    enable = true;
    ppfeaturemask = "0xffffffff";
  };

  # AMD specific kernel configuration
  boot.kernelPatches = [
    {
      name = "amd-performance";
      patch = null;
      extraStructuredConfig = with lib.kernel; {
        PREEMPT = lib.mkForce yes;
        PREEMPT_VOLUNTARY = lib.mkForce no;
        HZ_1000 = lib.mkForce yes;
        HZ = lib.mkForce (freeform "1000");
      };
    }
  ];

  # Enable zenpower kernel module for enhanced Ryzen monitoring
  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
  ];

  # Blacklist k10temp to use zenpower instead
  boot.blacklistedKernelModules = ["k10temp"];

  # System performance settings
  systemd.services.amd-performance = {
    description = "AMD Performance Optimizations";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "amd-performance" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Function to safely write to sysfs
        safe_write() {
          local value="$1"
          local file="$2"
          if [[ -w "$file" ]]; then
            echo "$value" > "$file" && echo "✓ Set $file to $value" || echo "✗ Failed to set $file"
          else
            echo "⚠ $file not writable or doesn't exist"
          fi
        }

        echo "Starting AMD performance optimizations..."

        # Set GPU to high performance mode
        for card in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
          [[ -e "$card" ]] && safe_write "high" "$card"
        done

        # Set compute mode for better performance
        for card in /sys/class/drm/card*/device/pp_power_profile_mode; do
          [[ -e "$card" ]] && safe_write "1" "$card"
        done

        # CPU performance settings
        if command -v cpupower &> /dev/null; then
          ${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g performance && \
            echo "✓ Set CPU governor to performance" || \
            echo "✗ Failed to set CPU governor"
        else
          echo "⚠ cpupower not found"
        fi

        # Enable turbo boost
        if [[ -e /sys/devices/system/cpu/cpufreq/boost ]]; then
          safe_write "1" "/sys/devices/system/cpu/cpufreq/boost"
        fi

        # Set CPU to maximum performance
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          [[ -e "$cpu" ]] && safe_write "performance" "$cpu"
        done

        echo "AMD performance optimizations completed"
      ''}";
    };
  };

  # Environment variables for AMD
  environment.variables = {
    # Vulkan
    AMD_VULKAN_ICD = "RADV";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

    # OpenGL
    MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";

    # Video acceleration
    VDPAU_DRIVER = "radeonsi";
    LIBVA_DRIVER_NAME = "radeonsi";

    # Performance
    AMD_DEBUG = "nohyperz";
    RADV_PERFTEST = "nggc,sam,ngg_streamout";

    # ROCm
    ROCM_PATH = "/run/opengl-driver";
  };
}
