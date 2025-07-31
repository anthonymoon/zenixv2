{
  description = "NixOS configuration with ephemeral root ZFS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Flake-wide cache configuration for development and CI/CD
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];
  };

  outputs =
    { self
    , nixpkgs
    , disko
    , pre-commit-hooks
    , ...
    } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations."@HOSTNAME@" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          ./hardware/common.nix
          ./hardware/disko-common.nix
        ];
      };

      # Test configurations for CI/CD
      nixosConfigurations."test-physical" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          ./hardware/common.nix
          ./hardware/disko-common.nix
          ({ lib, ... }: {
            networking.hostName = lib.mkForce "test-physical";
            disko.devices.disk.main.device = lib.mkForce "/dev/disk/by-id/test-disk";
          })
        ];
      };

      nixosConfigurations."test-vm" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          ./hardware/common.nix
          ./hardware/disko-common.nix
          ({ lib, ... }: {
            networking.hostName = lib.mkForce "test-vm";
            # Set environment variable to indicate VM
            environment.variables.NIXOS_VM = "1";
            disko.devices.disk.main.device = lib.mkForce "/dev/vda";
          })
        ];
      };

      checks.${system} = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = with pkgs; [
          alejandra
          statix
          deadnix
          shellcheck
          shfmt
          git
          gh
          pre-commit
        ];
      };
    };
}
