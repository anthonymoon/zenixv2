{
  description = "ZenixV2 - Omarchy-based NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      omarchy-nix,
      home-manager,
      disko,
      nixos-gaming,
      ...
    }@inputs:
    {
      nixosConfigurations.nixie = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Hardware configuration
          ./hosts/nixie/hardware-configuration.nix

          # Common modules
          ./modules/common
          ./modules/storage/zfs
          ./modules/hardware/amd/enhanced.nix
          ./modules/networking/bonding
          ./modules/networking/performance
          ./modules/services/samba
          ./modules/extras/pkgs
          ./modules/desktop/wayland

          # Omarchy modules
          omarchy-nix.nixosModules.default
          home-manager.nixosModules.home-manager

          # System configuration
          {
            networking.hostName = "nixie";

            # Configure omarchy
            omarchy = {
              full_name = "Anthony Moon";
              email_address = "tonymoon@gmail.com";
              theme = "tokyo-night";
            };

            # Configure home-manager
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.amoon = {
                imports = [ omarchy-nix.homeManagerModules.default ];
                home.stateVersion = "24.11";
              };
            };

            # User configuration
            users.users.amoon = {
              isNormalUser = true;
              extraGroups = [
                "wheel"
                "audio"
                "video"
              ];
              initialPassword = "nixos";
            };

            # Enable passwordless sudo
            security.sudo.extraRules = [
              {
                users = [ "amoon" ];
                commands = [
                  {
                    command = "ALL";
                    options = [ "NOPASSWD" ];
                  }
                ];
              }
            ];

            # Basic services - using systemd-networkd instead of NetworkManager
            networking.useNetworkd = true;
            systemd.network.enable = true;
            services.resolved.enable = true;
            
            # Timezone and NTP
            time.timeZone = "America/Vancouver";
            services.timesyncd = {
              enable = true;
              servers = [ "time.google.com" ];
            };
            
            # SSH configuration
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PasswordAuthentication = true;
              };
            };
            
            # Disable firewall
            networking.firewall.enable = false;
            
            # Enable mDNS
            services.avahi.nssmdns4 = true;
            networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];

            # System state version
            system.stateVersion = "24.11";
          }
        ];
      };

      # Development shells
      devShells = {
        x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
          packages = with nixpkgs.legacyPackages.x86_64-linux; [
            nixfmt-rfc-style
            git
          ];
          shellHook = ''
            echo "ZenixV2 development shell"
            echo "Based on omarchy-nix"
          '';
        };

        x86_64-darwin.default = nixpkgs.legacyPackages.x86_64-darwin.mkShell {
          packages = with nixpkgs.legacyPackages.x86_64-darwin; [
            nixfmt-rfc-style
            git
          ];
          shellHook = ''
            echo "ZenixV2 development shell"
            echo "Based on omarchy-nix"
          '';
        };
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
