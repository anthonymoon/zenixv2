#!/usr/bin/env bash

# NixOS dynamic configuration builder
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
HOSTNAME="${HOSTNAME:-$(hostname)}"
PROFILES=""
FLAKE_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

# Help function
show_help() {
    cat << EOF
NixOS Dynamic Configuration Builder

Usage: $(basename "$0") [OPTIONS] [PROFILES...]

Options:
    -h, --hostname NAME    Set hostname (default: current hostname)
    -f, --flake PATH      Path to flake directory (default: $FLAKE_DIR)
    -l, --list            List available profiles
    -d, --detect          Show detected hardware
    -n, --dry-run         Build but don't switch
    --help                Show this help

Examples:
    # Use current hostname with KDE and gaming
    $(basename "$0") kde gaming stable
    
    # Specify different hostname
    $(basename "$0") -h laptop hyprland unstable
    
    # Headless server
    $(basename "$0") headless hardened
    
    # Show what would be built
    $(basename "$0") -n kde gaming

Available Software Profiles:
    Desktop:  kde, gnome, hyprland, niri
    System:   stable, unstable, hardened, chaotic
    Use:      gaming, headless

Note: Hardware profiles are auto-detected (CPU, GPU, platform)
EOF
}

# List profiles
list_profiles() {
    echo -e "${BLUE}Available Software Profiles:${NC}"
    echo -e "${GREEN}Desktop Environments:${NC} kde, gnome, hyprland, niri"
    echo -e "${GREEN}System Profiles:${NC} stable, unstable, hardened, chaotic"
    echo -e "${GREEN}Use Cases:${NC} gaming, headless"
    echo ""
    echo -e "${YELLOW}Hardware profiles are auto-detected${NC}"
}

# Detect hardware
detect_hardware() {
    echo -e "${BLUE}Detecting hardware...${NC}"
    
    # CPU
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        echo -e "${GREEN}CPU:${NC} Intel"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        echo -e "${GREEN}CPU:${NC} AMD"
    fi
    
    # GPU
    GPUS=""
    [[ -e /sys/module/nvidia ]] && GPUS="nvidia "
    [[ -e /sys/module/amdgpu ]] && GPUS="${GPUS}amd "
    [[ -e /sys/module/i915 ]] && GPUS="${GPUS}intel"
    echo -e "${GREEN}GPU:${NC} ${GPUS:-none detected}"
    
    # Platform
    if grep -q "hypervisor" /proc/cpuinfo; then
        echo -e "${GREEN}Platform:${NC} Virtual Machine"
        if [[ -f /sys/devices/virtual/dmi/id/sys_vendor ]]; then
            echo -e "${GREEN}VM Type:${NC} $(cat /sys/devices/virtual/dmi/id/sys_vendor)"
        fi
    else
        echo -e "${GREEN}Platform:${NC} Physical"
    fi
}

# Parse arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        -f|--flake)
            FLAKE_DIR="$2"
            shift 2
            ;;
        -l|--list)
            list_profiles
            exit 0
            ;;
        -d|--detect)
            detect_hardware
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            PROFILES="${PROFILES}.$1"
            shift
            ;;
    esac
done

# Build configuration name
CONFIG_NAME="${HOSTNAME}${PROFILES}"

echo -e "${BLUE}Building configuration:${NC} ${CONFIG_NAME}"
echo -e "${BLUE}Flake directory:${NC} ${FLAKE_DIR}"

# Build command
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}Dry run - building only${NC}"
    CMD="nix build ${FLAKE_DIR}#nixosConfigurations.${CONFIG_NAME}.config.system.build.toplevel"
else
    CMD="sudo nixos-rebuild switch --flake ${FLAKE_DIR}#${CONFIG_NAME}"
fi

echo -e "${BLUE}Running:${NC} $CMD"
echo ""

# Execute
exec $CMD