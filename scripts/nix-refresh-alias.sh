#!/usr/bin/env bash
# Source this file to add nixos-refresh alias
# Add to ~/.bashrc or ~/.zshrc: source /path/to/nix-refresh-alias.sh

# Simple refresh commands
alias nixos-refresh='sudo nixos-rebuild switch --flake github:anthonymoon/zenixv2#nixie'
alias nixos-refresh-boot='sudo nixos-rebuild boot --flake github:anthonymoon/zenixv2#nixie'
alias nixos-refresh-local='sudo nixos-rebuild switch --flake .#nixie'
alias nixos-refresh-trace='sudo nixos-rebuild switch --flake github:anthonymoon/zenixv2#nixie --show-trace'

# Quick system info
alias nixos-generation='sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -n 5'
alias nixos-rollback='sudo nixos-rebuild switch --rollback'

echo "NixOS refresh aliases loaded!"
echo "Commands available:"
echo "  nixos-refresh       - Rebuild from GitHub"
echo "  nixos-refresh-boot  - Rebuild for next boot"
echo "  nixos-refresh-local - Rebuild from local flake"
echo "  nixos-refresh-trace - Rebuild with debug trace"
echo "  nixos-generation    - Show recent generations"
echo "  nixos-rollback      - Rollback to previous generation"