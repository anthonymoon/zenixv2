# Basic security hardening
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Firewall
  networking.firewall = {
    enable = lib.mkDefault true;
    allowPing = lib.mkDefault false;
    logRefusedConnections = lib.mkDefault false;
  };

  # SSH hardening
  services.openssh = {
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "no";
      KbdInteractiveAuthentication = lib.mkDefault false;
      X11Forwarding = lib.mkDefault false;
    };
  };

  # Sudo configuration
  security.sudo = {
    wheelNeedsPassword = lib.mkDefault true;
    execWheelOnly = lib.mkDefault true;
  };

  # Basic kernel hardening
  boot.kernel.sysctl = {
    # Network
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1;

    # Kernel
    "kernel.kptr_restrict" = lib.mkDefault 1;
    "kernel.yama.ptrace_scope" = lib.mkDefault 1;
  };

  # Disable unused network protocols
  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
  ];
}
