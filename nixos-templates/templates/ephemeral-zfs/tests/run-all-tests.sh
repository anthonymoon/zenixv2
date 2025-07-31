#!/usr/bin/env bash
# Run all tests

set -e

echo "=== Running All Tests ==="
echo

# Make sure we're in the right directory
cd "$(dirname "$0")/.."

# Make test scripts executable
chmod +x tests/*.sh

# Run each test
for test in tests/test-*.sh; do
    echo "Running $(basename "$test")..."
    if bash "$test"; then
        echo "✓ $(basename "$test") passed"
    else
        echo "✗ $(basename "$test") failed"
        exit 1
    fi
    echo
done

echo "=== All Tests Passed! ==="