{ config
, lib
, pkgs
, ...
}: {
  boot.kernel.sysctl = {
    # Network Performance Tuning
    "net.core.netdev_max_backlog" = 16384;
    "net.core.netdev_budget" = 50000;
    "net.core.netdev_budget_usecs" = 5000;
    "net.core.somaxconn" = 65535;
    "net.core.rmem_default" = 1048576;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_default" = 1048576;
    "net.core.wmem_max" = 16777216;
    "net.core.optmem_max" = 65536;
    "net.ipv4.tcp_rmem" = "4096 1048576 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.udp_rmem_min" = 8192;
    "net.ipv4.udp_wmem_min" = 8192;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 6;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_adv_win_scale" = 1;
    "net.ipv4.tcp_moderate_rcvbuf" = 1;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_notsent_lowat" = 16384;
    "net.ipv4.tcp_no_metrics_save" = 1;
    "net.ipv4.tcp_ecn" = 2;
    "net.ipv4.tcp_ecn_fallback" = 1;
    "net.ipv4.tcp_syncookies" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.ipv4.tcp_mem" = "786432 1048576 16777216";
    "net.ipv4.udp_mem" = "786432 1048576 16777216";
    "net.ipv4.tcp_fin_timeout" = 10;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.ip_local_port_range" = "1024 65535";
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_max_tw_buckets" = 2000000;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_syn_retries" = 2;
    "net.ipv4.tcp_synack_retries" = 2;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.neigh.default.gc_thresh1" = 80000;
    "net.ipv4.neigh.default.gc_thresh2" = 90000;
    "net.ipv4.neigh.default.gc_thresh3" = 100000;
    "net.ipv4.tcp_retries2" = 8;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;

    # Security hardening
    "kernel.kptr_restrict" = 1;
    "kernel.dmesg_restrict" = 1;
    "kernel.printk" = "3 3 3 3";
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_enable" = 0;
    "kernel.yama.ptrace_scope" = 2;
    "kernel.kexec_load_disabled" = 1;
    "kernel.sysrq" = 0;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.all.log_martians" = 0;
    "net.ipv4.conf.default.log_martians" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "kernel.pid_max" = 4194304;
    "kernel.perf_event_paranoid" = 3;
    "vm.unprivileged_userfaultfd" = 0;

    # File system
    "fs.file-max" = 9223372036854775807;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 8192;
    "fs.aio-max-nr" = 524288;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # Virtual Memory
    "vm.swappiness" = 1;
    "vm.overcommit_memory" = 1;
    "vm.overcommit_ratio" = 100;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 30;
    "vm.min_free_kbytes" = 65536;
    "vm.max_map_count" = 2147483642;
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;

    # Kernel
    "kernel.numa_balancing" = 0;
    "kernel.sched_migration_cost_ns" = 5000000;
    "kernel.sched_autogroup_enabled" = 0;
    "kernel.msgmnb" = 65536;
    "kernel.msgmax" = 65536;
    "kernel.watchdog" = 0;
    "kernel.nmi_watchdog" = 0;
    "kernel.io_uring_disabled" = 2;
    "kernel.split_lock_mitigate" = 0;
  };
}
