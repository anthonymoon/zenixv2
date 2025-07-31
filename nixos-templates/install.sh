#!/usr/bin/env bash
set -euo pipefail

# NixOS Templates Installation Script
# Unified installation system for all NixOS template configurations

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Default values
TEMPLATE=""
HOSTNAME=""
PROFILES=()
DISK="/dev/sda"
USERNAME="user"
TIMEZONE="UTC"
DRY_RUN=false
INTERACTIVE=false
PARAMS=()

# Help function
show_help() {
    cat << EOF
╔══════════════════════════════════════════════════════════════╗
║                    NixOS Template Installer                   ║
║                  Unified Multi-Repository System             ║
╚══════════════════════════════════════════════════════════════╝

Usage: $0 [OPTIONS] <template> <hostname> [profiles...]

📋 Available Templates (AMD Workstation Optimized):
  modern           🚀 Modern dynamic system with auto-detection
  ephemeral-zfs    💾 ZFS ephemeral root system
  minimal-zfs      🔧 Minimal ZFS system  
  deployment       🌐 Deployment-focused system
  personal         👤 Personal dotfiles configuration
  unified          🏗️ Unified disko-based system
  installer        💿 ZFS installer system
  legacy           🧪 Legacy/testing configurations

💡 Workstation Profile Examples:
  Desktop Environments: kde (Plasma6), gnome, hyprland
  Display Managers: tui-greet, gdm  
  System Versions: stable, unstable, hardened
  Usage Types: gaming, development, workstation

🖥️ AMD Workstation Standards:
  • ZFS root filesystem with systemd-boot
  • AMDGPU driver support only
  • Always DHCP networking
  • PipeWire audio system
  • Wayland-first desktop environments

🎯 Quick Examples:
  $0 modern workstation desktop kde stable
  $0 ephemeral-zfs server headless stable  
  $0 personal laptop desktop hyprland unstable
  $0 --interactive  # Guided setup

⚙️ Options:
  --disk DEVICE      Target disk (default: /dev/sda)
  --user USERNAME    Primary username (default: user)  
  --timezone TZ      System timezone (default: UTC)
  --param key=value  Set template parameter
  --dry-run          Show what would be done
  --list-profiles T  List available profiles for template T
  --interactive      Interactive guided setup
  --help             Show this help

🔧 Parameters (via --param key=value):
  hostname          System hostname
  username          Primary user
  disk             Target disk device
  timezone         System timezone
  hostId           ZFS host ID (for ZFS templates)
  poolName         ZFS pool name (for ZFS templates)
  email            Email address (for personal template)

📚 Examples with Parameters:
  $0 --param hostId=abcd1234 ephemeral-zfs myserver headless
  $0 --disk /dev/nvme0n1 --user alice modern desktop kde
  $0 --param email=user@domain.com personal laptop hyprland

🌐 Remote Installation:
  curl -sSL https://github.com/user/nixos-templates/raw/main/install.sh | bash -s -- modern workstation kde
EOF
}

# List available profiles for a template
list_profiles() {
    local template="$1"
    echo -e "${BLUE}Available profiles for template: ${template}${NC}"
    
    if [[ ! -f "$TEMPLATES_DIR/$template/template.nix" ]]; then
        echo -e "${RED}Template '$template' not found${NC}"
        return 1
    fi
    
    case "$template" in
        modern)
            echo "🖥️  Desktop: kde (Plasma6), gnome, hyprland"
            echo "📺 Display Manager: tui-greet, gdm"
            echo "⚙️  System: stable, unstable, hardened"
            echo "🎮 Usage: gaming, development"
            ;;
        ephemeral-zfs|minimal-zfs)
            echo "⚙️  System: stable"
            echo "💻 Usage: headless, desktop"
            echo "🖥️  Desktop: kde, gnome, hyprland"
            ;;
        deployment)
            echo "🎯 Target: remote, local, vm"
            echo "⚙️  System: stable"
            ;;
        personal)
            echo "🖥️  Desktop: kde (Plasma6), hyprland"
            echo "⚙️  System: stable, unstable"
            ;;
        unified|installer|legacy)
            echo "⚙️  System: stable"
            echo "💻 Usage: desktop, workstation"
            echo "🖥️  Desktop: kde, gnome, hyprland"
            ;;
        *)
            echo "⚙️  System: stable"
            echo "💻 Usage: workstation"
            ;;
    esac
}

