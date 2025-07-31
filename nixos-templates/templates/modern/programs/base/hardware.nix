{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # CPU management
    cpupower
    powertop
    turbostat

    # Storage tools
    hdparm
    sdparm
    smartmontools
    nvme-cli

    # System stress testing
    stress
    stress-ng
    s-tui

    # Performance monitoring
    perf-tools
    irqbalance

    # Firmware and drivers
    fwupd
    broadcom_sta

    # RAID/LVM
    mdadm
    lvm2

    # Kernel modules management
    kmod
  ];
}
