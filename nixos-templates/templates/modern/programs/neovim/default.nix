{ config
, lib
, pkgs
, ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      customRC = ''
        " Add your neovim configuration here
        set number
        set relativenumber
      '';

      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          # Add vim plugins here
          # vim-nix
          # vim-airline
        ];
      };
    };
  };
}
