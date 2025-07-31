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
    
    # Additional inputs - uncomment as needed:
    # nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixos-hardware.url = "github:NixOS/nixos-hardware";
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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

  outputs = { self, nixpkgs, ... }@inputs:
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