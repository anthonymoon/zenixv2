{ config
, lib
, pkgs
, ...
}: {
  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "nvme"
      "vfio-pci"
    ];

    kernelModules = [ "dm-snapshot" ];
  };

  boot.kernelModules = [
    "kvm-intel"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
    "i40e"
  ];
}
