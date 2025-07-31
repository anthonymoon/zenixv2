#!/usr/bin/env bash
# Quick setup script for binary cache in NixOS installer

echo "Setting up cachy.local binary cache..."

# Create nix.conf if it doesn't exist
sudo mkdir -p /etc/nix

# Configure the binary cache
sudo tee /etc/nix/nix.conf << 'EOF'
substituters = https://cache.nixos.org http://cachy.local
trusted-substituters = http://cachy.local
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc=
experimental-features = nix-command flakes
build-users-group = nixbld
EOF

# Restart nix daemon to apply changes
sudo systemctl restart nix-daemon

echo "Binary cache configured!"
echo ""
echo "Testing connection to cachy.local..."
if curl -s -o /dev/null -w "%{http_code}" http://cachy.local/nix-cache-info | grep -q 200; then
    echo "✅ Successfully connected to cachy.local"
else
    echo "❌ Failed to connect to cachy.local"
    echo "   Please check:"
    echo "   - Is cachy.local reachable? (ping cachy.local)"
    echo "   - Is nix-serve running on cachy.local?"
    echo "   - Do you need to add cachy.local to /etc/hosts?"
fi

echo ""
echo "You can now run the disko installer:"
echo "  nix run .#disko-install -- workstation.kde.stable /dev/sda"
echo ""
echo "Or use disko directly:"
echo "  sudo nix run github:nix-community/disko#disko-install -- \\"
echo "    --flake .#workstation.kde.stable \\"
echo "    --disk main /dev/sda \\"
echo "    --write-efi-boot-entries"