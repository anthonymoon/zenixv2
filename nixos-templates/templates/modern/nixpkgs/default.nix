{ config
, lib
, pkgs
, ...
}: {
  nixpkgs.config = {
    allowUnfree = true;

    # Allow specific insecure packages if needed
    permittedInsecurePackages = [
      # Add any insecure packages you need here
    ];

    # Package overrides
    packageOverrides = pkgs: {
      # Add any package overrides here
    };
  };
}
