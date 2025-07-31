# Hardened profile - maximum security
{ config, lib, pkgs, ... }:

{
  imports = [
    ../minimal
  ];
  
  # Use hardened kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_hardened;
  
  # Hardening flags
  boot.kernelParams = [
    "page_alloc.shuffle=1"
    "slab_nomerge"
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
    "quiet"
    "loglevel=0"
  ];
  
  # Security-focused kernel settings
  boot.kernel.sysctl = {
    # Kernel hardening
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.printk" = "3 3 3 3";
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.yama.ptrace_scope" = 2;
    "net.core.bpf_jit_harden" = 2;
    "dev.tty.ldisc_autoload" = 0;
    "vm.unprivileged_userfaultfd" = 0;
    "kernel.kexec_load_disabled" = 1;
    "kernel.sysrq" = 0;
    
    # Network hardening
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv4.tcp_sack" = 0;
    "net.ipv4.tcp_dsack" = 0;
    "net.ipv4.tcp_fack" = 0;
  };
  
  # Security services
  security = {
    lockKernelModules = lib.mkDefault true;
    protectKernelImage = lib.mkDefault true;
    allowSimultaneousMultithreading = lib.mkDefault false;
    forcePageTableIsolation = lib.mkDefault true;
    virtualisation.flushL1DataCache = lib.mkDefault "always";
    
    apparmor.enable = lib.mkDefault true;
    audit.enable = lib.mkDefault true;
    auditd.enable = lib.mkDefault true;
    
    sudo = {
      wheelNeedsPassword = lib.mkDefault true;
      execWheelOnly = lib.mkDefault true;
    };
  };
  
  # Minimal services
  services = {
    # No X11
    xserver.enable = lib.mkForce false;
    
    # No printing
    printing.enable = lib.mkForce false;
    
    # No avahi
    avahi.enable = lib.mkForce false;
  };
  
  # Strict firewall
  networking.firewall = {
    enable = lib.mkDefault true;
    allowedTCPPorts = lib.mkDefault [ ];
    allowedUDPPorts = lib.mkDefault [ ];
    allowPing = lib.mkDefault false;
    logRefusedConnections = lib.mkDefault true;
    logRefusedPackets = lib.mkDefault true;
  };
  
  # No unnecessary firmware
  hardware.enableRedistributableFirmware = lib.mkDefault false;
  hardware.enableAllFirmware = lib.mkDefault false;
}