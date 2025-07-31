{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # System management
    systemd
    systemctl
    journalctl

    # Service management
    supervisor

    # Cron replacements
    cronie

    # System information
    uname
    hostnamectl
    timedatectl
    localectl

    # User management
    shadow

    # PAM tools
    pam

    # SELinux tools (if used)
    # selinux-utils
    # policycoreutils

    # Audit tools
    audit

    # Performance tuning
    tuned

    # System configuration
    util-linux

    # Init system tools
    systemd-analyze

    # Logging
    rsyslog
    logrotate

    # NFS tools
    nfs-utils

    # Disk management
    util-linux

    # Web-based management
    cockpit
    cockpit-machines
    cockpit-storaged
    cockpit-networkmanager
    cockpit-packagekit
  ];
}
