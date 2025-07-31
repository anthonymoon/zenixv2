#!/usr/bin/env bash

set -euo pipefail

echo "Testing Cachy.local Binary Cache Configuration"
echo "============================================="

# Test connectivity
echo -e "\n1. Testing connectivity to cachy.local..."
if curl -s -o /dev/null -w "%{http_code}" http://cachy.local/nix-cache-info | grep -q 200; then
    echo "✅ Successfully connected to cachy.local"
    echo "   Cache info:"
    curl -s http://cachy.local/nix-cache-info | sed 's/^/   /'
else
    echo "❌ Failed to connect to cachy.local"
    exit 1
fi

# Check current Nix configuration
echo -e "\n2. Current Nix configuration..."
echo "   Substituters:"
nix show-config 2>/dev/null | grep "^substituters" | sed 's/^/   /'
echo "   Trusted public keys:"
nix show-config 2>/dev/null | grep "^trusted-public-keys" | sed 's/^/   /'

# Test querying a package from the cache
echo -e "\n3. Testing cache query..."
TEST_PKG="hello"
echo "   Attempting to query package '$TEST_PKG' from cachy.local..."
if nix path-info --store http://cachy.local nixpkgs#$TEST_PKG 2>&1 | grep -q "path"; then
    echo "✅ Successfully queried package from cachy.local"
else
    echo "⚠️  Package not found in cachy.local (this is normal if it hasn't been built/cached yet)"
fi

# Show how to rebuild configuration
echo -e "\n4. To apply the configuration:"
echo "   sudo nixos-rebuild switch"
echo "   or"
echo "   sudo nixos-rebuild switch --flake .#$(hostname)"

echo -e "\n5. Cache priority order:"
echo "   1. http://cachy.local (highest priority)"
echo "   2. http://localhost:5000"
echo "   3. https://cache.nixos.org/"
echo "   4. https://nix-community.cachix.org"

echo -e "\nConfiguration complete! The cachy.local binary cache is ready to use."