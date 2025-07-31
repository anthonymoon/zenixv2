# System-wide performance optimizations for NVMe and modern hardware
{ config
, lib
, pkgs
, ...
}: {
  # ZRAM swap configuration (16GB compressed)
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = "zstd";
    memoryPercent = 50; # Use up to 50% of RAM for zram
    memoryMax = 16 * 1024 * 1024 * 1024; # Max 16GB
    priority = 5; # Higher priority than disk swap
  };

  # Kernel parameters for better performance
  boot.kernel.sysctl = {
    # VM tuning for NVMe systems
    "vm.swappiness" = 10; # Prefer RAM over swap
    "vm.vfs_cache_pressure" = 50; # Keep file cache longer
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_expire_centisecs" = 6000; # 60 seconds
    "vm.dirty_writeback_centisecs" = 50; # 0.5 seconds for NVMe
    "vm.page-cluster" = 0; # Disable page clustering for SSD

    # Network performance
    "net.core.default_qdisc" = "cake"; # Modern queue discipline
    "net.ipv4.tcp_congestion_control" = "bbr"; # BBR congestion control
    "net.core.rmem_default" = 262144;
    "net.core.rmem_max" = 67108864;
    "net.core.wmem_default" = 262144;
    "net.core.wmem_max" = 67108864;

    # General responsiveness
    "kernel.sched_autogroup_enabled" = 1;
    "kernel.sched_migration_cost_ns" = 5000000; # 5ms
    "kernel.sched_min_granularity_ns" = 10000000; # 10ms
    "kernel.sched_wakeup_granularity_ns" = 15000000; # 15ms

    # File system optimizations
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_user_watches" = 1048576;
  };

  # NVMe-specific kernel parameters
  boot.kernelParams = [
    # NVMe optimizations
    "nvme_core.default_ps_max_latency_us=0" # Disable power saving
    "nvme_core.io_timeout=4294967295" # Max I/O timeout
    "nvme.poll_queues=8" # Number of poll queues

    # I/O scheduler optimizations
    "elevator=none" # No scheduler for NVMe (they handle queuing internally)

    # CPU performance optimizations
    "mitigations=off" # Disable CPU vulnerability mitigations (performance over security)
    "nowatchdog" # Disable watchdog
    "nmi_watchdog=0" # Disable NMI watchdog

    # Memory optimizations
    "transparent_hugepage=madvise" # Enable THP only on request
    "hugepagesz=2M" # Use 2MB huge pages
    "default_hugepagesz=2M"

    # Boot performance
    "quiet" # Reduce boot messages
    "loglevel=3" # Reduce kernel log verbosity
    "rd.udev.log_level=3" # Reduce udev log verbosity

    # Power management
    "intel_pstate=active" # Use Intel P-State driver (Intel CPUs)
    "amd_pstate=active" # Use AMD P-State driver (AMD CPUs)
  ];

  # I/O scheduler optimization via udev rules
  services.udev.extraRules = ''
    # NVMe: use none scheduler (no queuing needed, NVMe handles internally)
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="2048"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/io_poll}="1"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/io_poll_delay}="-1"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nomerges}="2"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/rq_affinity}="2"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/wbt_lat_usec}="75000"

    # SATA SSD: use mq-deadline for better fairness
    ACTION=="add|change", KERNEL=="sd[a-z]|hd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]|hd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/nr_requests}="1024"
    ACTION=="add|change", KERNEL=="sd[a-z]|hd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/read_ahead_kb}="128"

    # HDD: use bfq for better fairness with mixed workloads
    ACTION=="add|change", KERNEL=="sd[a-z]|hd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]|hd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/nr_requests}="128"
    ACTION=="add|change", KERNEL=="sd[a-z]|hd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/read_ahead_kb}="512"

    # Set appropriate I/O nice levels for system processes
    ACTION=="add|change", SUBSYSTEM=="block", ATTR{queue/scheduler}=="none", RUN+="${pkgs.util-linux}/bin/ionice -c 1 -n 4 -p 1"
  '';

  # CPU frequency scaling
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance"; # Use performance governor by default
    powertop.enable = false; # Disable powertop auto-tuning (can hurt performance)
  };

  # Hardware-specific optimizations
  hardware = {
    # Enable CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkDefault true;
    cpu.amd.updateMicrocode = lib.mkDefault true;

    # Enable all firmware
    enableAllFirmware = lib.mkDefault true;
    enableRedistributableFirmware = lib.mkDefault true;
  };

  # Systemd optimizations
  systemd = {
    # Reduce systemd overhead
    services = {
      # Optimize systemd-journald for NVMe
      systemd-journald.serviceConfig = {
        SystemMaxUse = "500M";
        SystemKeepFree = "1G";
        SystemMaxFileSize = "50M";
        SystemMaxFiles = 10;
        # Reduce sync frequency for NVMe
        SyncIntervalSec = "30s";
        # Enable compression
        Compress = "yes";
      };

      # Optimize systemd-logind
      systemd-logind.serviceConfig = {
        # Reduce polling frequency
        RuntimeDirectorySize = "10%";
        RemoveIPC = "yes";
      };
    };

    # Systemd sleep/hibernate settings
    sleep.extraConfig = ''
      # Disable hibernate (use suspend-to-RAM only)
      AllowHibernation=no
      AllowSuspendThenHibernate=no
      # Optimize suspend
      HibernateDelaySec=0
      SuspendState=mem
    '';

    # Reduce coredump size limits
    coredump.extraConfig = ''
      # Limit coredump size to save space
      ProcessSizeMax=2G
      ExternalSizeMax=2G
      MaxUse=5G
      KeepFree=1G
    '';
  };

  # Nix-specific optimizations
  nix = {
    # Performance optimizations for Nix
    settings = {
      # Use all available cores for building
      max-jobs = "auto";
      cores = 0; # Use all available cores per job

      # Keep build outputs and derivations for performance
      keep-outputs = true;
      keep-derivations = true;

      # Enable builders to use substitutes
      builders-use-substitutes = true;

      # Network optimizations
      connect-timeout = 5;
      download-attempts = 3;

      # Store optimizations
      auto-optimise-store = lib.mkDefault true;

      # Sandbox optimizations
      sandbox = lib.mkDefault true;
      extra-sandbox-paths = [
        "/etc/nsswitch.conf"
        "/etc/protocols"
        "/etc/services"
        "/etc/hosts"
        "/etc/resolv.conf"
      ];
    };

    # Garbage collection optimization
    gc = {
      automatic = lib.mkDefault true;
      dates = "weekly";
      options = "--delete-older-than 14d";
      persistent = true;
    };

    # Store optimization
    optimise = {
      automatic = lib.mkDefault true;
      dates = [ "weekly" ];
    };
  };

  # Environment optimizations
  environment = {
    # Set system-wide environment variables for performance
    sessionVariables = {
      # Use all CPU cores for compression
      XZ_OPT = "-T0";
      ZSTD_NBTHREADS = "0";

      # Optimize for NVMe storage
      TMPDIR = "/tmp";

      # Browser optimizations
      MOZ_USE_XINPUT2 = "1"; # Firefox touchpad scrolling
      NIXOS_OZONE_WL = "1"; # Chromium Wayland support
    };

    # System packages for performance monitoring
    systemPackages = with pkgs; [
      # Performance monitoring tools
      htop
      iotop
      iftop
      nethogs
      nmon

      # Disk utilities
      smartmontools
      nvme-cli

      # Network utilities
      speedtest-cli
      bandwhich

      # System utilities
      pciutils
      usbutils
      lshw

      # Compression tools with threading support
      pigz # Parallel gzip
      pbzip2 # Parallel bzip2
      pixz # Parallel xz
    ];
  };

  # Enable performance monitoring services
  services = {
    # Enable SMART monitoring for disk health
    smartd = {
      enable = true;
      autodetect = true;
      notifications = {
        wall.enable = false; # Disable wall notifications
        mail.enable = false; # Disable mail notifications (add your email if needed)
      };
    };

    # Tune system for performance
    irqbalance.enable = true; # Balance IRQs across CPUs

    # Disable unnecessary services for performance
    udisks2.enable = lib.mkDefault false; # Auto-mounting (usually not needed on servers)
    accounts-daemon.enable = lib.mkDefault false; # User account service

    # Enable automatic TRIM for SSDs
    fstrim = {
      enable = lib.mkDefault true;
      interval = "weekly";
    };
  };

  # Boot optimizations
  boot = {
    # Use latest kernel for best hardware support and performance
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Optimize initrd
    initrd = {
      # Compress initrd with fast algorithm
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ]; # High compression, all threads

      # Optimize module loading
      availableKernelModules = [
        # Storage controllers
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"

        # Network (for network boot/install)
        "e1000e"
        "r8169"

        # Filesystems
        "ext4"
        "btrfs"
        "vfat"
      ];

      # Reduce initrd size by excluding unnecessary modules
      includeDefaultModules = false;
    };

    # Boot loader optimizations
    loader = {
      # Reduce boot timeout
      timeout = lib.mkDefault 2;

      # SystemD-boot optimizations
      systemd-boot = {
        # Limit number of generations to save space
        configurationLimit = lib.mkDefault 20;
        # Disable boot editor for faster boot
        editor = lib.mkDefault false;
      };
    };

    # Kernel module optimizations
    kernelModules = [
      # CPU-specific modules (loaded automatically but explicitly listed)
      "kvm-intel"
      "kvm-amd"

      # Performance monitoring
      "msr" # Model-specific registers
      "cpuid" # CPU identification

      # Hardware monitoring
      "coretemp" # CPU temperature
      "k10temp" # AMD temperature
    ];

    # Blacklist problematic modules
    blacklistedKernelModules = [
      # Disable CPU vulnerabilities mitigations modules for performance
      # (Only if you understand the security implications)
      "iTCO_wdt" # Intel watchdog (can cause issues)
      "sp5100_tco" # AMD watchdog

      # Disable bluetooth if not needed (saves power/resources)
      # "bluetooth"
      # "btusb"
    ];

    # Additional module parameters
    extraModprobeConfig = ''
      # NVMe optimizations
      options nvme poll_queues=8
      options nvme_core default_ps_max_latency_us=0

      # Network optimizations
      options e1000e InterruptThrottleRate=1
      options r8169 use_dac=1

      # Disable PC speaker
      blacklist pcspkr
      blacklist snd_pcsp

      # CPU frequency scaling
      options intel_pstate hwp_only=1
      options amd_pstate shared_mem=1
    '';

    # Temporary filesystem optimizations
    tmp = {
      useTmpfs = lib.mkDefault true; # Use tmpfs for /tmp (faster, but uses RAM)
      tmpfsSize = "50%"; # Use up to 50% of RAM for /tmp
      cleanOnBoot = lib.mkDefault true;
    };
  };

  # Security optimizations (performance-focused)
  security = {
    # Optimize AppArmor for performance
    apparmor = {
      enable = lib.mkDefault false; # Disable for performance (enable if security is critical)
    };

    # Optimize audit system
    audit = {
      enable = lib.mkDefault false; # Disable for performance
    };

    # PAM optimizations
    pam = {
      # Increase limits for better performance
      loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "65536";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "65536";
        }
        {
          domain = "*";
          type = "soft";
          item = "nproc";
          value = "32768";
        }
        {
          domain = "*";
          type = "hard";
          item = "nproc";
          value = "32768";
        }
      ];
    };
  };
}
