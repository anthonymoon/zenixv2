{ config
, pkgs
, lib
, ...
}: {
  # Hostname
  networking.hostName = "nixos"; # Change this to your preferred hostname
  networking.hostId = "12345678"; # Required for ZFS, generate with: head -c 8 /etc/machine-id

  # Disable NetworkManager in favor of systemd-networkd
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;

  # Enable systemd-networkd
  systemd.network.enable = true;

  # systemd-resolved for DNS
  services.resolved = {
    enable = true;
    dnssec = "false";
    domains = [ "~." ];
    fallbackDns = [ "94.140.14.14" "94.140.15.15" ];
    llmnr = "true";
    extraConfig = ''
      DNSStubListener=no
    '';
  };

  # Bridge configuration
  systemd.network = {
    netdevs = {
      "30-virbr0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "virbr0";
        };
        bridgeConfig = {
          STP = true;
          Priority = 32768;
        };
      };
    };

    networks = {
      # Intel X710 Port 0
      "20-intel-x710-p0" = {
        matchConfig = {
          MACAddress = "f8:f2:1e:14:38:44";
          Name = "ens6f0np0";
        };
        networkConfig = {
          Bridge = "virbr0";
          LLDP = true;
          EmitLLDP = true;
        };
        linkConfig = {
          RequiredForOnline = "no";
        };
      };

      # Intel X710 Port 1
      "21-intel-x710-p1" = {
        matchConfig = {
          MACAddress = "f8:f2:1e:14:38:45"; # Update MAC address as needed
          Name = "ens6f1np1";
        };
        networkConfig = {
          Bridge = "virbr0";
          LLDP = true;
          EmitLLDP = true;
        };
        linkConfig = {
          RequiredForOnline = "no";
        };
      };

      # Bridge network configuration
      "30-virbr0" = {
        matchConfig = {
          Name = "virbr0";
        };
        networkConfig = {
          Address = "10.10.10.10/23";
          Gateway = "10.10.10.1";
          DNS = [ "94.140.14.14" "94.140.15.15" ];
          IPForward = "ipv4";
          IPMasquerade = "ipv4";
          LLDP = true;
          EmitLLDP = true;
          DHCP = "no";
          MulticastDNS = "no";
          LinkLocalAddressing = "no";
          IPv6AcceptRA = "no";
          KeepConfiguration = "static";
        };
        linkConfig = {
          RequiredForOnline = "yes";
          BindCarrier = "ens6*";
        };
        routes = [
          {
            routeConfig = {
              Gateway = "10.10.10.1";
              Metric = 100;
              GatewayOnLink = true;
            };
          }
        ];
      };

      # Default configuration for other interfaces
      "99-default" = {
        matchConfig = {
          Name = "en* eth*";
        };
        networkConfig = {
          DHCP = "yes";
          LLDP = true;
          EmitLLDP = true;
        };
        dhcpV4Config = {
          RouteMetric = 1024;
        };
        linkConfig = {
          RequiredForOnline = "no";
        };
      };
    };
  };

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # DNS configuration
  networking.nameservers = [ "94.140.14.14" "94.140.15.15" ];

  # Enable LLDP
  services.lldpd.enable = true;

  # Wireless configuration (if needed)
  # networking.wireless.enable = true;

  # Additional network optimizations
  boot.kernelModules = [ "tcp_bbr" ];
}
