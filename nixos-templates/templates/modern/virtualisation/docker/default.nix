{ config
, lib
, pkgs
, ...
}: {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--volumes" ];
    };
    daemon.settings = {
      bip = "172.17.0.1/16";
      fixed-cidr = "172.17.0.0/16";
      default-address-pools = [
        {
          base = "172.80.0.0/16";
          size = 24;
        }
        {
          base = "172.90.0.0/16";
          size = 24;
        }
      ];
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
      storage-driver = "overlay2";
      storage-opts = [ "overlay2.override_kernel_check=true" ];
      live-restore = true;
      userland-proxy = false;
      experimental = true;
      metrics-addr = "0.0.0.0:9323";
      default-ulimits = {
        nofile = {
          Name = "nofile";
          Hard = 64000;
          Soft = 64000;
        };
      };
    };
  };
}
