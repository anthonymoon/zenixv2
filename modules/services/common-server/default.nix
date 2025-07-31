# Common server services
{ config, lib, pkgs, ... }:

{
  # Basic monitoring
  services.netdata = {
    enable = lib.mkDefault true;
    config = {
      global = {
        "memory mode" = "ram";
        "update every" = 2;
      };
    };
  };
  
  # Log management
  services.journald = {
    extraConfig = ''
      MaxRetentionSec=2week
      SystemMaxUse=1G
    '';
  };
  
  # Automatic maintenance
  services.fstrim.enable = lib.mkDefault true;
  
  # NTP
  services.chrony.enable = lib.mkDefault true;
  
  # Metrics collection
  services.prometheus.exporters = {
    node = {
      enable = lib.mkDefault true;
      enabledCollectors = [ "systemd" ];
    };
  };
}