# User management module - DRY implementation
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users.management;
  utils = import ../../lib/utils.nix { inherit lib; };
  
  # User type definition
  userType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Username";
      };
      
      isAdmin = mkOption {
        type = types.bool;
        default = false;
        description = "Whether user has admin privileges";
      };
      
      shell = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "User shell";
      };
      
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "SSH authorized keys";
      };
      
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional groups beyond the profile defaults";
      };
      
      hashedPassword = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Hashed password (use mkpasswd -m sha-512)";
      };
      
      profile = mkOption {
        type = types.enum [ "base" "desktop" "development" "full" ];
        default = "base";
        description = "Group profile determining default groups";
      };
    };
  };
  
in {
  options.users.management = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable user management module";
    };
    
    defaultShell = mkOption {
      type = types.package;
      default = pkgs.bash;
      example = pkgs.zsh;
      description = "Default shell for users";
    };
    
    users = mkOption {
      type = types.listOf userType;
      default = [];
      description = "List of users to create";
      example = literalExpression ''
        [
          {
            name = "alice";
            isAdmin = true;
            profile = "development";
            shell = pkgs.zsh;
            authorizedKeys = [ "ssh-rsa AAAAB3..." ];
          }
          {
            name = "bob";
            profile = "desktop";
          }
        ]
      '';
    };
    
    requirePasswordChange = mkOption {
      type = types.bool;
      default = false;
      description = "Require password change on first login";
    };
    
    autoLogin = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Username for automatic login";
    };
    
    rootUser = {
      hashedPassword = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Root password hash (null disables password login)";
      };
      
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "SSH keys for root";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Configure root user
    users.users.root = {
      hashedPassword = cfg.rootUser.hashedPassword;
      openssh.authorizedKeys.keys = cfg.rootUser.authorizedKeys;
    };
    
    # Create managed users
    users.users = mkMerge (map (user: {
      ${user.name} = {
        isNormalUser = true;
        
        # Determine groups based on profile
        extraGroups = utils.userGroups.${user.profile} ++ user.extraGroups ++ 
          (optional user.isAdmin "wheel");
        
        # Shell configuration
        shell = user.shell or cfg.defaultShell;
        
        # Authentication
        hashedPassword = user.hashedPassword;
        openssh.authorizedKeys.keys = user.authorizedKeys;
        
        # Force password change if required
        passwordFile = mkIf (cfg.requirePasswordChange && user.hashedPassword == null) 
          (pkgs.writeText "${user.name}-password" "changeme");
      };
    }) cfg.users);
    
    # Auto-login configuration
    services.xserver.displayManager.autoLogin = mkIf (cfg.autoLogin != null) {
      enable = true;
      user = cfg.autoLogin;
    };
    
    # Additional security for managed users
    security = {
      # Require password for sudo even for wheel users
      sudo.wheelNeedsPassword = mkDefault true;
      
      # Password quality requirements
      pam.services.passwd.text = mkDefault ''
        password requisite pam_pwquality.so minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1
      '';
    };
    
    # User environment setup script
    environment.etc."profile.d/user-setup.sh".text = ''
      # Set up XDG directories for desktop users
      if [ -n "$HOME" ] && [ ! -f "$HOME/.config/user-dirs.dirs" ]; then
        ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update
      fi
      
      # Create common directories
      for dir in Documents Downloads Pictures Videos Music Desktop Templates Public; do
        mkdir -p "$HOME/$dir" 2>/dev/null || true
      done
    '';
    
    # Default shell configuration
    programs.bash.enableCompletion = mkDefault true;
    programs.zsh = mkIf (cfg.defaultShell == pkgs.zsh) {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
    
    # User quotas (optional)
    services.quotaon.enable = mkDefault false;
  };
}