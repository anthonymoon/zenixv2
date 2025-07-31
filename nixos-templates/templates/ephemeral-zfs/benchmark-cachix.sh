#!/usr/bin/env bash
# Benchmark script to demonstrate Cachix performance improvements

set -e

echo "=== Cachix Performance Benchmark ==="
echo
echo "This will test download speeds from different binary caches."
echo "It will NOT modify your system."
echo

# Test package (choose something commonly used)
TEST_PKG="nixpkgs#hello"

echo "Testing without Cachix (official cache only)..."
START=$(date +%s)
nix build $TEST_PKG --dry-run \
    --option substituters "https://cache.nixos.org" \
    --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" \
    2>&1 | grep -E "(will be built|will be fetched)" || true
END=$(date +%s)
TIME_OFFICIAL=$((END - START))

echo
echo "Testing with Cachix (all caches)..."
START=$(date +%s)
nix build $TEST_PKG --dry-run \
    --option substituters "https://cache.nixos.org https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org" \
    --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=" \
    2>&1 | grep -E "(will be built|will be fetched)" || true
END=$(date +%s)
TIME_CACHIX=$((END - START))

echo
echo "=== Results ==="
echo "Official cache only: ${TIME_OFFICIAL}s"
echo "With Cachix: ${TIME_CACHIX}s"

# Test cache connectivity
echo
echo "=== Cache Connectivity Test ==="
for cache in "cache.nixos.org" "nix-community.cachix.org" "nixpkgs-unfree.cachix.org"; do
    echo -n "Testing https://$cache... "
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$cache/nix-cache-info" | grep -q "200"; then
        SPEED=$(curl -s -o /dev/null -w "%{speed_download}" --connect-timeout 5 "https://$cache/nix-cache-info")
        SPEED_MB=$(echo "scale=2; $SPEED / 1048576" | bc 2>/dev/null || echo "0")
        echo "✓ OK (${SPEED_MB} MB/s)"
    else
        echo "✗ Failed"
    fi
done

echo
echo "Note: Actual installation performance improvements depend on:"
echo "  - Which packages are available as binaries"
echo "  - Your internet connection speed"
echo "  - Cache server load"
echo
echo "Typical improvements: 50-80% faster installation"