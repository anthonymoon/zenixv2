{ config, lib, pkgs, ... }:

{
  # Development-focused system configuration
  
  # Development tools and environments
  environment.systemPackages = with pkgs; [
    # Version control
    git
    git-lfs
    gh
    
    # Editors and IDEs
    neovim
    vscode
    
    # Programming languages
    python3
    nodejs
    rustc
    cargo
    go
    
    # Build tools
    gnumake
    cmake
    gcc
    clang
    
    # Development utilities
    jq
    ripgrep
    fd
    bat
    exa
    tree
    tmux
    
    # Network tools
    curl
    wget
    httpie
    
    # Container tools
    docker
    docker-compose
    
    # Database tools
    sqlite
    postgresql
  ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Development services
  services = {
    # Database services (optional, can be enabled per-project)
    postgresql = {
      enable = false; # Enable per-project as needed
      package = pkgs.postgresql_15;
    };
    
    # Redis for caching
    redis = {
      servers."" = {
        enable = false; # Enable per-project as needed
        port = 6379;
      };
    };
  };

  # Shell configuration
  programs = {
    zsh.enable = true;
    fish.enable = true;
    starship.enable = true;
  };

  # Increase file limits for development
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "65536";
    }
  ];
}
