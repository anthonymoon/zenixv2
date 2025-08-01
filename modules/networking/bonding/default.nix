# LACP bonding configuration for dual 10GbE
{ config, lib, pkgs, ... }:

{
  # Enable bonding kernel module
  boot.kernelModules = [ "bonding" ];
  
  # Network configuration with LACP bonding
  networking = {
    # Disable DHCP on individual interfaces
    interfaces.enp4s0f0np0.useDHCP = false;
    interfaces.enp4s0f1np1.useDHCP = false;
    
    # Create bond interface with LACP (802.3ad)
    bonds.bond0 = {
      interfaces = [ "enp4s0f0np0" "enp4s0f1np1" ];
      driverOptions = {
        mode = "802.3ad";  # LACP mode 4
        miimon = "100";
        lacp_rate = "fast";
        xmit_hash_policy = "layer3+4";
        ad_select = "bandwidth";
        downdelay = "200";
        updelay = "200";
      };
    };
    
    # Configure bond0 with DHCP or static IP
    interfaces.bond0.useDHCP = lib.mkDefault true;
    # For static IP, comment out above and uncomment below:
    # interfaces.bond0.ipv4.addresses = [{
    #   address = "10.10.10.11";
    #   prefixLength = 24;
    # }];
    # defaultGateway = "10.10.10.1";
    # nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
}