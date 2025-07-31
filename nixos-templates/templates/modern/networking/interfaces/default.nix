{ config
, lib
, pkgs
, ...
}: {
  networking = {
    hostName = "kronos";
    hostId = "6e1e4eb2";
    networkmanager.enable = false;
    useNetworkd = true;
    useDHCP = false;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
}
