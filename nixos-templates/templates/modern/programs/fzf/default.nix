{ config
, lib
, pkgs
, ...
}: {
  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };
}
