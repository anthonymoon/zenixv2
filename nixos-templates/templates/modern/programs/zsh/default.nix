{ config
, lib
, pkgs
, ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # Add any zsh-specific aliases here
    };

    interactiveShellInit = ''
      # Add any zsh-specific initialization here
    '';

    promptInit = ''
      # Prompt initialization (if not using starship)
    '';

    histSize = 100000;
    histFile = "$HOME/.zsh_history";

    setOptions = [
      "HIST_IGNORE_DUPS"
      "SHARE_HISTORY"
      "HIST_FCNTL_LOCK"
    ];
  };

  environment.systemPackages = with pkgs; [
    zsh
    zsh-completions
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-powerlevel10k
    zsh-prezto
    oh-my-zsh
    zsh-fzf-tab
    zsh-fzf-history-search
    zsh-vi-mode
    zsh-nix-shell
    nix-zsh-completions
  ];
}
