{ config
, lib
, pkgs
, ...
}: {
  systemd.network = {
    enable = true;
    wait-online.enable = false;

    networks = {
      "10-lan" = {
        matchConfig.Name = "enp0s31f6";
        bridgeConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "no";
      };

      "20-br0" = {
        matchConfig.Name = "br0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          LinkLocalAddressing = "yes";
        };
        dhcpV4Config = {
          RouteMetric = 10;
          UseDNS = true;
        };
        linkConfig = {
          RequiredForOnline = "yes";
          ActivationPolicy = "always-up";
        };
      };
    };

    netdevs = {
      "20-br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
        bridgeConfig = {
          STP = "no";
          ForwardDelaySec = 0;
          HelloTimeSec = 2;
          MaxAgeSec = 12;
          Priority = 32768;
        };
      };
    };
  };

  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    llmnr = "true";
    extraConfig = ''
      MulticastDNS=yes
      Cache=yes
      CacheFromLocalhost=yes
      DNSStubListener=yes
      DNSStubListenerExtra=0.0.0.0
    '';
  };
}
