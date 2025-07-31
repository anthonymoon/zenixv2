#!/usr/bin/env bash
# Pre-commit hook script for NixOS configuration

set -e

echo "Running pre-commit checks..."

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find all .nix files
NIX_FILES=$(find . -name "*.nix" -type f | grep -v ".git" | grep -v "result")

# Check syntax
echo -e "${YELLOW}Checking nix syntax...${NC}"
SYNTAX_ERRORS=0
for file in $NIX_FILES; do
    if nix-instantiate --parse "$file" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file"
        nix-instantiate --parse "$file" 2>&1 | sed 's/^/    /'
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
done

if [ $SYNTAX_ERRORS -gt 0 ]; then
    echo -e "${RED}Found $SYNTAX_ERRORS syntax errors${NC}"
    exit 1
fi

# Check for common anti-patterns
echo -e "\n${YELLOW}Checking for anti-patterns...${NC}"
PATTERN_ISSUES=0

# Check for rec in let bindings (can cause infinite recursion)
if grep -n "let rec" $NIX_FILES 2>/dev/null; then
    echo -e "  ${RED}✗${NC} Found 'let rec' which can cause infinite recursion"
    PATTERN_ISSUES=$((PATTERN_ISSUES + 1))
fi

# Check for unnecessary string interpolation
if grep -n '"\${[^}]*}"' $NIX_FILES 2>/dev/null | grep -v "\\\\"; then
    echo -e "  ${RED}✗${NC} Found unnecessary string interpolation"
    PATTERN_ISSUES=$((PATTERN_ISSUES + 1))
fi

# Check for hardcoded /nix/store paths
if grep -n "/nix/store/[a-z0-9]\{32\}" $NIX_FILES 2>/dev/null; then
    echo -e "  ${RED}✗${NC} Found hardcoded /nix/store paths"
    PATTERN_ISSUES=$((PATTERN_ISSUES + 1))
fi

if [ $PATTERN_ISSUES -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} No anti-patterns found"
fi

# Run flake check if available
if [ -f "flake.nix" ]; then
    echo -e "\n${YELLOW}Running flake check...${NC}"
    if nix flake check 2>&1; then
        echo -e "  ${GREEN}✓${NC} Flake check passed"
    else
        echo -e "  ${RED}✗${NC} Flake check failed"
        exit 1
    fi
fi

echo -e "\n${GREEN}All pre-commit checks passed!${NC}"