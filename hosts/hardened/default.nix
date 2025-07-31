# Hardened security-focused configuration
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/hardened.nix")
    ./hardware-configuration.nix
    ../../modules/common
  ];

  # Secure boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0; # No timeout for security
  
  # Hardened kernel
  boot.kernelPackages = pkgs.linuxPackages_hardened;
  
  # Security kernel parameters
  boot.kernel.sysctl = {
    # Network hardening
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
    
    # Kernel hardening
    "kernel.kptr_restrict" = 2;
    "kernel.yama.ptrace_scope" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "kernel.ftrace_enabled" = lib.mkDefault false;
  };
  
  # Strict firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    allowPing = false;
  };
  
  # Basic system
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  
  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];
  
  # No unnecessary services
  services.openssh.enable = false;
  
  # Security options
  security = {
    sudo.wheelNeedsPassword = true;
    sudo.execWheelOnly = true;
    hideProcessInformation = true;
    lockKernelModules = true;
    protectKernelImage = true;
    allowSimultaneousMultithreading = false;
    forcePageTableIsolation = true;
    virtualisation.flushL1DataCache = "always";
  };
  
  # AppArmor
  security.apparmor.enable = true;
  
  # Audit
  security.audit.enable = true;
  security.auditd.enable = true;

  # Admin user with minimal privileges
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$rounds=424242$YourHashedPasswordHere"; # mkpasswd -m sha-512 -R 424242
  };
  
  # Disable root
  users.users.root.hashedPassword = "!";

  system.stateVersion = "24.11";
}