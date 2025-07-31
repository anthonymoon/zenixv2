# VM Installation Guide

This guide covers installing the ephemeral root NixOS ZFS configuration on virtual machines.

## VM-Specific Configuration

The repository includes VM-specific configurations that address common issues:

1. **ZFS Import Issues**: VMs often fail to import ZFS pools on boot due to missing disk IDs
2. **Disk Identification**: Virtual disks use `/dev/vda` instead of by-id paths
3. **Resource Constraints**: Reduced partition sizes for smaller VM disks
4. **QEMU Integration**: Guest agent and VM-specific optimizations

## Installation Methods

### Method 1: Automatic VM Detection (Recommended)

The remote installer automatically detects VM disks and uses the appropriate configuration:

```bash
# From your workstation
./remote-install.sh <vm-ip> <hostname> /dev/vda
```

### Method 2: Direct VM Installation

Boot the VM with NixOS installer ISO and run:

```bash
# Download and run VM installer directly
curl -sL https://raw.githubusercontent.com/anthonymoon/zfs/main/install-vm.sh -o install-vm.sh
chmod +x install-vm.sh
./install-vm.sh myvm /dev/vda
```

### Method 3: Manual Installation

1. Boot NixOS installer ISO in VM
2. Set root password: `passwd`
3. Clone repository:
   ```bash
   git clone https://github.com/anthonymoon/zfs
   cd zfs
   ```
4. Run VM installer:
   ```bash
   ./install-vm.sh myvm /dev/vda
   ```

## VM Requirements

- **Minimum RAM**: 2GB (4GB recommended)
- **Minimum Disk**: 20GB (40GB recommended)
- **CPU**: 2+ cores recommended
- **Network**: Bridged or NAT with port forwarding for SSH

## Common VM Platforms

### QEMU/KVM

```bash
# Create VM with adequate resources
virt-install \
  --name nixos-zfs \
  --ram 4096 \
  --vcpus 2 \
  --disk size=40 \
  --cdrom nixos-minimal.iso \
  --network bridge=br0 \
  --graphics vnc \
  --os-variant nixos-unstable
```

### VirtualBox

1. Create new VM with:
   - Type: Linux
   - Version: Other Linux (64-bit)
   - RAM: 4096MB
   - Disk: 40GB (VDI, dynamically allocated)
2. Enable EFI in System settings
3. Attach NixOS ISO and boot

### VMware

1. Create new VM with:
   - Guest OS: Other Linux 5.x 64-bit
   - RAM: 4GB
   - Disk: 40GB
2. Enable UEFI boot
3. Install from NixOS ISO

## Troubleshooting VM Issues

### ZFS Pool Import Failures

The VM configuration includes:
- `boot.zfs.forceImportRoot = true` - Forces pool import even with hostid mismatch
- `boot.zfs.devNodes = "/dev/disk/by-partuuid"` - Uses by-partuuid for better VM device discovery
- Custom systemd service for explicit pool import

Note: If you still experience import issues, you can try:
- `boot.zfs.devNodes = "/dev/disk/by-path"` as an alternative
- `boot.zfs.devNodes = "/dev"` for direct device access (less reliable)

### Disk Not Found

VMs use different disk naming:
- Physical: `/dev/nvme0n1`, `/dev/sda`
- Virtual: `/dev/vda`, `/dev/vdb`

The VM installer handles this automatically.

### Performance Issues

1. Increase VM resources:
   ```bash
   virsh setvcpus nixos-zfs 4 --config
   virsh setmem nixos-zfs 8G --config
   ```

2. Enable VM optimizations:
   - VirtIO drivers (included in config)
   - Guest agent (auto-enabled)
   - Disable unused hardware

### Network Issues

1. Check VM network configuration
2. Ensure SSH is accessible:
   ```bash
   # On VM
   ip addr show
   systemctl status sshd
   ```

3. For NAT, forward SSH port:
   ```bash
   # VirtualBox
   VBoxManage modifyvm nixos-zfs --natpf1 "ssh,tcp,,2222,,22"
   
   # Then SSH to localhost:2222
   ssh -p 2222 root@localhost
   ```

## Post-Installation

1. Verify ZFS is working:
   ```bash
   zpool status
   zfs list
   ```

2. Check ephemeral root:
   ```bash
   touch /test-file
   reboot
   # File should be gone after reboot
   ```

3. Update configuration:
   ```bash
   cd /etc/nixos
   git pull
   nixos-rebuild switch
   ```

## VM-Specific Features

The VM configuration includes:

- **Reduced Sizes**: 512MB ESP, 1GB Docker volume
- **Force Import**: ZFS pools import even with hostid mismatches
- **Guest Services**: QEMU guest agent for better integration
- **Console Access**: Serial console on ttyS0 for debugging
- **Optimized Modules**: Only essential kernel modules loaded

## Example VM Deployment

```bash
# 1. Create VM (example with virsh)
virt-install \
  --name nixos-test \
  --ram 4096 \
  --vcpus 2 \
  --disk size=40,bus=virtio \
  --cdrom ~/nixos-minimal.iso \
  --network network=default \
  --graphics none \
  --console pty,target_type=serial \
  --os-variant nixos-unstable

# 2. Boot and set root password
# (Connect to console)
passwd

# 3. Get VM IP
ip addr show

# 4. From host, install remotely
./remote-install.sh 192.168.122.45 nixos-test /dev/vda

# 5. After installation, manage with:
nixos-rebuild switch --flake .#nixos-test --target-host root@192.168.122.45
```