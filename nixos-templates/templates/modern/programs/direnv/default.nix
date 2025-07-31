{ config
, lib
, pkgs
, ...
}: {
  programs.direnv = {
    enable = true;
    silent = false;
    loadInNixShell = true;

    # Enable nix-direnv for better Nix integration
    nix-direnv = {
      enable = true;
    };
  };
}
