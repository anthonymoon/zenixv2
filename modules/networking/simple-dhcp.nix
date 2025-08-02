# Simple DHCP configuration for Intel X710 interfaces
{ config, lib, pkgs, ... }:

{
  # Disable NetworkManager if enabled
  networking.networkmanager.enable = lib.mkForce false;
  
  # Enable systemd-networkd
  networking.useNetworkd = true;
  systemd.network.enable = true;
  
  # Wait for network to be online
  systemd.network.wait-online = {
    enable = true;
    anyInterface = true;
    timeout = 30;
  };

  # Configure DHCP for all ethernet interfaces
  systemd.network.networks = {
    "10-ethernet" = {
      matchConfig.Type = "ether";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      dhcpV4Config = {
        RouteMetric = 100;
        UseDNS = true;
        UseNTP = true;
      };
      dhcpV6Config = {
        RouteMetric = 100;
        UseDNS = true;
        UseNTP = true;
      };
      # Intel X710 specific optimizations
      linkConfig = {
        # Increase ring buffer sizes for 10GbE
        RxBufferSize = "4096";
        TxBufferSize = "4096";
        # Enable hardware offload features
        GenericSegmentationOffload = true;
        TCPSegmentationOffload = true;
        GenericReceiveOffload = true;
      };
    };
  };

  # Basic firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH
    allowPing = true;
  };

  # Ensure the i40e driver is loaded for Intel X710
  boot.kernelModules = [ "i40e" ];
}