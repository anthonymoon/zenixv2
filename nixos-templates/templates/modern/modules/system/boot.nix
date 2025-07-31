# Boot and initrd configuration optimized for modern hardware
{ config
, lib
, pkgs
, ...
}: {
  # Essential boot configuration
  boot = {
    # Kernel modules for initrd
    initrd = {
      # Core modules needed for boot on modern systems
      availableKernelModules =
        [
          # Storage controllers (NVMe, SATA, USB)
          "nvme"
          "xhci_pci"
          "ehci_pci"
          "ahci"
          "usbhid"
          "usb_storage"
          "sd_mod"
          "sr_mod"

          # Network controllers for network boot/recovery
          "e1000e"
          "igb"
          "r8169"
          "8139too"

          # Filesystem support
          "ext4"
          "btrfs"
          "vfat"
          "ntfs"

          # Encryption support
          "dm_crypt"
          "dm_mod"
          "aesni_intel"
          "cryptd"
          "sha256_ssse3"
          "sha1_ssse3"

          # RAID support
          "md_mod"
          "raid0"
          "raid1"
          "raid10"
          "raid456"

          # LVM support
          "dm_snapshot"
          "dm_mirror"
          "dm_raid"

          # Input devices
          "hid_generic"
          "hid_lenovo"
          "hid_apple"
          "hid_roccat"
          "hid_logitech_hidpp"
        ]
        ++ lib.optionals (builtins.any (fs: fs == "zfs") (config.boot.supportedFilesystems or [ ])) [
          # ZFS modules
          "zfs"
          "spl"
          "znvpair"
          "zcommon"
          "zunicode"
          "zavl"
          "icp"
        ];

      # Kernel modules to load in initrd
      kernelModules = [
        # TPM modules for encrypted systems
        "tpm"
        "tpm_tis"
        "tpm_crb"
        "tpm_infineon"

        # Hardware monitoring
        "coretemp"
        "k10temp"

        # CPU features
        "msr"
        "cpuid"
      ];

      # Include essential tools in initrd
      extraUtilsCommands =
        ''
          # Filesystem tools
          copy_bin_and_libs ${pkgs.btrfs-progs}/bin/btrfs
          copy_bin_and_libs ${pkgs.e2fsprogs}/bin/e2fsck
          copy_bin_and_libs ${pkgs.e2fsprogs}/bin/resize2fs
          copy_bin_and_libs ${pkgs.util-linux}/bin/blkid
          copy_bin_and_libs ${pkgs.util-linux}/bin/mount
          copy_bin_and_libs ${pkgs.util-linux}/bin/umount
          copy_bin_and_libs ${pkgs.util-linux}/bin/lsblk
          copy_bin_and_libs ${pkgs.util-linux}/bin/wipefs

          # Disk tools
          copy_bin_and_libs ${pkgs.smartmontools}/bin/smartctl
          copy_bin_and_libs ${pkgs.hdparm}/bin/hdparm

          # Network tools (for debugging)
          copy_bin_and_libs ${pkgs.iproute2}/bin/ip
          copy_bin_and_libs ${pkgs.iputils}/bin/ping

          # System tools
          copy_bin_and_libs ${pkgs.pciutils}/bin/lspci
          copy_bin_and_libs ${pkgs.usbutils}/bin/lsusb
          copy_bin_and_libs ${pkgs.coreutils}/bin/lscpu

          # Text processing for debugging
          copy_bin_and_libs ${pkgs.gnugrep}/bin/grep
          copy_bin_and_libs ${pkgs.gnused}/bin/sed
          copy_bin_and_libs ${pkgs.gawk}/bin/awk
        ''
        + lib.optionalString (builtins.any (fs: fs == "zfs") (config.boot.supportedFilesystems or [ ])) ''
          # ZFS tools
          copy_bin_and_libs ${pkgs.zfs}/bin/zfs
          copy_bin_and_libs ${pkgs.zfs}/bin/zpool
          copy_bin_and_libs ${pkgs.zfs}/bin/zdb
        '';

      # Post device commands for optimization
      postDeviceCommands = lib.mkAfter ''
        # Set optimal queue depths and settings for NVMe devices
        for dev in /sys/class/block/nvme*/queue; do
          if [ -w "$dev/nr_requests" ]; then
            echo 2048 > "$dev/nr_requests" 2>/dev/null || true
          fi
          if [ -w "$dev/nomerges" ]; then
            echo 2 > "$dev/nomerges" 2>/dev/null || true
          fi
          if [ -w "$dev/rq_affinity" ]; then
            echo 2 > "$dev/rq_affinity" 2>/dev/null || true
          fi
          if [ -w "$dev/io_poll" ]; then
            echo 1 > "$dev/io_poll" 2>/dev/null || true
          fi
        done

        # Optimize SATA SSDs
        for dev in /sys/class/block/sd*/queue; do
          if [ -f "$(dirname "$dev")/queue/rotational" ] && [ "$(cat "$(dirname "$dev")/queue/rotational")" = "0" ]; then
            if [ -w "$dev/scheduler" ]; then
              echo mq-deadline > "$dev/scheduler" 2>/dev/null || true
            fi
            if [ -w "$dev/nr_requests" ]; then
              echo 1024 > "$dev/nr_requests" 2>/dev/null || true
            fi
          fi
        done

        # Enable TRIM for all SSDs early in boot
        for dev in /dev/sd? /dev/nvme?n?; do
          if [ -b "$dev" ]; then
            ${pkgs.util-linux}/bin/fstrim "$dev" 2>/dev/null || true &
          fi
        done
        wait
      '';

      # Network configuration for network boot/recovery
      network = {
        enable = lib.mkDefault false; # Enable if network boot is needed
        ssh = {
          enable = lib.mkDefault false;
          port = 22;
          authorizedKeys = [ ]; # Add your SSH keys here if needed
          hostKeys = [ ]; # Will generate automatically
        };
      };

      # SystemD in initrd for modern boot (optional, but recommended for encryption)
      systemd = {
        enable = lib.mkDefault false; # Enable for advanced features like TPM2 unlock
        emergencyAccess = "$6$rounds=1000000$..."; # Add password hash for emergency access

        # Services in initrd
        services = lib.mkIf config.boot.initrd.systemd.enable {
          # Emergency shell access
          emergency = {
            wants = [ "systemd-ask-password-console.service" ];
          };
        };
      };

      # Verbose logging during early boot (disable for faster boot)
      verbose = lib.mkDefault false;

      # Initrd compression (zstd is fastest to decompress)
      compressor = "zstd";
      compressorArgs = [ "-1" "-T0" ]; # Fast compression, all threads
    };

    # Use latest kernel for best hardware support
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Additional kernel modules for full system
    kernelModules = [
      # Virtualization
      "kvm-intel"
      "kvm-amd"

      # Hardware monitoring
      "coretemp"
      "k10temp"
      "nct6775" # Common motherboard sensor chip
      "it87" # Another common sensor chip

      # Performance monitoring
      "msr"
      "cpuid"

      # Network
      "tcp_bbr" # BBR congestion control

      # Security (optional)
      # "tpm_rng"  # TPM random number generator
    ];

    # Blacklist problematic or unnecessary modules
    blacklistedKernelModules = [
      # Disable PC speaker
      "pcspkr"
      "snd_pcsp"

      # Disable floppy (ancient)
      "floppy"

      # Disable parallel port (ancient)
      "parport"
      "parport_pc"

      # Disable serial port (usually not needed)
      # "8250_pci"

      # Disable wireless if not needed (saves power)
      # "iwlwifi"
      # "ath9k"
      # "rtw88"

      # Disable bluetooth if not needed
      # "bluetooth"
      # "btusb"

      # Disable webcam if not needed (privacy/security)
      # "uvcvideo"
    ];

    # Extra module configuration
    extraModprobeConfig = ''
      # NVMe optimizations
      options nvme poll_queues=8
      options nvme_core default_ps_max_latency_us=0 io_timeout=4294967295

      # Network driver optimizations
      options e1000e InterruptThrottleRate=1 IntMode=1
      options igb RSS=8,8,8,8,8,8,8,8
      options r8169 use_dac=1

      # USB optimizations
      options usbcore autosuspend=-1

      # SATA optimizations
      options libata force=3.0Gbps  # Force SATA 3.0 if detection fails

      # CPU frequency scaling optimizations
      options intel_pstate hwp_only=1 no_hwp=0
      options amd_pstate shared_mem=1

      # Sound optimization (reduce latency)
      options snd-hda-intel power_save=0 power_save_controller=N

      # Graphics optimizations
      options i915 enable_fbc=1 enable_psr=1 disable_power_well=0
      options amdgpu ppfeaturemask=0xffffffff

      # Network security
      options ipv6 disable=0  # Keep IPv6 enabled (disabling can cause issues)

      # Filesystem optimizations
      options btrfs skip_balance_on_resume=1
    '';

    # Kernel command line parameters
    kernelParams = [
      # Boot performance
      "quiet" # Reduce boot messages
      "loglevel=3" # Reduce kernel log verbosity
      "rd.udev.log_level=3" # Reduce udev verbosity
      "rd.systemd.show_status=false" # Hide systemd status during boot
      "splash" # Show splash screen instead of text

      # CPU optimizations
      "intel_pstate=active" # Use Intel P-State (Intel CPUs)
      "amd_pstate=active" # Use AMD P-State (AMD CPUs)
      "processor.max_cstate=1" # Limit C-states for lower latency
      "intel_idle.max_cstate=1" # Intel-specific C-state limit

      # Memory optimizations
      "transparent_hugepage=madvise" # Enable THP only on request
      "hugepagesz=2M" # Use 2MB huge pages
      "default_hugepagesz=2M"

      # Security vs Performance (choose based on needs)
      "mitigations=off" # Disable CPU vulnerability mitigations (PERFORMANCE)
      # "mitigations=auto"       # Enable all mitigations (SECURITY)

      # Hardware optimizations
      "pcie_aspm=off" # Disable PCIe power management for performance
      "pci=realloc=on" # Enable PCI resource reallocation
      "intel_iommu=on" # Enable Intel IOMMU (if supported)
      "iommu=pt" # Use passthrough mode for better performance

      # Network optimizations
      "ipv6.disable=0" # Keep IPv6 enabled

      # Storage optimizations
      "elevator=none" # No I/O scheduler for NVMe
      "nvme_core.default_ps_max_latency_us=0" # Disable NVMe power saving

      # System responsiveness
      "nowatchdog" # Disable hardware watchdog
      "nmi_watchdog=0" # Disable NMI watchdog
      "rcu_nocbs=0-$(nproc)" # RCU no-callback mode for all CPUs

      # Random number generation
      "random.trust_cpu=on" # Trust CPU RNG
      "rng_core.default_quality=1000" # High quality RNG

      # Time management
      "tsc=reliable" # Trust TSC clocksource
      "clocksource=tsc" # Use TSC as primary clocksource
      "highres=on" # Enable high-resolution timers
      "nohz=on" # Enable tickless kernel
      "nohz_full=1-$(nproc)" # Tickless mode for all CPUs except 0

      # Memory management
      "zswap.enabled=0" # Disable zswap (we use zram instead)
      "vm.zone_reclaim_mode=0" # Disable zone reclaim
    ];

    # Boot loader configuration
    loader = {
      # Timeout for boot menu
      timeout = lib.mkDefault 3;

      # SystemD-boot configuration (recommended for UEFI)
      systemd-boot = {
        enable = lib.mkDefault true;

        # Limit stored configurations to save space
        configurationLimit = lib.mkDefault 20;

        # Disable boot menu editor for security
        editor = lib.mkDefault false;

        # Console mode for better compatibility
        consoleMode = lib.mkDefault "auto";

        # Memory test
        memtest86.enable = lib.mkDefault false; # Disable to save space
      };

      # EFI settings
      efi = {
        canTouchEfiVariables = lib.mkDefault true;
        efiSysMountPoint = "/boot";
      };
    };

    # Temporary filesystem in RAM
    tmp = {
      useTmpfs = lib.mkDefault true; # Use tmpfs for /tmp (faster)
      tmpfsSize = "50%"; # Use up to 50% of RAM
      cleanOnBoot = lib.mkDefault true; # Clean /tmp on boot
    };

    # Console configuration
    consoleLogLevel = 3; # Reduce console log verbosity

    # Plymouth for boot splash (optional)
    plymouth = {
      enable = lib.mkDefault false; # Enable for graphical boot splash
      theme = "breeze"; # KDE theme
    };
  };
}
