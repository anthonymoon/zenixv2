{ config
, pkgs
, lib
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./services.nix
    ./networking.nix
    ./users
    ./system/nix/full-cache.nix # Enable local Nix cache with optimizations
  ];

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos; # You may need to use a different kernel package
    kernelParams = [
      "apparmor=0"
      "cryptomgr.notests"
      "elevator=none"
      "fastboot"
      "i40e.enable_sw_lldp=0"
      "intel_iommu=on"
      "iommu=pt"
      "kvm_intel.nested=1"
      "loglevel=3"
      "mitigations=off"
      "nowatchdog"
      "nvidia-drm.modeset=1"
      "nvme_core.default_ps_max_latency_us=0"
      "pci=realloc=on"
      "pcie_aspm=off"
      "quiet"
      "random.trust_cpu=on"
      "rd.udev.log_level=3"
      "scsi_mod.use_blk_mq=1"
      "splash"
      "tsc=reliable"
      "zfs.zfs_autoimport_disable=1"
      "zswap.enabled=0"
    ];

    # Kernel modules
    blacklistedKernelModules = [ "nouveau" "amdgpu" "radeon" ];
    extraModulePackages = with config.boot.kernelPackages; [
      nvidia_x11
    ];

    # Kernel sysctl settings
    kernel.sysctl = {
      # Filesystem optimizations
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_instances" = 8192;
      "fs.inotify.max_user_watches" = 1048576;

      # Kernel security & performance
      "kernel.kptr_restrict" = 2;
      "kernel.perf_event_paranoid" = 3;
      "kernel.unprivileged_bpf_disabled" = 1;
      "kernel.randomize_va_space" = 2;
      "kernel.sysrq" = 0;
      "kernel.sched_autogroup_enabled" = 0;
      "kernel.numa_balancing" = 0;
      "kernel.shmmax" = 68719476736;
      "kernel.shmall" = 16777216;
      "kernel.msgmax" = 65536;
      "kernel.msgmni" = 32768;

      # Network core optimizations
      "net.core.bpf_jit_enable" = 1;
      "net.core.bpf_jit_harden" = 0;
      "net.core.rmem_default" = 67108864;
      "net.core.rmem_max" = 1073741824;
      "net.core.wmem_default" = 67108864;
      "net.core.wmem_max" = 1073741824;
      "net.core.netdev_max_backlog" = 500000;
      "net.core.netdev_budget" = 8000;
      "net.core.netdev_budget_usecs" = 100000;
      "net.core.busy_read" = 50;
      "net.core.busy_poll" = 50;
      "net.core.somaxconn" = 262144;
      "net.core.optmem_max" = 134217728;
      "net.core.default_qdisc" = "fq";

      # TCP optimizations
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_rmem" = "65536 16777216 1073741824";
      "net.ipv4.tcp_wmem" = "65536 16777216 1073741824";
      "net.ipv4.tcp_mem" = "16777216 33554432 268435456";
      "net.ipv4.tcp_max_syn_backlog" = 262144;
      "net.ipv4.tcp_max_tw_buckets" = 16000000;
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_timestamps" = 1;
      "net.ipv4.tcp_sack" = 1;
      "net.ipv4.tcp_fack" = 1;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_fin_timeout" = 10;
      "net.ipv4.tcp_keepalive_time" = 120;
      "net.ipv4.tcp_keepalive_probes" = 3;
      "net.ipv4.tcp_keepalive_intvl" = 10;
      "net.ipv4.tcp_retries1" = 2;
      "net.ipv4.tcp_retries2" = 5;
      "net.ipv4.tcp_synack_retries" = 2;
      "net.ipv4.tcp_syn_retries" = 2;
      "net.ipv4.tcp_adv_win_scale" = 2;
      "net.ipv4.tcp_moderate_rcvbuf" = 1;
      "net.ipv4.tcp_frto" = 2;
      "net.ipv4.tcp_low_latency" = 1;
      "net.ipv4.tcp_ecn" = 2;
      "net.ipv4.ip_local_port_range" = "1024 65535";

      # ARP table scaling
      "net.ipv4.neigh.default.gc_thresh1" = 4096;
      "net.ipv4.neigh.default.gc_thresh2" = 8192;
      "net.ipv4.neigh.default.gc_thresh3" = 16384;

      # Security settings
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv4.tcp_syncookies" = 1;

      # IPv6 optimizations
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.default.autoconf" = 0;
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.default.accept_ra" = 0;

      # Virtual memory optimizations
      "vm.swappiness" = 1;
      "vm.dirty_ratio" = 40;
      "vm.dirty_background_ratio" = 5;
      "vm.vfs_cache_pressure" = 50;
      "vm.max_map_count" = 262144;
      "vm.min_free_kbytes" = 131072;
      "vm.nr_hugepages" = 8192;
      "vm.hugetlb_shm_group" = 0;
      "vm.overcommit_memory" = 1;
      "vm.overcommit_ratio" = 80;
      "vm.zone_reclaim_mode" = 0;
    };

    # Support for ZFS
    supportedFilesystems = [ "zfs" "btrfs" ];
    zfs.forceImportRoot = false;
  };

  # Hardware configuration
  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
    };
    bluetooth.enable = true;
    enableRedistributableFirmware = true;
  };

  # System configuration
  system.stateVersion = "24.11";

  # Time zone and locale
  time.timeZone = "America/New_York"; # Adjust as needed
  i18n.defaultLocale = "en_US.UTF-8";

  # Console configuration
  console = {
    font = "ter-v32n";
    keyMap = "us";
  };

  # Enable firmware updates
  services.fwupd.enable = true;

  # Enable trim for SSDs
  services.fstrim.enable = true;

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };
}
