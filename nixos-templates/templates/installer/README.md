# NixOS ZFS Installer - AMD Ryzen Optimized

Minimal NixOS installer with ZFS root, Wayland-only GNOME, optimized for AMD Ryzen 5600X + AMD GPU + NVMe.

## Install

From NixOS ISO:

```bash
# Partition and install (replace /dev/nvme0n1 with your disk)
sudo nix run --experimental-features "nix-command flakes" \
  github:nix-community/disko -- --mode disko --flake .#default \
  --arg device '"/dev/nvme0n1"'

# Generate hardware config
sudo nixos-generate-config --root /mnt --no-filesystems

# Install
sudo nixos-install --flake .#default

# Reboot
reboot
```

## Post-Install

1. Login: `nixos` / password: `nixos`
2. Change password: `passwd`
3. Add SSH keys: `mkdir -p ~/.ssh && echo "your-key" > ~/.ssh/authorized_keys`
4. Update hostname: edit flake.nix, `nixos-rebuild switch`

## Optimizations

- **CPU**: AMD P-State driver, performance governor
- **GPU**: AMDGPU driver with Vulkan/OpenCL
- **Storage**: NVMe-optimized ZFS with TRIM
- **Display**: Wayland-only (no X11 fallback)
- **SSH**: Enabled with password authentication