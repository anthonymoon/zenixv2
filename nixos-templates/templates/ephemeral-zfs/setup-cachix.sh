#!/usr/bin/env bash
# Setup Cachix binary caches for faster package downloads
# Can be run on existing NixOS systems to enable caching

set -e

echo "=== Cachix Setup for NixOS ==="
echo
echo "This will configure binary caches for faster package downloads:"
echo "  • cache.nixos.org (default)"
echo "  • nix-community.cachix.org (community packages)"
echo "  • nixpkgs-unfree.cachix.org (unfree packages)"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Create a temporary file for the new configuration
TEMP_FILE=$(mktemp)

# Check if we already have cachix configured
if grep -q "nix-community.cachix.org" /etc/nixos/configuration.nix; then
    echo "Cachix appears to be already configured."
    echo "Check your /etc/nixos/configuration.nix file."
    exit 0
fi

echo "Adding Cachix configuration to your system..."

# Create the nix settings block
cat > "$TEMP_FILE" << 'EOF'
  # Binary cache configuration for faster downloads
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];
    
    # Performance optimizations
    max-jobs = "auto";
    cores = 0;
    
    # Better caching
    keep-outputs = true;
    keep-derivations = true;
  };
EOF

echo
echo "To enable Cachix, add the following to your /etc/nixos/configuration.nix:"
echo "=================="
cat "$TEMP_FILE"
echo "=================="
echo
echo "Then rebuild your system with:"
echo "  sudo nixos-rebuild switch"
echo
echo "For immediate use without rebuilding, you can use:"
echo "  nix-build --option substituters 'https://cache.nixos.org https://nix-community.cachix.org'"
echo

# Ask if user wants to test the caches
read -r -p "Would you like to test the cache connectivity? (y/n): " test_cache
if [[ "$test_cache" == "y" ]]; then
    echo
    echo "Testing cache connectivity..."
    
    # Test each cache
    for cache in "https://cache.nixos.org" "https://nix-community.cachix.org" "https://nixpkgs-unfree.cachix.org"; do
        echo -n "  Testing $cache... "
        if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$cache/nix-cache-info" | grep -q "200"; then
            echo "✓ OK"
        else
            echo "✗ Failed"
        fi
    done
fi

# Cleanup
rm -f "$TEMP_FILE"

echo
echo "Setup complete! Remember to add the configuration to your system."