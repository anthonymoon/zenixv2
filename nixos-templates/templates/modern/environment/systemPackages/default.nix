{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Core system utilities
    coreutils
    util-linux
    procps
    psmisc
    findutils
    gnugrep
    gawk
    gnused
    diffutils
    patch
    which
    file

    # System tools
    systemd
    shadow
    pam
    kbd
    kmod

    # Compression
    gzip
    bzip2
    xz
    zstd

    # Archives
    gnutar
    cpio
    zip
    unzip

    # Text editors (minimal)
    nano
    vim

    # Networking basics
    inetutils
    iputils
    iproute2
    iptables
    nftables
    ethtool
    tcpdump
    netcat
    socat
    openssh
    curl
    wget
    rsync

    # DNS tools
    bind
    dnsutils

    # System monitoring
    htop
    iotop
    iftop
    lsof
    strace
    sysstat
    dool

    # Hardware tools
    pciutils
    usbutils
    lshw
    hwinfo
    dmidecode
    lm_sensors
    smartmontools
    hdparm
    sdparm
    nvme-cli

    # Filesystem tools
    e2fsprogs
    xfsprogs
    btrfs-progs
    dosfstools
    ntfs3g
    nfs-utils
    parted
    gptfdisk
    lvm2
    mdadm
    cryptsetup

    # Process management
    psmisc
    killall

    # Time
    chrony
    tzdata

    # Logs
    rsyslog
    logrotate
    # journalctl is part of systemd (already included above)

    # Package management
    nix
    nix-index

    # Shell basics
    bash
    bash-completion

    # Man pages
    man-db
    man-pages

    # Security basics
    sudo
    openssl
    cacert
    gnupg

    # Service management
    systemctl

    # Basic debugging
    gdb
    valgrind
    perf-tools

    # Kernel tools
    kexec-tools
    kernel-config

    # Boot
    grub2
    efibootmgr
    efivar

    # Other essentials
    bc
    tree
    less
    moreutils
    jq
    yq
    ripgrep
    fd
    tmux
    screen
    git

    # System info
    neofetch
    inxi

    # Cron
    cronie

    # Mail
    mailutils
    postfix

    # Performance
    cpupower
    powertop
    turbostat
    irqbalance
    numactl

    # Virtualization (if needed for servers)
    qemu
    libvirt

    # Container runtime (if needed)
    docker
    podman

    # Backup tools
    borgbackup
    restic

    # Remote management
    cockpit
  ];
}
