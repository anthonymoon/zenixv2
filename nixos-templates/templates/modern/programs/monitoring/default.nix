{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
    btop
    gtop
    glances

    # Process monitoring
    iotop
    atop

    # Network monitoring
    iftop
    nethogs
    vnstat

    # GPU monitoring
    nvtop
    nvidia-smi

    # Disk monitoring
    ncdu
    duf

    # System information
    neofetch
    inxi

    # Performance monitoring
    s-tui
    gotop

    # Log monitoring
    lnav
    multitail

    # Resource usage
    dstat
    sysstat

    # Temperature monitoring
    lm_sensors
    thermald
  ];
}
