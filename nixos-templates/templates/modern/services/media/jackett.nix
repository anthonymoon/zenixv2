{ config
, lib
, pkgs
, ...
}: {
  services.jackett = {
    enable = true;
    openFirewall = true;
  };
}