# Interactive mode
interactive_setup() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Interactive NixOS Template Setup                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Template selection
    if [[ -z "$TEMPLATE" ]]; then
        echo -e "${YELLOW}📋 Available templates:${NC}"
        echo "1) modern - 🚀 Modern dynamic system with auto-detection"
        echo "2) ephemeral-zfs - 💾 ZFS ephemeral root system"
        echo "3) minimal-zfs - 🔧 Minimal ZFS system"
        echo "4) deployment - 🌐 Deployment-focused system"
        echo "5) personal - 👤 Personal dotfiles configuration"
        echo "6) unified - 🏗️ Unified disko-based system"
        echo "7) installer - 💿 ZFS installer system"
        echo "8) legacy - 🧪 Legacy/testing configurations"
        echo ""
        
        read -p "Select template (1-8): " template_choice
        case $template_choice in
            1) TEMPLATE="modern";;
            2) TEMPLATE="ephemeral-zfs";;
            3) TEMPLATE="minimal-zfs";;
            4) TEMPLATE="deployment";;
            5) TEMPLATE="personal";;
            6) TEMPLATE="unified";;
            7) TEMPLATE="installer";;
            8) TEMPLATE="legacy";;
            *) echo -e "${RED}Invalid selection${NC}"; exit 1;;
        esac
    fi
    
    # Hostname
    if [[ -z "$HOSTNAME" ]]; then
        read -p "🏠 Enter hostname [nixos]: " input_hostname
        HOSTNAME="${input_hostname:-nixos}"
    fi
    
    # Username
    read -p "👤 Enter username [$USERNAME]: " input_username
    USERNAME="${input_username:-$USERNAME}"
    
    # Disk selection
    echo -e "${YELLOW}💾 Available disks:${NC}"
    lsblk -d -o NAME,SIZE,MODEL 2>/dev/null | grep -E "(nvme|sd[a-z]|hd[a-z])" || echo "Unable to detect disks automatically"
    read -p "💽 Enter target disk [$DISK]: " input_disk
    DISK="${input_disk:-$DISK}"
    
    # Timezone
    read -p "🌍 Enter timezone [$TIMEZONE]: " input_timezone
    TIMEZONE="${input_timezone:-$TIMEZONE}"
    
    # Profiles based on template
    echo -e "${YELLOW}🔧 Available profiles for ${TEMPLATE}:${NC}"
    list_profiles "$TEMPLATE"
    echo ""
    
    case "$TEMPLATE" in
        modern)
            read -p "🖥️  Desktop environment (kde/gnome/hyprland) [kde]: " desktop
            read -p "📺 Display manager (tui-greet/gdm) [auto]: " dm
            read -p "⚙️  System version (stable/unstable/hardened) [stable]: " sysver
            read -p "🎮 Usage type (gaming/development) []: " usage
            PROFILES=("${desktop:-kde}" "${sysver:-stable}")
            [[ -n "$dm" && "$dm" != "auto" ]] && PROFILES+=("$dm")
            [[ -n "$usage" ]] && PROFILES+=("$usage")
            ;;
        ephemeral-zfs|minimal-zfs)
            read -p "⚙️  System version (stable) [stable]: " sysver
            read -p "💻 Usage (headless/desktop) [desktop]: " usage
            PROFILES=("${sysver:-stable}" "${usage:-desktop}")
            if [[ "${usage:-desktop}" == "desktop" ]]; then
                read -p "🖥️  Desktop environment (kde/gnome/hyprland) [kde]: " desktop
                read -p "📺 Display manager (tui-greet/gdm) [auto]: " dm
                PROFILES+=("${desktop:-kde}")
                [[ -n "$dm" && "$dm" != "auto" ]] && PROFILES+=("$dm")
            fi
            # ZFS-specific parameters
            read -p "🆔 ZFS Host ID (8 hex chars) [$(head -c 8 /etc/machine-id 2>/dev/null || echo 'deadbeef')]: " hostid
            PARAMS+=("hostId=${hostid:-deadbeef}")
            ;;
        personal)
            read -p "🖥️  Desktop environment (kde/hyprland) [kde]: " desktop
            read -p "📺 Display manager (tui-greet/gdm) [auto]: " dm
            read -p "⚙️  System version (stable/unstable) [stable]: " sysver
            read -p "📧 Email address: " email
            PROFILES=("${desktop:-kde}" "${sysver:-stable}")
            [[ -n "$dm" && "$dm" != "auto" ]] && PROFILES+=("$dm")
            [[ -n "$email" ]] && PARAMS+=("email=$email")
            ;;
        *)
            read -p "⚙️  System version [stable]: " sysver
            read -p "💻 Usage type [workstation]: " usage
            read -p "🖥️  Desktop environment (kde/gnome/hyprland) [kde]: " desktop
            PROFILES=("${sysver:-stable}" "${usage:-workstation}" "${desktop:-kde}")
            ;;
    esac
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --disk)
                DISK="$2"
                shift 2
                ;;
            --user)
                USERNAME="$2"
                shift 2
                ;;
            --timezone)
                TIMEZONE="$2"
                shift 2
                ;;
            --param)
                PARAMS+=("$2")
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --list-profiles)
                if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                    list_profiles "$2"
                    exit 0
                else
                    echo -e "${RED}Template name required for --list-profiles${NC}"
                    exit 1
                fi
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$TEMPLATE" ]]; then
                    TEMPLATE="$1"
                elif [[ -z "$HOSTNAME" ]]; then
                    HOSTNAME="$1"
                else
                    PROFILES+=("$1")
                fi
                shift
                ;;
        esac
    done
}

