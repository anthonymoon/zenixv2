{
  description = "ZenixV2 - Omarchy-based NixOS Configuration";

  inputs = {
    # Core nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Omarchy-nix for Hyprland setup
    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Disk management
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, omarchy-nix, home-manager, disko, ... }@inputs:
    let
      system = "x86_64-linux";
      
      # Helper function to create a system
      mkSystem = { hostname, username, fullName, email, theme ? "tokyo-night", extraModules ? [] }: 
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            # Omarchy base
            omarchy-nix.nixosModules.default
            home-manager.nixosModules.home-manager
            
            # Disko for disk management
            disko.nixosModules.disko
            
            # Host-specific hardware configuration
            ./hosts/${hostname}/hardware-configuration.nix
            
            # Common modules
            ./modules/common
            ./modules/storage/zfs
            ./modules/hardware/amd
            
            # System configuration
            {
              networking.hostName = hostname;
              
              # Configure omarchy
              omarchy = {
                full_name = fullName;
                email_address = email;
                theme = theme;
              };
              
              # Configure home-manager
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = {
                  imports = [ omarchy-nix.homeManagerModules.default ];
                  home.stateVersion = "24.11";
                };
              };
              
              # Main user configuration
              users.users.${username} = {
                isNormalUser = true;
                extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
                initialPassword = "changeme";
              };
              
              # Enable NetworkManager
              networking.networkmanager.enable = true;
              
              # System state version
              system.stateVersion = "24.11";
            }
          ] ++ extraModules;
        };
    in
    {
      # NixOS configurations
      nixosConfigurations = {
        # Minimal configuration with ZFS
        minimal = mkSystem {
          hostname = "minimal";
          username = "user";
          fullName = "NixOS User";
          email = "user@example.com";
          theme = "tokyo-night";
          extraModules = [ ./hosts/minimal/disko.nix ];
        };
        
        # Workstation configuration
        workstation = mkSystem {
          hostname = "workstation";
          username = "user";
          fullName = "Your Name";
          email = "your.email@example.com";
          theme = "tokyo-night";
          extraModules = [ 
            ./hosts/workstation/disko.nix
            {
              # Additional workstation packages
              environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
                libreoffice
                thunderbird
                vlc
                gimp
                inkscape
              ];
            }
          ];
        };
        
        # Gaming configuration
        gaming = mkSystem {
          hostname = "gaming";
          username = "gamer";
          fullName = "Gamer";
          email = "gamer@example.com";
          theme = "catppuccin";
          extraModules = [
            ./hosts/gaming/disko.nix
            {
              # Gaming-specific configuration
              programs.steam = {
                enable = true;
                remotePlay.openFirewall = true;
              };
              
              programs.gamemode.enable = true;
              
              environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
                lutris
                mangohud
                discord
              ];
              
              # Performance tweaks
              boot.kernelPackages = nixpkgs.legacyPackages.${system}.linuxPackages_xanmod_latest;
            }
          ];
        };
        
        # Development configuration
        dev = mkSystem {
          hostname = "dev";
          username = "developer";
          fullName = "Developer";
          email = "dev@example.com";
          theme = "gruvbox";
          extraModules = [
            ./hosts/dev/disko.nix
            {
              # Development tools
              environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
                # Version control
                git
                gh
                lazygit
                
                # Editors (VSCode is included in omarchy)
                neovim
                
                # Languages and tools
                nodejs
                python3
                rustup
                go
                
                # Containers
                docker
                docker-compose
                
                # Database clients
                postgresql
                redis
              ];
              
              # Enable Docker
              virtualisation.docker.enable = true;
            }
          ];
        };
      };

      # Development shell
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = with nixpkgs.legacyPackages.${system}; [
          nixfmt-rfc-style
          git
        ];
        shellHook = ''
          echo "ZenixV2 development shell"
          echo "Based on omarchy-nix"
        '';
      };

      # Templates
      templates = {
        default = {
          path = ./templates/default;
          description = "Omarchy-based NixOS configuration";
          welcomeText = ''
            # Omarchy-based NixOS Configuration
            
            Edit the configuration to set your username and personal details.
            
            To install:
              sudo nixos-install --flake .#hostname
          '';
        };
      };
    };
}