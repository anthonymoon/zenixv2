# Gaming system configuration
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
    ../../modules/common
  ];

  # Boot loader with larger timeout for dual boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 5;
  
  # Gaming kernel
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  
  # Enable networking
  networking.networkmanager.enable = true;
  
  # Basic system
  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Sound is configured in the gaming profile
  
  # OpenGL with 32-bit support for games
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
    ];
  };
  
  # Steam and gaming packages
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  # Gaming packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    firefox
    git
    htop
    discord
    lutris
    wine
    winetricks
    mangohud
    gamemode
  ];
  
  # Gamemode for performance
  programs.gamemode.enable = true;

  # Enable SSH
  services.openssh.enable = true;

  # Gaming user
  users.users.gamer = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "gamemode" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "24.11";
}