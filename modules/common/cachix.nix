{ config, lib, ... }:

{
  options.common.cachix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable common cachix substituters";
    };

    substituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ];
      description = "List of binary cache substituters";
    };

    trustedPublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      ];
      description = "List of trusted public keys for substituters";
    };

    enableLocalCache = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable local binary cache";
    };

    localCacheUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://10.10.10.10:5000";
      description = "URL for local binary cache";
    };
  };

  config = lib.mkIf config.common.cachix.enable {
    nix.settings = {
      substituters =
        config.common.cachix.substituters
        ++ lib.optional config.common.cachix.enableLocalCache config.common.cachix.localCacheUrl;

      trusted-public-keys = config.common.cachix.trustedPublicKeys;

      # Connection settings
      connect-timeout = 5;
      download-attempts = 3;

      # Fallback to building if substitutes fail
      fallback = true;
    };
  };
}
