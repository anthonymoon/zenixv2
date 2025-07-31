{ config, lib, pkgs, ... }:

{
  # Security hardened system configuration
  
  # Hardened kernel
  boot.kernelPackages = pkgs.linuxPackages_hardened;
  
  # Security-focused kernel parameters
  boot.kernelParams = [
    "slab_nomerge"
    "slub_debug=FZP"
    "page_poison=1"
    "pti=on"
  ];

  # Enhanced security settings
  security = {
    sudo.enable = false; # Use doas instead
    doas = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
        keepEnv = true;
        persist = true;
      }];
    };
    
    # AppArmor profiles
    apparmor.enable = true;
    
    # Audit system
    auditd.enable = true;
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowPing = false;
    logReversePathDrops = true;
  };

  # Disable unnecessary services
  services = {
    printing.enable = false;
    avahi.enable = false;
    # Keep SSH but harden it
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        Protocol = "2";
      };
    };
  };

  # Security-focused packages
  environment.systemPackages = with pkgs; [
    fail2ban
    clamav
    rkhunter
    chkrootkit
  ];
}
