{ config, lib, ... }:

{
  # Import physical configuration as base
  imports = [ ./physical.nix ];

  # VM-specific overrides
  disko.devices.disk.main.device = lib.mkForce "/dev/vda";

  # VM optimizations
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "sr_mod"
    "virtio_blk"
    "virtio_net"
  ];

  # Reduce ZFS memory usage for VMs
  boot.kernelParams = lib.mkForce [
    "zfs.zfs_arc_max=536870912" # 512MB ARC max for VMs
  ];

  # VM guest additions
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Disable physical hardware features
  hardware.cpu.intel.updateMicrocode = false;
  hardware.cpu.amd.updateMicrocode = false;

  # VM-specific disk tuning
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };
}
