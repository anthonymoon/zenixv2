# Enhanced LACP bonding configuration with Intel X710 optimizations
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.networking.bonding;
in {
  options.networking.bonding = {
    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "enp4s0f0np0" "enp4s0f1np1" ];
      description = "Network interfaces to bond";
    };

    macAddress = lib.mkOption {
      type = lib.types.str;
      default = "52:54:00:12:34:56";
      description = "MAC address for bond0 interface";
    };

    mtu = lib.mkOption {
      type = lib.types.int;
      default = 9000;
      description = "MTU size for jumbo frames";
    };

    staticIP = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.10.10.11/24";
      description = "Static IP address (null for DHCP)";
    };

    gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.10.10.1";
      description = "Default gateway (null for DHCP)";
    };
  };

  config = {
    # Enable bonding kernel module
    boot.kernelModules = [ "bonding" ];

    # Intel X710 specific optimizations
    boot.kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "pcie_aspm=off"  # Disable ASPM for lower latency
    ];

    # Network configuration with LACP bonding
    networking = {
      useDHCP = false;
      useNetworkd = true;

      # Create bond interface with LACP (802.3ad)
      bonds.bond0 = {
        interfaces = cfg.interfaces;
        driverOptions = {
          mode = "802.3ad";           # LACP mode 4
          miimon = "100";            # Link monitoring in ms
          lacp_rate = "fast";        # Fast LACP (1s)
          xmit_hash_policy = "layer3+4";  # L3+L4 hashing
          ad_select = "bandwidth";   # Select by bandwidth
          downdelay = "200";         # Down delay in ms
          updelay = "200";           # Up delay in ms
          use_carrier = "1";         # Use carrier for link detection
          arp_interval = "0";        # Disable ARP monitoring (using MII)
          arp_validate = "none";     # No ARP validation
          all_slaves_active = "0";   # Drop duplicate frames
          packets_per_slave = "1";   # Round-robin packets
          tlb_dynamic_lb = "1";     # Dynamic load balancing
          resend_igmp = "1";         # IGMP membership reports
        };
      };
    };

    # Configure systemd-networkd for bond0
    systemd.network = {
      enable = true;

      # Bond netdev configuration
      netdevs."10-bond0" = {
        netdevConfig = {
          Name = "bond0";
          Kind = "bond";
          MACAddress = cfg.macAddress;
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer3+4";
          MIIMonitorSec = "100ms";
          LACPTransmitRate = "fast";
          AdSelect = "bandwidth";
          UpDelaySec = "200ms";
          DownDelaySec = "200ms";
          AllSlavesActive = false;
          ResendIGMP = 1;
        };
      };

      # Configure the physical interfaces as bond slaves
      networks = lib.listToAttrs (map (iface: {
        name = "10-bond-slave-${iface}";
        value = {
          matchConfig.Name = iface;
          networkConfig = {
            Bond = "bond0";
            LinkLocalAddressing = "no";
            IPv6AcceptRA = false;
            LLDP = true;
            EmitLLDP = "customer-bridge";
          };
        };
      }) cfg.interfaces);

      # Configure bond0 with DHCP or static IP
      networks."20-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = if cfg.staticIP == null then "yes" else "no";
          LinkLocalAddressing = "ipv6";
          IPv6AcceptRA = true;
          LLDP = true;
          EmitLLDP = "customer-bridge";
        } // lib.optionalAttrs (cfg.staticIP != null) {
          Address = cfg.staticIP;
          Gateway = cfg.gateway;
          DNS = [ "1.1.1.1" "8.8.8.8" ];
        };
        dhcpV4Config = lib.optionalAttrs (cfg.staticIP == null) {
          UseDomains = true;
          UseRoutes = true;
          UseNTP = true;
          RouteMetric = 100;
          ClientIdentifier = "mac";
        };
        linkConfig = {
          RequiredForOnline = "routable";
          MTUBytes = toString cfg.mtu;
        };
      };

      # Configure the physical interfaces
      links = lib.listToAttrs (map (iface: {
        name = "10-${iface}";
        value = {
          matchConfig.Name = iface;
          linkConfig = {
            MTUBytes = toString cfg.mtu;
            WakeOnLan = "magic";
            # Intel X710 specific
            GSO = true;
            GSOMaxBytes = 65536;
            GSOMaxSegments = 64;
            TSO = true;
            TCP6SegmentationOffload = true;
            RxBufferSize = 4096;
            TxBufferSize = 4096;
          };
        };
      }) cfg.interfaces);
    };

    # Intel X710 specific udev rules
    services.udev.extraRules = ''
      # Intel X710 optimization
      ACTION=="add", SUBSYSTEM=="net", DRIVERS=="i40e", ATTR{device/numa_node}=="-1", ATTR{device/numa_node}="0"
      
      # Set CPU affinity for NIC interrupts
      ACTION=="add", SUBSYSTEM=="net", NAME=="enp4s0f0np0", RUN+="${pkgs.writeShellScript "set-irq-affinity" ''
        #!/bin/sh
        # Spread interrupts across CPU cores
        for irq in $(grep enp4s0f0np0 /proc/interrupts | cut -d: -f1); do
          echo 0-7 > /proc/irq/$irq/smp_affinity_list
        done
      ''}"
      
      ACTION=="add", SUBSYSTEM=="net", NAME=="enp4s0f1np1", RUN+="${pkgs.writeShellScript "set-irq-affinity" ''
        #!/bin/sh
        # Spread interrupts across CPU cores
        for irq in $(grep enp4s0f1np1 /proc/interrupts | cut -d: -f1); do
          echo 8-15 > /proc/irq/$irq/smp_affinity_list
        done
      ''}"
    '';

    # Intel X710 performance tuning service
    systemd.services.intel-x710-tuning = {
      description = "Intel X710 Performance Tuning";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        # Wait for interfaces
        sleep 5

        # Configure each interface
        for iface in ${lib.concatStringsSep " " cfg.interfaces}; do
          if [[ -e /sys/class/net/$iface ]]; then
            echo "Configuring $iface..."
            
            # Ring buffer sizes
            ${pkgs.ethtool}/bin/ethtool -G $iface rx 4096 tx 4096 || true
            
            # Offload settings
            ${pkgs.ethtool}/bin/ethtool -K $iface \
              rx on tx on \
              gso on gro on \
              tso on \
              lro off \
              rx-vlan-offload on \
              tx-vlan-offload on \
              ntuple on \
              rxhash on \
              rx-all off || true
            
            # Coalescing for low latency
            ${pkgs.ethtool}/bin/ethtool -C $iface \
              adaptive-rx on \
              adaptive-tx on \
              rx-usecs 10 \
              tx-usecs 10 || true
            
            # Flow control off for low latency
            ${pkgs.ethtool}/bin/ethtool -A $iface rx off tx off || true
            
            # Enable RSS (Receive Side Scaling)
            ${pkgs.ethtool}/bin/ethtool -N $iface rx-flow-hash udp4 sdfn || true
            ${pkgs.ethtool}/bin/ethtool -N $iface rx-flow-hash tcp4 sdfn || true
          fi
        done

        # Configure bond0
        if [[ -e /sys/class/net/bond0 ]]; then
          echo "Configuring bond0..."
          
          # Set queue count
          echo 16 > /sys/class/net/bond0/queues/tx-0/xps_cpus || true
          
          # Enable RPS (Receive Packet Steering)
          echo 65535 > /sys/class/net/bond0/queues/rx-0/rps_cpus || true
        fi

        echo "Intel X710 tuning completed"
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Network debugging tools
    environment.systemPackages = with pkgs; [
      ethtool
      iproute2
      tcpdump
      iperf3
      nload
      iftop
      mtr
      bandwhich
    ];
  };
}