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

    # Basic tools
    bc
    less
    which
    tree
    moreutils

    # Compression tools
    gzip
    bzip2
    xz
    zip
    unzip
    p7zip
    unrar
    zstd

    # Text editors
    nano
    vim

    # File system tools
    e2fsprogs
    xfsprogs
    btrfs-progs
    dosfstools
    ntfs3g
    exfat
    exfatprogs
    f2fs-tools
    jfsutils
    reiserfsprogs
    squashfs-tools
    mtools
    fatresize

    # Hardware tools
    pciutils
    usbutils
    lshw
    hwinfo
    lm_sensors

    # Network basics
    inetutils
    iputils
    net-tools
    curl
    wget

    # System info
    htop
    iotop
    iftop
    lsof

    # Disk management
    parted
    gptfdisk
    testdisk

    # Process management
    killall

    # Archive tools
    cpio
    tar

    # Other essentials
    file
    findutils
    gnugrep
    gawk
    gnused
    diffutils
    patch

    # Time and date
    chrony
    tzdata

    # Manual pages
    man-db
    man-pages
  ];
}
