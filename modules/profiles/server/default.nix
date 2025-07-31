# Server profile - optimized for server workloads
{ config, lib, pkgs, ... }:

{
  imports = [
    ../minimal
  ];
  
  # Server packages
  environment.systemPackages = with pkgs; [
    # Monitoring
    htop
    iotop
    iftop
    nload
    vnstat
    
    # Administration
    tmux
    screen
    ncdu
    tree
    rsync
    
    # Network tools
    tcpdump
    nmap
    traceroute
    dig
    whois
    
    # Text processing
    jq
    yq
    ripgrep
    
    # Backup
    restic
    rclone
  ];
  
  # Server optimizations
  boot.kernel.sysctl = {
    # Network performance
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    
    # Connection handling
    "net.core.somaxconn" = 65535;
    "net.ipv4.tcp_max_syn_backlog" = 65535;
    "net.core.netdev_max_backlog" = 65536;
    
    # Memory
    "vm.swappiness" = 10;
  };
  
  # Hardening
  networking.firewall.enable = lib.mkDefault true;
  services.fail2ban.enable = lib.mkDefault true;
  
  # SSH hardening
  services.openssh = {
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "no";
      KbdInteractiveAuthentication = lib.mkDefault false;
    };
  };
  
  # Automatic updates
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    allowReboot = lib.mkDefault false;
    dates = "02:00";
  };
  
  # Log rotation
  services.logrotate.enable = true;
  
  # System monitoring
  services.netdata = {
    enable = lib.mkDefault true;
    config = {
      global = {
        "memory mode" = "ram";
        "update every" = 2;
      };
    };
  };
}