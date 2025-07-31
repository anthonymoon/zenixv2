#!/usr/bin/env bash
# Test template replacement functionality

set -e

echo "=== Testing Template Replacement ==="

# Create test directory
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test values
TEST_HOSTNAME="testhost"
TEST_DISK_ID="ata-Samsung_SSD_850_EVO_500GB_S21PNXAGA12345"

# Copy template files
cp configuration.nix "$TEST_DIR/"
cp -r hardware "$TEST_DIR/"

# Perform replacements
sed -i "s|@HOSTNAME@|$TEST_HOSTNAME|g" "$TEST_DIR/configuration.nix"
sed -i "s|@DISK_ID@|$TEST_DISK_ID|g" "$TEST_DIR/hardware/disko-config.nix"

# Test 1: Check hostname replacement
echo -n "Test 1 - Hostname replacement: "
if grep -q "networking.hostName = \"$TEST_HOSTNAME\"" "$TEST_DIR/configuration.nix"; then
    echo "PASS"
else
    echo "FAIL"
    grep "networking.hostName" "$TEST_DIR/configuration.nix"
    exit 1
fi

# Test 2: Check user amoon is hardcoded
echo -n "Test 2 - User amoon hardcoded: "
if grep -q "users.users.amoon" "$TEST_DIR/configuration.nix"; then
    echo "PASS"
else
    echo "FAIL"
    grep "users.users" "$TEST_DIR/configuration.nix"
    exit 1
fi

# Test 3: Check disk ID replacement
echo -n "Test 3 - Disk ID replacement: "
if grep -q "device = \"/dev/disk/by-id/$TEST_DISK_ID\"" "$TEST_DIR/hardware/disko-config.nix"; then
    echo "PASS"
else
    echo "FAIL"
    grep "device = " "$TEST_DIR/hardware/disko-config.nix" | head -1
    exit 1
fi

# Test 4: Ensure no templates remain
echo -n "Test 4 - No remaining templates: "
if grep -r "@[A-Z_]*@" "$TEST_DIR/" > /dev/null; then
    echo "FAIL - Found remaining templates:"
    grep -r "@[A-Z_]*@" "$TEST_DIR/"
    exit 1
else
    echo "PASS"
fi

echo
echo "All template replacement tests passed!"