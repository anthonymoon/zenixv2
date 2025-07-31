#!/usr/bin/env bash
# Test remote installation scripts

set -e

echo "=== Testing Remote Installation Scripts ==="

# Test 1: Check remote-install.sh exists and is executable
echo -n "Test 1 - Remote installer exists and executable: "
if [ -x ./remote-install.sh ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Check install-from-url.sh exists and is executable
echo -n "Test 2 - URL installer exists and executable: "
if [ -x ./install-from-url.sh ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Validate remote-install.sh parameter checking
echo -n "Test 3 - Remote installer parameter validation: "
if ./remote-install.sh 2>&1 | grep -q "Usage:"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 4: Check master flake exists
echo -n "Test 4 - Master flake configuration exists: "
if [ -f ./flake-master.nix ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 5: Validate master flake has example hosts
echo -n "Test 5 - Master flake contains example hosts: "
if grep -q "homeserver.*mkHost.*homeserver" ./flake-master.nix && \
   grep -q "workstation.*mkHost.*workstation" ./flake-master.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 6: Check configuration has SSH keys
echo -n "Test 6 - SSH keys configured for all users: "
if grep -q "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA898oqxREsBRW49hvI92CPWTebvwPoUeMSq5VMyzoM3" ./configuration.nix && \
   grep -c "ssh-ed25519" ./configuration.nix | grep -q "3"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 7: Check IPv6 is disabled
echo -n "Test 7 - IPv6 disabled in configuration: "
if grep -q "networking.enableIPv6 = false" ./configuration.nix && \
   grep -q "ipv6.disable=1" ./configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 8: Check default passwords are set
echo -n "Test 8 - Default passwords configured: "
if grep -q 'password = "nixos"' ./configuration.nix && \
   grep -c 'password = "nixos"' ./configuration.nix | grep -q "3"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo
echo "All remote installation tests passed!"