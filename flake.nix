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
    
    # Hyprland and related
    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Additional inputs - uncomment as needed:
    # nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixos-hardware.url = "github:NixOS/nixos-hardware";
    # agenix = {
    #   url = "github:ryantm/agenix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # lanzaboote = {
    #   url = "github:nix-community/lanzaboote/v0.4.1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, disko, hyprland, nix-colors, home-manager, ... }@inputs:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
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
            echo "NixOS development shell"
            echo "Available tools: nixfmt-rfc-style, statix, deadnix, git"
            echo ""
            echo "Run 'git commit' to use pre-commit hooks"
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
            ./modules/hardware/amd
          ];
        };
        
        workstation-gnome = lib.mkSystem {
          hostname = "workstation-gnome";
          system = "x86_64-linux";
          modules = [
            ./hosts/workstation
            ./modules/profiles/workstation
            ./modules/desktop/gnome
            ./modules/hardware/amd
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
            ./modules/hardware/amd
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
            ./modules/hardware/amd
          ];
        };
        
        # Hyprland workstation
        hyprland = lib.mkSystem {
          hostname = "hyprland";
          system = "x86_64-linux";
          modules = [
            ./hosts/workstation
            ./modules/profiles/hyprland
            ./modules/hardware/amd
            # Include omarchy modules
            ./modules/omarchy/nixos/default.nix
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
        installer = {
          path = ./templates/installer;
          description = "NixOS installer for UEFI AMD systems with NVMe";
          welcomeText = ''
            # NixOS Installer - UEFI AMD Systems
            
            This installer is preconfigured for:
            - UEFI boot with systemd-boot
            - AMD CPU (kvm-amd module)
            - NVMe drive at /dev/nvme0n1
            - ZFS root filesystem
            
            To install:
               sudo nix run .
            
            WARNING: This will DESTROY all data on /dev/nvme0n1!
          '';
        };
        
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
        hyprland = import ./modules/desktop/hyprland;
        
        # Hardware support
        nvidia = import ./modules/hardware/nvidia;
        amd = import ./modules/hardware/amd;
        intel = import ./modules/hardware/intel;
        
        # Security
        hardening = import ./modules/security/hardening;
        
        # Common configurations
        common = import ./modules/common;
        cachix = import ./modules/common/cachix.nix;
        
        # Omarchy modules
        omarchy = import ./modules/omarchy/config.nix;
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
        # Basic flake check is run automatically
      });

      # Apps for common operations
      apps = forAllSystems (system: {
        # Pure Nix installation workflow
        install = {
          type = "app";
          program = toString (nixpkgs.legacyPackages.${system}.writeShellScript "install" ''
            #!/bin/sh
            set -e
            
            echo "NixOS Pure Nix Installer"
            echo "========================"
            echo ""
            echo "This installer uses a pure Nix workflow:"
            echo "1. Detect hardware using nixos-facter"
            echo "2. Generate hardware-specific flake from template"
            echo "3. Use disko-install to partition, format, and install"
            echo ""
            
            # First generate the installer
            echo "Generating hardware-specific installer..."
            exec nix run ${self}#generate-installer
          '');
        };
        
        deploy = {
          type = "app";
          program = "${self.packages.${system}.deployer}/bin/nixos-deploy";
        };
        
        # Direct disko-install for each configuration
        install-minimal-zfs = {
          type = "app";
          program = toString (nixpkgs.legacyPackages.${system}.writeShellScript "install-minimal-zfs" ''
            #!${nixpkgs.legacyPackages.${system}.bash}/bin/bash
            set -euo pipefail
            
            DISK=''${DISK:-/dev/nvme0n1}
            
            echo "Installing minimal-zfs to $DISK"
            echo "This will DESTROY all data on $DISK!"
            echo "Press Ctrl+C within 5 seconds to abort..."
            sleep 5
            
            exec ${disko.packages.${system}.disko-install}/bin/disko-install \
              --flake "${self}#minimal-zfs" \
              --disk main "$DISK"
          '');
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
        
        # Simple deploy app for the installer template
        deploy-installer = {
          type = "app";
          program = toString (nixpkgs.legacyPackages.${system}.writeShellScript "deploy-installer" ''
            #!/bin/sh
            set -e
            
            echo "NixOS Installer Deployment"
            echo "=========================="
            echo ""
            echo "This will:"
            echo "1. Initialize the installer template"
            echo "2. Run the installer immediately"
            echo ""
            echo "Requirements:"
            echo "- UEFI system with AMD CPU"
            echo "- NVMe drive at /dev/nvme0n1"
            echo ""
            echo "WARNING: This will DESTROY all data on /dev/nvme0n1!"
            echo "Press Ctrl+C to abort, or wait 5 seconds to continue..."
            sleep 5
            
            # Create temporary directory
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            
            echo ""
            echo "Initializing installer..."
            ${nixpkgs.legacyPackages.${system}.nix}/bin/nix flake init -t ${self}#installer
            
            echo ""
            echo "Running installer..."
            exec ${nixpkgs.legacyPackages.${system}.nix}/bin/nix run .
          '');
        };
        
      });

      # Packages
      packages = forAllSystems (system: 
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Placeholder for future deployment tool
          # deployer = pkgs.writeShellScriptBin "nixos-deploy" ''
          #   echo "Deploy tool not yet implemented"
          # '';
        });
    };
}