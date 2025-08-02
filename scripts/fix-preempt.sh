#!/usr/bin/env bash
# Fix PREEMPT conflict by clearing cache and rebuilding

set -euo pipefail

echo "🔧 Fixing PREEMPT kernel conflict..."

# Try to clear evaluation cache
echo "📦 Clearing Nix evaluation cache..."
sudo rm -rf /root/.cache/nix 2>/dev/null || true
rm -rf ~/.cache/nix 2>/dev/null || true

# Update nix flake lock
echo "🔒 Updating flake lock..."
if [[ -d ~/nix ]]; then
    cd ~/nix
    nix flake update --commit-lock-file 2>/dev/null || true
fi

# Try with --refresh flag to bypass cache
echo "🔄 Rebuilding with cache refresh..."
sudo nixos-rebuild switch --flake github:anthonymoon/zenixv2#nixie --refresh --option eval-cache false

echo "✅ Done! If the error persists, try:"
echo "  1. sudo nixos-rebuild switch --flake github:anthonymoon/zenixv2#nixie --override-input nixpkgs github:NixOS/nixpkgs/nixos-unstable"
echo "  2. Or use a specific commit: sudo nixos-rebuild switch --flake github:anthonymoon/zenixv2/e674b34#nixie"