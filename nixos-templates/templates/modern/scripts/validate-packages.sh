#!/usr/bin/env bash
# Validate all package names in systemPackages

set -euo pipefail

echo "Validating package names in systemPackages..."

# Extract package names from the systemPackages file
PACKAGES_FILE="environment/systemPackages/default.nix"

if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo "Error: $PACKAGES_FILE not found"
    exit 1
fi

# Extract package names (simple regex for packages not in comments)
PACKAGES=$(grep -E '^\s*[a-zA-Z0-9_-]+\s*$' "$PACKAGES_FILE" | sed 's/^\s*//;s/\s*$//' | grep -v '^#')

FAILED_PACKAGES=()
TOTAL_PACKAGES=0

echo "Checking packages..."

for pkg in $PACKAGES; do
    TOTAL_PACKAGES=$((TOTAL_PACKAGES + 1))
    echo -n "  $pkg... "
    
    if nix eval --expr "with import <nixpkgs> {}; $pkg.name or \"$pkg\"" &>/dev/null; then
        echo "✓"
    else
        echo "✗"
        FAILED_PACKAGES+=("$pkg")
    fi
done

echo ""
echo "Results:"
echo "  Total packages checked: $TOTAL_PACKAGES"
echo "  Failed: ${#FAILED_PACKAGES[@]}"

if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
    echo ""
    echo "Failed packages:"
    for pkg in "${FAILED_PACKAGES[@]}"; do
        echo "  ✗ $pkg"
        # Try to suggest alternatives
        echo -n "    Searching for alternatives... "
        ALTERNATIVES=$(nix search nixpkgs "^$pkg" --json 2>/dev/null | jq -r 'keys[]' | head -5 || echo "")
        if [[ -n "$ALTERNATIVES" ]]; then
            echo "Found:"
            echo "$ALTERNATIVES" | sed 's/^/      /'
        else
            echo "None found"
        fi
    done
    exit 1
else
    echo "All packages validated successfully! ✓"
fi