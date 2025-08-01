# LACP bonding configuration for dual 10GbE with systemd-networkd
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable bonding kernel module
  boot.kernelModules = ["bonding"];

  # Network configuration with LACP bonding
  networking = {
    useDHCP = false;
    useNetworkd = true;

    # Create bond interface with LACP (802.3ad)
    bonds.bond0 = {
      interfaces = [
        "enp4s0f0np0"
        "enp4s0f1np1"
      ];
      driverOptions = {
        mode = "802.3ad"; # LACP mode 4
        miimon = "100";
        lacp_rate = "fast";
        xmit_hash_policy = "layer3+4";
        ad_select = "bandwidth";
        downdelay = "200";
        updelay = "200";
      };
    };
  };

  # Configure systemd-networkd for bond0
  systemd.network = {
    enable = true;

    # Configure the physical interfaces as bond slaves
    networks = {
      "10-bond-slave-enp4s0f0np0" = {
        matchConfig.Name = "enp4s0f0np0";
        networkConfig = {
          Bond = "bond0";
          LinkLocalAddressing = "no";
          IPv6AcceptRA = false;
        };
      };

      "10-bond-slave-enp4s0f1np1" = {
        matchConfig.Name = "enp4s0f1np1";
        networkConfig = {
          Bond = "bond0";
          LinkLocalAddressing = "no";
          IPv6AcceptRA = false;
        };
      };

      # Configure bond0 with DHCP and unique MAC
      "20-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "yes";
          LinkLocalAddressing = "ipv6";
          IPv6AcceptRA = true;
        };
        dhcpV4Config = {
          UseDomains = true;
          UseRoutes = true;
          UseNTP = true;
          RouteMetric = 100;
        };
        linkConfig = {
          # Set a unique MAC address for bond0
          MACAddress = "52:54:00:12:34:56";
          RequiredForOnline = "routable";
        };
      };
    };

    # Configure the physical interfaces
    links = {
      "10-enp4s0f0np0" = {
        matchConfig.Name = "enp4s0f0np0";
        linkConfig = {
          MTUBytes = "9000";
          WakeOnLan = "magic";
        };
      };

      "10-enp4s0f1np1" = {
        matchConfig.Name = "enp4s0f1np1";
        linkConfig = {
          MTUBytes = "9000";
          WakeOnLan = "magic";
        };
      };
    };
  };

  # Install network utilities
  environment.systemPackages = with pkgs; [
    ethtool
    iproute2
  ];
}
