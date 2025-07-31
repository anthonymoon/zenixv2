{
  description = "Minimal NixOS Configuration with ZFS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # NixOS configuration for 'nixies' host
      nixosConfigurations.nixies = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./hardware.nix
          ./profile.nix
        ];
      };

      # Disko configuration
      diskoConfigurations.nixies = import ./disko.nix;

      # Apps
      apps.${system} = {
        install = {
          type = "app";
          program = toString (pkgs.writeShellScript "install-nixos" ''
            set -euo pipefail

            # Ensure nix experimental features are enabled
            export NIX_CONFIG="experimental-features = nix-command flakes"

            # Check if running as root, elevate if needed
            if [ "$EUID" -ne 0 ]; then
              echo "🔐 Elevating to root permissions..."
              exec sudo -E "$0" "$@"
            fi

            # Parse arguments
            disk="''${1:-}"

            if [ -z "$disk" ]; then
              echo "❌ Error: Disk is required"
              echo ""
              echo "Usage: nix run github:anthonymoon/nixos-unified#install DISK"
              echo ""
              echo "Examples:"
              echo "  nix run github:anthonymoon/nixos-unified#install /dev/nvme0n1"
              echo "  nix run github:anthonymoon/nixos-unified#install /dev/sda"
              exit 1
            fi

            # Auto-detect disk if common path provided
            if [ ! -b "$disk" ]; then
              echo "❌ Error: Disk $disk not found"
              exit 1
            fi

            echo "🏗️  Installing NixOS for 'nixies' host with ZFS"
            echo "   Disk: $disk"
            echo ""

            # Confirm installation
            read -p "⚠️  WARNING: This will ERASE ALL DATA on $disk. Continue? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
              echo "Installation cancelled."
              exit 0
            fi

            echo "🚀 Starting installation..."

            # Clean up cache and temporary files first
            echo "🧹 Cleaning cache and temporary files..."
            rm -rf /tmp/* /root/.cache/ 2>/dev/null || true

            # Load ZFS kernel modules
            echo "🔧 Loading ZFS kernel modules..."
            modprobe zfs || {
              echo "❌ Error: Could not load ZFS modules"
              echo "💡 Please boot from a NixOS ISO with ZFS support"
              exit 1
            }

            # Convert disk path to disk-by-id if possible
            if [[ "$disk" != /dev/disk/by-id/* ]]; then
              echo "🔍 Finding disk by-id path for $disk..."
              disk_by_id=$(find /dev/disk/by-id/ -type l | while read -r id; do
                if [ "$(readlink -f "$id")" = "$disk" ] && [[ "$id" != *-part* ]]; then
                  echo "$id"
                  break
                fi
              done | head -n1)

              if [ -n "$disk_by_id" ]; then
                disk="$disk_by_id"
                echo "📀 Using disk by-id: $disk"
              fi
            fi

            # Clean up any existing ZFS pools
            echo "🧹 Cleaning up existing configurations..."
            umount -R /mnt 2>/dev/null || true
            zpool export -a 2>/dev/null || true

            # Partition and format disk with disko
            echo "💾 Partitioning disk with ZFS..."
            nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
              --mode disko \
              --flake "github:anthonymoon/nixos-unified#nixies" \
              --arg disk "\"$disk\""

            # Install NixOS
            echo "📦 Installing NixOS..."
            nixos-install \
              --flake "github:anthonymoon/nixos-unified#nixies" \
              --root /mnt \
              --no-root-passwd

            echo "✅ Installation completed successfully!"
            echo ""
            echo "Next steps:"
            echo "1. Reboot: reboot"
            echo "2. Set admin password: passwd admin"
            echo "3. Add SSH keys to /home/admin/.ssh/authorized_keys"
            echo "4. Customize /etc/nixos/configuration.nix as needed"
          '');
        };
        default = self.apps.${system}.install;
      };
    };
}
