# Binary Cache Setup for NixOS Installation

## Setting up Binary Cache with cachy.local

### 1. Configure Nix to use cachy.local as a substituter

First, you need to get the public key from your nixserve server on cachy.local:

```bash
# On cachy.local, run:
cat /etc/nix/signing-key.pub
```

### 2. Configure the installer environment

In the NixOS installer environment, you need to configure nix.conf:

```bash
# Add to /etc/nix/nix.conf (create if it doesn't exist):
sudo tee -a /etc/nix/nix.conf << 'EOF'
substituters = https://cache.nixos.org https://cachy.local:5000
trusted-substituters = https://cachy.local:5000
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= cachy.local:YOUR_PUBLIC_KEY_HERE
experimental-features = nix-command flakes
EOF
```

### 3. Test the cache connection

```bash
# Test if you can reach the cache
curl -I https://cachy.local:5000/nix-cache-info

# Or if using HTTP:
curl -I http://cachy.local:5000/nix-cache-info
```

### 4. For permanent configuration in your NixOS config

Add this to your system configuration (e.g., in `hosts/workstation/default.nix`):

```nix
{
  nix = {
    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://cachy.local:5000"  # or http:// if not using HTTPS
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cachy.local:YOUR_PUBLIC_KEY_HERE"
      ];
      trusted-substituters = [
        "https://cachy.local:5000"
      ];
    };
  };
}
```

## Using Disko for Installation

### Option 1: Using the flake's disko-install app (Fixed)

```bash
# From the nixos-fun directory:
sudo nix run .#disko-install -- workstation.kde.stable /dev/sda
```

### Option 2: Using disko directly

```bash
# First, partition and format the disk:
sudo nix run github:nix-community/disko -- \
  --mode disko \
  --flake .#workstation.kde.stable

# Then install NixOS:
sudo nixos-install --flake .#workstation.kde.stable
```

### Option 3: Manual disko with custom disk

```bash
# Run disko-install with proper disk configuration
sudo nix run github:nix-community/disko#disko-install -- \
  --flake .#workstation.kde.stable \
  --disk main /dev/sda \
  --write-efi-boot-entries
```

## Troubleshooting

### If you get "attribute missing" error:

The configuration name format is: `hostname.profile1.profile2...`

Valid examples:
- `workstation.kde.stable`
- `workstation.gnome.unstable`
- `workstation.kde.gaming.unstable`
- `mypc.hyprland.stable`

### If the cache isn't working:

1. Check if nixserve is running on cachy.local:
   ```bash
   systemctl status nix-serve  # on cachy.local
   ```

2. Check network connectivity:
   ```bash
   ping cachy.local
   nc -zv cachy.local 5000
   ```

3. Verify the public key matches between server and client

4. Check nix daemon logs:
   ```bash
   sudo journalctl -u nix-daemon -f
   ```

### For HTTP instead of HTTPS:

If your nixserve is running on HTTP, use:
- `http://cachy.local:5000` instead of `https://cachy.local:5000`
- Make sure to add it to `trusted-substituters` since it's not HTTPS