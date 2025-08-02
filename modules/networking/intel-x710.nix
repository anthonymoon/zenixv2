# Intel X710 10GbE NIC configuration with DHCP
{ config, lib, pkgs, ... }:

{
  # i40e driver module parameters
  boot = {
    kernelModules = [ "i40e" ];
    extraModprobeConfig = ''
      # Intel i40e driver optimizations for X710
      options i40e debug=0
      options i40e int_mode=0
      options i40e flow_director=1
      options i40e max_intrs=0
      options i40e tx_ring_size=4096
      options i40e rx_ring_size=4096
      options i40e allow_unsupported_sfp=1
    '';
    
    # Ensure i40e module is in initrd
    initrd.kernelModules = [ "i40e" ];
  };

  # Disable NetworkManager
  networking.networkmanager.enable = lib.mkForce false;
  
  # Enable systemd-networkd
  networking.useNetworkd = true;
  systemd.network.enable = true;
  
  # Don't wait for network on boot
  systemd.network.wait-online.enable = false;

  # Configure DHCP for all ethernet interfaces
  systemd.network.networks = {
    "10-ethernet" = {
      matchConfig.Type = "ether";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
      dhcpV4Config = {
        RouteMetric = 100;
        UseDNS = true;
        UseNTP = true;
      };
      linkConfig = {
        RequiredForOnline = "no";
        MTUBytes = "9000";  # Jumbo frames for 10GbE
      };
    };
  };

  # Kernel sysctl parameters for Intel X710
  boot.kernel.sysctl = {
    # Network performance tuning for 10GbE
    "net.core.rmem_max" = 268435456;
    "net.core.wmem_max" = 268435456;
    "net.core.rmem_default" = 67108864;
    "net.core.wmem_default" = 67108864;
    "net.ipv4.tcp_rmem" = "4096 87380 268435456";
    "net.ipv4.tcp_wmem" = "4096 65536 268435456";
    "net.core.netdev_max_backlog" = 5000;
    "net.core.netdev_budget" = 600;
    "net.core.netdev_budget_usecs" = 8000;
    
    # BBR congestion control
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    
    # TCP optimizations
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_low_latency" = 1;
    "net.core.somaxconn" = 4096;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_window_scaling" = 1;
    
    # File system
    "fs.file-max" = 2097152;
    
    # ARP cache
    "net.ipv4.neigh.default.gc_thresh1" = 4096;
    "net.ipv4.neigh.default.gc_thresh2" = 8192;
    "net.ipv4.neigh.default.gc_thresh3" = 16384;
    
    # RPS/RFS
    "net.core.rps_sock_flow_entries" = 32768;
    "net.core.dev_weight" = 64;
  };

  # Systemd service for Intel X710 optimization
  systemd.services."intel-x710-optimization" = {
    description = "Intel X710 NIC Optimization";
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "optimize-x710" ''
        # Wait for interfaces to be available
        sleep 5
        
        # Find all Intel X710 interfaces
        for pci in $(lspci -D | grep "Ethernet controller: Intel Corporation Ethernet Controller X710" | cut -d' ' -f1); do
          # Find network interface name for this PCI device
          for iface in /sys/class/net/*; do
            if [ -e "$iface/device" ] && [ "$(readlink -f $iface/device | grep -o '[0-9a-f]\{4\}:[0-9a-f]\{2\}:[0-9a-f]\{2\}\.[0-9]')" = "$pci" ]; then
              ifname=$(basename $iface)
              echo "Optimizing Intel X710 interface: $ifname"
              
              # Ring buffers
              ${pkgs.ethtool}/bin/ethtool -G $ifname rx 4096 tx 4096 2>/dev/null || true
              
              # Interrupt coalescing
              ${pkgs.ethtool}/bin/ethtool -C $ifname adaptive-rx on adaptive-tx on rx-usecs 10 tx-usecs 10 2>/dev/null || true
              
              # Offloads
              ${pkgs.ethtool}/bin/ethtool -K $ifname rx on tx on tso on gso on gro on 2>/dev/null || true
              
              # Flow control
              ${pkgs.ethtool}/bin/ethtool -A $ifname rx on tx on 2>/dev/null || true
              
              # Intel specific optimizations
              echo 1 > /sys/class/net/$ifname/device/itr 2>/dev/null || true
              
              # Enable adaptive ITR
              echo 1 > /sys/class/net/$ifname/device/adaptive-itr 2>/dev/null || true
              
              # Set NAPI weight
              echo 128 > /sys/class/net/$ifname/device/napi_weight 2>/dev/null || true
              
              # Configure RSS
              ${pkgs.ethtool}/bin/ethtool -X $ifname equal $(nproc) 2>/dev/null || true
              
              # Set flow hash
              ${pkgs.ethtool}/bin/ethtool -N $ifname rx-flow-hash tcp4 sdfn 2>/dev/null || true
              ${pkgs.ethtool}/bin/ethtool -N $ifname rx-flow-hash udp4 sdfn 2>/dev/null || true
              
              # ATR (Application Targeted Routing)
              ${pkgs.ethtool}/bin/ethtool --set-priv-flags $ifname flow-director-atr on 2>/dev/null || true
              
              # Enable RPS (Receive Packet Steering)
              echo ffff > /sys/class/net/$ifname/queues/rx-0/rps_cpus 2>/dev/null || true
            fi
          done
        done
        
        # Enable RFS (Receive Flow Steering)
        echo 32768 > /proc/sys/net/core/rps_sock_flow_entries 2>/dev/null || true
      ''}";
    };
  };

  # Install network tools
  environment.systemPackages = with pkgs; [
    ethtool
    tcpdump
    iperf3
    pciutils
    lshw
  ];
}