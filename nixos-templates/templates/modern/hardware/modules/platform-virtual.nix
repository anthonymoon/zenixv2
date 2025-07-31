{ config
, lib
, pkgs
, ...
}: {
  # Virtual platform configuration (auto-detected)
  boot = {
    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_scsi"
      "virtio_net"
      "virtio_blk"
    ];
    kernelModules = [ "virtio_balloon" ];
    kernelParams = [ "console=ttyS0" ];
  };

  # VM services
  services = {
    qemuGuest.enable = lib.mkDefault true;
    spice-vdagentd.enable = lib.mkDefault true;
  };

  # Disable physical-only features
  powerManagement.enable = false;
  services.thermald.enable = false;
  services.fstrim.enable = false;
}
