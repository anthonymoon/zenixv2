{ config
, lib
, pkgs
, ...
}: {
  programs.tmux = {
    enable = true;

    # Tmux configuration options
    clock24 = true;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    shortcut = "b"; # Default prefix key
    terminal = "screen-256color";

    extraConfig = ''
      # Add custom tmux configuration here
      set -g mouse on
    '';
  };
}
