{ config
, lib
, pkgs
, ...
}: {
  # Local binary cache configuration
  nix.settings = {
    # Add local cache to substituters
    substituters =
      [
        "http://localhost:5000" # Local nix-serve cache
      ]
      ++ config.nix.settings.substituters;

    # Trust the local cache
    trusted-substituters =
      [
        "http://localhost:5000"
      ]
      ++ config.nix.settings.trusted-substituters;

    # Build settings for better caching
    keep-outputs = true;
    keep-derivations = true;

    # Garbage collection settings
    min-free = lib.mkDefault (1024 * 1024 * 1024); # 1GB
    max-free = lib.mkDefault (10 * 1024 * 1024 * 1024); # 10GB

    # Build cache settings
    max-jobs = lib.mkDefault "auto";
    cores = lib.mkDefault 0; # Use all available cores

    # Enable content-addressed derivations for better deduplication
    experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
  };

  # Configure nix-serve for local binary cache
  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/var/keys/cache-priv-key.pem";
    extraParams = ''
      --priority 10
    '';
  };

  # Optional: Set up a reverse proxy with caching
  services.nginx = {
    enable = lib.mkDefault true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    virtualHosts."cache.local" = {
      locations."/" = {
        proxyPass = "http://localhost:5000";
        extraConfig = ''
          proxy_cache_valid 200 302 60m;
          proxy_cache_valid 404 1m;
          proxy_cache_bypass $http_pragma $http_authorization;
          proxy_cache_revalidate on;
          proxy_cache_min_uses 3;
          proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
          proxy_cache_lock on;
        '';
      };
    };
  };

  # Add cache.local to /etc/hosts
  networking.extraHosts = ''
    127.0.0.1 cache.local
  '';

  # Systemd service to ensure cache directory exists
  systemd.tmpfiles.rules = [
    "d /var/cache/nix 0755 root root -"
    "d /var/keys 0755 root root -"
  ];

  # Optional: Distributed builds configuration
  nix.distributedBuilds = lib.mkDefault false;
  nix.buildMachines = lib.mkDefault [ ];
}
