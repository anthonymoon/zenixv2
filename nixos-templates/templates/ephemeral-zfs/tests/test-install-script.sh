#!/usr/bin/env bash
# Test install script parameter validation

set -e

echo "=== Testing Install Script Validation ==="

# Test 1: Missing arguments
echo -n "Test 1 - Missing arguments: "
if ./install.sh 2>&1 | grep -q "Usage:"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Invalid hostname
echo -n "Test 2 - Invalid hostname: "
if ./install.sh "invalid_hostname!" "/dev/sda" 2>&1 | grep -q "Invalid hostname"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Invalid disk (updated for 2 args)
echo -n "Test 3 - Invalid disk: "
if ./install.sh "validhost" "/dev/nonexistent" 2>&1 | grep -q "not a block device"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 4: Valid hostname patterns
echo -n "Test 4 - Valid hostname patterns: "
VALID_HOSTNAMES=("myhost" "test-host" "host123" "a" "host-123-test")
for hostname in "${VALID_HOSTNAMES[@]}"; do
    if ! ./install.sh "$hostname" "/dev/null" 2>&1 | grep -q "Invalid hostname"; then
        continue
    else
        echo "FAIL - '$hostname' should be valid"
        exit 1
    fi
done
echo "PASS"

echo
echo "All install script validation tests passed!"