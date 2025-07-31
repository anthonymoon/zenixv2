#!/usr/bin/env bash
# Test Cachix configuration

set -e

echo "=== Testing Cachix Configuration ==="

# Test 1: Check Cachix is configured in configuration.nix
echo -n "Test 1 - Cachix substituters configured: "
if grep -q "nix-community.cachix.org" ./configuration.nix && \
   grep -q "nixpkgs-unfree.cachix.org" ./configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Check trusted public keys
echo -n "Test 2 - Cachix public keys configured: "
if grep -q "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ./configuration.nix && \
   grep -q "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=" ./configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Check parallel build settings
echo -n "Test 3 - Parallel build settings: "
if grep -q 'max-jobs = "auto"' ./configuration.nix && \
   grep -q "cores = 0" ./configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 4: Check optimized installer exists
echo -n "Test 4 - Optimized installer exists: "
if [ -x ./install-optimized.sh ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 5: Check setup script exists
echo -n "Test 5 - Cachix setup script exists: "
if [ -x ./setup-cachix.sh ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 6: Check install-from-url has optimizations
echo -n "Test 6 - URL installer has Cachix config: "
if grep -q "nix-community.cachix.org" ./install-from-url.sh; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 7: Check caching options
echo -n "Test 7 - Caching options configured: "
if grep -q "keep-outputs = true" ./configuration.nix && \
   grep -q "keep-derivations = true" ./configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo
echo "All Cachix configuration tests passed!"