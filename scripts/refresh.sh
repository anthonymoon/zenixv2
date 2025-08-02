#!/usr/bin/env bash
# Refresh NixOS configuration from GitHub and rebuild

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔄 Refreshing NixOS configuration...${NC}"

# Parse arguments
FLAKE_REF="${1:-github:anthonymoon/zenixv2#nixie}"
OPERATION="${2:-switch}"

# Extract flake URL and hostname
if [[ "$FLAKE_REF" =~ ^(.+)#(.+)$ ]]; then
    FLAKE_URL="${BASH_REMATCH[1]}"
    HOSTNAME="${BASH_REMATCH[2]}"
else
    echo -e "${RED}❌ Invalid flake reference format. Use: flake-url#hostname${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Flake: ${FLAKE_URL}${NC}"
echo -e "${GREEN}🖥️  Host: ${HOSTNAME}${NC}"
echo -e "${GREEN}🔧 Operation: ${OPERATION}${NC}"

# Update flake inputs
echo -e "\n${YELLOW}📥 Updating flake inputs...${NC}"
nix flake update "$FLAKE_URL" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not update flake inputs (this is normal for remote flakes)${NC}"

# Build the system
echo -e "\n${YELLOW}🔨 Building system configuration...${NC}"
if sudo nixos-rebuild "$OPERATION" --flake "$FLAKE_REF"; then
    echo -e "\n${GREEN}✅ System successfully updated!${NC}"
    
    # Show current generation
    echo -e "\n${YELLOW}📊 Current system generation:${NC}"
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -n 1
    
    # Reminder for boot vs switch
    if [[ "$OPERATION" == "boot" ]]; then
        echo -e "\n${YELLOW}💡 Changes will take effect after reboot${NC}"
        echo -e "   Run: ${GREEN}sudo reboot${NC}"
    fi
else
    echo -e "\n${RED}❌ Build failed!${NC}"
    echo -e "${YELLOW}💡 Try running with --show-trace for more details:${NC}"
    echo -e "   sudo nixos-rebuild $OPERATION --flake $FLAKE_REF --show-trace"
    exit 1
fi