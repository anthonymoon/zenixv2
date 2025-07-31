# Workstation-specific systemd services examples
{ config, lib, pkgs, ... }:

{
  # Example workstation services (commented out by default)
  # Uncomment and customize as needed
  
  systemd.services = {
    # ZFS snapshot before updates
    pre-update-snapshot = {
      description = "Create ZFS snapshot before system updates";
      before = [ "nixos-upgrade.service" ];
      requiredBy = [ "nixos-upgrade.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "pre-update-snapshot" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          SNAPSHOT_NAME="auto-upgrade-$(date +%Y%m%d-%H%M%S)"
          
          # Create snapshots of important datasets
          for dataset in rpool/root rpool/home; do
            if ${pkgs.zfs}/bin/zfs list "$dataset" &>/dev/null; then
              echo "Creating snapshot: $dataset@$SNAPSHOT_NAME"
              ${pkgs.zfs}/bin/zfs snapshot "$dataset@$SNAPSHOT_NAME"
            fi
          done
        ''}";
      };
    };

    # GPU memory cleanup service (useful for AMD GPUs)
    gpu-memory-cleanup = {
      description = "Clean up GPU memory periodically";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "gpu-cleanup" ''
          #!/usr/bin/env bash
          # Drop caches to free up memory
          echo 3 > /proc/sys/vm/drop_caches
          
          # AMD GPU specific cleanup
          if [ -d /sys/class/drm/card0 ]; then
            echo "GPU memory cleanup completed"
          fi
        ''}";
      };
    };

    # Custom download manager service example
    # download-manager = {
    #   description = "Custom download manager";
    #   after = [ "network.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     Type = "simple";
    #     User = "downloader";
    #     Group = "users";
    #     WorkingDirectory = "/var/lib/downloads";
    #     ExecStart = "${pkgs.aria2}/bin/aria2c --enable-rpc --rpc-listen-all";
    #     Restart = "always";
    #     RestartSec = 10;
    #   };
    # };

    # Development environment auto-start
    # dev-environment = {
    #   description = "Start development environment";
    #   after = [ "graphical-session.target" ];
    #   wantedBy = [ "default.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     User = "%I";  # Use with dev-environment@username.service
    #     ExecStart = "${pkgs.writeShellScript "start-dev" ''
    #       #!/usr/bin/env bash
    #       # Start development services
    #       ${pkgs.docker}/bin/docker start postgres redis || true
    #       ${pkgs.tmux}/bin/tmux new-session -d -s dev || true
    #     ''}";
    #   };
    # };
  };

  # Corresponding timers
  systemd.timers = {
    # Run GPU cleanup every 6 hours
    gpu-memory-cleanup = {
      description = "Run GPU memory cleanup periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1h";
        OnUnitActiveSec = "6h";
        Persistent = true;
      };
    };

    # Example: Daily workspace backup
    # workspace-backup = {
    #   description = "Daily workspace backup";
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     Persistent = true;
    #     RandomizedDelaySec = "30m";
    #   };
    # };
  };

  # User services example
  systemd.user.services = {
    # Syncthing auto-start (per user)
    # syncthing = {
    #   description = "Syncthing file synchronization";
    #   after = [ "graphical-session.target" ];
    #   wantedBy = [ "default.target" ];
    #   serviceConfig = {
    #     Type = "simple";
    #     ExecStart = "${pkgs.syncthing}/bin/syncthing -no-browser";
    #     Restart = "always";
    #     RestartSec = 10;
    #   };
    # };
  };

  # Create a helpful guide in the system
  environment.etc."nixos-templates/workstation-services.md".text = ''
    # Workstation Services Guide

    ## Pre-configured Services

    ### ZFS Pre-update Snapshots
    Automatically creates ZFS snapshots before system upgrades.
    This provides an easy rollback mechanism if updates cause issues.

    ### GPU Memory Cleanup
    Periodically cleans GPU memory and system caches.
    Runs every 6 hours to maintain system performance.

    ## Enabling Services

    To enable any of the example services:
    1. Edit your configuration.nix
    2. Uncomment the desired service
    3. Customize as needed
    4. Run: sudo nixos-rebuild switch

    ## Creating Your Own Services

    ### Basic Pattern
    ```nix
    systemd.services.my-service = {
      description = "What it does";
      after = [ "network.target" ];  # Dependencies
      wantedBy = [ "multi-user.target" ];  # When to start
      serviceConfig = {
        Type = "simple";  # or "oneshot", "forking", etc.
        ExecStart = "/path/to/executable";
        Restart = "always";  # Auto-restart on failure
        User = "username";  # Run as specific user
      };
    };
    ```

    ### With Timer
    ```nix
    systemd.timers.my-service = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";  # or "hourly", "*:0/15", etc.
        Persistent = true;  # Run if missed
      };
    };
    ```

    ## Useful Commands

    - View service status: systemctl status my-service
    - View logs: journalctl -u my-service
    - Start/stop: systemctl start/stop my-service
    - Enable/disable: systemctl enable/disable my-service
    - List timers: systemctl list-timers
  '';
}
