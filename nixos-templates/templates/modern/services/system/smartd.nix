{ config
, lib
, pkgs
, ...
}: {
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      test = true;
      wall.enable = true;
    };
  };
}
