# Network performance optimizations for 20Gbps
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Kernel parameters optimized for 20Gbps networking
  boot.kernel.sysctl = {
    # Core network settings
    "net.core.netdev_max_backlog" = 5000;
    "net.core.rmem_max" = 134217728; # 128MB
    "net.core.wmem_max" = 134217728; # 128MB
    "net.core.rmem_default" = 67108864; # 64MB
    "net.core.wmem_default" = 67108864; # 64MB
    "net.core.optmem_max" = 134217728; # 128MB

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
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      # Set CPU affinity for network interrupts
      # This spreads interrupts across all CPU cores

      # Enable RPS (Receive Packet Steering) for bond0
      echo ffff > /sys/class/net/bond0/queues/rx-0/rps_cpus 2>/dev/null || true

      # Enable RFS (Receive Flow Steering)
      echo 32768 > /proc/sys/net/core/rps_sock_flow_entries

      # Set ring buffer sizes for Intel i40e
      for iface in enp4s0f0np0 enp4s0f1np1; do
        if [ -d "/sys/class/net/$iface" ]; then
          ${pkgs.ethtool}/bin/ethtool -G $iface rx 4096 tx 4096 2>/dev/null || true
          ${pkgs.ethtool}/bin/ethtool -K $iface rx-checksumming on tx-checksumming on sg on tso on gso on gro on lro on 2>/dev/null || true
          ${pkgs.ethtool}/bin/ethtool -C $iface rx-usecs 10 tx-usecs 10 2>/dev/null || true
        fi
      done
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
}