# Validate template and configuration
validate_config() {
    # Check if template exists
    if [[ ! -d "$TEMPLATES_DIR/$TEMPLATE" ]]; then
        echo -e "${RED}❌ Template '$TEMPLATE' not found${NC}"
        echo -e "${YELLOW}Available templates:${NC}"
        ls -1 "$TEMPLATES_DIR" | sed 's/^/  /'
        exit 1
    fi
    
    # Check if disk exists
    if [[ ! -b "$DISK" ]] && [[ "$DRY_RUN" == "false" ]]; then
        echo -e "${RED}❌ Disk '$DISK' not found${NC}"
        echo -e "${YELLOW}Available disks:${NC}"
        lsblk -d -o NAME,SIZE,MODEL 2>/dev/null || echo "Unable to list disks"
        exit 1
    fi
    
    # Validate hostname
    if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
        echo -e "${RED}❌ Invalid hostname: $HOSTNAME${NC}"
        exit 1
    fi
    
    # Validate username
    if [[ ! "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}❌ Invalid username: $USERNAME${NC}"
        exit 1
    fi
}

# Show installation summary
show_summary() {
    local config_name="$HOSTNAME.$TEMPLATE"
    if [[ ${#PROFILES[@]} -gt 0 ]]; then
        config_name="$config_name.$(IFS=.; echo "${PROFILES[*]}")"
    fi
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Installation Summary                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}📋 Template:${NC} $TEMPLATE"
    echo -e "${GREEN}🏠 Hostname:${NC} $HOSTNAME"  
    echo -e "${GREEN}👤 Username:${NC} $USERNAME"
    echo -e "${GREEN}🔧 Profiles:${NC} ${PROFILES[*]:-none}"
    echo -e "${GREEN}💽 Target Disk:${NC} $DISK"
    echo -e "${GREEN}🌍 Timezone:${NC} $TIMEZONE"
    echo -e "${GREEN}⚙️  Configuration:${NC} $config_name"
    
    if [[ ${#PARAMS[@]} -gt 0 ]]; then
        echo -e "${GREEN}🔧 Parameters:${NC}"
        for param in "${PARAMS[@]}"; do
            echo -e "   • $param"
        done
    fi
    echo ""
}

# Execute installation
install_system() {
    local config_name="$HOSTNAME.$TEMPLATE"
    if [[ ${#PROFILES[@]} -gt 0 ]]; then
        config_name="$config_name.$(IFS=.; echo "${PROFILES[*]}")"
    fi
    
    # Build parameter arguments
    local param_args=""
    for param in "${PARAMS[@]}"; do
        param_args="$param_args --param $param"
    done
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY RUN] Would execute:${NC}"
        echo "1. 💽 Partition disk: $DISK"
        echo "2. 📦 Install NixOS: $config_name"
        echo "3. 👤 Setup user: $USERNAME"
        echo "4. ⚙️  Apply parameters: ${PARAMS[*]:-none}"
        return 0
    fi
    
    echo -e "${RED}⚠️  WARNING: This will COMPLETELY ERASE $DISK!${NC}"
    read -p "Continue with installation? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "❌ Installation aborted."
        exit 1
    fi
    
    echo -e "${BLUE}🚀 Starting installation...${NC}"
    
    # Step 1: Partition with disko
    echo -e "${YELLOW}[1/4] 💽 Partitioning disk with disko...${NC}"
    if ! sudo nix run github:nix-community/disko/latest -- \
        --mode disko \
        --flake "$SCRIPT_DIR#$config_name" \
        --arg device "\"$DISK\""; then
        echo -e "${RED}❌ Disk partitioning failed${NC}"
        exit 1
    fi
    
    # Step 2: Configure nix in target
    echo -e "${YELLOW}[2/4] ⚙️  Configuring nix settings...${NC}"
    sudo mkdir -p /mnt/etc/nix
    sudo tee /mnt/etc/nix/nix.conf > /dev/null << 'EOF'
experimental-features = nix-command flakes
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
max-jobs = auto
cores = 0
EOF
    
    # Step 3: Install NixOS
    echo -e "${YELLOW}[3/4] 📦 Installing NixOS system...${NC}"
    if ! sudo nixos-install \
        --flake "$SCRIPT_DIR#$config_name" \
        --no-channel-copy \
        $param_args; then
        echo -e "${RED}❌ NixOS installation failed${NC}"
        exit 1
    fi
    
    # Step 4: Post-install setup
    echo -e "${YELLOW}[4/4] 🔧 Post-installation setup...${NC}"
    sudo nixos-enter --root /mnt -c "
        # Create user if it doesn't exist
        if ! id $USERNAME &>/dev/null; then
            useradd -m -G wheel,networkmanager,video,audio $USERNAME
        fi
        
        # Set timezone
        timedatectl set-timezone $TIMEZONE || true
        
        echo 'Please set passwords for root and $USERNAME after reboot'
    " || echo "⚠️  Some post-install steps may need manual completion"
    
    # Success message
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   ✅ Installation Complete!                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}🎉 System installed with template: ${TEMPLATE}${NC}"
    echo -e "${CYAN}⚙️  Configuration: ${config_name}${NC}"
    echo -e "${CYAN}👤 Username: ${USERNAME}${NC}"
    echo -e "${CYAN}🔧 Next steps:${NC}"
    echo -e "   1. 🔄 Reboot: sudo reboot"
    echo -e "   2. 🔑 Set passwords for root and $USERNAME"
    echo -e "   3. 🚀 Enjoy your new NixOS system!"
}

# Main execution
main() {
    # Show banner
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                   NixOS Templates Installer                  ║${NC}"
    echo -e "${PURPLE}║                 Unified Multi-Repository System             ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Parse arguments
    parse_args "$@"
    
    # Run interactive mode if requested
    if [[ "$INTERACTIVE" == "true" ]]; then
        interactive_setup
    fi
    
    # Validate required arguments
    if [[ -z "$TEMPLATE" ]] || [[ -z "$HOSTNAME" ]]; then
        echo -e "${RED}❌ Template and hostname are required${NC}"
        echo -e "${YELLOW}💡 Use --interactive for guided setup${NC}"
        echo -e "${YELLOW}💡 Use --help for detailed usage${NC}"
        exit 1
    fi
    
    # Validate configuration
    validate_config
    
    # Show summary
    show_summary
    
    # Execute installation
    install_system
}

# Run main function with all arguments
main "$@"