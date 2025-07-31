# Workstation configuration
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
  
  # Enable networking
  networking.networkmanager.enable = true;
  
  # Basic system
  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Sound is configured in the workstation profile
  
  # OpenGL
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  
  # Basic packages for workstation
  environment.systemPackages = with pkgs; [
    vim
    wget
    firefox
    git
    htop
  ];
  
  # Enable CUPS for printing
  services.printing.enable = true;

  # Enable SSH
  services.openssh.enable = true;

  # Basic user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "24.11";
}