{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    alsa-firmware
    alsa-plugins
    alsa-utils
    pulseaudio
  ];
}
