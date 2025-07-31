{ config
, lib
, pkgs
, ...
}: {
  # Advanced build cache and optimization settings
  nix = {
    settings = {
      # Build performance
      max-jobs = lib.mkDefault "auto";
      cores = lib.mkDefault 0; # Use all available cores

      # Build isolation and sandboxing
      sandbox = true;
      sandbox-fallback = false;

      # Caching behavior
      keep-outputs = true;
      keep-derivations = true;
      keep-env-derivations = true;

      # Download settings
      http-connections = 128;
      download-attempts = 5;
      connect-timeout = 5;
      stalled-download-timeout = 300;

      # Build timeouts
      max-silent-time = 3600; # 1 hour
      timeout = 86400; # 24 hours

      # Narinfo caching
      narinfo-cache-negative-ttl = 3600; # 1 hour
      narinfo-cache-positive-ttl = 2592000; # 30 days

      # Binary cache settings
      netrc-file = "/etc/nix/netrc";
      fallback = true;

      # Diff hook for better debugging
      run-diff-hook = true;
      diff-hook = pkgs.writeScript "diff-hook" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.diffutils}/bin/diff -r "$1" "$2" || true
      '';

      # Post-build hook for cache population
      post-build-hook = pkgs.writeScript "post-build-hook" ''
        #!${pkgs.bash}/bin/bash
        set -eu
        set -o pipefail

        # Only upload if local cache is running
        if ${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/nix-cache-info | grep -q "200"; then
          echo "Uploading paths to local cache..." >&2
          exec nix copy --to 'http://localhost:5000?priority=10' $OUT_PATHS
        fi
      '';
    };

    # Extra configuration
    extraOptions = ''
      # Garbage collection thresholds
      min-free = ${toString (1 * 1024 * 1024 * 1024)} # 1GB
      max-free = ${toString (10 * 1024 * 1024 * 1024)} # 10GB

      # Build user settings
      build-users-group = nixbld

      # Log settings
      build-max-log-size = ${toString (100 * 1024 * 1024)} # 100MB

      # Compression
      compress-build-log = true

      # Allow import from derivation
      allow-import-from-derivation = true
    '';
  };

  # Systemd services for cache maintenance
  systemd.services.nix-cache-optimize = {
    description = "Optimize Nix store and cache";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-store --optimise";
    };
  };

  systemd.timers.nix-cache-optimize = {
    description = "Optimize Nix store and cache timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Cache warmup service
  systemd.services.nix-cache-warmup = {
    description = "Warm up Nix binary cache";
    after = [ "nix-serve.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "cache-warmup" ''
        #!${pkgs.bash}/bin/bash
        set -eu

        # Wait for nix-serve to be ready
        for i in {1..30}; do
          if ${pkgs.curl}/bin/curl -s http://localhost:5000/nix-cache-info >/dev/null 2>&1; then
            echo "Local cache is ready"
            break
          fi
          echo "Waiting for local cache... ($i/30)"
          sleep 2
        done

        # Pre-populate cache with commonly used packages
        echo "Pre-populating cache with common packages..."
        ${pkgs.nix}/bin/nix copy --to 'http://localhost:5000' \
          ${pkgs.coreutils} \
          ${pkgs.bash} \
          ${pkgs.git} \
          ${pkgs.gnumake} \
          ${pkgs.gcc} \
          || true
      '';
    };
  };
}
