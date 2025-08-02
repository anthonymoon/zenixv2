# User configuration abstraction module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zenix.user;
in {
  options.zenix.user = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Primary user account name";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "User's full name";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "User's email address";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "wheel" "audio" "video" ];
      description = "Additional groups for the user";
    };

    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zsh;
      description = "User's default shell";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH authorized keys for the user";
    };

    initialPassword = lib.mkOption {
      type = lib.types.str;
      default = "changeme";
      description = "Initial password for the user (should be changed on first login)";
    };

    sudoTimeout = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Sudo password timeout in minutes";
    };

    passwordlessSudo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable passwordless sudo (security risk - use with caution)";
    };
  };

  config = {
    # Create the user account
    users.users.${cfg.username} = {
      isNormalUser = true;
      description = cfg.fullName;
      extraGroups = cfg.extraGroups;
      shell = cfg.shell;
      initialPassword = cfg.initialPassword;
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };

    # Configure sudo rules
    security.sudo = {
      extraRules = [
        {
          users = [ cfg.username ];
          commands = [
            {
              command = "ALL";
              options = [ "SETENV" ] ++ lib.optional cfg.passwordlessSudo "NOPASSWD";
            }
          ];
        }
      ];
      extraConfig = lib.mkIf (!cfg.passwordlessSudo) ''
        Defaults        timestamp_timeout=${toString cfg.sudoTimeout}
        Defaults        lecture=once
        Defaults        passwd_tries=3
        Defaults        insults
      '';
    };

    # Assertions
    assertions = [
      {
        assertion = cfg.username != "root";
        message = "Username cannot be 'root'";
      }
      {
        assertion = cfg.initialPassword != "changeme" || cfg.authorizedKeys != [];
        message = "Please set a secure initial password or provide SSH keys";
      }
    ];
  };
}