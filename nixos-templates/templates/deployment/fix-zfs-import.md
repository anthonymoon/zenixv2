# Fix for ZFS Pool Import in QEMU VMs

Add this to your `/etc/nixos/nixos-zfs-root-config.nix`:

```nix
{
  # ... existing configuration ...
  
  boot = {
    # Fix for virtio device pool import
    zfs.devNodes = "/dev/disk/by-partlabel";
    
    # Alternative options if above doesn't work:
    # zfs.devNodes = "/dev/disk/by-path";
    # zfs.devNodes = "/dev/disk/by-partuuid";
    # zfs.devNodes = "/dev";
    
    # ... rest of boot configuration ...
  };
}
```

## Why This Works

1. Disko creates partitions with labels like `disk-vda-zfs`
2. These labels are persistent across reboots
3. By telling ZFS to look in `/dev/disk/by-partlabel`, it can find the pool reliably

## Alternative: Use virtio-scsi

For better ZFS compatibility, consider using virtio-scsi instead of virtio-blk:

In your VM configuration (libvirt XML):
```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native'/>
  <source file='/path/to/disk.qcow2'/>
  <target dev='sda' bus='scsi'/>
  <address type='drive' controller='0' bus='0' target='0' unit='0'/>
</disk>
<controller type='scsi' index='0' model='virtio-scsi'>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
</controller>
```

This will present the disk as `/dev/sda` with proper `/dev/disk/by-id` entries.