# Development machine configuration
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
  
  # Sound is configured in the development profile
  
  # OpenGL
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  
  # Development tools
  programs.git.enable = true;
  programs.direnv.enable = true;
  
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  # Development packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    vscode
    
    # Version control
    git
    git-lfs
    
    # Languages
    gcc
    python3
    nodejs
    rustc
    cargo
    go
    
    # Tools
    gnumake
    cmake
    pkg-config
    binutils
    
    # Utilities
    wget
    curl
    htop
    tmux
    ripgrep
    fd
    jq
    tree
    
    # Browsers
    firefox
    chromium
  ];
  
  # Enable lorri for nix-shell
  services.lorri.enable = true;

  # Enable SSH
  services.openssh.enable = true;

  # Developer user
  users.users.dev = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "docker" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "24.11";
}