{ config
, lib
, pkgs
, ...
}: {
  users.users.root = {
    # Root user configuration
    shell = pkgs.bash;

    # SSH keys for root access (if needed)
    openssh.authorizedKeys.keys = [
      # Add SSH public keys for root access here
      # WARNING: Only add if absolutely necessary for system administration
    ];
  };

  # Optionally disable root login
  # security.sudo.wheelNeedsPassword = true;
  # services.openssh.settings.PermitRootLogin = "no";
}
