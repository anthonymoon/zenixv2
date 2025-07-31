{ config
, lib
, pkgs
, ...
}: {
  # Cachy.local binary cache configuration
  nix.settings = {
    # Add cachy.local to substituters
    substituters = lib.mkBefore [
      "http://cachy.local" # Cachy.local nix-serve cache
    ];

    # Trust the cachy.local cache
    trusted-substituters = lib.mkBefore [
      "http://cachy.local"
    ];

    # Add the public key for cachy.local
    trusted-public-keys = lib.mkBefore [
      "nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc="
    ];
  };

  # Optional: Add cachy.local to /etc/hosts if needed
  # networking.extraHosts = ''
  #   10.10.10.10 cachy.local cachy
  # '';
}
