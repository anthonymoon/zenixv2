# NixOS 25.11pre Configuration with ZFS

This configuration is designed for NixOS 25.11pre-git (Xantusia) with ZFS support.

## Key Features

- **Kernel**: Uses ZFS-compatible kernel selection to ensure ZFS module compatibility
- **ZFS**: Full ZFS root support with automated scrub and trim
- **Boot**: Supports both UEFI (systemd-boot) and BIOS (GRUB) systems
- **Flakes**: Enabled by default for reproducible builds

## Important Considerations

### Kernel Compatibility

The configuration uses `config.boot.zfs.package.latestCompatibleLinuxPackages` which automatically selects the newest kernel version that's compatible with ZFS. This is important because:

- Kernel 6.14.10 is very new and may not have ZFS support yet
- ZFS typically lags behind the latest kernel releases
- Using an incompatible kernel will prevent your system from booting

### Before Installation

1. **Generate a unique hostId**:
   ```bash
   head -c 8 /etc/machine-id
   ```
   Replace the `hostId` in configuration.nix with this value.

2. **Update filesystem UUIDs**:
   - Get your boot partition UUID: `blkid /dev/nvme0n1p1`
   - Update the UUID in hardware-configuration.nix

3. **Adjust ZFS dataset paths**:
   - Modify the fileSystems entries to match your ZFS pool layout
   - Common layouts:
     - `poolname/root/nixos` for root
     - `poolname/home` for home directories
     - `poolname/nix` for nix store (optional)

4. **Set your timezone**:
   - Update `time.timeZone` in configuration.nix

5. **Configure networking**:
   - Set your desired hostname
   - Adjust firewall rules as needed

### Installation Steps

1. **Clone/copy this configuration**:
   ```bash
   git clone <this-repo> /mnt/etc/nixos
   cd /mnt/etc/nixos
   ```

2. **Customize the configuration**:
   ```bash
   vim configuration.nix  # Make necessary adjustments
   vim hardware-configuration.nix  # Update filesystem paths
   ```

3. **Install NixOS**:
   ```bash
   nixos-install --flake .#nixos
   ```

   Or without flakes:
   ```bash
   nixos-install
   ```

4. **Post-installation**:
   - Change default passwords immediately
   - Set up SSH keys
   - Disable root SSH access
   - Configure user accounts properly

### Troubleshooting

#### ZFS Module Not Found

If you get ZFS-related errors during boot:

1. Boot from the installer ISO
2. Import your pool: `zpool import -f poolname`
3. Mount filesystems: `mount -t zfs poolname/root/nixos /mnt`
4. Edit configuration to use a different kernel
5. Rebuild: `nixos-rebuild boot --install-bootloader`

#### Kernel Panic

If the system won't boot with kernel 6.14.10:

1. At boot menu, select an older generation
2. Edit configuration.nix to explicitly use an older kernel:
   ```nix
   boot.kernelPackages = pkgs.linuxPackages_6_6;
   ```
3. Rebuild the system

### Maintenance

- **Update system**: `nixos-rebuild switch --flake .#nixos`
- **Garbage collection**: Automated weekly, or run `nix-collect-garbage -d`
- **ZFS scrubs**: Automated weekly
- **Check ZFS status**: `zpool status`

### Security Notes

1. The configuration includes default passwords - change them immediately
2. SSH root login is enabled for initial setup - disable after configuration
3. Consider enabling disk encryption for sensitive data
4. Review and adjust firewall rules for your use case

### Performance Tuning

The configuration includes several performance optimizations:

- ZFS ARC limited to 8GB (adjust based on your RAM)
- CPU governor set to "performance"
- ZRAM swap enabled for better memory usage
- Transparent hugepages set to "madvise"

Adjust these settings based on your hardware and workload.