#!/usr/bin/env bash
# Run microvm installation test

set -euo pipefail

echo "🧪 NixOS Fun Installation Test"
echo "=============================="

# Check if we have the required tools
if ! command -v nix &> /dev/null; then
    echo "❌ Error: nix is not installed"
    exit 1
fi

if ! nix eval --expr 'builtins.currentSystem' &> /dev/null; then
    echo "❌ Error: nix is not properly configured"
    exit 1
fi

# Run the test
echo "🚀 Starting microvm test..."

cd "$(dirname "$0")/.."

# Build and run the test
nix build -f tests/microvm-test.nix --impure -o result-test

if [[ -f result-test ]]; then
    echo "✅ Test built successfully"
    
    # Run the actual test
    echo "🔄 Running installation test..."
    
    # Use nixos-test to run the test
    nix run nixpkgs#nixosTests.make-test-python -- tests/microvm-test.nix --impure
    
    echo "🎉 Test completed successfully!"
else
    echo "❌ Test build failed"
    exit 1
fi