{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Base system tools
    alsa-firmware
    alsa-plugins
    alsa-utils
    arch-install-scripts
    bash-completion
    bc
    bind
    broadcom_sta
    btrfs-progs
    cdrtools
    chezmoi
    coreutils
    cpupower
    curl
    dnsmasq
    dosfstools
    e2fsprogs
    efibootmgr
    ethtool
    exfat
    exfatprogs
    f2fs-tools
    fatresize
    fuse3
    git
    gnupg
    gptfdisk
    hdparm
    htop
    btop
    hwinfo
    iftop
    inetutils
    iotop
    iperf3
    iproute2
    iptables
    iputils
    irqbalance
    jfsutils
    jq
    killall
    lm_sensors
    lsd
    lshw
    lsof
    lsscsi
    ltrace
    lvm2
    mdadm
    msr-tools
    mtools
    ncdu
    nfs-utils
    nmap
    ntfs3g
    nvme-cli
    ocfs2-tools
    p7zip
    parted
    pciutils
    perf-tools
    powertop
    pv
    ranger
    reiserfsprogs
    rsync
    sdparm
    sg3_utils
    smartmontools
    socat
    sshfs
    strace
    sysstat
    tcpdump
    testdisk
    tldr
    tmux
    tree
    udisks2
    unrar
    unzip
    usbutils
    vim
    wget
    which
    xfsprogs
    xterm
    zip
    zsh

    # Development tools
    gcc
    gnumake
    python3
    rustc
    cargo

    # Container tools
    podman
    podman-compose
    docker-compose

    # Virtualization
    virt-manager
    virt-viewer
    qemu
    OVMF

    # Media tools
    ffmpeg

    # Text editors
    nano
    neovim
  ];

  # Shell configuration
  programs.fish.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "docker" "kubectl" ];
    };
  };

  # Font packages
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
  ];
}
