{
  description = "Unified NixOS Configuration Framework";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Development
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Disk management
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hardware detection
    nixos-facter = {
      url = "github:nix-community/nixos-facter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nixos-facter-modules = {
      url = "github:nix-community/nixos-facter-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Additional inputs - uncomment as needed:
    # nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixos-hardware.url = "github:NixOS/nixos-hardware";
    # agenix = {
    #   url = "github:ryantm/agenix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # lanzaboote = {
    #   url = "github:nix-community/lanzaboote/v0.4.1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, disko, nixos-facter, nixos-facter-modules, ... }@inputs:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      
      # Common library functions
      lib = import ./lib { inherit inputs; };
    in
    {
      # Development shells
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            nixfmt-rfc-style
            statix
            deadnix
            git
            age
            ssh-to-age
          ];
          shellHook = ''
            ${inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                nixfmt.enable = true;
                statix.enable = true;
                deadnix.enable = true;
              };
            }.shellHook}
          '';
        };
      });

      # NixOS configurations
      nixosConfigurations = {
        # Minimal configurations
        minimal = lib.mkSystem {
          hostname = "minimal";
          system = "x86_64-linux";
          modules = [
            ./hosts/minimal
            ./modules/profiles/minimal
          ];
        };
        
        minimal-zfs = lib.mkSystem {
          hostname = "minimal-zfs";
          system = "x86_64-linux";
          modules = [
            ./hosts/minimal-zfs
            ./modules/profiles/minimal
            ./modules/storage/zfs
          ];
        };
        
        # Auto-configured system with hardware detection
        auto-zfs = lib.mkSystem {
          hostname = "auto-zfs";
          system = "x86_64-linux";
          modules = [
            ./hosts/auto-zfs
            ./modules/profiles/minimal
          ];
        };
        
        # Ephemeral systems
        ephemeral = lib.mkSystem {
          hostname = "ephemeral";
          system = "x86_64-linux";
          modules = [
            ./hosts/ephemeral
            ./modules/profiles/ephemeral
            ./modules/storage/tmpfs-root
          ];
        };
        
        ephemeral-zfs = lib.mkSystem {
          hostname = "ephemeral-zfs";
          system = "x86_64-linux";
          modules = [
            ./hosts/ephemeral-zfs
            ./modules/profiles/ephemeral
            ./modules/storage/zfs-ephemeral
          ];
        };
        
        # Workstation configurations
        workstation = lib.mkSystem {
          hostname = "workstation";
          system = "x86_64-linux";
          modules = [
            ./hosts/workstation
            ./modules/profiles/workstation
            ./modules/desktop/kde
          ];
        };
        
        workstation-gnome = lib.mkSystem {
          hostname = "workstation-gnome";
          system = "x86_64-linux";
          modules = [
            ./hosts/workstation
            ./modules/profiles/workstation
            ./modules/desktop/gnome
          ];
        };
        
        # Gaming system
        gaming = lib.mkSystem {
          hostname = "gaming";
          system = "x86_64-linux";
          modules = [
            ./hosts/gaming
            ./modules/profiles/gaming
            ./modules/desktop/kde
            ./modules/hardware/nvidia
          ];
        };
        
        # Server configurations
        server = lib.mkSystem {
          hostname = "server";
          system = "x86_64-linux";
          modules = [
            ./hosts/server
            ./modules/profiles/server
            ./modules/services/common-server
          ];
        };
        
        # Development machine
        dev = lib.mkSystem {
          hostname = "dev";
          system = "x86_64-linux";
          modules = [
            ./hosts/dev
            ./modules/profiles/development
            ./modules/desktop/kde
          ];
        };
        
        # Security-focused
        hardened = lib.mkSystem {
          hostname = "hardened";
          system = "x86_64-linux";
          modules = [
            ./hosts/hardened
            ./modules/profiles/hardened
            ./modules/security/full-hardening
          ];
        };
      };

      # Templates for quick starts
      templates = {
        minimal = {
          path = ./templates/minimal;
          description = "Minimal NixOS configuration";
        };
        
        ephemeral = {
          path = ./templates/ephemeral;
          description = "Ephemeral system with tmpfs root";
        };
        
        workstation = {
          path = ./templates/workstation;
          description = "Desktop workstation configuration";
        };
        
        server = {
          path = ./templates/server;
          description = "Server configuration";
        };
      };

      # Shared modules for external consumption
      nixosModules = {
        # Storage modules
        zfs = import ./modules/storage/zfs;
        zfs-ephemeral = import ./modules/storage/zfs-ephemeral;
        tmpfs-root = import ./modules/storage/tmpfs-root;
        
        # Desktop environments
        kde = import ./modules/desktop/kde;
        gnome = import ./modules/desktop/gnome;
        
        # Hardware support
        nvidia = import ./modules/hardware/nvidia;
        amd = import ./modules/hardware/amd;
        intel = import ./modules/hardware/intel;
        
        # Security
        hardening = import ./modules/security/hardening;
        
        # Common configurations
        common = import ./modules/common;
        cachix = import ./modules/common/cachix.nix;
      };
      
      # Disko configurations
      diskoConfigurations = {
        minimal-zfs = import ./hosts/minimal-zfs/disko.nix;
      };

      # Helper functions
      lib = {
        mkSystem = lib.mkSystem;
        mkProfile = lib.mkProfile;
        hardware = lib.hardware;
      };

      # Checks
      checks = forAllSystems (system: {
        pre-commit = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      });

      # Apps for common operations
      apps = forAllSystems (system: {
        install = {
          type = "app";
          program = "${self.packages.${system}.installer}/bin/nixos-install-unified";
        };
        
        deploy = {
          type = "app";
          program = "${self.packages.${system}.deployer}/bin/nixos-deploy";
        };
        
        # Disko formatters for each configuration
        format-minimal-zfs = {
          type = "app";
          program = toString (nixpkgs.legacyPackages.${system}.writeShellScript "format-minimal-zfs" ''
            set -e
            echo "Formatting disk with minimal-zfs configuration..."
            ${disko.packages.${system}.disko}/bin/disko \
              --mode disko \
              --flake ${self}#minimal-zfs \
              -- \
              --arg device \"''${DISK:-/dev/nvme0n1}\"
          '');
        };
        
        # Dynamic installer with hardware detection
        install-auto = {
          type = "app";
          program = toString (nixpkgs.legacyPackages.${system}.writeShellScript "install-auto" ''
            #!${nixpkgs.legacyPackages.${system}.bash}/bin/bash
            set -euo pipefail
            
            echo "NixOS Auto-Installer with Hardware Detection"
            echo "==========================================="
            
            # Configuration
            HOSTNAME=''${HOSTNAME:-minimal-zfs}
            POOL_NAME=''${POOL_NAME:-rpool}
            
            # Step 1: Run hardware detection
            echo "Step 1: Detecting hardware..."
            FACTER_REPORT=$(mktemp /tmp/facter-XXXXXX.json)
            trap "rm -f $FACTER_REPORT" EXIT
            
            ${nixos-facter.packages.${system}.default}/bin/nixos-facter -o "$FACTER_REPORT"
            
            echo "Hardware detection complete. Report saved to: $FACTER_REPORT"
            
            # Display detected hardware
            echo ""
            echo "Detected Hardware:"
            echo "=================="
            ${nixpkgs.legacyPackages.${system}.jq}/bin/jq -r '
              "CPU: \(.hardware.cpu.model // "Unknown")",
              "Memory: \((.hardware.memory.total // 0) / 1024 / 1024 / 1024 | round)GB",
              "Boot Mode: \(if .boot.efi then "UEFI" else "BIOS" end)",
              "Disks:",
              (.hardware.storage.disks[]? | "  - \(.name): \(.model // "Unknown") (\(.size // 0) / 1024 / 1024 / 1024 | round)GB)")
            ' "$FACTER_REPORT"
            
            # Determine primary disk
            PRIMARY_DISK=$(${nixpkgs.legacyPackages.${system}.jq}/bin/jq -r '
              .hardware.storage.disks[]? |
              select(.name | startswith("nvme")) |
              "/dev/\(.name)" |
              . // empty
            ' "$FACTER_REPORT" | head -1)
            
            if [ -z "$PRIMARY_DISK" ]; then
              PRIMARY_DISK=$(${nixpkgs.legacyPackages.${system}.jq}/bin/jq -r '
                .hardware.storage.disks[]? |
                select(.name | startswith("sd")) |
                "/dev/\(.name)" |
                . // empty
              ' "$FACTER_REPORT" | head -1)
            fi
            
            if [ -z "$PRIMARY_DISK" ]; then
              echo "ERROR: No suitable disk found for installation"
              exit 1
            fi
            
            echo ""
            echo "Selected disk: $PRIMARY_DISK"
            echo ""
            echo "This will DESTROY all data on $PRIMARY_DISK!"
            echo "Press Ctrl+C to abort, or wait 10 seconds to continue..."
            sleep 10
            
            # Step 2: Generate dynamic disko configuration
            echo ""
            echo "Step 2: Generating disk configuration..."
            DISKO_CONFIG=$(mktemp /tmp/disko-XXXXXX.nix)
            trap "rm -f $FACTER_REPORT $DISKO_CONFIG" EXIT
            
            cat > "$DISKO_CONFIG" << 'EOF'
            ${builtins.readFile ./lib/dynamic-disko.nix}
            EOF
            
            # Step 3: Clean existing pools
            echo ""
            echo "Step 3: Cleaning existing configurations..."
            ${nixpkgs.legacyPackages.${system}.zfs}/bin/zpool destroy -f "$POOL_NAME" 2>/dev/null || true
            ${nixpkgs.legacyPackages.${system}.util-linux}/bin/wipefs -af "$PRIMARY_DISK"
            
            # Step 4: Run disko
            echo ""
            echo "Step 4: Partitioning and formatting disk..."
            ${disko.packages.${system}.disko}/bin/disko \
              --mode destroy,format,mount \
              --flake ${self}#$HOSTNAME
            
            # Step 5: Generate hardware configuration
            echo ""
            echo "Step 5: Generating NixOS hardware configuration..."
            ${nixpkgs.legacyPackages.${system}.nixos-install-tools}/bin/nixos-generate-config \
              --root /mnt \
              --show-hardware-config > /mnt/etc/nixos/hardware-configuration.nix
            
            # Step 6: Install NixOS
            echo ""
            echo "Step 6: Installing NixOS..."
            ${nixpkgs.legacyPackages.${system}.nixos-install-tools}/bin/nixos-install \
              --no-root-passwd \
              --flake ${self}#$HOSTNAME
            
            echo ""
            echo "Installation complete!"
            echo ""
            echo "Next steps:"
            echo "1. Reboot into your new system"
            echo "2. Set a password for the admin user"
            echo "3. Configure your system as needed"
          '');
        };
      });

      # Packages
      packages = forAllSystems (system: {
        installer = nixpkgs.legacyPackages.${system}.writeShellScriptBin "nixos-install-unified" ''
          ${builtins.readFile ./scripts/install.sh}
        '';
        
        deployer = nixpkgs.legacyPackages.${system}.writeShellScriptBin "nixos-deploy" ''
          ${builtins.readFile ./scripts/deploy.sh}
        '';
      });
    };
}