#!/usr/bin/env bash
# Test ephemeral root configuration

set -e

echo "=== Testing Ephemeral Root Configuration ==="

# Test 1: Check rollback service exists
echo -n "Test 1 - Rollback service defined: "
if grep -q "services.rollback-root" hardware/hardware-configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Check ZFS rollback command
echo -n "Test 2 - ZFS rollback command: "
if grep -q "zfs rollback -r rpool/nixos/empty@start" hardware/hardware-configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Check persistent paths
echo -n "Test 3 - Persistent paths configured: "
PERSISTENT_PATHS=("/nix" "/home" "/var/log" "/var/lib" "/etc/nixos" "/persist")
MISSING_PATHS=()

for path in "${PERSISTENT_PATHS[@]}"; do
    if ! grep -q "fileSystems.\"$path\"" hardware/hardware-configuration.nix; then
        MISSING_PATHS+=("$path")
    fi
done

if [ ${#MISSING_PATHS[@]} -eq 0 ]; then
    echo "PASS"
else
    echo "FAIL - Missing paths: ${MISSING_PATHS[*]}"
    exit 1
fi

# Test 4: Check root filesystem
echo -n "Test 4 - Root filesystem on ephemeral dataset: "
if grep -A2 'fileSystems."/"' hardware/hardware-configuration.nix | grep -q 'device = "rpool/nixos/empty"'; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 5: Check snapshot creation in disko
echo -n "Test 5 - Snapshot creation configured: "
if grep -q 'postCreateHook = "zfs snapshot rpool/nixos/empty@start"' hardware/disko-config.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 6: Check persistence configuration
echo -n "Test 6 - SSH key persistence: "
if grep -q "/persist/etc/ssh" configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 7: Check machine-id persistence
echo -n "Test 7 - Machine ID persistence: "
if grep -q 'environment.etc."machine-id".source = "/persist/etc/machine-id"' configuration.nix; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo
echo "All ephemeral root tests passed!"