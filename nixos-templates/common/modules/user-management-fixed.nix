# User management module - following NixOS best practices
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users.management;
in {
  options.users.management = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable user management module";
    };
    
    # Define each user explicitly - more readable and maintainable
    alice = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable user alice";
      };
      
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "SSH authorized keys for alice";
      };
    };
    
    bob = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable user bob";
      };
      
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "SSH authorized keys for bob";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Root user configuration
    users.users.root = {
      # Disable root password login by default (SSH key only)
      hashedPassword = null;
      openssh.authorizedKeys.keys = [
        # Add your admin SSH keys here
      ];
    };
    
    # User alice - admin/developer
    users.users.alice = mkIf cfg.alice.enable {
      isNormalUser = true;
      description = "Alice";
      extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = cfg.alice.authorizedKeys;
      # Set password with: mkpasswd -m sha-512
      # hashedPassword = "$6$...";
    };
    
    # User bob - regular desktop user  
    users.users.bob = mkIf cfg.bob.enable {
      isNormalUser = true;
      description = "Bob";
      extraGroups = [ "networkmanager" "audio" "video" ];
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = cfg.bob.authorizedKeys;
    };
    
    # Common security settings
    security = {
      # Require password for sudo
      sudo.wheelNeedsPassword = true;
      
      # Enable sudo for wheel group
      sudo.enable = true;
    };
    
    # Shell configurations
    programs.zsh = {
      enable = true;
      enableCompletion = true;
    };
    
    programs.bash.enableCompletion = true;
  };
}