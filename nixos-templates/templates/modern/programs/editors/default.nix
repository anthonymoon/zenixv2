{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Terminal editors
    neovim
    vim
    emacs
    micro
    nano

    # Code editors (CLI-capable)
    helix
    kakoune

    # Enhanced vim
    neovim
    vimPlugins.vim-plug
    vimPlugins.nerdtree
    vimPlugins.vim-airline

    # Editor utilities
    editorconfig-core-c

    # Language servers
    nil # Nix
    rust-analyzer
    gopls
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted

    # Linters and formatters
    nixpkgs-fmt
    rustfmt
    gofmt
    prettier
    black

    # Documentation
    tldr
    cheat
  ];
}
