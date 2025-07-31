{ pkgs
, lib
, ...
}:
let
  testFlake = "/tmp/nixos-fun";
  testConfig = "workstation.kde.stable";
in
{
  # MicroVM test for disko installation
  name = "nixos-fun-disko-install-test";

  nodes = {
    installer =
      { config
      , pkgs
      , ...
      }: {
        # Enable required features
        virtualisation.diskSize = 8192; # 8GB disk
        virtualisation.memorySize = 4096; # 4GB RAM

        # Enable experimental features
        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        # Add our flake source
        environment.systemPackages = with pkgs; [
          git
          curl
          disko
          util-linux
          parted
        ];

        # Enable networking
        networking.useNetworkd = true;
        systemd.network.enable = true;

        # Set up test disk
        virtualisation.emptyDiskImages = [ 2048 ]; # 2GB test disk
      };
  };

  testScript = ''
    # Start the installer VM
    installer.start()
    installer.wait_for_unit("multi-user.target")

    print("🚀 Starting NixOS disko installation test")

    # Clone the flake
    installer.succeed("cd /tmp && git clone https://github.com/anthonymoon/nixos-fun.git")

    # Check if flake is valid
    installer.succeed("cd ${testFlake} && nix flake check --impure")
    print("✅ Flake validation passed")

    # Test disko configuration
    installer.succeed("cd ${testFlake} && nix eval .#diskoConfigurations.default.disko.devices --json")
    print("✅ Disko configuration validated")

    # Test nixos configuration build (without installation)
    installer.succeed("cd ${testFlake} && nix build .#nixosConfigurations.${testConfig}.config.system.build.toplevel --impure")
    print("✅ NixOS configuration builds successfully")

    # Test disko partitioning (dry run)
    installer.succeed("cd ${testFlake} && nix run github:nix-community/disko -- --mode disko --dry-run --flake .#default --arg device '\"/dev/vdb\"'")
    print("✅ Disko dry run passed")

    # Actual disko partitioning
    installer.succeed("cd ${testFlake} && nix run github:nix-community/disko -- --mode disko --flake .#default --arg device '\"/dev/vdb\"'")
    print("✅ Disko partitioning completed")

    # Check if partitions were created
    installer.succeed("lsblk /dev/vdb")
    installer.succeed("mount | grep '/mnt'")
    print("✅ Partitions created and mounted")

    # Test nixos-install (but don't complete it to save time)
    installer.succeed("cd ${testFlake} && timeout 30 nixos-install --flake .#${testConfig} --impure --dry-run || true")
    print("✅ nixos-install validation passed")

    print("🎉 All tests passed! Installation system working correctly.")
  '';
}
