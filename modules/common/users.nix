# Simple user configuration following NixOS best practices
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Define users directly - simple and clear
  users.users = {
    # Secure root user
    root = {
      hashedPassword = null; # Disable password login
      openssh.authorizedKeys.keys = [
        # Add admin SSH keys here
      ];
    };

    # Example user with sudo access
    amoon = {
      isNormalUser = true;
      description = "Anthony Moon";
      extraGroups = [
        "wheel" # Enable sudo
        "networkmanager" # Network configuration
        "audio" # Audio access
        "video" # Video/graphics access
        "docker" # Docker access (if needed)
      ];
      shell = pkgs.zsh;
      # Generate with: mkpasswd -m sha-512
      hashedPassword = "$6$rounds=656000$..."; # Replace with actual hash
      openssh.authorizedKeys.keys = [
        # "ssh-ed25519 AAAA... user@host"
      ];
    };
  };

  # Basic security settings
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true; # Require password for sudo
  };

  # Enable the shells we're using
  programs.zsh.enable = true;
}
