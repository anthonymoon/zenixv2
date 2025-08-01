# Example of simple, direct flake configuration without over-abstraction
{
  description = "Simple NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = import ./lib/simple.nix { inherit nixpkgs; };
    in
    {
      # Direct nixosSystem calls - clear and obvious
      nixosConfigurations = {
        # Minimal server
        server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/server/configuration.nix
            ./hosts/server/hardware-configuration.nix
            # Direct imports - no abstraction needed
            ./modules/common/default.nix
            ./modules/storage/zfs
          ];
        };

        # Desktop workstation
        workstation = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/workstation/configuration.nix
            ./hosts/workstation/hardware-configuration.nix
            ./modules/common/default.nix
            ./modules/desktop/kde
            # Just import what you need
            (
              { pkgs, ... }:
              {
                # Direct configuration - no need for builders
                services.xserver.enable = true;
                services.xserver.displayManager.sddm.enable = true;
                services.xserver.desktopManager.plasma5.enable = true;

                # Direct package installation
                environment.systemPackages = with pkgs; [
                  firefox
                  thunderbird
                  vscode
                ];
              }
            )
          ];
        };
      };
    };
}
