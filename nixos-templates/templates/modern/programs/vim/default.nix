{ config
, lib
, pkgs
, ...
}: {
  programs.vim = {
    enable = true;
    defaultEditor = false; # Set to true if vim should be the default editor
  };
}
