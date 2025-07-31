{
  description = "Unified NixOS Template System - Install any configuration with templates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-25-05.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Disk management and installation
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure boot support
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional inputs
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  # Flake-wide cache configuration
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
      "https://hyprland.cachix.org"
      "https://chaotic-nyx.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , nixpkgs-25-05
    , disko
    , lanzaboote
    , pre-commit-hooks
    , chaotic
    , hyprland
    , nixos-hardware
    , ...
    } @ inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      # Template configuration system
      templateConfig = import ./lib/templates.nix { inherit lib; };
      
      # Builder functions
      builders = import ./lib/builders.nix { 
        inherit lib inputs system; 
        inherit nixpkgs nixpkgs-stable nixpkgs-25-05;
      };

      # Pre-commit hooks configuration with parallelization
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        
        # Enable parallel execution for faster checks
        settings = {
          # Run hooks in parallel
          parallel = true;
          # Auto-detect number of CPU cores
          jobs = null;
          # Continue checking all files even if one fails
          fail_fast = false;
        };
        
        hooks = {
          # Nix formatting and linting (parallel-safe)
          nixfmt-rfc-style.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          
          # Shell script checks (parallel-safe)
          shellcheck.enable = true;
          shfmt.enable = true;
          
          # File cleanup (parallel-safe)
          trailing-whitespace.enable = true;
          end-of-file-fixer.enable = true;
          check-added-large-files.enable = true;
          
          # Custom parallel hooks from our library
          parallel-nix-check = {
            enable = true;
            entry = "${pkgs.writeShellScript "parallel-nix-check" ''
              # Run multiple Nix checks in parallel
              ${pkgs.parallel}/bin/parallel -j+0 --halt now,fail=1 ::: \
                "${pkgs.statix}/bin/statix check ." \
                "${pkgs.deadnix}/bin/deadnix --fail ." \
                "${pkgs.nix}/bin/nix flake check --no-build"
            ''}";
            pass_filenames = false;
            stages = [ "push" ];
          };
        };
      };

    in
    {
      # Template definitions - each can be installed individually
      templates = {
        # Modern dynamic system with auto-detection
        modern = {
          description = "Modern NixOS with dynamic configuration and auto-hardware detection";
          path = ./templates/modern;
        };

        # ZFS ephemeral root system
        ephemeral-zfs = {
          description = "ZFS ephemeral root system that resets on boot";
          path = ./templates/ephemeral-zfs;
        };

        # Minimal ZFS system
        minimal-zfs = {
          description = "Minimal ZFS-based system";
          path = ./templates/minimal-zfs;
        };

        # Deployment-focused system
        deployment = {
          description = "System optimized for automated deployment";
          path = ./templates/deployment;
        };

        # Personal dotfiles configuration
        personal = {
          description = "Personal configuration with dotfiles and age encryption";
          path = ./templates/personal;
        };

        # Unified simple system
        unified = {
          description = "Unified approach with disko integration";
          path = ./templates/unified;
        };

        # Installer system
        installer = {
          description = "ZFS installer configuration";
          path = ./templates/installer;
        };

        # Legacy/testing configurations
        legacy = {
          description = "Legacy and testing configurations";
          path = ./templates/legacy;
        };
      };

      # Generated configurations using template system
      nixosConfigurations = 
        # Example configurations for testing
        {
          "example.modern.desktop.kde" = builders.buildSystem {
            template = "modern";
            hostname = "example";
            profiles = [ "desktop" "kde" "stable" ];
            params = {
              hostId = "deadbeef";
            };
          };
          
          "example.ephemeral-zfs.server" = builders.buildSystem {
            template = "ephemeral-zfs";
            hostname = "example";
            profiles = [ "headless" "stable" ];
          };
        };

      # Installation apps
      apps.${system} = import ./lib/apps.nix { 
        inherit lib inputs system;
        templates = templateConfig;
        pkgs = nixpkgs.legacyPackages.${system};
      };

      # Library functions for template system
      lib = {
        templates = templateConfig;
        inherit builders;
        
        # Template instantiation
        instantiateTemplate = template: params: 
          builders.instantiateTemplate template params;
          
        # Available profiles by template
        profilesByTemplate = templateConfig.getProfilesByTemplate;
        
        # Template validation
        validateTemplate = builders.validateTemplate;
      };

      # Development shell
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        inherit (pre-commit-check) shellHook;
        packages = with nixpkgs.legacyPackages.${system}; [
          # Nix development tools
          nixos-rebuild
          nix-output-monitor
          nvd
          alejandra
          statix
          deadnix

          # Template tools
          disko.packages.${system}.disko
          util-linux
          parted
          smartmontools

          # System tools
          git
          jq
          rsync

          # Filesystem tools
          btrfs-progs
          zfs

          # Monitoring and debugging
          btop
          iotop

          # Pre-commit
          pre-commit
        ];
      };

      # Formatter
      formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

      # Checks
      checks.${system} = {
        pre-commit-check = pre-commit-check;
      };
    };
}
