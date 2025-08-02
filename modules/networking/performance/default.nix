# Network performance optimizations for 20Gbps
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.networking.performance;
  # Helper to check if a value is a power of 2
  isPowerOf2 = n: n != 0 && (builtins.bitAnd n (n - 1)) == 0;
in {
  options.networking.performance = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable network performance optimizations";
    };

    targetBandwidth = lib.mkOption {
      type = lib.types.str;
      default = "20Gbps";
      description = "Target network bandwidth for optimizations";
    };

    enableBBR = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TCP BBR congestion control";
    };

    bufferSize = lib.mkOption {
      type = lib.types.int;
      default = 134217728; # 128MB
      description = "Network buffer size in bytes";
    };
  };

  config = lib.mkIf cfg.enable {
  # Kernel parameters optimized for 20Gbps networking
  boot.kernel.sysctl = {
    # Core network settings
    "net.core.netdev_max_backlog" = 5000;
    "net.core.rmem_max" = cfg.bufferSize;
    "net.core.wmem_max" = cfg.bufferSize;
    "net.core.rmem_default" = cfg.bufferSize / 2;
    "net.core.wmem_default" = cfg.bufferSize / 2;
    "net.core.optmem_max" = cfg.bufferSize;

    # Enable receive packet steering
    "net.core.rps_sock_flow_entries" = 32768;

    # TCP settings for high throughput
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_no_metrics_save" = 1;
    "net.ipv4.tcp_moderate_rcvbuf" = 1;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_window_scaling" = 1;

    # IP settings
    "net.ipv4.ip_forward" = 0;
    "net.ipv4.conf.all.forwarding" = 0;
    "net.ipv4.conf.default.forwarding" = 0;

    # Increase socket buffer sizes
    "net.core.somaxconn" = 4096;
    "net.ipv4.tcp_max_syn_backlog" = 8192;

    # Enable TCP BBR congestion control
    "net.core.default_qdisc" = "fq";

    # Increase the tcp-time-wait buckets pool size
    "net.ipv4.tcp_max_tw_buckets" = 2000000;

    # Reuse TIME-WAIT sockets faster
    "net.ipv4.tcp_tw_reuse" = 1;

    # Increase the maximum memory used to reassemble IP fragments
    "net.ipv4.ipfrag_high_thresh" = 8388608;
    "net.ipv4.ipfrag_low_thresh" = 6291456;

    # Increase TCP queue length
    "net.ipv4.neigh.default.gc_thresh1" = 2048;
    "net.ipv4.neigh.default.gc_thresh2" = 4096;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;

    # ARP cache settings
    "net.ipv4.neigh.default.gc_interval" = 30;
    "net.ipv4.neigh.default.gc_stale_time" = 120;

    # Interface specific settings
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
  };

  # Enable kernel modules for better network performance
  boot.kernelModules = [
    "tcp_bbr" # BBR congestion control
  ];

  # CPU affinity and interrupt handling
  systemd.services.network-tuning = {
    description = "Network Performance Tuning";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    script = ''
      # Set CPU affinity for network interrupts
      # This spreads interrupts across all CPU cores

      # Enable RFS (Receive Flow Steering)
      echo 32768 > /proc/sys/net/core/rps_sock_flow_entries

      # Network tuning is now handled by intel-x710 module
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Install network performance tools
  environment.systemPackages = with pkgs; [
    ethtool
    iperf3
    nload
    iftop
    nethogs
    bmon
  ];

  # Assertions
  assertions = [
    {
      assertion = cfg.bufferSize >= 67108864; # 64MB minimum
      message = "Network buffer size should be at least 64MB for high-performance networking";
    }
    {
      assertion = cfg.bufferSize <= 2147483648; # 2GB maximum
      message = "Network buffer size should not exceed 2GB to avoid memory issues";
    }
    {
      assertion = isPowerOf2 cfg.bufferSize;
      message = "Network buffer size should be a power of 2 for optimal performance";
    }
  ];
  };
}
