#!/usr/bin/env bash
# Simple host installation script
set -euo pipefail

# Enable experimental features for this session
export NIX_CONFIG="experimental-features = nix-command flakes"

usage() {
    cat << EOF
Usage: $0 <hostname> [disk] [options]

Install NixOS with disko using the specified hostname configuration.

Arguments:
    hostname    Host configuration to install (e.g., laptop.kde.gaming.unstable)
    disk        Optional disk to use (if not specified, auto-detection is used)

Options:
    --dry-run   Show what would be done without actually installing
    --mount-only  Only mount existing filesystems, don't install

Examples:
    $0 laptop.kde.gaming.unstable
    $0 server.headless.stable /dev/nvme0n1
    $0 workstation.hyprland.unstable --dry-run
    $0 server.headless.stable --mount-only

EOF
}

# Default values
HOSTNAME=""
DISK=""
DRY_RUN=false
MOUNT_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            usage
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --mount-only)
            MOUNT_ONLY=true
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            if [ -z "$HOSTNAME" ]; then
                HOSTNAME="$1"
            elif [ -z "$DISK" ]; then
                DISK="$1"
            else
                echo "Too many arguments" >&2
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$HOSTNAME" ]; then
    echo "Error: hostname is required" >&2
    usage
    exit 1
fi

# Check if running as root for installation
if [ "$DRY_RUN" = false ] && [[ $EUID -ne 0 ]]; then
    echo "Error: Installation requires root privileges. Use sudo." >&2
    exit 1
fi

# Check if nix is available
if ! command -v nix &> /dev/null; then
    echo "Error: Nix is not installed" >&2
    exit 1
fi

# Check if flake exists
if [ ! -f "flake.nix" ]; then
    echo "Error: flake.nix not found. Run from the nixos configuration directory." >&2
    exit 1
fi

echo "NixOS Installation Script"
echo "========================"
echo "Hostname: $HOSTNAME"
if [ -n "$DISK" ]; then
    echo "Disk: $DISK"
else
    echo "Disk: Auto-detect"
fi
echo "Dry run: $DRY_RUN"
echo "Mount only: $MOUNT_ONLY"
echo

# Warn about data destruction
if [ "$MOUNT_ONLY" = false ] && [ "$DRY_RUN" = false ]; then
    echo "⚠️  WARNING: This will DESTROY ALL DATA on the target disk!"
    echo "⚠️  Make sure you have backups of any important data!"
    echo
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Build the command
if [ "$DRY_RUN" = true ]; then
    cmd=(echo "Would run:")
else
    cmd=()
fi

cmd+=(nix run "github:nix-community/disko/latest#disko-install" --)
cmd+=(--flake ".#$HOSTNAME")

if [ "$MOUNT_ONLY" = true ]; then
    cmd+=(--mount-only)
else
    cmd+=(--write-efi-boot-entries)
fi

if [ -n "$DISK" ]; then
    cmd+=(--disk main "$DISK")
fi

echo "Command: ${cmd[*]}"
echo

# Execute the command
if [ "$DRY_RUN" = true ]; then
    "${cmd[@]}"
    echo
    echo "Add --dry-run=false to actually run the installation"
else
    if "${cmd[@]}"; then
        echo
        echo "✅ Installation completed successfully!"
        
        if [ "$MOUNT_ONLY" = false ]; then
            echo
            echo "Next steps:"
            echo "  1. Reboot into your new system"
            echo "  2. Set user passwords: sudo passwd <username>"
            echo "  3. Run: sudo nixos-rebuild switch"
            
            # Check if encryption was used
            if echo "$HOSTNAME" | grep -q "luks"; then
                echo "  4. Set up TPM2 auto-unlock (see documentation)"
                echo "  5. Configure secure boot with lanzaboote"
            fi
        else
            echo
            echo "Filesystems mounted. You can now:"
            echo "  • Chroot: nixos-enter"
            echo "  • Make changes and rebuild"
            echo "  • Unmount when done"
        fi
    else
        echo
        echo "❌ Installation failed!"
        exit 1
    fi
fi