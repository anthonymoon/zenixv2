{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Shells
    bash
    dash

    # Shell enhancements
    bash-completion

    # Prompt
    starship
    powerline-go

    # Shell utilities
    direnv
    thefuck

    # History management
    mcfly
    atuin

    # Shell scripting tools
    shellcheck
    shfmt

    # Command line helpers
    tldr
    navi
    howdoi
  ];

  # Enable bash
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };
}
