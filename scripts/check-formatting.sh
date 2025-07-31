#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "🔍 Checking Nix formatting for all repositories..."
echo

# Base directories to check
REPOS=(
    "/Users/amoon/nix/nix/nixos-claude"
    "/Users/amoon/nix/nix/nixos-fun"
    "/Users/amoon/nix/nix/nixos-unified"
    "/Users/amoon/nix/nix/nixos-zfs"
    "/Users/amoon/nix/nix/nixos-zfsroot"
    "/Users/amoon/nix/nixos-zfs"
    "/Users/amoon/nix/nixos-zfs-installer"
    "/Users/amoon/nix/nixos-zfs-minimal"
    "/Users/amoon/nix/nixos-zfsroot"
)

TOTAL_FILES=0
UNFORMATTED_FILES=0

for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        echo -e "${YELLOW}Checking repository: $repo${NC}"
        
        # Find all .nix files
        while IFS= read -r -d '' file; do
            TOTAL_FILES=$((TOTAL_FILES + 1))
            
            # Check if file needs formatting
            if ! nixpkgs-fmt --check "$file" &>/dev/null; then
                echo -e "  ${RED}✗${NC} $file needs formatting"
                UNFORMATTED_FILES=$((UNFORMATTED_FILES + 1))
                
                # Optionally format the file
                if [ "${1:-}" = "--fix" ]; then
                    nixpkgs-fmt "$file"
                    echo -e "    ${GREEN}→ Fixed${NC}"
                fi
            else
                if [ "${VERBOSE:-}" = "1" ]; then
                    echo -e "  ${GREEN}✓${NC} $file"
                fi
            fi
        done < <(find "$repo" -name "*.nix" -type f -print0 2>/dev/null)
        
        echo
    fi
done

echo "📊 Summary:"
echo "  Total .nix files checked: $TOTAL_FILES"
echo "  Files needing formatting: $UNFORMATTED_FILES"

if [ $UNFORMATTED_FILES -gt 0 ]; then
    echo
    echo -e "${YELLOW}💡 To fix formatting issues, run:${NC}"
    echo "  $0 --fix"
    exit 1
else
    echo -e "${GREEN}✅ All files are properly formatted!${NC}"
fi