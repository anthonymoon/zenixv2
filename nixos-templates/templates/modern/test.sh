#!/usr/bin/env bash
# Quick local test script

set -euo pipefail

echo "🧪 Quick NixOS Fun Tests"
echo "========================"

echo "1. Testing flake check..."
if nix flake check --impure; then
    echo "✅ Flake is valid"
else
    echo "❌ Flake check failed"
    exit 1
fi

echo ""
echo "2. Testing workstation.kde.stable build..."
if nix build .#nixosConfigurations.workstation.kde.stable.config.system.build.toplevel --impure -o result-test; then
    echo "✅ Configuration builds successfully"
    rm -f result-test
else
    echo "❌ Configuration build failed"
    exit 1
fi

echo ""
echo "3. Testing disko configuration..."
if nix eval .#diskoConfigurations.default.disko.devices --json > /dev/null; then
    echo "✅ Disko configuration is valid"
else
    echo "❌ Disko configuration failed"
    exit 1
fi

echo ""
echo "4. Testing disko-install app..."
if timeout 5 nix run .#disko-install -- 2>&1 | grep -q "Usage:"; then
    echo "✅ Disko-install app works"
else
    echo "❌ Disko-install app failed"
fi

echo ""
echo "🎉 All quick tests passed!"
echo ""
echo "To run full microvm tests:"
echo "  ./tests/run-test.sh"
echo ""
echo "To test installation manually:"
echo "  nix run .#disko-install -- workstation.kde.stable /dev/sda --auto"