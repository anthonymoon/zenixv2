{ config
, lib
, pkgs
, ...
}: {
  # Distributed builds configuration (disabled by default)
  nix = {
    # Enable distributed builds
    distributedBuilds = lib.mkDefault false;

    # Define build machines (example configuration)
    buildMachines = lib.mkDefault [
      # Example remote builder
      # {
      #   hostName = "builder.example.com";
      #   system = "x86_64-linux";
      #   maxJobs = 4;
      #   speedFactor = 2;
      #   supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      #   mandatoryFeatures = [ ];
      #   sshUser = "nixbld";
      #   sshKey = "/root/.ssh/id_builder";
      # }

      # Example local VM builder
      # {
      #   hostName = "localhost";
      #   system = "x86_64-linux";
      #   maxJobs = 2;
      #   speedFactor = 1;
      #   supportedFeatures = [ "kvm" "nixos-test" ];
      #   mandatoryFeatures = [ ];
      #   sshUser = "root";
      #   sshKey = "/root/.ssh/id_local";
      # }
    ];

    # Extra options for distributed builds
    extraOptions = lib.mkIf config.nix.distributedBuilds ''
      # Distributed build settings
      builders-use-substitutes = true

      # Require signatures for distributed builds
      require-sigs = true

      # Builder timeout
      builder-timeout = 3600
    '';
  };

  # SSH configuration for builders (when enabled)
  programs.ssh.extraConfig = lib.mkIf config.nix.distributedBuilds ''
    Host builder.example.com
      HostName builder.example.com
      User nixbld
      IdentityFile /root/.ssh/id_builder
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
      ConnectTimeout 5
      ServerAliveInterval 60
      ServerAliveCountMax 3
  '';

  # Systemd service to test builders
  systemd.services.test-builders = lib.mkIf config.nix.distributedBuilds {
    description = "Test Nix distributed builders";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "test-builders" ''
        #!${pkgs.bash}/bin/bash
        set -eu

        echo "Testing distributed builders..."

        # Test each builder
        ${pkgs.nix}/bin/nix store ping --store daemon || true

        # Show builder status
        echo "Builder status:"
        ${pkgs.nix}/bin/nix show-config | grep -E "(buildMachines|distributedBuilds)" || true
      '';
    };
  };
}
