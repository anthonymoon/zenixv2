# NixOS Hardware-Specific Installer

This template generates a hardware-specific NixOS installer configuration based on detected hardware.

## Prerequisites

- NixOS live environment or existing Linux system with Nix
- Root access (for hardware detection)
- Target disk for installation

## Usage

### Step 1: Generate Installer

From the NixOS installer environment:

```bash
# Create a working directory
mkdir -p /tmp/installer && cd /tmp/installer

# Initialize the installer template
nix flake init -t github:anthonymoon/zenixv2#installer

# Run hardware detection (requires root)
sudo nix run nixpkgs#nixos-facter -- -o facter.json
```

### Step 2: Run Installation

```bash
# Review detected hardware
cat facter.json | jq '.hardware'

# Run the installer
sudo nix run .
```

## What It Does

1. **Hardware Detection**: Uses the `facter.json` file to determine:
   - Primary disk (NVMe preferred, then SATA)
   - Boot mode (UEFI or BIOS)
   - CPU type for kernel modules
   - Memory size for configuration tuning

2. **Disk Configuration**: Automatically configures:
   - GPT partitioning
   - EFI System Partition (for UEFI) or BIOS boot partition
   - ZFS root pool with optimized datasets

3. **System Installation**: Uses `disko-install` to:
   - Partition and format the disk
   - Create ZFS datasets
   - Mount filesystems
   - Install NixOS
   - Configure bootloader

## Customization

Edit the generated `flake.nix` to customize:
- Disk selection
- ZFS pool configuration
- Additional NixOS modules
- System packages

## Advanced Usage

### Specify Different Disk

```bash
# Edit flake.nix and change primaryDisk
vim flake.nix

# Or override in facter.json before running
```

### Add Custom Configuration

```nix
# In flake.nix, add to the modules section:
{
  # Your custom configuration
  services.openssh.enable = true;
  users.users.myuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
```

## Troubleshooting

### Hardware Detection Fails

If `nixos-facter` fails, you can create a minimal `facter.json`:

```json
{
  "boot": { "efi": true },
  "hardware": {
    "storage": {
      "disks": [
        { "name": "nvme0n1", "size": 512110190592 }
      ]
    },
    "cpu": { "vendor": "GenuineIntel" },
    "memory": { "total": 17179869184 }
  }
}
```

### Installation Fails

Check:
- Disk is not in use: `lsblk`
- No existing ZFS pools: `zpool list`
- Sufficient disk space
- Network connectivity for package downloads