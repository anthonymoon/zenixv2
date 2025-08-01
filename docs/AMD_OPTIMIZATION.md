# AMD CPU & GPU Optimization Guide

## Overview

This configuration provides comprehensive AMD Ryzen CPU and Radeon GPU optimization with monitoring and overclocking tools.

## Features Added

### GPU Tools
- **amdgpu_top** - Real-time AMD GPU monitoring TUI
- **LACT** - Linux AMDGPU Control Application (GUI)
- **radeontop** - GPU utilization monitor
- **CoreCtrl** - GPU/CPU control GUI with overclocking

### CPU Tools
- **ryzen-monitor-ng** - Ryzen-specific monitoring
- **zenstates** - Ryzen P-state control
- **cpupower-gui** - CPU frequency control
- **MSR tools** - Direct MSR access for overclocking

### Terminal Emulators
- **Kitty** - GPU-accelerated terminal
- **Ghostty** - Modern terminal emulator

## AMD 7800 XT Optimizations

### Kernel Parameters
```
amdgpu.ppfeaturemask=0xffffffff  # Enable all power features
amdgpu.gpu_recovery=1            # Enable GPU recovery
amdgpu.deep_color=1              # 10-bit color support
amdgpu.vm_update_mode=3          # CPU update mode (better performance)
amdgpu.smu_memory_pool_size=512  # Larger SMU memory pool
amd_pstate=active                # Active P-state for Ryzen
```

### Performance Features
- Full power profile control
- Deep color (10-bit) support
- Experimental hardware features enabled
- Optimized memory management
- High priority compute queues

## Overclocking Support

### MSR Access
The configuration enables writable MSRs for CPU overclocking:
- MSR module auto-loaded
- MSR devices accessible to `msr` group
- User automatically added to `msr` group

### GPU Overclocking
- CoreCtrl enabled with full ppfeaturemask
- LACT for fine-grained GPU control
- Power profiles unlocked

## Monitoring Tools

### GPU Monitoring
```bash
# Real-time GPU stats
amdgpu_top

# GUI control
lact

# Utilization monitor
radeontop

# ROCm SMI
rocm-smi
```

### CPU Monitoring
```bash
# Ryzen-specific monitoring
ryzen-monitor-ng

# P-state control
sudo zenstates

# CPU frequency
cpupower-gui

# Sensors
sensors
```

## Performance Profiles

### High Performance Mode
Automatically enabled on boot:
- GPU set to `high` performance
- CPU governor set to `performance`
- Turbo boost enabled
- All cores at maximum frequency

### Manual Control
```bash
# Set GPU to compute mode
echo 1 > /sys/class/drm/card0/device/pp_power_profile_mode

# Set CPU to max performance
sudo cpupower frequency-set -g performance
```

## Benchmarking Tools

The configuration includes:
- **glmark2** - OpenGL benchmark
- **vkmark** - Vulkan benchmark
- **unigine-heaven/valley/superposition** - GPU stress tests
- **stress-ng** - System stress test
- **sysbench** - System benchmark

## Environment Variables

Optimized for AMD hardware:
```bash
AMD_VULKAN_ICD=RADV              # Use RADV driver
MESA_LOADER_DRIVER_OVERRIDE=radeonsi
RADV_PERFTEST=nggc,sam,ngg_streamout
```

## nixos-hardware Integration

The configuration imports `nixos-hardware.nixosModules.common-gpu-amd` which provides:
- Additional firmware
- Kernel patches
- Udev rules
- Power management optimizations

## Usage Examples

### Check GPU Status
```bash
# Real-time monitoring
amdgpu_top

# Detailed GPU info
rocm-smi

# Check current power profile
cat /sys/class/drm/card0/device/pp_power_profile_mode
```

### CPU Overclocking
```bash
# Check current P-states
sudo zenstates -l

# Monitor CPU frequency
watch -n 1 "cpupower frequency-info"

# Stress test
stress-ng --cpu 12 --timeout 60s
```

### GPU Overclocking
```bash
# Launch LACT GUI
lact

# Or use CoreCtrl
corectrl
```

## Troubleshooting

### GPU Not Detected
```bash
# Check kernel module
lsmod | grep amdgpu

# Check device
lspci -v | grep -A 20 "VGA\|Display"
```

### Performance Issues
```bash
# Verify performance mode
cat /sys/class/drm/card0/device/power_dpm_force_performance_level

# Check thermal throttling
sensors
```

### MSR Access Denied
```bash
# Verify group membership
groups | grep msr

# Re-login or run
newgrp msr
```

## Safety Notes

- Monitor temperatures when overclocking
- Start with small increments
- Test stability with stress tools
- Keep stock profiles for recovery
- BIOS settings may limit some features