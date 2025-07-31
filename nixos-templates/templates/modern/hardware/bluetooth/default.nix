{ config
, lib
, pkgs
, ...
}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        FastConnectable = true;
        MultiProfile = "multiple";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
}
