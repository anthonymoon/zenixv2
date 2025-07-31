{ config
, lib
, pkgs
, ...
}: {
  # Physical hardware platform (auto-detected)
  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
    enableAllFirmware = lib.mkDefault true;
  };

  # Physical machine services
  services = {
    fstrim.enable = lib.mkDefault true;
    smartd = {
      enable = lib.mkDefault true;
      autodetect = true;
    };
  };

  # Power management for physical hardware
  powerManagement = {
    enable = lib.mkDefault true;
    powertop.enable = lib.mkDefault true;
  };

  services.thermald.enable =
    lib.mkDefault
      (config.hardware.cpu.intel.updateMicrocode or false);
}
