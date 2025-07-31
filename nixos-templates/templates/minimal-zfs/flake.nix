{
  description = "Minimal NixOS with ZFS root on GPT/ESP";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: {
    nixosConfigurations = {
      # Physical machine configuration
      zfs-physical = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hardware/physical.nix
          ./modules/zfs-root.nix
          ./profiles/base.nix
        ];
      };

      # Virtual machine configuration
      zfs-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hardware/vm.nix
          ./modules/zfs-root.nix
          ./profiles/base.nix
        ];
      };
    };

    # Deployment app
    apps.x86_64-linux.deploy = {
      type = "app";
      program = toString (nixpkgs.legacyPackages.x86_64-linux.writeShellScript "deploy" ''
        set -euo pipefail
        
        DISK="''${1:-/dev/sda}"
        HOST="''${2:-zfs-physical}"
        
        echo "Deploying NixOS with ZFS root to $DISK as $HOST"
        
        # Build the system
        nix build .#nixosConfigurations.$HOST.config.system.build.diskoScript
        
        # Run disko partitioning
        sudo ./result
        
        # Install NixOS
        sudo nixos-install --root /mnt --flake .#$HOST --no-root-passwd
        
        echo "Installation complete! Reboot to use your new system."
      '');
    };
  };
}
