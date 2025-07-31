# Development profile - programming and development tools
{ config, lib, pkgs, ... }:

{
  imports = [
    ../workstation
  ];
  
  # Development packages
  environment.systemPackages = with pkgs; [
    # Editors and IDEs
    vscode
    neovim
    emacs
    jetbrains.idea-community
    
    # Version control
    git
    git-lfs
    tig
    lazygit
    gh
    
    # Languages and compilers
    gcc
    clang
    rustup
    go
    python3Full
    nodejs
    deno
    elixir
    
    # Build tools
    gnumake
    cmake
    ninja
    meson
    pkg-config
    
    # Debugging
    gdb
    valgrind
    strace
    ltrace
    
    # Containers
    docker-compose
    podman
    buildah
    
    # Development utilities
    direnv
    httpie
    jq
    yq
    ripgrep
    fd
    bat
    exa
    tokei
    hyperfine
    
    # Documentation
    zeal
    
    # Database clients
    postgresql
    mysql
    redis
    sqlite
  ];
  
  # Programming language support
  programs.java.enable = true;
  
  # Development services
  services.postgresql = {
    enable = lib.mkDefault false; # Enable when needed
    package = pkgs.postgresql_15;
  };
  
  services.redis.servers."".enable = lib.mkDefault false;
  
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  
  # Podman as docker alternative
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  
  # Development environment
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  
  services.lorri.enable = true;
  
  # Git configuration
  programs.git = {
    enable = true;
    lfs.enable = true;
  };
}