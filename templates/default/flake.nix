{
  description = "My Omarchy-based NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, omarchy-nix, home-manager, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Hardware configuration
        ./hardware-configuration.nix
        
        # Omarchy modules
        omarchy-nix.nixosModules.default
        home-manager.nixosModules.home-manager
        
        # System configuration
        {
          networking.hostName = "myhost";
          
          # Configure omarchy
          omarchy = {
            full_name = "Your Name";
            email_address = "your.email@example.com";
            theme = "tokyo-night";
          };
          
          # Configure home-manager
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.myuser = {
              imports = [ omarchy-nix.homeManagerModules.default ];
              home.stateVersion = "24.11";
            };
          };
          
          # User configuration
          users.users.myuser = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
            initialPassword = "changeme";
          };
          
          # Basic services
          networking.networkmanager.enable = true;
          
          # System state version
          system.stateVersion = "24.11";
        }
      ];
    };
  };
}