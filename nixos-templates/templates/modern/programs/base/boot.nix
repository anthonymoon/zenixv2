{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
    systemd-boot
    syslinux
    os-prober
    memtest86plus
    arch-install-scripts
  ];
}
