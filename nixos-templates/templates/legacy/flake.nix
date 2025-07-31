{
  description = "NixOS 25.11pre configuration with ZFS support";

  inputs = {
    # Use nixos-unstable for 25.11pre
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Hardware support
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    # Home Manager (optional)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Replace "nixos" with your desired hostname
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        
        modules = [
          ./configuration.nix
          
          # Include hardware-specific modules if needed
          # nixos-hardware.nixosModules.common-cpu-amd
          # nixos-hardware.nixosModules.common-gpu-amd
          # nixos-hardware.nixosModules.common-pc-ssd
          
          # Optional: Home Manager integration
          # home-manager.nixosModules.home-manager
          # {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   home-manager.users.youruser = import ./home.nix;
          # }
        ];
        
        specialArgs = { inherit inputs; };
      };
    };
    
    # Optional: Development shell for this flake
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      packages = with nixpkgs.legacyPackages.x86_64-linux; [
        nixos-rebuild
        git
        vim
      ];
      
      shellHook = ''
        echo "NixOS 25.11pre development environment"
        echo "Run 'sudo nixos-rebuild switch --flake .#nixos' to apply configuration"
      '';
    };
  };
}
