# Server configuration
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
    ../../modules/common
  ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Server kernel
  boot.kernelPackages = pkgs.linuxPackages_hardened;
  
  # Networking
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };
  
  # Basic system
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  
  # Server packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    wget
    curl
    ncdu
    iotop
  ];

  # Enable SSH with hardening
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };
  
  # Fail2ban for SSH protection
  services.fail2ban.enable = true;
  
  # Automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  # Admin user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # Disable password for sudo
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.11";
}