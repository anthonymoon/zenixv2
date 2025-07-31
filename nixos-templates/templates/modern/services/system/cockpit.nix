{ config
, lib
, pkgs
, ...
}: {
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        Origins = "https://kronos.lan:9090 wss://kronos.lan:9090";
        ProtocolHeader = "X-Forwarded-Proto";
        AllowUnencrypted = true;
      };
    };
  };
}
