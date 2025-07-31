# Common headless server profile
{ config, lib, pkgs, ... }:

{
  # Disable graphical services
  services.xserver.enable = lib.mkForce false;
  hardware.opengl.enable = lib.mkForce false;
  sound.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;

  # Server-oriented packages
  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
    iotop
    nethogs
    
    # Network tools
    tcpdump
    nmap
    
    # File tools
    rsync
    rclone
    
    # Development
    git
    
    # Text processing
    jq
    
    # System utilities
    lsof
    psmisc
    pciutils
    usbutils
  ];

  # Server services
  services = {
    # System monitoring
    smartd = {
      enable = lib.mkDefault true;
      autodetect = lib.mkDefault true;
    };
    
    # Log management
    journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=7day
    '';
  };

  # Optimize for server use
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  
  # Security hardening for servers
  security = {
    pam.loginLimits = [
      { domain = "*"; item = "nofile"; type = "soft"; value = "65536"; }
      { domain = "*"; item = "nofile"; type = "hard"; value = "65536"; }
    ];
  };

  # Network optimization
  boot.kernel.sysctl = {
    # Network performance
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    
    # Security
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
  };

  # Firewall for servers
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH only by default
    logReversePathDrops = true;
  };
}
