{ lib, inputs, system, templates, pkgs }:

{
  # Main installation app
  install = {
    type = "app";
    program = "${pkgs.writeShellScript "nixos-templates-install" ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Colors and formatting
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      PURPLE='\033[0;35m'
      CYAN='\033[0;36m'
      NC='\033[0m' # No Color

      # Help function
      show_help() {
        cat << EOF
      ╔══════════════════════════════════════════════════════════════╗
      ║                    NixOS Template Installer                   ║
      ╚══════════════════════════════════════════════════════════════╝

      Usage: nixos-templates-install [OPTIONS] <template> <hostname> [profiles...]

      Templates:
        modern           Modern dynamic system with auto-detection
        ephemeral-zfs    ZFS ephemeral root system
        minimal-zfs      Minimal ZFS system
        deployment       Deployment-focused system
        personal         Personal dotfiles configuration
        unified          Unified disko-based system
        installer        ZFS installer system
        legacy           Legacy/testing configurations

      Examples:
        nixos-templates-install modern workstation desktop kde stable
        nixos-templates-install ephemeral-zfs server headless stable
        nixos-templates-install personal laptop desktop hyprland unstable

      Options:
        --disk DEVICE    Target disk (default: /dev/sda)
        --user USERNAME  Primary username (default: user)
        --timezone TZ    System timezone (default: UTC)
        --dry-run        Show what would be done without executing
        --list-profiles  List available profiles for a template
        --interactive    Interactive mode with guided setup
        --help           Show this help

      Parameters (can be set via --param key=value):
        hostname         System hostname
        username         Primary user
        disk            Target disk device
        timezone        System timezone
        hostId          ZFS host ID (for ZFS templates)
        poolName        ZFS pool name (for ZFS templates)

      Examples with parameters:
        nixos-templates-install --param hostId=abcd1234 ephemeral-zfs myserver headless
        nixos-templates-install --disk /dev/nvme0n1 --user alice modern desktop kde
      EOF
      }

      # Parse arguments
      TEMPLATE=""
      HOSTNAME=""
      PROFILES=()
      DISK="/dev/sda"
      USERNAME="user"
      TIMEZONE="UTC"
      DRY_RUN=false
      LIST_PROFILES=false
      INTERACTIVE=false
      PARAMS=()

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
            LIST_PROFILES=true
            shift
            ;;
          --interactive)
            INTERACTIVE=true
            shift
            ;;
          -*)
            echo -e "''${RED}Unknown option: $1''${NC}"
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

      # List profiles if requested
      if [[ "$LIST_PROFILES" == "true" ]]; then
        if [[ -z "$TEMPLATE" ]]; then
          echo -e "''${RED}Template name required for --list-profiles''${NC}"
          exit 1
        fi
        
        echo -e "''${BLUE}Available profiles for template: ''${TEMPLATE}''${NC}"
        case "$TEMPLATE" in
          modern)
            echo "Desktop: kde, gnome, hyprland, niri"
            echo "System: stable, unstable, hardened, chaotic"
            echo "Usage: gaming, headless, development"
            ;;
          ephemeral-zfs|minimal-zfs)
            echo "System: stable, 25-05"
            echo "Usage: headless, desktop"
            ;;
          deployment)
            echo "Target: remote, local, vm"
            echo "System: stable"
            ;;
          personal)
            echo "Desktop: kde, hyprland"
            echo "System: stable, unstable"
            ;;
          *)
            echo "System: stable"
            echo "Usage: base, desktop, server"
            ;;
        esac
        exit 0
      fi

      # Interactive mode
      if [[ "$INTERACTIVE" == "true" ]]; then
        echo -e "''${CYAN}=== Interactive NixOS Template Setup ===''${NC}"
        
        # Template selection
        if [[ -z "$TEMPLATE" ]]; then
          echo -e "''${YELLOW}Available templates:''${NC}"
          echo "1) modern - Modern dynamic system with auto-detection"
          echo "2) ephemeral-zfs - ZFS ephemeral root system"
          echo "3) minimal-zfs - Minimal ZFS system"
          echo "4) deployment - Deployment-focused system"
          echo "5) personal - Personal dotfiles configuration"
          echo "6) unified - Unified disko-based system"
          echo "7) installer - ZFS installer system"
          echo "8) legacy - Legacy/testing configurations"
          
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
            *) echo -e "''${RED}Invalid selection''${NC}"; exit 1;;
          esac
        fi
        
        # Hostname
        if [[ -z "$HOSTNAME" ]]; then
          read -p "Enter hostname [nixos]: " input_hostname
          HOSTNAME="''${input_hostname:-nixos}"
        fi
        
        # Disk
        echo -e "''${YELLOW}Available disks:''${NC}"
        lsblk -d -o NAME,SIZE,MODEL | grep -E "(nvme|sd[a-z]|hd[a-z])" || true
        read -p "Enter target disk [$DISK]: " input_disk
        DISK="''${input_disk:-$DISK}"
        
        # Profiles based on template
        echo -e "''${YELLOW}Select profiles for ''${TEMPLATE}:''${NC}"
        case "$TEMPLATE" in
          modern)
            read -p "Desktop environment (kde/gnome/hyprland/niri) [kde]: " desktop
            read -p "System version (stable/unstable/hardened/chaotic) [stable]: " sysver
            read -p "Usage type (gaming/headless/development) []: " usage
            PROFILES=(''${desktop:-kde} ''${sysver:-stable})
            [[ -n "$usage" ]] && PROFILES+=("$usage")
            ;;
          ephemeral-zfs|minimal-zfs)
            read -p "System version (stable/25-05) [stable]: " sysver
            read -p "Usage (headless/desktop) [headless]: " usage
            PROFILES=(''${sysver:-stable} ''${usage:-headless})
            ;;
        esac
      fi

      # Validate required arguments
      if [[ -z "$TEMPLATE" ]] || [[ -z "$HOSTNAME" ]]; then
        echo -e "''${RED}Template and hostname are required''${NC}"
        show_help
        exit 1
      fi

      # Build configuration name
      CONFIG_NAME="$HOSTNAME.$TEMPLATE"
      if [[ ''${#PROFILES[@]} -gt 0 ]]; then
        CONFIG_NAME="$CONFIG_NAME.$(IFS=.; echo "''${PROFILES[*]}")"
      fi

      # Build parameter string
      PARAM_STRING=""
      for param in "''${PARAMS[@]}"; do
        PARAM_STRING="$PARAM_STRING --param $param"
      done

      # Show configuration summary
      echo -e "''${CYAN}╔══════════════════════════════════════════════════════════════╗''${NC}"
      echo -e "''${CYAN}║                    Installation Summary                      ║''${NC}"
      echo -e "''${CYAN}╚══════════════════════════════════════════════════════════════╝''${NC}"
      echo -e "''${GREEN}Template:''${NC} $TEMPLATE"
      echo -e "''${GREEN}Hostname:''${NC} $HOSTNAME"
      echo -e "''${GREEN}Profiles:''${NC} ''${PROFILES[*]}"
      echo -e "''${GREEN}Target Disk:''${NC} $DISK"
      echo -e "''${GREEN}Username:''${NC} $USERNAME"
      echo -e "''${GREEN}Timezone:''${NC} $TIMEZONE"
      echo -e "''${GREEN}Configuration:''${NC} $CONFIG_NAME"
      echo ""

      if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "''${YELLOW}[DRY RUN] Would execute:''${NC}"
        echo "1. Partition disk with disko"
        echo "2. Install NixOS with configuration: $CONFIG_NAME"
        echo "3. Set up user account and initial passwords"
        exit 0
      fi

      # Confirmation
      echo -e "''${RED}WARNING: This will COMPLETELY ERASE $DISK!''${NC}"
      read -p "Continue? (yes/no): " confirm
      if [[ "$confirm" != "yes" ]]; then
        echo "Installation aborted."
        exit 1
      fi

      # Installation process
      echo -e "''${BLUE}Starting installation...''${NC}"

      # Step 1: Partition with disko
      echo -e "''${YELLOW}[1/3] Partitioning disk with disko...''${NC}"
      sudo nix run github:nix-community/disko/latest -- \
        --mode disko \
        --flake ".#$CONFIG_NAME" \
        --arg device "\"$DISK\""

      # Step 2: Install NixOS
      echo -e "''${YELLOW}[2/3] Installing NixOS...''${NC}"
      sudo nixos-install \
        --flake ".#$CONFIG_NAME" \
        --no-channel-copy \
        $PARAM_STRING

      # Step 3: Post-install setup
      echo -e "''${YELLOW}[3/3] Post-installation setup...''${NC}"
      sudo nixos-enter --root /mnt -c "
        useradd -m -G wheel,networkmanager,video,audio $USERNAME || true
        passwd $USERNAME
      "

      echo -e "''${GREEN}╔══════════════════════════════════════════════════════════════╗''${NC}"
      echo -e "''${GREEN}║                   Installation Complete!                     ║''${NC}"
      echo -e "''${GREEN}╚══════════════════════════════════════════════════════════════╝''${NC}"
      echo -e "''${CYAN}System installed with template: ''${TEMPLATE}''${NC}"
      echo -e "''${CYAN}Configuration: ''${CONFIG_NAME}''${NC}"
      echo -e "''${CYAN}You can now reboot into your new system.''${NC}"
    ''}/bin/nixos-templates-install";
  };

  # Template listing app
  list = {
    type = "app";
    program = "${pkgs.writeShellScript "nixos-templates-list" ''
      #!/usr/bin/env bash
      
      echo "╔══════════════════════════════════════════════════════════════╗"
      echo "║                     Available Templates                      ║"
      echo "╚══════════════════════════════════════════════════════════════╝"
      echo ""
      echo "🚀 modern"
      echo "   Modern dynamic system with auto-hardware detection"
      echo "   Profiles: desktop (kde/gnome/hyprland), system (stable/unstable)"
      echo ""
      echo "💾 ephemeral-zfs"
      echo "   ZFS ephemeral root system that resets on boot"
      echo "   Profiles: system (stable/25-05), usage (headless/desktop)"
      echo ""
      echo "🔧 minimal-zfs"
      echo "   Minimal ZFS-based system"
      echo "   Profiles: system (stable), usage (base/server)"
      echo ""
      echo "🌐 deployment"
      echo "   System optimized for automated deployment"
      echo "   Profiles: target (remote/local/vm), system (stable)"
      echo ""
      echo "👤 personal"
      echo "   Personal configuration with dotfiles and age encryption"
      echo "   Profiles: desktop (kde/hyprland), system (stable/unstable)"
      echo ""
      echo "🏗️ unified"
      echo "   Unified approach with disko integration"
      echo "   Profiles: system (stable), usage (desktop/server)"
      echo ""
      echo "💿 installer"
      echo "   ZFS installer configuration"
      echo "   Profiles: target (installer), system (stable)"
      echo ""
      echo "🧪 legacy"
      echo "   Legacy and testing configurations"
      echo "   Profiles: version (25-11-pre), usage (testing)"
      echo ""
      echo "Usage:"
      echo "  nix run .#install <template> <hostname> [profiles...]"
      echo "  nix run .#install --interactive"
      echo ""
      echo "Examples:"
      echo "  nix run .#install modern workstation desktop kde stable"
      echo "  nix run .#install ephemeral-zfs server headless stable"
      echo "  nix run .#install --interactive"
    ''}/bin/nixos-templates-list";
  };

  # Template validation app
  validate = {
    type = "app";
    program = "${pkgs.writeShellScript "nixos-templates-validate" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      TEMPLATE="''${1:-}"
      HOSTNAME="''${2:-test}"
      
      if [[ -z "$TEMPLATE" ]]; then
        echo "Usage: nixos-templates-validate <template> [hostname]"
        exit 1
      fi
      
      echo "Validating template: $TEMPLATE"
      echo "Testing with hostname: $HOSTNAME"
      
      # Test configuration evaluation
      if nix eval --show-trace ".#nixosConfigurations.$HOSTNAME.$TEMPLATE.config.system.build.toplevel" >/dev/null 2>&1; then
        echo "✅ Template $TEMPLATE validates successfully"
      else
        echo "❌ Template $TEMPLATE validation failed"
        exit 1
      fi
    ''}/bin/nixos-templates-validate";
  };
}
